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
    @State private var currentTime = Date()

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            TimerLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.7))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    getCountDownTextView(from: state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    getTimerDisplayTextView(from: state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                }
            } compactLeading: {
                getCountDownTextView(from: state)
            } compactTrailing: {
                getTimerDisplayTextView(from: state)
            } minimal: {
                getTimerDisplayTextView(from: state)
            }
        }
    }

    @ViewBuilder
    func getTimerDisplayTextView(from state: TimerAttributes.ContentState) -> some View {
        if state.timerStatus == .playing {
            Text(state.endTime, style: .timer)
        } else {
            Text(getTimerDisplayText(from: state))
        }
    }

    @ViewBuilder
    func getCountDownTextView(from state: TimerAttributes.ContentState) -> some View {
        Text("\(state.timerType.rawValue) \(state.interval)")
            .contentTransition(.identity)
    }

    func getTimerDisplayText(from state: TimerAttributes.ContentState) -> String {
        var retVal = ""
        switch state.timerStatus {
        case .paused:
            retVal = state.currentTimerValue.getTimerLabelValue()
        case .playing:
            break
        case .finished:
            retVal = "Finished"
        default:
            break
        }
        
        return retVal
    }
}

extension TimerAttributes {
    static var preview: TimerAttributes {
        TimerAttributes(name: "Preview")
    }
}

extension TimerAttributes {
    static var defaultValue: TimerAttributes.ContentState {
        TimerAttributes.ContentState(currentTimerValue: 10,
                                     endTime: .now + 10,
                                     intervals: 0,
                                     interval: 0,
                                     timerType: .main,
                                     timerStatus: .playing)
    }

    static var finishValue: TimerAttributes.ContentState {
        TimerAttributes.ContentState(currentTimerValue: 10,
                                     endTime: .now + 10,
                                     intervals: 0,
                                     interval: 0,
                                     timerType: .main,
                                     timerStatus: .playing)
    }
}

#Preview("Notification", as: .content, using: TimerAttributes.preview) {
    CatodoroWidgetLiveActivity()
} contentStates: {
    TimerAttributes.defaultValue
}

#Preview("Notification", as: .content, using: TimerAttributes.preview) {
    CatodoroWidgetLiveActivity()
} contentStates: {
    TimerAttributes.finishValue
}
