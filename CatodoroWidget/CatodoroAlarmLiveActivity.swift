//
//  CatodoroAlarmLiveActivity.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import AlarmKit
import CatodoroShared
import SwiftUI
import WidgetKit

/// Drawn by the system for AlarmKit countdowns scheduled by CountdownEngine.
struct CatodoroAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<CatodoroAlarmMetadata>.self) { context in
            TimerLiveActivityCard(state: .init(alarm: context.state, metadata: context.attributes.metadata))
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.black)
                .widgetURL(DeepLink.timer)
            } dynamicIsland: { context in
                catodoroDynamicIsland(state: .init(alarm: context.state, metadata: context.attributes.metadata))
            }
    }
}

extension TimerAttributes.ContentState {
    /// Maps an AlarmKit countdown onto the state the Catodoro views already understand.
    init(alarm: AlarmPresentationState, metadata: CatodoroAlarmMetadata?) {
        let isBreak = metadata?.phase.isBreak ?? false
        let status: TimerStatus
        let remaining: TimeInterval
        let endTime: Date

        switch alarm.mode {
        case .countdown(let countdown):
            status = .playing
            endTime = countdown.fireDate
            remaining = max(0, countdown.fireDate.timeIntervalSinceNow)

        case .paused(let paused):
            status = .paused
            remaining = max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration)
            endTime = .now.addingTimeInterval(remaining)

        case .alert:
            // Last step -> finished card (Focus again / End); otherwise 00:00 until the next step starts.
            status = metadata?.isLastStep == true ? .finished : .playing
            remaining = 0
            endTime = .now

        @unknown default:
            status = .paused
            remaining = 0
            endTime = .now
        }

        self.init(
            currentTimerValue: remaining,
            endTime: endTime,
            intervals: metadata?.totalIntervals ?? 1,
            interval: metadata?.interval ?? 1,
            timerType: isBreak ? .interval : .main,
            timerStatus: status,
            phaseDuration: metadata?.phaseDuration,
            accentCode: metadata?.accentCode
        )
    }
}
