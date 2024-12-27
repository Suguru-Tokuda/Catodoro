//
//  TimerViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import Foundation

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
    case breakTime
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
    var timerActionSubject: PassthroughSubject<TimerActions, Never> = .init()
    var timerLabelSubject: PassthroughSubject<String, Never> = .init()
    var timerIntervalSubject: PassthroughSubject<TimeInterval, Never> = .init()
    private var interval: Int = 1
    private var timer: Timer?
    private var timerType: TimerType?
    private var cancellables: Set<AnyCancellable> = .init()
    private var audioManager: AudioManaging
    private var preferences: CatodoroPreferencesProtocol?

    init(audioManager: AudioManaging = AudioManager(), preferences: CatodoroPreferencesProtocol?) {
        self.audioManager = audioManager
        self.preferences = preferences
        addSubscriptions()
    }

    private func addSubscriptions() {
        timerIntervalSubject
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .sink { [weak self] value in
                guard let self else { return }
                if value == 0 {
                    if timerType == .breakTime {
                        interval += 1
                    }
                    
                    if interval == (intervals + 1) {
                        if let timer {
                            timer.invalidate()
                            self.timer = nil
                        }
                        timerActionSubject.send(.finish)
                        stopTimer()
                    } else {
                        timerType = timerType == .main ? .breakTime : .main
                        switch timerType {
                        case .breakTime:
                            duration = intervalDuration
                        case .main, .none:
                            duration = totalDuration
                        }
                        DispatchQueue.main.async {
                            self.startTimer()
                        }
                    }
                }

                timerLabelSubject.send(timerNameString)
            }
            .store(in: &cancellables)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
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
        DispatchQueue.main.async {
            self.startTimer()
        }
    }

    func handlePlayPauseButtonTap() {
        switch timerStatus {
        case .paused:
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

        timerStatus = .playing
        timerActionSubject.send(.start)
        try? audioManager.stop()
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

    func stopTimer() {
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
        timerLabelSubject.send(timerNameString)
        timerActionSubject.send(.stop)
    }

    var timerNameString: String {
        switch timerType {
        case .main, .none:
            "Timer \(interval)"
        case .breakTime:
            "Break \(interval)"
        }
    }
    
    func playFinishSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName
        try? audioManager.setPlayer(fileName: fileName, fileExtension: "mp3")
        try? audioManager.play()
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
