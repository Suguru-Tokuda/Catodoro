//
//  CatodoroWidgetLiveActivity.swift
//  CatodoroWidget
//
//  Created by Suguru Tokuda on 1/8/25.
//

import ActivityKit
import CatodoroShared
import WidgetKit
import SwiftUI

struct CatodoroWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            TimerLiveActivityView(context: context)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.black)
                .widgetURL(DeepLink.timer)
        } dynamicIsland: { context in
            catodoroDynamicIsland(state: context.state)
        }
    }
}

/// The one Dynamic Island used by both the TimerAttributes and AlarmKit Live Activities.
func catodoroDynamicIsland(state: TimerAttributes.ContentState) -> DynamicIsland {
    let accent = ActivityTheme.accent(state.accentCode, scheme: .dark)
    return DynamicIsland {
        DynamicIslandExpandedRegion(.bottom) {
            ExpandedTimerActivity(state: state)
        }
    } compactLeading: {
        PawIconView(accent: accent, accessibilityLabelTitle: state.phaseTitle)
    } compactTrailing: {
        ActivityCountdown(state: state)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(accent)
            .frame(width: state.currentTimerValue >= 3600 ? Spacing.space66 : Spacing.space48)
    } minimal: {
        PawIconView(accent: accent, accessibilityLabelTitle: state.phaseTitle)
    }
    .widgetURL(DeepLink.timer)
    .keylineTint(accent)
}

extension TimerAttributes {
    static var preview: TimerAttributes {
        TimerAttributes(name: AppStrings.Common.catodoro)
    }

    static var defaultValue: TimerAttributes.ContentState {
        .init(currentTimerValue: 1122, endTime: .now + 1122, intervals: 4, interval: 2,
              timerType: .main, timerStatus: .playing, phaseDuration: 1500)
    }

    static var breakValue: TimerAttributes.ContentState {
        .init(currentTimerValue: 252, endTime: .now + 252, intervals: 4, interval: 2,
              timerType: .interval, timerStatus: .playing, phaseDuration: 300)
    }

    static var finishValue: TimerAttributes.ContentState {
        .init(currentTimerValue: 0, endTime: .now, intervals: 4, interval: 4,
              timerType: .main, timerStatus: .finished, phaseDuration: 1500)
    }
}

#Preview("Focus", as: .content, using: TimerAttributes.preview) {
    CatodoroWidgetLiveActivity()
} contentStates: {
    TimerAttributes.defaultValue
    TimerAttributes.breakValue
    TimerAttributes.finishValue
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: TimerAttributes.preview) {
    CatodoroWidgetLiveActivity()
} contentStates: {
    TimerAttributes.defaultValue
    TimerAttributes.breakValue
}
