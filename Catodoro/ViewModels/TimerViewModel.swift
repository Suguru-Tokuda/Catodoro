// TimerViewModel.swift
// Catodoro
// Created by Suguru Tokuda on 8/21/24.

import AVFoundation
import Combine
import CatodoroShared
import Foundation
import UIKit

enum TimerActions {
    case start, pause, resume, stop, finish
}

class TimerViewModel {
    // MARK: - Properties

    // Timer values
    var currentTimerValue: TimeInterval = 0
    private var totalDuration: TimeInterval = 0
    private var intervalDuration: TimeInterval = 0
    private let timerInterval: Double = 0.01
    private var intervals: Int = 0
    var duration: TimeInterval = 0
    
    // Publishers
    var timerSubject = PassthroughSubject<String, Never>()
    var timerStatusSubject = PassthroughSubject<TimerStatus, Never>()
    var timerActionSubject = CurrentValueSubject<TimerActions, Never>(.stop)
    var timerLabelSubject = PassthroughSubject<String, Never>()
    var timerIntervalSubject = PassthroughSubject<TimeInterval, Never>()

    // Sound-related properties
    private var intermediateSoundDuration = 1.0
    private var interval: Int = 1
    private var intermediateSoundTimer: Timer?
    
    // State properties
    private var timerType: TimerType?
    private var cancellables = Set<AnyCancellable>()
    private var lastTimerLabelDisplayed: String?
    private var timerStatus: TimerStatus = .paused {
        didSet { timerStatusSubject.send(timerStatus) }
    }

    // Background timer
    private var backgroundEntryTime: Date?
    private var lastTimerValue: TimeInterval?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: DispatchSourceTimer?
    private let backgroundTimerTaskName = "Catodoro.BackgroundTimerTask"
    private let backgroundTimerInterval: Double = 1

    // Dependencies
    private var audioManager: AudioManaging
    private weak var preferences: CatodoroPreferencesProtocol?
    private weak var liveActivityManager: LiveActivityManaging?

    // MARK: - Initializer
    init(audioManager: AudioManaging = AudioManager(),
         preferences: CatodoroPreferencesProtocol?,
         liveActivityManager: LiveActivityManaging? = LiveActivityManager()) {
        self.audioManager = audioManager
        self.preferences = preferences
        self.liveActivityManager = liveActivityManager
        addSubscriptions()
        setupPlayerSound()
    }

    // MARK: - Configuration
    func configure(totalDuration: TimeInterval, intervalDuration: TimeInterval, intervals: Int) {
        self.totalDuration = totalDuration
        self.intervalDuration = intervalDuration
        self.intervals = intervals
        self.duration = totalDuration
        self.currentTimerValue = totalDuration
        self.timerType = .main
        self.interval = 1

        DispatchQueue.main.async { [weak self] in self?.startTimer() }
    }

    // MARK: - Timer Controls
    func handlePlayPauseButtonTap() {
        switch timerStatus {
        case .paused:
            if timerActionSubject.value == .finish {
                resetTimer()
            } else if currentTimerValue == duration {
                startTimer()
            } else {
                resumeTimer()
            }
        case .playing:
            pauseTimer()
        default: break
        }
    }

    func startTimer() {
        currentTimerValue = duration
        if backgroundTimer == nil {
            setupBackgroundTimer()

            backgroundTimer?.setEventHandler { [weak self] in
                self?.updateTimerValue()
            }
            backgroundTimer?.resume()
        }

        timerStatus = .playing
        timerActionSubject.send(.start)
        startLiveActivity()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func pauseTimer() {
        guard timerStatus == .playing else { return }
        cancelBackgroundTimer()
        timerStatus = .paused
        timerActionSubject.send(.pause)
        updateLiveActivity()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resumeTimer() {
        guard timerStatus == .paused else { return }
        cancelBackgroundTimer()
        setupBackgroundTimer()
        
        backgroundTimer?.setEventHandler { [weak self] in
            self?.updateTimerValue()
        }
        backgroundTimer?.resume()
        
        timerStatus = .playing
        timerActionSubject.send(.resume)
        updateLiveActivity()
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func finishTimer() {
        cancelBackgroundTimer()
        playFinishSound()
        timerStatus = .paused
        endLiveActivity()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func stopTimer() {
        resetTimer()
        timerLabelSubject.send(timerNameString)
        timerActionSubject.send(.stop)
        endLiveActivity()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resetTimer() {
        cancelBackgroundTimer()
        timerType = .main
        duration = totalDuration
        currentTimerValue = totalDuration
        timerSubject.send(currentTimerValue.getTimerLabelValue())
        timerStatus = .paused
        interval = 1
    }

    // MARK: - Background Timer
    private func setupBackgroundTimer() {
        let timerQueue = DispatchQueue(label: "com.catodoro.timerQueue", qos: .userInitiated)
        backgroundTimer = DispatchSource.makeTimerSource(queue: timerQueue)
        backgroundTimer?.schedule(deadline: .now(), repeating: timerInterval)
    }

    private func cancelBackgroundTimer() {
        backgroundTimer?.cancel()
        backgroundTimer = nil
    }

    private func updateTimerValue() {
        currentTimerValue = max(0, currentTimerValue - timerInterval)

        DispatchQueue.main.async {
            self.timerSubject.send(self.currentTimerValue.getTimerLabelValue())
            self.timerIntervalSubject.send(self.currentTimerValue)
        }
    }

    // MARK: - Sound Management
    private func setupPlayerSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName
        try? audioManager.setPlayer(fileName: fileName, fileExtension: "mp3")
    }

    func playFinishSound() {
        try? audioManager.play(numberOfLoops: 0)
    }

    func playIntermediateSound() {
        stopSound()
        try? audioManager.play(numberOfLoops: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + intermediateSoundDuration) { [weak self] in
            self?.stopSound()
        }
    }

    func stopSound() {
        try? audioManager.stop()
    }

    var audioState: AudioState {
        audioManager.audioState
    }

    // MARK: - Live Activity
    private func startLiveActivity() {
        guard let liveActivityManager, !liveActivityManager.hasLiveActivity() else { return }
        try? liveActivityManager.startLiveActivity(
            name: "Catodoro Timer",
            currentTimerValue: currentTimerValue,
            totalDuration: totalDuration,
            intervalDuration: intervalDuration,
            intervals: intervals,
            interval: interval,
            timerType: timerType ?? .main,
            timerStatus: timerStatus
        )
    }

    private func updateLiveActivity() {
        guard let liveActivityManager else { return }
        Task { [weak self] in
            guard let self else { return }
            await liveActivityManager.updateLiveActivity(
                currentTimerValue: currentTimerValue,
                totalDuration: totalDuration,
                intervalDuration: intervalDuration,
                intervals: intervals,
                interval: interval,
                timerType: timerType ?? .main,
                timerStatus: timerStatus
            )
        }
    }

    private func endLiveActivity() {
        liveActivityManager?.endLiveActivity()
    }

    // MARK: - Notification Handling
    private func addSubscriptions() {
        timerIntervalSubject
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] value in self?.handleTimerInterval(value) }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }

    private func handleTimerInterval(_ value: TimeInterval) {
        if value == 0 {
            handleIntervalSwitch()
        } else if lastTimerLabelDisplayed != currentTimerValue.getTimerLabelValue() {
            updateLiveActivity()
            lastTimerLabelDisplayed = currentTimerValue.getTimerLabelValue()
        }

        if timerActionSubject.value != .finish {
            timerLabelSubject.send(timerNameString)
        }
    }

    private func handleIntervalSwitch() {
        if timerType == .interval || intervalDuration == 0 {
            interval += 1
        }

        if interval >= intervals && timerType == .main {
            timerActionSubject.send(.finish)
            finishTimer()
        } else {
            timerType = timerType == .main ? .interval : .main
            duration = timerType == .interval ? intervalDuration : totalDuration
            playIntermediateSound()
            DispatchQueue.main.async { [weak self] in self?.startTimer() }
        }
    }

    // MARK: - Deinitializer
    deinit {
        removeSubscriptions()
        liveActivityManager?.endLiveActivity()
    }

    // MARK: - Timer Name
    var timerNameString: String {
        switch timerType {
        case .main, .none: return "Timer \(interval)"
        case .interval: return "Break \(interval)"
        default: return ""
        }
    }

    // MARK: - App Lifecycle Notifications
    @objc private func handleAppWillResignActive() {
        guard timerStatus == .playing else { return }
        lastTimerValue = currentTimerValue
    }

    @objc private func handleAppDidBecomeActive() {
        guard let entryTime = backgroundEntryTime, let lastTimerValue else { return }
        let elapsedTime = Date().timeIntervalSince(entryTime)
        currentTimerValue = max(0, lastTimerValue - elapsedTime)

        if timerStatus == .playing {
            resumeTimer()
        }
    }
}

#if DEBUG
extension TimerViewModel {
    struct TestHooks {
        let target: TimerViewModel

        var totalDuration: TimeInterval? { target.totalDuration }
        var intervalDuration: TimeInterval? { target.intervalDuration }
        var timerType: TimerType? { target.timerType }
        var timerStatus: TimerStatus { target.timerStatus }
        var backgroundTimer: DispatchSourceTimer? { target.backgroundTimer }
    }

    var testHooks: TestHooks { TestHooks(target: self) }
}
#endif
