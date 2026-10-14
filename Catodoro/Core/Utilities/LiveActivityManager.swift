//
//  LiveActivityManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/12/25.
//

import ActivityKit
import CatodoroShared
import Foundation

protocol LiveActivityManaging: AnyObject {
    func startLiveActivity(name: String,
                           currentTimerValue: TimeInterval,
                           endTime: Date,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus,
                           phaseDuration: TimeInterval,
                           accentCode: String?) throws

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            endTime: Date,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus,
                            soundName: String?,
                            phaseDuration: TimeInterval,
                            accentCode: String?) async
    func endLiveActivity()

    func hasLiveActivity() -> Bool

    /// Ends activities this process didn't start (left behind when the app was killed mid-timer).
    func endStaleActivities()
}

extension LiveActivityManaging {
    func endStaleActivities() {}
}

enum LiveActivityError: Error {
    case start
    case disabled
}

final class LiveActivityManager: LiveActivityManaging {
    private let lock = NSLock()
    private var currentActivity: Activity<TimerAttributes>?
    private var pendingOperation: Task<Void, Never>?
    private let activitiesEnabled: () -> Bool

    init(activitiesEnabled: @escaping () -> Bool = { ActivityAuthorizationInfo().areActivitiesEnabled }) {
        self.activitiesEnabled = activitiesEnabled
    }

    func startLiveActivity(name: String,
                           currentTimerValue: TimeInterval,
                           endTime: Date,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus,
                           phaseDuration: TimeInterval,
                           accentCode: String?) throws {
        guard activitiesEnabled() else {
            throw LiveActivityError.disabled
        }

        let state = TimerAttributes.ContentState(currentTimerValue: currentTimerValue, endTime: endTime,
                                                intervals: intervals, interval: interval,
                                                timerType: timerType, timerStatus: timerStatus,
                                                phaseDuration: phaseDuration, accentCode: accentCode)
        // Request is synchronous and throwing, so the caller can handle authorization/request failures.
        try lock.withLock {
            guard currentActivity == nil else { return }

            currentActivity = try Activity.request(attributes: TimerAttributes(name: name),
                                                   content: ActivityContent(state: state, staleDate: nil))
        }
    }

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            endTime: Date,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus,
                            soundName: String?,
                            phaseDuration: TimeInterval,
                            accentCode: String?) async {
        let state = TimerAttributes.ContentState(currentTimerValue: currentTimerValue, endTime: endTime,
                                                intervals: intervals, interval: interval,
                                                timerType: timerType, timerStatus: timerStatus,
                                                phaseDuration: phaseDuration, accentCode: accentCode)
        let task: Task<Void, Never>? = lock.withLock {
            guard let activity = currentActivity else { return nil }

            let previous = pendingOperation
            let task = Task {
                await previous?.value
                var alert: AlertConfiguration?
                if let soundName {
                    alert = AlertConfiguration(title: timerStatus == .finished ? "Routine complete" : "Catodoro",
                                               body: timerType == .interval ? "Rest your paws." : "Time to focus.",
                                               sound: .named("\(soundName).mp3"))
                }
                await activity.update(ActivityContent(state: state, staleDate: nil), alertConfiguration: alert)
            }
            pendingOperation = task
            return task
        }
        await task?.value
    }

    func endLiveActivity() {
        // Clear ownership immediately; ending the old activity must not end a newly started routine.
        lock.withLock {
            guard let activity = currentActivity else { return }

            currentActivity = nil
            let previous = pendingOperation
            pendingOperation = Task {
                await previous?.value
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    func hasLiveActivity() -> Bool {
        lock.withLock { currentActivity != nil }
    }

    func endStaleActivities() {
        // Snapshot now so an activity started right after launch is never ended by mistake.
        let stale: [Activity<TimerAttributes>] = lock.withLock {
            Activity<TimerAttributes>.activities.filter { $0.id != currentActivity?.id }
        }
        guard !stale.isEmpty else { return }

        Task {
            for activity in stale {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
