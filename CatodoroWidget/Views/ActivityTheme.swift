//
//  ActivityTheme.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import CatodoroShared
import SwiftUI

/// SwiftUI-only theme keeps the widget independent of the UIKit app target.
enum ActivityTheme {
    // The shared views also compile in the app for intents and rendering tests.
    // Keep their small activity artwork in the extension's resource bundle.
    static let imageBundle: Bundle = {
        let extensionURL = Bundle.main.bundleURL
            .appendingPathComponent("PlugIns/CatodoroWidgetExtension.appex")
        return Bundle(url: extensionURL) ?? .main
    }()

    static func color(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 255) / 255,
              green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255)
    }

    static func background(_ scheme: ColorScheme) -> Color {
        color(scheme == .dark ? 0x201D24 : 0xFAF6EE)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        color(scheme == .dark ? 0xFFF3DF : 0x35251F)
    }

    static func accent(_ code: String?, scheme: ColorScheme) -> Color {
        let palette: [String: (UInt32, UInt32)] = [
            "nBlue": (0x23676A, 0x80D7C4), "nGreen": (0x456C47, 0xABD29C),
            "nOrange": (0x9F4E27, 0xF0B182), "nPink": (0xA14364, 0xEDACBF),
            "nPurple": (0x70538F, 0xC6B3EA), "nYellow": (0x80601C, 0xE5CA83)
        ]
        let pair = palette[code ?? ""] ?? palette["nBlue"]!
        return color(scheme == .dark ? pair.1 : pair.0)
    }
}

struct ActivityCountdown: View {
    let state: TimerAttributes.ContentState

    var body: some View {
        Group {
            if state.timerStatus == .playing {
                Text(timerInterval: Date.distantPast...state.endTime, countsDown: true)
            } else {
                Text(state.timerStatus == .finished ? "00:00" : state.countdown)
            }
        }
        .monospacedDigit()
        .contentTransition(.identity)
        .accessibilityLabel(state.timerStatus == .finished ? "Routine complete" : "Time remaining")
    }
}

struct ActivityProgress: View {
    let state: TimerAttributes.ContentState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if state.timerStatus == .playing, let duration = state.phaseDuration, duration > 0 {
            ProgressView(timerInterval: state.endTime.addingTimeInterval(-duration)...state.endTime, countsDown: false)
                .labelsHidden()
                .progressViewStyle(.linear)
                .accessibilityHidden(true)
        } else {
            GeometryReader { geometry in
                Capsule()
                    .fill(accent.opacity(0.18))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(accent)
                            .frame(width: geometry.size.width * (state.timerStatus == .finished ? 1 : progress))
                    }
            }
                .frame(height: 4)
                .accessibilityHidden(true)
        }
    }

    private var accent: Color {
        ActivityTheme.accent(state.accentCode, scheme: colorScheme)
    }

    private var progress: Double {
        guard let duration = state.phaseDuration, duration > 0 else { return 0 }

        return min(1, max(0, 1 - state.currentTimerValue / duration))
    }
}

struct ActivityControls: View {
    let state: TimerAttributes.ContentState
    let island: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if state.timerStatus == .finished {
                Button(intent: RepeatTimerIntent()) {
                    Label("Focus again", systemImage: "arrow.clockwise")
                }
            } else if state.canSkipBreak {
                Button(intent: SkipBreakIntent()) {
                    Label("Skip break", systemImage: "forward.end.fill")
                }
            } else {
                Button(intent: PlayTimerIntent()) {
                    Label(state.timerStatus == .paused ? "Resume" : "Pause",
                          systemImage: state.timerStatus == .paused ? "play.fill" : "pause.fill")
                }
            }

            Button(intent: StopTimerIntent()) {
                Label("End", systemImage: "xmark")
            }
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(ActivityTheme.accent(state.accentCode, scheme: island ? .dark : colorScheme))
    }
}
