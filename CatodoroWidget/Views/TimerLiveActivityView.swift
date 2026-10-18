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
    let context: ActivityViewContext<TimerAttributes>

    var body: some View {
        TimerLiveActivityCard(state: context.state)
    }
}

struct TimerLiveActivityCard: View {
    let state: TimerAttributes.ContentState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image("Activity" + state.artworkName, bundle: ActivityTheme.imageBundle)
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 96)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(state.phaseTitle)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
                ActivityCountdown(state: state)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .transition(.identity)
                Text(state.sessionSummary)
                    .font(.system(.caption, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(ActivityTheme.text(colorScheme).opacity(0.75))
                ActivityProgress(state: state)
                    .tint(accent)
                ActivityControls(state: state, island: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .foregroundStyle(ActivityTheme.text(colorScheme))
        .background(ActivityTheme.background(colorScheme))
        .contentTransition(.identity)
        
    }

    private var accent: Color {
        ActivityTheme.accent(state.accentCode, scheme: colorScheme)
    }
}

struct ExpandedTimerActivity: View {
    let state: TimerAttributes.ContentState

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image("Activity" + state.artworkName, bundle: ActivityTheme.imageBundle)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 56)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.phaseTitle)
                        .font(.system(.headline, design: .rounded))
                    Text(state.sessionSummary)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer(minLength: 0)
            }
            ActivityCountdown(state: state)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .lineLimit(1)
            ActivityProgress(state: state)
                .tint(ActivityTheme.accent(state.accentCode, scheme: .dark))
            ActivityControls(state: state, island: true)
        }
        .foregroundStyle(ActivityTheme.accent(state.accentCode, scheme: .dark))
    }
}
