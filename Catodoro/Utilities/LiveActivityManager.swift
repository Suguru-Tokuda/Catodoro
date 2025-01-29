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
                           timerStatus: TimerStatus) throws

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            endTime: Date,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus,
                            soundName: String?) async
    func endLiveActivity()

    func hasLiveActivity() -> Bool
}

enum LiveActivityError: Error {
    case start
}

class LiveActivityManager: LiveActivityManaging {
    private var currentActivity: Activity<TimerAttributes>?
    
    func startLiveActivity(name: String,
                           currentTimerValue: TimeInterval,
                           endTime: Date,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus) throws {
        Task {
            guard currentActivity == nil else {
                await updateLiveActivity(currentTimerValue: currentTimerValue,
                                         endTime: endTime,
                                         intervals: intervals,
                                         interval: interval,
                                         timerType: timerType,
                                         timerStatus: timerStatus,
                                         soundName: nil)
                return
            }
            if let currentActivity {
                await currentActivity.end(nil)
            }
            let timer = TimerAttributes(name: name)
            let initialState = TimerAttributes.ContentState(currentTimerValue: currentTimerValue,
                                                            endTime: endTime,
                                                            intervals: intervals,
                                                            interval: interval,
                                                            timerType: timerType,
                                                            timerStatus: timerStatus)
            let content = ActivityContent(state: initialState, staleDate: nil)
            
            do {
                currentActivity = try Activity<TimerAttributes>
                    .request(attributes: timer,
                             content: content)
            } catch {
                throw error
            }
        }
    }

    @MainActor
    func updateLiveActivity(currentTimerValue: TimeInterval,
                            endTime: Date,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus,
                            soundName: String?
    ) async {
        guard let currentActivity else { return }
        let updatedState = TimerAttributes.ContentState(currentTimerValue: currentTimerValue,
                                                        endTime: endTime,
                                                        intervals: intervals,
                                                        interval: interval,
                                                        timerType: timerType,
                                                        timerStatus: timerStatus)
        var alertConfig: AlertConfiguration?

        if let soundName {
            alertConfig = .init(title: timerStatus == .finished ? "Finished" : "\(timerType.rawValue) \(interval)",
                                body: "",
                                sound: .named("\(soundName).mp3"))
        }

        await currentActivity.update(
            ActivityContent(state: updatedState, staleDate: nil),
            alertConfiguration: alertConfig
        )
    }
    
    func endLiveActivity() {
        guard let currentActivity else { return }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            for activity in Activity<TimerAttributes>.activities {
                await activity.end(nil)
            }
            await currentActivity.end(nil, dismissalPolicy: .immediate)
            semaphore.signal()
        }
        semaphore.wait()
        self.currentActivity = nil
    }

    func hasLiveActivity() -> Bool {
        currentActivity != nil
    }
}
