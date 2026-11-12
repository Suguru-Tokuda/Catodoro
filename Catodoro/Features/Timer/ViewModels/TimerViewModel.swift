//
//  TimerViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import CatodoroShared
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
        status == .finished ? AppStrings.Common.routineComplete : (isBreak ? AppStrings.Common.catnapBreak : AppStrings.Timer.focusSession)
    }

    var sessionSummary: String {
        status == .finished ? AppStrings.Timer.sessionsCompleted(sessionCount)
            : AppStrings.Timer.sessionProgress(sessionIndex, isBreak ? max(0, sessionCount - 1) : sessionCount)
    }
}

final class TimerViewModel {
    let presentationSubject = CurrentValueSubject<TimerPresentationState, Never>(TimerPresentationState(
        isBreak: false,
        status: .paused,
        sessionIndex: 1,
        sessionCount: 0,
        remainingDuration: 0,
        phaseDuration: 0
    ))
    let timerActionSubject = CurrentValueSubject<TimerActions, Never>(.stop)

    private(set) var countdownError: Error?
    private(set) var audioError: Error?
    private(set) var hapticsError: Error?
    private var cycleID: UUID?
    private let countdown: CountdownControlling
    private var audioManager: AudioManaging
    private weak var preferences: CatodoroPreferencesProtocol?
    private let hapticsManager: HapticsManaging
    private let now: () -> Date
    private let schedulesTicks: Bool
    private var isAppActive = true
    private var appStateSubscription: AnyCancellable?

    /// Last session received from the engine. Only used to render and to detect changes.
    private var session: CycleSession?
    private var observeTask: Task<Void, Never>?
    private var ticker: AnyCancellable?

    var timerStatus: TimerStatus { presentationSubject.value.status }
    var isBreak: Bool { presentationSubject.value.isBreak }

    init(
        countdown: CountdownControlling,
        audioManager: AudioManaging = AudioManager(),
        preferences: CatodoroPreferencesProtocol?,
        hapticsManager: HapticsManaging = HapticsManager(),
        schedulesTicks: Bool = true,
        now: @escaping () -> Date = Date.init
    ) {
        self.countdown = countdown
        self.audioManager = audioManager
        self.preferences = preferences
        self.hapticsManager = hapticsManager
        self.now = now
        self.schedulesTicks = schedulesTicks
        setupPlayerSound()
        observeSession()
        addSubscriptions()
    }

    deinit {
        removeSubscriptions()
    }

    private func addSubscriptions() {
        appStateSubscription = Publishers.Merge(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in true },
            NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).map { _ in false }
        )
        .sink { [weak self] isActive in
            self?.isAppActive = isActive
        }
    }

    private func removeSubscriptions() {
        observeTask?.cancel()
        observeTask = nil
        appStateSubscription?.cancel()
        appStateSubscription = nil
    }

    // MARK: - User actions

    /// Starts a new cycle, replacing any running one.
    func configure(config: TimerConfigModel) {
        let steps = config.cycleSteps
        let countdown = countdown

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let id = try await countdown.start(steps: steps)
                cycleID = id
                apply(await countdown.currentSession())
            } catch {
                countdownError = error
                timerActionSubject.send(.stop)
            }
        }
    }

    /// Shows a cycle that's already running, e.g. one restored after a relaunch.
    /// Unlike `configure(config:)`, this doesn't start or replace anything.
    func attach(to session: CycleSession) {
        cycleID = session.id
        apply(session)

        // An update can land between the caller reading `session` and this call,
        // and `apply` drops anything that arrives before `cycleID` is set, so re-read once.
        let countdown = countdown
        Task { @MainActor [weak self] in
            self?.apply(await countdown.currentSession())
        }
    }

    func handlePlayPauseButtonTap() {
        switch timerStatus {
        case .playing, .paused:
            perform { try await $0.togglePauseResume(alarmID: $1) }

        case .finished:
            perform { try await $0.restartCycle(from: $1) }

        @unknown default:
            break
        }
    }

    /// A skipped break starts the next focus session, including when the braek was paused.
    func skipBreak() {
        guard isBreak, timerStatus != .finished else { return }
        perform { try await $0.skipBreak(from: $1) }
    }

    func stopTimer() {
        guard session != nil else {
            // Nothing running (e.g. start failed): just leave the screen.
            timerActionSubject.send(.stop)
            return
        }

        let countdown = countdown

        Task { @MainActor in await countdown.endCycle(from: "") }
    }

    private func perform(_ action: @escaping @Sendable (CountdownControlling, String) async throws -> Void) {
        let countdown = countdown
        let alarmID = session?.alarmID.uuidString ?? ""

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await action(countdown, alarmID)
            } catch {
                countdownError = error
            }
        }
    }

    // MARK: - Observing the engine

    private func observeSession() {
        let updates = countdown.sessionUpdates()
        observeTask = Task { @MainActor [weak self] in
            for await session in updates {
                self?.apply(session)
            }
        }
    }

    private func apply(_ new: CycleSession?) {
        // Ignore anything that isn't this screen's cycle (e.g. a leftover being stopped).
        guard let cycleID else { return }
        if let new, new.id != cycleID { return }

        let old = session
        session = new

        guard let new else {
            ticker = nil
            stopSound()
            stopHaptics()

            if old != nil {
                timerActionSubject.send(.stop)
            }
            return
        }

        updateTicker(for: new.state)
        publish()

        let isNewCycle = old?.id != new.id
        let stepChanged = !isNewCycle && old?.index != new.index
        let justFinished = new.state == .alerting && new.step.isLastStep && old?.state != .alerting

        if isNewCycle {
            stopSound()
            timerActionSubject.send(.start)
        } else if stepChanged {
            stopSound() // a cue from the previous phase must nost carry into this one.
            timerActionSubject.send(.start)
            phaseFeedback(playSound: new.step.phase.isBreak)
        } else if justFinished {
            timerActionSubject.send(.finish)
            phaseFeedback(playSound: true)
        } else if case .paused = new.state, old?.state != new.state {
            timerActionSubject.send(.pause)
            stopHaptics()
        } else if case .running = new.state, case .paused = old?.state {
            timerActionSubject.send(.resume)
        }
    }

    /// Display-only ticker: recomputes the label from the session's end date.
    private func updateTicker(for state: CycleSession.State) {
        guard case .running = state, schedulesTicks else {
            ticker = nil
            return
        }
        guard ticker == nil else { return }

        ticker = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.publish() }
    }

    private func publish() {
        guard let session else { return }
        let step = session.step

        let remaining: TimeInterval
        let status: TimerStatus

        switch session.state {
        case .running(let endDate):
            remaining = min(step.duration, max(0, endDate.timeIntervalSince(now())))
            status = .playing

        case .paused(let pausedRemaining):
            remaining = pausedRemaining
            status = .paused

        case .alerting:
            remaining = 0
            status = step.isLastStep ? .finished : .playing
        }

        presentationSubject.send(TimerPresentationState(
            isBreak: step.phase.isBreak,
            status: status,
            sessionIndex: step.interval,
            sessionCount: step.totalIntervals,
            remainingDuration: remaining,
            phaseDuration: step.duration
        ))
    }

    // MARK: - In-app feedback (foreground only: AlarmKit / notifications handle the background)

    private func phaseFeedback(playSound: Bool) {
        guard isAppActive else { return }

        if playSound {
            playCue()
        }

        playHaptics()
    }

    private func setupPlayerSound() {
        let fileName = SoundOptions(preferences?.sound ?? "").fileName

        enqueueAudioOperation { manager in
            try manager.setPlayer(fileName: fileName, fileExtension: "mp3")
        }
    }

    private func playCue() {
        enqueueAudioOperation { manager in
            try manager.play(numberOfLoops: 0)
        }
    }

    private func stopSound() {
        enqueueAudioOperation { manager in
            try manager.stop()
        }
    }

    private func playHaptics() {
        do {
            try hapticsManager.start()
        } catch {
            hapticsError = error
        }
    }

    private func stopHaptics() {
        hapticsManager.stop()
    }

    private func enqueueAudioOperation(_ operation: @escaping @Sendable (AudioManaging) throws -> Void) {
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
}

#if DEBUG
extension TimerViewModel {
    var testHooks: TestHooks {
        .init(target: self)
    }

    @MainActor
    struct TestHooks {
        let target: TimerViewModel

        func flushAudioOperations() async {
            await withCheckedContinuation { continuation in
                AudioManager.playbackQueue.async {
                    DispatchQueue.main.async {
                        continuation.resume()
                    }
                }
            }
        }

        var session: CycleSession? { target.session }
        var hapticsError: Error? { target.hapticsError }
        var countdownError: Error? { target.countdownError }

        /// Feed a session directly, without a real engine.
        func apply(_ session: CycleSession?) { target.apply(session) }
    }
}
#endif
