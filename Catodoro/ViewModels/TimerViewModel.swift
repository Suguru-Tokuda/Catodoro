//
//  TimerViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import AVFoundation
import Combine
import Foundation
import UIKit

enum TimerStatus {
    case paused
    case playing
}

enum TimerActions {
    case start
    case pause
    case resume
    case stop
    case finish
}

enum TimerType {
    case main
    case interval
}

class TimerViewModel {
    var currentTimerValue: TimeInterval = 0 // Could be timerTime or intervalTime
    private var totalDuration: TimeInterval = 0
    private var intervalDuration: TimeInterval = 0 // in seconds
    private let timerInterval: Double = 0.01 // used to update the timer for every x seconds.
    private var intervals: Int = 0
    var duration: TimeInterval = 0
    /// Used to send updated string representation of
    /// timer value for timer label
    var timerSubject: PassthroughSubject<String, Never> = .init()
    var timerStatusSubject: PassthroughSubject<TimerStatus, Never> = .init()
    var timerActionSubject: CurrentValueSubject<TimerActions, Never> = .init(.stop)
    var timerLabelSubject: PassthroughSubject<String, Never> = .init()
    var timerIntervalSubject: PassthroughSubject<TimeInterval, Never> = .init()
    private var intermediateSoundDuration = 2.0
    private var interval: Int = 1
    private var timer: Timer?
    private var intermediateSoundTimer: Timer?
    private var timerType: TimerType?
    private var cancellables: Set<AnyCancellable> = .init()
    private var audioManager: AudioManaging
    private var preferences: CatodoroPreferencesProtocol?
    private var nowPlayingManager: NowPlayingManaging?

    // MARK: extra properties
    private var backgroundEntryTime: Date?
    private var lastTimerValue: TimeInterval?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var backgroundTimer: DispatchSourceTimer?
    private let backgroundTimerTaskName = "Catodoro.BackgroundTimerTask"
    private let backgroundTimerInterval: Double = 1

    init(audioManager: AudioManaging = AudioManager(),
         preferences: CatodoroPreferencesProtocol?,
         nowPlayingManager: NowPlayingManaging? = NowPlayingManager()) {
        self.audioManager = audioManager
        self.preferences = preferences
        self.nowPlayingManager = nowPlayingManager
        addSubscriptions()
    }

    private func addSubscriptions() {
        timerIntervalSubject
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] value in
                guard let self else { return }
                if value == 0 {
                    if timerType == .interval || intervalDuration == 0 {
                        interval += 1
                    }
                    
                    if interval >= intervals && timerType == .main {
                        timerActionSubject.send(.finish)
                        finishTimer()
                    } else {
                        timerType = timerType == .main ? .interval : .main
                        switch timerType {
                        case .interval:
                            duration = intervalDuration
                        case .main, .none:
                            duration = totalDuration
                        }
                        
                        playIntermediateSound()
                        
                        DispatchQueue.main.async { [weak self] in
                            guard let self else { return }
                            startTimer()
                        }
                    }
                }

                if timerActionSubject.value != .finish {
                    timerLabelSubject.send(timerNameString)
                }
                
                var remainingTime: TimeInterval = 0
                switch timerType {
                case .main:
                    remainingTime = totalDuration - currentTimerValue
                case .interval:
                    remainingTime = intervalDuration - currentTimerValue
                default:
                    break
                }

                nowPlayingManager?.configureNowPlayingInfo(with: totalDuration,
                                                           elapsedTime: currentTimerValue,
                                                           remainingTime: remainingTime,
                                                           inInterval: timerType == .interval,
                                                           currentInterval: interval,
                                                           intervals: intervals,
                                                           isPaused: timerStatus == .paused)
            }
            .store(in: &cancellables)

        nowPlayingManager?.pauseTimer = { [weak self] in
            guard let self else { return }
            pauseTimer()
        }

        nowPlayingManager?.resumeTimer = { [weak self] in
            guard let self else { return }
            resumeTimer()
        }

        nowPlayingManager?.stopTimer = { [weak self] in
            guard let self else { return }
            stopTimer()
        }

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
                                               selector: #selector(handleAppDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAppWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
        removeNotificationCenterSubscriptions()
    }

    private func removeNotificationCenterSubscriptions() {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willResignActiveNotification,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)

        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
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
            self.startTimer()
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
        }
    }

    func startTimer() {
        if let timer {
            timer.invalidate()
            self.timer = nil
        }
        currentTimerValue = duration

        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTimerValue = max(0, self.currentTimerValue - self.timerInterval)
            self.timerSubject.send(self.currentTimerValue.getTimerLabelValue())
            self.timerIntervalSubject.send(self.currentTimerValue)
        }

        playSilentSound()
        timerStatus = .playing
        timerActionSubject.send(.start)
        if intermediateSoundTimer == nil {
            stopSound()
        }
    }

    func pauseTimer() {
        guard timerStatus == .playing, let timer else { return }
        timer.invalidate()
        self.timer = nil
        timerStatus = .paused
        timerActionSubject.send(.pause)
    }

    func resumeTimer() {
        guard timerStatus == .paused else { return }
        if let timer {
            timer.invalidate()
            self.timer = nil
        }
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.currentTimerValue = max(0, self.currentTimerValue - self.timerInterval)
            self.timerIntervalSubject.send(self.currentTimerValue)
            self.timerSubject.send(self.currentTimerValue.getTimerLabelValue())
        }
        timerStatus = .playing
        timerActionSubject.send(.resume)
    }

    func finishTimer() {
        if let timer {
            timer.invalidate()
            self.timer = nil
        }
        playFinishSound()
        timerStatus = .paused
    }

    func stopTimer() {
        resetTimer()
        timerLabelSubject.send(timerNameString)
        timerActionSubject.send(.stop)
    }

    func resetTimer() {
        if let timer {
            timer.invalidate()
            self.timer = nil
        }
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
        }
    }
    
    func playFinishSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName
        try? audioManager.setPlayer(fileName: fileName, fileExtension: "mp3")
        try? audioManager.play(numberOfLoops: 0)
    }

    func playIntermediateSound() {
        intermediateSoundTimer?.invalidate()
        stopSound()

        let fileName = SoundOptions(preferences?.sound ?? "").fileName
        try? audioManager.setPlayer(fileName: fileName, fileExtension: "mp3")
        try? audioManager.play(numberOfLoops: 0)

        intermediateSoundTimer = Timer.scheduledTimer(withTimeInterval: intermediateSoundDuration,
                                                      repeats: false) { [weak self] _ in
            guard let self else { return }
            stopSound()
            intermediateSoundTimer?.invalidate()
            intermediateSoundTimer = nil
        }
    }

    func playSilentSound() {
        if intermediateSoundTimer == nil {
            try? audioManager.setPlayer(fileName: "silent", fileExtension: "mp3")
            try? audioManager.play(numberOfLoops: -1)
        }
    }

    func stopSound() {
        try? audioManager.stop()
    }

    var audioState: AudioState {
        audioManager.audioState
    }

    deinit {
        removeSubscriptions()
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

    func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: backgroundTimerTaskName) {
            // End the task if time expires
            UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
            self.backgroundTaskID = .invalid
        }
    }

    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
    
    @objc private func updateNowPlayingInfo() {
        let elapsedTime = duration - currentTimerValue
        nowPlayingManager?.configureNowPlayingInfo(
            with: duration,
            elapsedTime: elapsedTime,
            remainingTime: currentTimerValue,
            inInterval: timerType == .interval,
            currentInterval: interval,
            intervals: intervals,
            isPaused: timerStatus == .paused
        )
    }

    @objc private func handleAppDidEnterBackground() {
        startBackgroundTimer()
    }

    @objc private func handleAppWillEnterForeground() {
        stopBackgroundTimer()
    }

    func startBackgroundTimer() {
        let queue = DispatchQueue.global(qos: .background)
        backgroundTimer = DispatchSource.makeTimerSource(queue: queue)
        backgroundTimer?.schedule(deadline: .now(),
                                  repeating: backgroundTimerInterval)
        backgroundTimer?.setEventHandler { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                startBackgroundTask()
                updateNowPlayingInfo()
                endBackgroundTask()
            }
        }
        backgroundTimer?.resume()
    }

    func stopBackgroundTimer() {
        backgroundTimer?.cancel()
        backgroundTimer = nil
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
        var timer: Timer? { target.timer }
        var timerType: TimerType? { target.timerType }
    }
}
#endif
