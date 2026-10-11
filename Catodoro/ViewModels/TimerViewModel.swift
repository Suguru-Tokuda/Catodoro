//
//  TimerViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import AVFoundation
import Combine
import CatodoroShared
import Foundation
import UIKit

enum TimerActions {
    case start
    case pause
    case resume
    case stop
    case finish
}

/// One snapshot drives the countdown, ring, session indicators and available actions.
struct TimerPresentationState: Equatable {
    let isBreak: Bool
    let status: TimerStatus
    let sessionIndex: Int
    let sessionCount: Int
    let remainingDuration: TimeInterval
    let phaseDuration: TimeInterval

    var progress: CGFloat {
        guard phaseDuration > 0 else {
            return 0
        }

        return CGFloat(min(1, max(0, 1 - remainingDuration / phaseDuration)))
    }

    var countdown: String {
        let seconds = Int(ceil(max(0, remainingDuration)))

        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }

        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    var phaseTitle: String {
        status == .finished ? "Routine complete" : (isBreak ? "Catnap break" : "Focus session")
    }

    var sessionSummary: String {
        status == .finished ? "\(sessionCount) sessions completed"
            : "\(sessionIndex) of \(isBreak ? max(0, sessionCount - 1) : sessionCount)"
    }
}

class TimerViewModel {
    private(set) var currentTimerValue: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var intervalDuration: TimeInterval = 0
    private var intervals = 0
    private(set) var duration: TimeInterval = 0
    private var interval = 1
    private var timerType: TimerType? = .main
    private var deadline: Date?
    private var backgroundTimer: DispatchSourceTimer?
    private var generation = 0
    private let now: () -> Date
    private let schedulesTicks: Bool
    private let applicationIsActive: () -> Bool
    private var preferenceSubscription: AnyCancellable?
    private var liveActivityTask: Task<Void, Never>?
    private var liveActivityGeneration = 0
    private(set) var liveActivityError: Error?
    private(set) var audioError: Error?

    let presentationSubject = CurrentValueSubject<TimerPresentationState, Never>(
        .init(isBreak: false, status: .paused, sessionIndex: 1, sessionCount: 0,
              remainingDuration: 0, phaseDuration: 0))
    let timerSubject = PassthroughSubject<String, Never>()
    let timerStatusSubject = PassthroughSubject<TimerStatus, Never>()
    let timerActionSubject = CurrentValueSubject<TimerActions, Never>(.stop)
    let timerLabelSubject = PassthroughSubject<String, Never>()
    let timerIntervalSubject = PassthroughSubject<TimeInterval, Never>()

    private var audioManager: AudioManaging
    private weak var preferences: CatodoroPreferencesProtocol?
    private weak var liveActivityManager: LiveActivityManaging?

    private(set) var timerStatus: TimerStatus = .paused

    init(audioManager: AudioManaging = AudioManager(),
         preferences: CatodoroPreferencesProtocol?,
         liveActivityManager: LiveActivityManaging? = LiveActivityManager(),
         now: @escaping () -> Date = Date.init,
         schedulesTicks: Bool = true,
         applicationIsActive: @escaping () -> Bool = { UIApplication.shared.applicationState == .active }) {
        self.audioManager = audioManager
        self.preferences = preferences
        self.liveActivityManager = liveActivityManager
        self.now = now
        self.schedulesTicks = schedulesTicks
        self.applicationIsActive = applicationIsActive
        addNotificationCenterSubscriptions()
        setupPlayerSound()
        preferenceSubscription = preferences?.liveActivityPublisher
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }

                if enabled && self.intervals > 0 && self.timerActionSubject.value != .stop {
                    self.startLiveActivity()
                    self.updateLiveActivity()
                } else if !enabled {
                    self.endLiveActivity()
                }
            }
    }

    private var endTime: Date {
        deadline ?? now().addingTimeInterval(currentTimerValue)
    }

    var isBreak: Bool {
        timerType == .interval
    }

    var timerNameString: String {
        isBreak ? "Catnap break \(interval)" : "Focus session \(interval)"
    }

    func configure(totalDuration: TimeInterval, intervalDuration: TimeInterval, intervals: Int) {
        guard totalDuration.isFinite, totalDuration > 0,
              intervalDuration.isFinite, intervalDuration >= 0, (1...20).contains(intervals) else {
            return
        }

        self.totalDuration = totalDuration
        self.intervalDuration = intervalDuration
        self.intervals = intervals
        resetTimer()
        let configuredGeneration = generation
        DispatchQueue.main.async { [weak self] in
            guard let self, generation == configuredGeneration else {
                return
            }

            startTimer()
        }
    }

    func handlePlayPauseButtonTap() {
        switch timerStatus {
        case .playing:
            pauseTimer()
        case .paused:
            resumeTimer()
        case .finished:
            repeatTimer()
        }
    }

    func startTimer() {
        guard duration > 0 else {
            return
        }

        generation += 1
        currentTimerValue = duration
        deadline = now().addingTimeInterval(duration)
        timerStatus = .playing
        setupBackgroundTimer()
        publishState()
        timerActionSubject.send(.start)
        startLiveActivity()
    }

    func pauseTimer() {
        refresh()
        guard timerStatus == .playing else {
            return
        }

        generation += 1
        deadline = nil
        cancelBackgroundTimer()
        timerStatus = .paused
        publishState()
        timerActionSubject.send(.pause)
        updateLiveActivity()
    }

    func resumeTimer() {
        guard timerStatus == .paused, currentTimerValue > 0 else {
            return
        }

        generation += 1
        deadline = now().addingTimeInterval(currentTimerValue)
        timerStatus = .playing
        setupBackgroundTimer()
        publishState()
        timerActionSubject.send(.resume)
        startLiveActivity()
        updateLiveActivity()
    }

    func finishTimer() {
        currentTimerValue = 0
        deadline = nil
        cancelBackgroundTimer()
        timerStatus = .finished
        publishState()
        timerActionSubject.send(.finish)
        notifyPhaseChange(isComplete: true)
    }

    /// A skipped break starts the next full focus session, including when the break was paused.
    func skipBreak() {
        let wasBreak = isBreak
        refresh()
        guard wasBreak, isBreak, timerStatus != .finished, interval < intervals else { return }

        generation += 1
        interval += 1
        timerType = .main
        duration = totalDuration
        currentTimerValue = totalDuration
        timerStatus = .playing
        deadline = now().addingTimeInterval(totalDuration)
        setupBackgroundTimer()
        publishState()
        timerActionSubject.send(.start)
        notifyPhaseChange(isComplete: false)
    }

    func stopTimer() {
        resetTimer()
        timerActionSubject.send(.stop)
        endLiveActivity()
    }

    private func repeatTimer() {
        resetTimer()
        startTimer()
        updateLiveActivity()
    }

    func resetTimer() {
        generation += 1
        stopSound()
        cancelBackgroundTimer()
        deadline = nil
        timerType = .main
        duration = totalDuration
        currentTimerValue = totalDuration
        timerStatus = .paused
        interval = 1
        publishState()
    }

    /// Deadline reconciliation also consumes missed phases after app suspension.
    func refresh() {
        guard timerStatus == .playing, var phaseDeadline = deadline else {
            return
        }

        let instant = now()
        var changedPhase = false

        while instant >= phaseDeadline {
            if !isBreak && interval >= intervals {
                finishTimer()
                return
            }

            if !isBreak && intervalDuration > 0 {
                timerType = .interval
                duration = intervalDuration
            } else {
                interval += 1
                timerType = .main
                duration = totalDuration
            }

            phaseDeadline = phaseDeadline.addingTimeInterval(duration)
            deadline = phaseDeadline
            changedPhase = true
        }

        currentTimerValue = min(duration, max(0, phaseDeadline.timeIntervalSince(instant)))
        publishState()

        if changedPhase {
            timerActionSubject.send(.start)
            notifyPhaseChange(isComplete: false)
        }
    }

    private func publishState() {
        presentationSubject.send(.init(isBreak: isBreak, status: timerStatus,
            sessionIndex: interval, sessionCount: intervals,
            remainingDuration: currentTimerValue, phaseDuration: duration))
        timerSubject.send(currentTimerValue.getTimerLabelValue())
        timerStatusSubject.send(timerStatus)
        timerLabelSubject.send(timerNameString)
        timerIntervalSubject.send(currentTimerValue)
    }

    private func setupBackgroundTimer() {
        cancelBackgroundTimer()
        guard schedulesTicks else {
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 0.2)
        timer.setEventHandler { [weak self] in
            self?.refresh()
        }
        backgroundTimer = timer
        timer.resume()
    }

    private func cancelBackgroundTimer() {
        backgroundTimer?.cancel()
        backgroundTimer = nil
    }

    private func addNotificationCenterSubscriptions() {
        let notifications: [(Notification.Name, Selector)] = [
            (UIApplication.didBecomeActiveNotification, #selector(handleAppDidBecomeActive)),
            (.skipBreakActionTriggered, #selector(handleSkipBreakAction)),
            (.playTimerActionTriggered, #selector(handlePlayTimerAction)),
            (.stopTimerActionTriggered, #selector(handleStopTimerAction)),
            (.repeatTimerActionTriggered, #selector(handleRepeatTimerAction))
        ]

        for (name, selector) in notifications {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
    }

    @objc private func handleAppDidBecomeActive() {
        refresh()
        updateLiveActivity()
    }

    @objc private func handleSkipBreakAction() {
        skipBreak()
    }

    @objc private func handlePlayTimerAction() {
        handlePlayPauseButtonTap()
    }

    @objc private func handleStopTimerAction() {
        stopTimer()
    }

    @objc private func handleRepeatTimerAction() {
        repeatTimer()
    }

    private func setupPlayerSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName

        enqueueAudioOperation { manager in
            try manager.setPlayer(fileName: fileName, fileExtension: "mp3")
        }
    }

    private func notifyPhaseChange(isComplete: Bool) {
        if applicationIsActive() {
            if isComplete {
                playFinishSound()
            } else {
                playIntermediateSound()
            }

            updateLiveActivity()
        } else {
            updateLiveActivity(with: SoundOptions(preferences?.sound ?? "").fileName)
        }
    }

    func playFinishSound() {
        playCue()
    }

    func playIntermediateSound() {
        playCue()
    }

    private func playCue() {
        enqueueAudioOperation { manager in
            try manager.play(numberOfLoops: 0)
        }
    }

    func stopSound() {
        enqueueAudioOperation { manager in
            try manager.stop()
        }
    }

    private func enqueueAudioOperation(_ operation: @escaping (AudioManaging) throws -> Void) {
        let manager = audioManager
        AudioManager.playbackQueue.async { [weak self] in
            let error: Error?

            do {
                try operation(manager)
                error = nil
            } catch let operationError {
                error = operationError
            }

            DispatchQueue.main.async { [weak self] in
                self?.audioError = error
            }
        }
    }

    var audioState: AudioState {
        audioManager.audioState
    }

    deinit {
        liveActivityTask?.cancel()
        cancelBackgroundTimer()
        NotificationCenter.default.removeObserver(self)
        let manager = audioManager
        AudioManager.playbackQueue.async {
            try? manager.stop()
        }
        liveActivityManager?.endLiveActivity()
    }
}

// MARK: - Live Activity

extension TimerViewModel {
    private func startLiveActivity() {
        guard preferences?.liveActivityEnabled != false,
              let liveActivityManager, !liveActivityManager.hasLiveActivity() else { return }
        do {
            liveActivityError = nil
            try liveActivityManager.startLiveActivity(name: "Catodoro Timer",
                                                      currentTimerValue: currentTimerValue,
                                                      endTime: endTime,
                                                      intervals: intervals,
                                                      interval: interval,
                                                      timerType: timerType ?? .main,
                                                      timerStatus: timerStatus,
                                                      phaseDuration: duration,
                                                      accentCode: preferences?.color)

        } catch {
            liveActivityError = error
        }
    }

    private func updateLiveActivity(with sound: String? = nil) {
        guard preferences?.liveActivityEnabled != false, let liveActivityManager else { return }
        let value = currentTimerValue
        let end = endTime
        let count = intervals
        let session = interval
        let phase = timerType ?? .main
        let status = timerStatus
        let phaseDuration = duration
        let accent = preferences?.color
        let previous = liveActivityTask
        let generation = liveActivityGeneration
        liveActivityTask = Task { [weak self] in
            await previous?.value
            guard !Task.isCancelled,
                  let self, self.liveActivityGeneration == generation,
                  self.preferences?.liveActivityEnabled != false else { return }

            await liveActivityManager.updateLiveActivity(currentTimerValue: value,
                                                        endTime: end,
                                                        intervals: count,
                                                        interval: session,
                                                        timerType: phase,
                                                        timerStatus: status,
                                                        soundName: sound,
                                                        phaseDuration: phaseDuration,
                                                        accentCode: accent)
        }
    }

    private func endLiveActivity() {
        liveActivityGeneration += 1
        liveActivityTask?.cancel()
        guard let liveActivityManager else { return }
        liveActivityManager.endLiveActivity()
    }
}

#if DEBUG
extension TimerViewModel {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerViewModel

        func flushLiveActivityOperations() async {
            await target.liveActivityTask?.value
        }

        func flushAudioOperations() async {
            await withCheckedContinuation { continuation in
                AudioManager.playbackQueue.async {
                    DispatchQueue.main.async {
                        continuation.resume()
                    }
                }
            }
        }

        var totalDuration: TimeInterval? { target.totalDuration }
        var intervalDuration: TimeInterval? { target.intervalDuration }
        var timerType: TimerType? { target.timerType }
        var timerStatus: TimerStatus { target.timerStatus }
        var backgroundTimer: DispatchSourceTimer? { target.backgroundTimer }
    }
}
#endif
