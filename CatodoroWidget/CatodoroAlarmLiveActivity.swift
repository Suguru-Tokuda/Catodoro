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
            } dynamicIsland: { context in
                catodoroDynamicIsland(state: .init(alarm: context.state, metadata: context.attributes.metadata))
            }
    }
}

private func alarmPhaseTitle(_ metadata: CatodoroAlarmMetadata?) -> String {
    guard let metadata else { return AppStrings.Common.focusTime }
    return metadata.phase.isBreak ? AppStrings.Common.catnapBreak : AppStrings.Common.focusTime
}

private struct AlarmCountdownText: View {
    let state: AlarmPresentationState

    var body: some View {
        switch state.mode {
        case .alert(_):
            Text("0:00")
        case .countdown(let countdown):
            Text(timerInterval: Date.now...max(Date.now, countdown.fireDate), countsDown: true)
        case .paused(let paused):
            let remaining = max(0, paused.totalCountdownDuration - paused.previouslyElapsedDuration)
            Text(Duration.seconds(remaining.rounded(.up)), format: .time(pattern: .minuteSecond))
        @unknown default:
            EmptyView()
        }
    }
}

private struct AlarmControls: View {
    let state: AlarmPresentationState
    let metadata: CatodoroAlarmMetadata?

    var body: some View {
        let id = state.alarmID.uuidString
        HStack(spacing: Spacing.space8) {
            if metadata?.phase.isBreak == true {
                Button(intent: SkipBreakIntent(alarmID: id)) {
                    Label(AppStrings.Common.skipBreak, systemImage: "forward.end.fill")
                }
            } else {
                Button(intent: PlayTimerIntent(alarmID: id)) {
                    if case .paused = state.mode {
                        Label(AppStrings.Common.resume, systemImage: "play.fill")
                    } else {
                        Label(AppStrings.Common.pause, systemImage: "pause.fill")
                    }
                }
            }
            Button(intent: StopTimerIntent(alarmID: id)) {
                Label(AppStrings.Common.end, systemImage: "xmark")
            }
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
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
