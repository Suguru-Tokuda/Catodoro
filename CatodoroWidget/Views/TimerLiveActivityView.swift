//
//  TimerLiveActivityView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/27/25.
//

import CatodoroShared
import WidgetKit
import SwiftUI

struct TimerLiveActivityView: View {
    @State private var currentTime = Date()
    let context: ActivityViewContext<TimerAttributes>
    
    var body: some View {
        let state = context.state
            VStack(spacing: 4) {
                HStack {
                    getCountDownTextView(from: state)
                        .font(.system(size: 16, weight: .medium))
                    Spacer()
                }
                HStack {
                    getTimerDisplayTextView(from: state)
                        .contentTransition(.identity)
                        .font(.system(size: 48, weight: .light))
                    Spacer()
                    HStack(alignment: .center, spacing: 4) {
                        if state.timerStatus == .finished {
                            Button(intent: RepeatTimerIntent()) {
                                CircleButtonView(imageSystemName: state.timerStatus == .paused ? "play.fill" : "arrow.trianglehead.clockwise",
                                                 foregroundColor: .white,
                                                 backgroundColor: .green,
                                                 size: 40,
                                                 padding: 8)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(intent: PlayTimerIntent()) {
                                CircleButtonView(imageSystemName: state.timerStatus == .paused ? "play.fill" : "pause.fill",
                                                 foregroundColor: .white,
                                                 backgroundColor: .green,
                                                 size: 40,
                                                 padding: 8)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button(intent: StopTimerIntent()) {
                            CircleButtonView(imageSystemName: "stop.fill",
                                             foregroundColor: .white,
                                             backgroundColor: .red,
                                             size: 40,
                                             padding: 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentTransition(.identity)
                }
            }
            .contentTransition(.identity)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
