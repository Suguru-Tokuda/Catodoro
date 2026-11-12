//
//  CountdownEngine.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/7/26.
//

import ActivityKit
import AlarmKit
import AppIntents
import CatodoroShared
import Combine
import UIKit
import UserNotifications

/// Permission state without prompting (see `CountdownEngine.resolveBackend`).
enum AuthorizationStatus {
    case authorized, notDetermined, denied
}

@MainActor
final class CountdownEngine: NSObject, ObservableObject {
    /// Source of truth for the current countdown. Persisted so it survives relaunch.
    @Published private(set) var session: CycleSession?
    /// The backend the user chose. `.liveActivity` needs no permission;
    /// `.alarmKit` and `.notification` are opt-in and fall back to `.liveActivity` if denied.
    var preferredBackend: CycleSession.Backend {
        preferences.alertStyle.resolved().backend
    }

    private let liveActivityManager: LiveActivityManaging
    private let preferences: CatodoroPreferencesProtocol
    private let notificationCenter = UNUserNotificationCenter.current()
    private let storeKey = "countdown.session"
    private var alarmUpdatesTask: Task<Void, Never>?
    /// Set while AlarmKit is scheduling, so an update that doesn't list the
    /// new alarm yet isn't mistaken for "alarm finished".
    private var schedulingID: UUID?

    // .liveActivity backend: the engine's own clock
    private var phaseClock: DispatchSourceTimer?
    private var isCatchingUp = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var lifecycleObservers: [NSObjectProtocol] = []

    init(liveActivityManager: LiveActivityManaging,
         preferences: CatodoroPreferencesProtocol
    ) {
        self.liveActivityManager = liveActivityManager
        self.preferences = preferences
        super.init()
        notificationCenter.delegate = self
        restore()
        if #available(iOS 26.0, *) {
            cancelOrphanedAlarms()
        }
        observeAppLifeCycle()

        if #available(iOS 26.0, *) {
            observeAlarmKit()
        }
    }

    // MARK: - Public API

    @discardableResult
    func requestAuthorization(for backend: CycleSession.Backend) async -> Bool {
        switch backend {
        case .alarmKit:
            guard #available(iOS 26.0, *) else { return false }

            do {
                return try await AlarmManager.shared.requestAuthorization() == .authorized
            } catch {
                return false
            }
        case .notification:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }

        case .liveActivity:
            return true
        }
    }

    func start(steps: [CycleStep]) async throws -> UUID {
        if #available(iOS 26.0, *) {
            cancelOrphanedAlarms()
        }

        guard !steps.isEmpty else { throw CountdownError.invalidSteps }
        
        if let leftover = session {
            await stop(alarmID: leftover.alarmID.uuidString)
        }

        let preferred = preferredBackend
        let backend = await resolveBackend()

        let sessionID = UUID()
        try await startStep(at: 0, in: steps, sessionID: sessionID, backend: backend)
        #if DEBUG
        debugLiveActivityState(context: "start (preferred: \(preferred), using: \(backend))")
        // The system can create the Live Activity slightly after scheduling, so check again.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            self?.debugLiveActivityState(context: "2s after start")
        }
        #endif
        return sessionID
    }

    func pause(alarmID: String? = nil) async throws {
        guard var current = session, matches(alarmID),
              // check the current state is running
              case .running(let endDate) = current.state else { return }

        let remaining = max(0, endDate.timeIntervalSinceNow)
        current.state = .paused(remaining: remaining)

        switch current.backend {
        case .alarmKit:
            if #available(iOS 26.0, *) { try AlarmManager.shared.pause(id: current.alarmID) }
            setSession(current)
        case .liveActivity:
            setSession(current)
            stopPhaseClock()
            await updateTimerActivity(for: current, playSound: false)

        case .notification:
            setSession(current)
            cancelNotification(id: current.alarmID)
            await updateActivity(FocusActivityAttributes.ContentState(
                endDate: .now.addingTimeInterval(remaining),
                pauseRemaining: remaining
            ))
        }
    }

    func resume(alarmID: String? = nil) async throws {
        guard var current = session, matches(alarmID),
              case .paused(let remaining) = current.state else { return }

        let endDate = Date.now.addingTimeInterval(remaining)
        current.state = .running(endDate: endDate)

        switch current.backend {
        case .alarmKit:
            if #available(iOS 26.0, *) { try AlarmManager.shared.resume(id: current.alarmID) }
            setSession(current)
        case .liveActivity:
            setSession(current)
            startPhaseClock()
            await updateTimerActivity(for: current, playSound: false)
        case .notification:
            setSession(current)
            try await scheduleNotification(id: current.alarmID, fireIn: remaining)
            await updateActivity(FocusActivityAttributes.ContentState(endDate: endDate, pauseRemaining: nil))
        }
    }

    func stop(alarmID: String? = nil) async {
        guard let current = session, matches(alarmID) else { return }
        setSession(nil)
        removeAlarm(of: current)

        switch current.backend {
        case .alarmKit:
            break
        case .liveActivity:
            liveActivityManager.endLiveActivity()
        case .notification:
            await endActivities()
        }
    }

    /// Call when the app becomes active, to catch anything that happened while suspended.
    func reconcile() async {
        guard let current = session else {
            await endActivities()
            return
        }

        switch current.backend {
        case .alarmKit:
            if #available(iOS 26.0, *) {
                if let alarms = try? AlarmManager.shared.alarms { applyAlarmKit(alarms) }
            }
        case .liveActivity:
            if !liveActivityManager.hasLiveActivity() {
                startTimerActivity(for: current)
            }
            await catchUpLiveActivityBackend()
            if let session, case .running = session.state {
                startPhaseClock()
            }
        case .notification:
            if case .running(let endDate) = current.state, endDate <= .now {
                await finishNotificationSession(id: current.alarmID)
            }
        }
    }

    func togglePauseResume(alarmID: String) async throws {
        guard let current = session, matches(alarmID) else { return }

        switch current.state {
        case .running: try await pause(alarmID: alarmID)
        case .paused: try await resume(alarmID: alarmID)
        case .alerting: break
        }
    }

    func advance(from alarmID: String) async throws {
        guard let current = session, matches(alarmID) else { return }
        try await move(from: current, to: current.index + 1)
    }

    func skipBreak(from alarmID: String) async throws {
        guard let current = session, matches(alarmID) else { return }

        var next = current.index + 1
        if !current.step.phase.isBreak,
           current.steps.indices.contains(next),
           current.steps[next].phase.isBreak {
            next += 1
        }
        try await move(from: current, to: next)
    }

    func restartCycle(from alarmID: String) async throws {
        guard let current = session, matches(alarmID) else { return }
        
        removeAlarm(of: current)

        switch current.backend {
        case .alarmKit:
            break
        case .liveActivity:
            liveActivityManager.endLiveActivity()
        case .notification:
            await endActivities()
        }

        try await startStep(at: 0, in: current.steps, sessionID: current.id, backend: current.backend)
    }

    // MARK: - AlarmKit backend (iOS 26+)

    /// - Parameters:
    ///   - duration: Seconds until the alert. Shorter than `step.duration` when resuming a
    ///     break the system already started counting.
    ///   - breakAfter: Length of the break that follows this focus step, if any. The alert's
    ///     "Start break" button then has the system count it down (`postAlert`) even if the
    ///     app never runs; `AdvanceIntent` swaps in a real break alarm when it can.
    @available(iOS 26.0, *)
    private func scheduleAlarm(id: UUID, step: CycleStep, duration: TimeInterval, breakAfter: TimeInterval?) async throws {
        let alert = alertContent(for: step, alarmID: id, startsBreak: breakAfter != nil)

        let presentation = AlarmPresentation(
            alert: alert.presentation,
            countdown: AlarmPresentation.Countdown(
                title: countdownTitle(for: step),
                pauseButton: AlarmButton(text: AppStrings.Alarm.pauseButton, textColor: .white, systemImageName: "pause.fill")
            ),
            paused: AlarmPresentation.Paused(
                title: AppStrings.Alarm.paused,
                resumeButton: AlarmButton(text: AppStrings.Alarm.resumeButton, textColor: .white, systemImageName: "play.fill")
            )
        )

        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: CatodoroAlarmMetadata(
                phase: step.phase,
                interval: step.interval,
                totalIntervals: step.totalIntervals,
                isLastStep: step.isLastStep,
                phaseDuration: step.duration,
                accentCode: preferences.color
            ),
            tintColor: step.phase.isBreak ? .teal : .orange
        )

        let soundFile = "\(SoundOptions(preferences.sound ?? "").fileName).mp3"

        let config = AlarmManager.AlarmConfiguration(
            countdownDuration: Alarm.CountdownDuration(preAlert: duration, postAlert: breakAfter),
            attributes: attributes,
            stopIntent: alert.stopIntent,
            secondaryIntent: alert.secondaryIntent,
            sound: .named(soundFile)
        )

        schedulingID = id
        defer { schedulingID = nil }
        _ = try await AlarmManager.shared.schedule(id: id, configuration: config)

        // The cycle may have been ended or moved on while we were scheduling.
        if session?.alarmID != id {
            try? AlarmManager.shared.cancel(id: id)
        }
    }

    @available(iOS 26.0, *)
    private func observeAlarmKit() {
        alarmUpdatesTask?.cancel()
        alarmUpdatesTask = Task { [weak self] in
            for await alarms in AlarmManager.shared.alarmUpdates {
                guard let self else { return }
                applyAlarmKit(alarms)
            }
        }
    }

    @available(iOS 26.0, *)
    private func applyAlarmKit(_ alarms: [Alarm]) {
        guard var current = session, current.backend == .alarmKit else { return }

        guard let alarm = alarms.first(where: { $0.id == current.alarmID }) else {
            if current.alarmID == schedulingID { return } // not listed yet

            if (try? AlarmManager.shared.alarms)?.contains(where: { $0.id == current.alarmID }) == true {
                return
            }

            // Did this alarm already go off? (We may have missed .alerting while suspended.)
            let alreadyFired: Bool
            switch current.state {
            case .running(let endDate):
                alreadyFired = endDate <= .now.addingTimeInterval(1)
            case .paused(_):
                alreadyFired = false
            case .alerting:
                alreadyFired = true
            }

            guard alreadyFired else {
                log("Alarm \(current.alarmID.short) cancelled -> cycle finished")
                setSession(nil)
                return
            }

            if current.step.isLastStep {
                // Finished: keep the session so the app shows Dismiss / Focus again.
                if current.state != .alerting {
                    current.state = .alerting
                    setSession(current)
                }
                return
            }

            // Stopped at the alert -> next step, exactly like AdvanceIntent.
            let id = current.alarmID.uuidString
            Task { try? await self.advance(from: id) }
            return
        }

        switch alarm.state {
        case .countdown:
            if case .paused(let remaining) = current.state {
                current.state = .running(endDate: .now.addingTimeInterval(remaining))
                setSession(current)
            } else if current.state == .alerting,
                      Self.breakDuration(after: current.index, in: current.steps) != nil {
                // "Start break" was tapped and the system is counting the break down on this
                // alarm, but its intent didn't reach us. Move to the break; `move` keeps the
                // system's end date.
                log("System break countdown on \(current.alarmID.short) -> break")
                let id = current.alarmID.uuidString
                Task { try? await self.advance(from: id) }
            }

        case .paused:
            if case .running(let endDate) = current.state {
                current.state = .paused(remaining: max(0, endDate.timeIntervalSinceNow))
                setSession(current)
            }

        case .alerting:
            guard current.state != .alerting else { return }

            if UIApplication.shared.applicationState == .active, !current.step.isLastStep {
                // Foreground: move straight on (advance removes the ringing alarm).
                let id = current.alarmID.uuidString
                Task { try? await self.advance(from: id) }
            } else {
                if UIApplication.shared.applicationState == .active {
                    // Last step while the app is open: the in-app finished screen takes over.
                    try? AlarmManager.shared.stop(id: current.alarmID)
                }
                current.state = .alerting // UI shows Dimiss / Restart, or waits for the aler tap.
                setSession(current)
            }

        case .scheduled:
            break

        @unknown default:
            break
        }
    }

    @available(iOS 26.0, *)
    private func cancelOrphanedAlarms() {
        let owned = session?.backend == .alarmKit ? session?.alarmID : nil
        for alarm in (try? AlarmManager.shared.alarms) ?? [] where alarm.id != owned {
            try? AlarmManager.shared.stop(id: alarm.id)
            try? AlarmManager.shared.cancel(id: alarm.id)
        }
    }

    // MARK: - Notification backend (iOS 18+)

    private func scheduleNotification(id: UUID, fireIn: TimeInterval) async throws {
        guard let step = session?.step else { return }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: step)
        content.sound = .default

        // Breaks through Focus only with the Time Sensitive Notifications capability.
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fireIn), repeats: false)
        try await notificationCenter.add(UNNotificationRequest(
            identifier: id.uuidString,
            content: content,
            trigger: trigger
        ))
    }

    private func cancelNotification(id: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    private func startActivity(id: UUID, endDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            log("Live Activities are turned off for Catodoro")
            return
        }

        do {
            _ = try Activity.request(
                attributes: FocusActivityAttributes(sessionID: id.uuidString, label: "Catodoro"),
                content: ActivityContent(
                    state: FocusActivityAttributes.ContentState(endDate: endDate, pauseRemaining: nil),
                    staleDate: endDate
                ),
                pushType: nil
            )
        } catch {
            log("Live Activity failed: \(error.localizedDescription)")
        }
    }

    private func updateActivity(_ state: FocusActivityAttributes.ContentState) async {
        // Running: stale at the end time. Paused: never stale.
        let staleDate = state.pauseRemaining == nil ? state.endDate : nil
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.update(ActivityContent(state: state, staleDate: staleDate))
        }
    }

    private func endActivities() async {
        for activity in Activity<FocusActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    fileprivate func notificationDidFire(identifier: String) async {
        guard let id = UUID(uuidString: identifier) else { return }
        await finishNotificationSession(id: id)
    }

    private func finishNotificationSession(id: UUID) async {
        guard var current = session,
              current.backend == .notification,
              current.alarmID == id else { return } // stale notification

        if current.step.isLastStep {
            current.state = .alerting
            setSession(current)
        } else {
            try? await advance(from: id.uuidString)
        }
    }

    private func notificationTitle(for step: CycleStep) -> String {
        if step.isLastStep { return AppStrings.Notifications.cycleComplete }
        return step.phase == .focus ? AppStrings.Notifications.focusCompleteBreakNext : AppStrings.Notifications.breakOverFocusNext
    }

    // MARK: - Helpers

    /// The preferred backend if it's allowed, otherwise the next one that is.
    private func resolveBackend() async -> CycleSession.Backend {
        let preferred = preferredBackend
        let backend = await Self.resolveBackend(
            preferred: preferred,
            status: { await self.authorizationStatus(for: $0) },
            request: { await self.requestAuthorization(for: $0) }
        )
        if backend != preferred {
            log("\(preferred) not allowed, using \(backend) for this cycle")
        }
        return backend
    }

    /// Picks the backend for a new cycle without surprising the user with a prompt:
    /// fallbacks are only used if already allowed, and only the style the user chose
    /// is asked for, when iOS hasn't asked yet (e.g. a restored setting).
    /// `.liveActivity` needs no permission, so this always returns something.
    static func resolveBackend(
        preferred: CycleSession.Backend,
        status: (CycleSession.Backend) async -> AuthorizationStatus,
        request: (CycleSession.Backend) async -> Bool
    ) async -> CycleSession.Backend {
        for backend in fallbackOrder(for: preferred) {
            switch await status(backend) {
            case .authorized:
                return backend
            case .notDetermined where backend == preferred:
                if await request(backend) { return backend }
            case .notDetermined, .denied:
                continue
            }
        }
        return .liveActivity // unreachable: .liveActivity is always authorized
    }

    static func fallbackOrder(for preferred: CycleSession.Backend) -> [CycleSession.Backend] {
        switch preferred {
        case .alarmKit: [.alarmKit, .notification, .liveActivity]
        case .notification: [.notification, .liveActivity]
        case .liveActivity: [.liveActivity]
        }
    }

    // Current permission without prompting.
    private func authorizationStatus(for backend: CycleSession.Backend) async -> AuthorizationStatus {
        switch backend {
        case .alarmKit:
            guard #available(iOS 26.0, *) else { return .denied }
            switch AlarmManager.shared.authorizationState {
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            case .authorized:
                return .authorized
            @unknown default:
                return .denied
            }
        case .liveActivity:
            return .authorized
        case .notification:
            switch await notificationCenter.notificationSettings().authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                return .authorized
            case .notDetermined:
                return .notDetermined
            case .denied:
                return .denied
            @unknown default:
                return .denied
            }
        }
    }

    private func move(from current: CycleSession, to index: Int) async throws {
        // Read before removing the alarm: its Live Activity holds the system break countdown.
        let breakEndDate = systemBreakEndDate(from: current, movingTo: index)
        removeAlarm(of: current)
        guard current.steps.indices.contains(index) else {
            await stop(alarmID: current.alarmID.uuidString)
            return
        }
        try await startStep(at: index, in: current.steps, sessionID: current.id,
                            backend: current.backend, endDate: breakEndDate)
    }

    /// Length of the break right after the focus step at `index`, or nil when none follows.
    static func breakDuration(after index: Int, in steps: [CycleStep]) -> TimeInterval? {
        guard steps.indices.contains(index), !steps[index].phase.isBreak,
              steps.indices.contains(index + 1), steps[index + 1].phase.isBreak,
              steps[index + 1].duration > 0 else { return nil }
        return steps[index + 1].duration
    }

    /// When the user tapped "Start break", AlarmKit counts the break down on the focus alarm.
    /// Returns when that countdown ends, so the break alarm that replaces it keeps the same end.
    private func systemBreakEndDate(from current: CycleSession, movingTo index: Int) -> Date? {
        guard current.backend == .alarmKit,
              index == current.index + 1,
              Self.breakDuration(after: current.index, in: current.steps) != nil else { return nil }
        guard #available(iOS 26.0, *) else { return nil }

        let activity = Activity<AlarmAttributes<CatodoroAlarmMetadata>>.activities
            .first { $0.content.state.alarmID == current.alarmID }
        guard case .countdown(let countdown)? = activity?.content.state.mode else { return nil }
        return countdown.fireDate
    }

    private func removeAlarm(of session: CycleSession) {
        switch session.backend {
        case .alarmKit:
            if #available(iOS 26.0, *) {
                try? AlarmManager.shared.stop(id: session.alarmID)
                try? AlarmManager.shared.cancel(id: session.alarmID)
            }
        case .liveActivity:
            stopPhaseClock()
        case .notification:
            cancelNotification(id: session.alarmID)
            notificationCenter.removeDeliveredNotifications(withIdentifiers: [session.alarmID.uuidString])
        }
    }

    /// - Parameter endDate: When this step should end. Defaults to a full step from now;
    ///   used to continue a break the system already started counting.
    private func startStep(at index: Int,
                           in steps: [CycleStep],
                           sessionID: UUID,
                           backend: CycleSession.Backend,
                           endDate requestedEndDate: Date? = nil
    ) async throws {
        guard steps.indices.contains(index) else { throw CountdownError.invalidSteps }

        let step = steps[index]
        let alarmID = UUID()
        let fullEndDate = Date.now.addingTimeInterval(step.duration)
        let endDate = requestedEndDate.map { min(max($0, .now.addingTimeInterval(1)), fullEndDate) } ?? fullEndDate
        let duration = endDate.timeIntervalSinceNow

        // Set state first so AlarmKit updates that arrive mid-schedule match this session.
        setSession(CycleSession(
            id: sessionID,
            alarmID: alarmID,
            steps: steps,
            index: index,
            backend: backend,
            state: .running(endDate: endDate)
        ))

        do {
            switch backend {
            case .alarmKit:
                guard #available(iOS 26.0, *) else { throw CountdownError.alarmKitUnavailable }
                try await scheduleAlarm(id: alarmID, step: step, duration: duration,
                                        breakAfter: Self.breakDuration(after: index, in: steps))
            case .liveActivity:
                guard let session else { return }

                if index == 0 {
                    startTimerActivity(for: session)
                } else {
                    await updateTimerActivity(for: session, playSound: false)
                }
                startPhaseClock()
            case .notification:
                try await scheduleNotification(id: alarmID, fireIn: duration)

                if index == 0 {
                    startActivity(id: sessionID, endDate: endDate)
                } else {
                    await updateActivity(FocusActivityAttributes.ContentState(endDate: endDate, pauseRemaining: nil))
                }
            }
        } catch {
            setSession(nil)
            throw error
        }
    }

    private func matches(_ alarmID: String?) -> Bool {
        guard let alarmID, !alarmID.isEmpty else { return true }
        return alarmID == session?.alarmID.uuidString
    }

    private func log(_ text: String) {
        print("⏱️", text)
    }

    // MARK: - Per-step content

    private func countdownTitle(for step: CycleStep) -> LocalizedStringResource {
        switch step.phase {
        case .focus: AppStrings.Alarm.focusCountdown(step.interval, of: step.totalIntervals)
        case .catnap: AppStrings.Alarm.catnapBreak
        @unknown default: ""
        }
    }

    @available(iOS 26.0, *)
    private func alertContent(for step: CycleStep, alarmID: UUID, startsBreak: Bool) -> (
        presentation: AlarmPresentation.Alert,
        stopIntent: any LiveActivityIntent,
        secondaryIntent: (any LiveActivityIntent)?
    ) {
        let id = alarmID.uuidString

        if step.isLastStep {
            return (
                AlarmPresentation.Alert(
                    title: AppStrings.Alarm.cycleComplete,
                    secondaryButton: AlarmButton(text: AppStrings.Alarm.restartButton, textColor: .white, systemImageName: "arrow.counterclockwise"),
                    secondaryButtonBehavior: .custom
                ),
                StopTimerIntent(alarmID: id),
                RepeatTimerIntent(alarmID: id)
            )
        }

        switch step.phase {
        case .focus:
            guard startsBreak else {
                // No break configured: stopping the alert starts the next focus.
                return (AlarmPresentation.Alert(title: AppStrings.Alarm.focusComplete), AdvanceIntent(alarmID: id), nil)
            }
            // "Start break" is a system countdown (postAlert = break length), so the break
            // runs even if the app can't. Its intent also wakes the app, which replaces this
            // alarm with a proper break alarm for the time that's left.
            return (
                AlarmPresentation.Alert(
                    title: AppStrings.Alarm.focusComplete,
                    secondaryButton: AlarmButton(text: AppStrings.Alarm.startBreakButton, textColor: .white, systemImageName: "moon.zzz.fill"),
                    secondaryButtonBehavior: .countdown
                ),
                AdvanceIntent(alarmID: id),
                AdvanceIntent(alarmID: id)
            )
        case .catnap:
            return (
                AlarmPresentation.Alert(title: AppStrings.Alarm.breakOver),
                AdvanceIntent(alarmID: id),
                nil
            )
        @unknown default:
            return (
                AlarmPresentation.Alert(title: AppStrings.Alarm.breakOver),
                AdvanceIntent(alarmID: id),
                nil
            )
        }
    }

    // MARK: - Persistence

    private func setSession(_ newValue: CycleSession?) {
        session = newValue
        if let newValue,
           let data = try? JSONEncoder().encode(newValue) {
            UserDefaults.standard.set(data, forKey: storeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: storeKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: storeKey),
              let saved = try? JSONDecoder().decode(CycleSession.self, from: data) else { return }
        session = saved
    }
}

// MARK: - Live Activity Manager helpers

extension CountdownEngine {
    private func timerActivityState(for session: CycleSession) -> (status: TimerStatus, remaining: TimeInterval, endTime: Date) {
        switch session.state {
        case .running(let endDate):
            return (.playing, max(0, endDate.timeIntervalSinceNow), endDate)
        case .paused(let remaining):
            return (.paused, remaining, .now.addingTimeInterval(remaining))
        case .alerting:
            return (session.step.isLastStep ? .finished : .playing, 0, .now)
        }
    }

    private func startTimerActivity(for session: CycleSession) {
        guard preferences.liveActivityEnabled != false else { return }
        let step = session.step
        let state = timerActivityState(for: session)

        do {
            try liveActivityManager.startLiveActivity(
                name: AppStrings.Timer.catodoroTimer,
                currentTimerValue: state.remaining,
                endTime: state.endTime,
                intervals: step.totalIntervals,
                interval: step.interval,
                timerType: step.phase.isBreak ? .interval : .main,
                timerStatus: state.status,
                phaseDuration: step.duration,
                accentCode: preferences.color
            )
        } catch {
            log("Live Activity failed: \(error)")
        }
    }

    /// 'playSound' attaches the alert sound to the update. It's only used while the
    /// app is in the background; in the foreground, TimerViewModel plays the cue in-app.
    private func updateTimerActivity(for session: CycleSession, playSound: Bool) async {
        guard preferences.liveActivityEnabled != false else { return }
        let step = session.step
        let state = timerActivityState(for: session)
        let inBackground = UIApplication.shared.applicationState != .active
        let sound = (playSound && inBackground) ? SoundOptions(preferences.sound ?? "").fileName : nil

        await liveActivityManager.updateLiveActivity(
            currentTimerValue: state.remaining,
            endTime: state.endTime,
            intervals: step.totalIntervals,
            interval: step.interval,
            timerType: step.phase.isBreak ? .interval : .main,
            timerStatus: state.status,
            soundName: sound,
            phaseDuration: step.duration,
            accentCode: preferences.color
        )
    }

    private func startPhaseClock() {
        stopPhaseClock()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 0.5)
        timer.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                Task { await self.catchUpLiveActivityBackend() }
            }
        }

        phaseClock = timer
        timer.resume()
    }

    private func stopPhaseClock() {
        phaseClock?.cancel()
        phaseClock = nil
    }

    /// Moves the cycle to where it should be *now*. Each step starts the previous
    /// step's end time, not at "now", so a long suspension lands on the right step
    /// with the right remaining time, like the old 'refresh()' loop.
    private func catchUpLiveActivityBackend() async {
        guard !isCatchingUp,
              var current = session,
              current.backend == .liveActivity,
              case .running(var endDate) = current.state,
              endDate <= .now else { return }

        isCatchingUp = true
        defer { isCatchingUp = false }

        var index = current.index
        while endDate <= .now {
            if current.steps[index].isLastStep {
                // Whole cycle finished: show Dismiss / Focus again.
                current.index = index
                current.alarmID = UUID()
                current.state = .alerting
                setSession(current)
                stopPhaseClock()
                await updateTimerActivity(for: current, playSound: true)
                return
            }
            index += 1
            endDate = endDate.addingTimeInterval(current.steps[index].duration)
        }

        current.index = index
        current.alarmID = UUID()
        current.state = .running(endDate: endDate)
        setSession(current)
        // Old behavior: sound when a catnap starts (and on finish, above).
        await updateTimerActivity(for: current, playSound: current.step.phase.isBreak)
    }
}

// MARK: - Background management

extension CountdownEngine {
    private func observeAppLifeCycle() {
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.beginBackgroundRuntime() }
            },
            center.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.endBackgroundRuntime() }
            }
        ]
    }

    private func beginBackgroundRuntime() {
        guard backgroundTask == .invalid,
              let session, session.backend == .liveActivity,
              case .running = session.state else { return }

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: AppStrings.Diagnostics.phaseTransitionTaskName) { [weak self] in
            MainActor.assumeIsolated { self?.endBackgroundRuntime() }
        }
    }

    private func endBackgroundRuntime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension CountdownEngine: UNUserNotificationCenterDelegate {
    nonisolated
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let identifier = notification.request.identifier
        await notificationDidFire(identifier: identifier)
        return [.banner, .list, .sound]
    }

    nonisolated
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let identifier = response.notification.request.identifier
        await notificationDidFire(identifier: identifier)
    }
}

private extension UUID {
    var short: String { String(uuidString.prefix(8))}
}

// MARK: - Debug

#if DEBUG
extension CountdownEngine{
    /// Temporary diagnostics for "Live Activity doesn't show up".
    /// Follows the chain: app schedules an alarm -> system creates the activity -> widget renders it.
    private func debugLiveActivityState(context: String) {
        print("🔎 [\(context)]")
        print("🔎 Live Activities enabled:", ActivityAuthorizationInfo().areActivitiesEnabled)

        if let session {
            print("🔎 session: backend=\(session.backend) step=\(session.index) alarm=\(session.alarmID.short) state=\(session.state)")
        } else {
            print("🔎 session: nil")
        }

        if #available(iOS 26.0, *) {
            let alarms = (try? AlarmManager.shared.alarms) ?? []
            print("🔎 alarms (\(alarms.count)):", alarms.map { "\($0.id.short) \($0.state)" })
            print("🔎 AlarmKit authorization:", AlarmManager.shared.authorizationState)

            let alarmActivities = Activity<AlarmAttributes<CatodoroAlarmMetadata>>.activities
            print("🔎 alarm activities (\(alarmActivities.count)):", alarmActivities.map { "\($0.activityState)" })
        }

        let timerActivities = Activity<TimerAttributes>.activities
        print("🔎 timer activities (\(timerActivities.count)):", timerActivities.map { "\($0.activityState)" })

        let focusActivities = Activity<FocusActivityAttributes>.activities
        print("🔎 focus activities (\(focusActivities.count)):", focusActivities.map { "\($0.activityState)" })
    }

}
#endif
