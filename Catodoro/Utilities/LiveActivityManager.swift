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
                           totalDuration: TimeInterval,
                           intervalDuration: TimeInterval,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus) throws

    func updateLiveActivity(currentTimerValue: TimeInterval,
                            totalDuration: TimeInterval,
                            intervalDuration: TimeInterval,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus) async
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
                           totalDuration: TimeInterval,
                           intervalDuration: TimeInterval,
                           intervals: Int,
                           interval: Int,
                           timerType: TimerType,
                           timerStatus: TimerStatus) throws {
        Task {
            guard currentActivity == nil else {
                await updateLiveActivity(currentTimerValue: currentTimerValue,
                                   totalDuration: totalDuration,
                                   intervalDuration: intervalDuration,
                                   intervals: intervals,
                                   interval: interval,
                                   timerType: timerType,
                                   timerStatus: timerStatus)
                return
            }
            if let currentActivity {
                await currentActivity.end(nil)
            }
            let attributes = TimerAttributes(name: name)
            let initialState = TimerAttributes.ContentState(totalDuration: totalDuration,
                                                            intervalDuration: intervalDuration,
                                                            currentTimerValue: currentTimerValue,
                                                            intervals: intervals,
                                                            interval: interval,
                                                            timerType: timerType,
                                                            timerStatus: timerStatus)
            let content = ActivityContent(state: initialState, staleDate: nil)
            
            do {
                currentActivity = try Activity<TimerAttributes>
                    .request(attributes: attributes,
                             content: content)
            } catch {
                throw error
            }
        }
    }
    
    func updateLiveActivity(currentTimerValue: TimeInterval,
                            totalDuration: TimeInterval,
                            intervalDuration: TimeInterval,
                            intervals: Int,
                            interval: Int,
                            timerType: TimerType,
                            timerStatus: TimerStatus) async {
        guard let currentActivity else { return }
        let updatedState = TimerAttributes.ContentState(totalDuration: totalDuration,
                                                        intervalDuration: intervalDuration,
                                                        currentTimerValue: currentTimerValue,
                                                        intervals: intervals,
                                                        interval: interval,
                                                        timerType: timerType,
                                                        timerStatus: timerStatus)
        await currentActivity.update(ActivityContent(state: updatedState, staleDate: nil))
    }
    
    func endLiveActivity() {
        guard let currentActivity else { return }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await currentActivity.end(nil, dismissalPolicy: .immediate)
            semaphore.signal()
        }
        semaphore.wait()
    }

    func hasLiveActivity() -> Bool {
        currentActivity != nil
    }
}
