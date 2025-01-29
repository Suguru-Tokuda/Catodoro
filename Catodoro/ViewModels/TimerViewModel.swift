//
//  TimerViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import AVFoundation
import Combine
import CatodoroShared
import Darwin
import Foundation
import UIKit

enum TimerActions {
    case start
    case pause
    case resume
    case stop
    case finish
}

class TimerViewModel {
    var currentTimerValue: TimeInterval = 0 // Could be timerTime or intervalTime
    private var totalDuration: TimeInterval = 0
    private var intervalDuration: TimeInterval = 0 // in seconds
    private let timerInterval: Double = 0.01 // used to update the timer for every x seconds.
    private var intervals: Int = 0
    var duration: TimeInterval = 0

    private var endTime: Date {
        return Date.now + currentTimerValue
    }

    // MARK: Publishers
    /// Used to send updated string representation of
    /// timer value for timer label
    var timerSubject: PassthroughSubject<String, Never> = .init()
    var timerStatusSubject: PassthroughSubject<TimerStatus, Never> = .init()
    var timerActionSubject: CurrentValueSubject<TimerActions, Never> = .init(.stop)
    var timerLabelSubject: PassthroughSubject<String, Never> = .init()
    var timerIntervalSubject: PassthroughSubject<TimeInterval, Never> = .init()

    private var intermediateSoundDuration = 1.0
    private var interval: Int = 1
    private var intermediateSoundTimer: Timer?
    private var timerType: TimerType?
    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: extra properties
    private var backgroundEntryTime: Date?
    private var lastTimerValue: TimeInterval?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: DispatchSourceTimer?
    private let backgroundTimerTaskName = "Catodoro.BackgroundTimerTask"
    private let backgroundTimerInterval: Double = 1

    // MARK: Dependencies
    private var audioManager: AudioManaging
    private weak var preferences: CatodoroPreferencesProtocol?
    private weak var liveActivityManager: LiveActivityManaging?

    init(audioManager: AudioManaging = AudioManager(),
         preferences: CatodoroPreferencesProtocol?,
         liveActivityManager: LiveActivityManaging? = LiveActivityManager()) {
        self.audioManager = audioManager
        self.preferences = preferences
        self.liveActivityManager = liveActivityManager
        addSubscriptions()
        setupPlayerSound()
    }

    private func addSubscriptions() {
        timerIntervalSubject
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] value in
                guard let self else { return }
                handleTimerValueChange(value: value)
            }
            .store(in: &cancellables)

        addNotificationCenterSubscriptions()
    }

    private func addNotificationCenterSubscriptions() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePlayTimerAction),
                                               name: .playTimerActionTriggered,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleStopTimerAction),
                                               name: .stopTimerActionTriggered,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRepeatTimerAction),
                                               name: .repeatTimerActionTriggered,
                                               object: nil)

    }

    private func removeSubscriptions() {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    var timerStatus: TimerStatus = .paused {
        didSet {
            timerStatusSubject.send(timerStatus)
        }
    }

    func configure(totalDuration: TimeInterval, intervalDuration: TimeInterval, intervals: Int) {
        self.duration = totalDuration
        self.totalDuration = totalDuration
        self.currentTimerValue = totalDuration
        self.intervalDuration = intervalDuration
        self.intervals = intervals
        self.timerType = .main
        interval = 1
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            startTimer()
        }
    }

    func handlePlayPauseButtonTap() {
        switch timerStatus {
        case .paused:
            switch timerActionSubject.value {
            case .finish:
                resetTimer()
            default:
                break
            }
            
            if currentTimerValue == duration {
                startTimer()
            } else {
                resumeTimer()
            }
        case .playing:
            pauseTimer()
        default:
            break
        }
    }

    func startTimer() {
        currentTimerValue = duration
        setupBackgroundTimer()
        timerStatus = .playing
        timerActionSubject.send(.start)        
        startLiveActivity()
    }

    func pauseTimer() {
        guard timerStatus == .playing else { return }
        cancelBackgroundTimer()
        timerStatus = .paused
        timerActionSubject.send(.pause)
        updateLiveActivity()
    }

    func resumeTimer() {
        guard timerStatus == .paused else { return }
        cancelBackgroundTimer()
        setupBackgroundTimer()
        timerStatus = .playing
        timerActionSubject.send(.resume)
        updateLiveActivity()
    }

    func finishTimer() {
        timerStatus = .finished
        updateLiveActivity(with: SoundOptions(preferences?.sound ?? "").fileName)
//        playFinishSound()
    }

    func stopTimer() {
        resetTimer()
        timerLabelSubject.send(timerNameString)
        timerActionSubject.send(.stop)
        endLiveActivity()
    }

    private func repeatTimer() {
        resetTimer()
        timerLabelSubject.send(timerNameString)
        startTimer()
        updateLiveActivity()
    }

    func resetTimer() {
        stopSound()
        cancelBackgroundTimer()
        timerType = .main
        duration = totalDuration
        currentTimerValue = totalDuration
        timerSubject.send(currentTimerValue.getTimerLabelValue())
        timerStatus = .paused
        interval = 1
    }

    var timerNameString: String {
        switch timerType {
        case .main, .none:
            "Timer \(interval)"
        case .interval:
            "Break \(interval)"
        default:
            ""
        }
    }

    private func setupPlayerSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName
        try? audioManager.setPlayer(fileName: fileName, fileExtension: "mp3")
    }
    
    func playFinishSound() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            try? audioManager.play(numberOfLoops: 0)
        }
    }

    func playIntermediateSound() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            try? audioManager.play(numberOfLoops: 0)

            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + intermediateSoundDuration) { [weak self] in
                guard let self else { return }
                guard timerStatus != .finished else { return }
                self.stopSound()
            }
        }
    }

    func stopSound() {
        try? audioManager.stop()
    }

    var audioState: AudioState {
        audioManager.audioState
    }

    private func handleTimerValueChange(value: TimeInterval) {
        if value == 0 {
            if timerType == .interval || intervalDuration == 0 {
                interval += 1
            }
            
            if interval >= intervals && timerType == .main {
                if timerStatus != .finished {
                    timerActionSubject.send(.finish)
                    finishTimer()
                    cancelBackgroundTimer()
                }
            } else {
                timerType = timerType == .main ? .interval : .main
                switch timerType {
                case .interval:
                    duration = intervalDuration
                case .main, .none:
                    duration = totalDuration
                default:
                    break
                }

                startTimer()
                updateLiveActivity(with: SoundOptions(preferences?.sound ?? "").fileName)
//                playIntermediateSound()
            }
        }

        if timerActionSubject.value != .finish {
            timerLabelSubject.send(timerNameString)
        }
    }

    deinit {
        removeSubscriptions()
        liveActivityManager?.endLiveActivity()
    }
}

extension TimerViewModel {
    private func setupBackgroundTimer() {
        let timerQueue = DispatchQueue(label: "com.catodoro.timerQueue", qos: .userInitiated)
        backgroundTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        backgroundTimer?.schedule(deadline: .now(), repeating: timerInterval)

        backgroundTimer?.setEventHandler { [weak self] in
            guard let self else { return }
            currentTimerValue = max(0, currentTimerValue - timerInterval)
            timerIntervalSubject.send(currentTimerValue)
            timerSubject.send(currentTimerValue.getTimerLabelValue())
        }

        backgroundTimer?.resume()
    }

    private func cancelBackgroundTimer() {
        backgroundTimer?.cancel()
        backgroundTimer = nil
    }
}

// Remote Control Configurations

extension TimerViewModel {
    @objc private func handleAppWillResignActive() {
        guard timerStatus == .playing else { return }
        lastTimerValue = currentTimerValue
    }

    @objc private func handleAppDidBecomeActive() {
        guard let entryTime = backgroundEntryTime,
                let lastTimerValue else { return }
        let elapstedTime = Date().timeIntervalSince(entryTime)
        let newTimerValue = max(0, lastTimerValue - elapstedTime)
        currentTimerValue = newTimerValue
        self.lastTimerValue = nil
    
        // Resume the timer if necessary
        if timerStatus == .playing {
            resumeTimer()
        }
    }

    @objc private func handlePlayTimerAction() {
        switch timerStatus {
        case .paused:
            resumeTimer()
        case .playing:
            pauseTimer()
        default:
            break
        }
        updateLiveActivity()
    }

    @objc private func handleStopTimerAction() {
        stopTimer()
    }

    @objc private func handleRepeatTimerAction() {
        repeatTimer()
    }
}

// MARK: - Live Acitivity

extension TimerViewModel {
    private func startLiveActivity() {
        guard let liveActivityManager, !liveActivityManager.hasLiveActivity() else { return }
        do {
            try liveActivityManager.startLiveActivity(name: "Catodoro Timer",
                                                      currentTimerValue: currentTimerValue,
                                                      endTime: endTime,
                                                      intervals: intervals,
                                                      interval: interval,
                                                      timerType: timerType ?? .main,
                                                      timerStatus: timerStatus)

        } catch {
            // TODO: Do something with
        }
    }

    private func updateLiveActivity(with sound: String? = nil) {
        guard let liveActivityManager else { return }
        Task { [weak self] in
            guard let self else { return }
            await liveActivityManager.updateLiveActivity(currentTimerValue: currentTimerValue,
                                                         endTime: endTime,
                                                         intervals: intervals,
                                                         interval: interval,
                                                         timerType: timerType ?? .main,
                                                         timerStatus: timerStatus,
                                                         soundName: sound)
        }
    }

    private func endLiveActivity() {
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

        var totalDuration: TimeInterval? { target.totalDuration }
        var intervalDuration: TimeInterval? { target.intervalDuration }
        var timerType: TimerType? { target.timerType }
        var timerStatus: TimerStatus { target.timerStatus }
        var backgroundTimer: DispatchSourceTimer? { target.backgroundTimer }
    }
}
#endif
