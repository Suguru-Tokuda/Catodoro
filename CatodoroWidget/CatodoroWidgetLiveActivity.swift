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
            let timerLabelText = context.state.currentTimerValue.getTimerLabelValue()
            VStack(spacing: 4) {
                HStack {
                    Text("\(context.state.timerType.rawValue) \(context.state.interval)")
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                HStack {
                    Text(timerLabelText)
                        .font(.system(size: 48, weight: .light))
                    Spacer()
                    HStack(alignment: .center, spacing: 4) {
                        Button(intent: PlayTimerIntent()) {
                            CircleButtonView(imageSystemName: context.state.timerStatus == .paused ? "play.fill" : "pause.fill",
                                             foregroundColor: .white,
                                             backgroundColor: .green,
                                             size: 40,
                                             padding: 8)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: StopTimerIntent()) {
                            CircleButtonView(imageSystemName: "stop.fill",
                                             foregroundColor: .white,
                                             backgroundColor: .red,
                                             size: 40,
                                             padding: 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .activityBackgroundTint(Color.black)
            .activitySystemActionForegroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.currentTimerValue.getTimerLabelValue())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.currentTimerValue.getTimerLabelValue())

                }
                DynamicIslandExpandedRegion(.bottom) {
                }
            } compactLeading: {
                Text("\(context.state.timerType.rawValue) \(context.state.interval)")
            } compactTrailing: {
                Text(context.state.currentTimerValue.getTimerLabelValue())
            } minimal: {
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TimerAttributes {
    static var preview: TimerAttributes {
        TimerAttributes(name: "Preview")
    }
}

extension TimerAttributes {
    fileprivate static var defaultValue: TimerAttributes.ContentState {
        TimerAttributes.ContentState(totalDuration: 0,
                                     intervalDuration: 0,
                                     currentTimerValue: 0,
                                     intervals: 0,
                                     interval: 0,
                                     timerType: .main,
                                     timerStatus: .paused)
    }
}

#Preview("Notification", as: .content, using: TimerAttributes.preview) {
    CatodoroWidgetLiveActivity()
} contentStates: {
    TimerAttributes.defaultValue
}
