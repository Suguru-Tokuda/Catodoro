//
//  CatodoroWidget.swift
//  CatodoroWidget
//
//  Created by Suguru Tokuda on 1/21/25.
//

import AlarmKit
import CatodoroShared
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct CatodoroWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(AppStrings.Widget.time)
            Text(entry.date, style: .time)

            Text(AppStrings.Widget.emoji)
            Text(entry.emoji)
        }
    }
}

@available(iOS 26.0, *)
struct CatodoroWidget: Widget {
    let kind: String = "CatodoroWidget"

    var body: some WidgetConfiguration {
        ActivityConfiguration(
            for: AlarmAttributes<CatodoroAlarmMetadata>.self
        ) { context in
            countdown(context.state)
                .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    countdown(context.state)
                }
            } compactLeading: {
                Image(systemName: "pawprint.fill")
            } compactTrailing: {
                countdown(context.state)
                    .frame(width: 56)
            } minimal: {
                Image(systemName: "pawprint.fill")
            }
        }
    }

    @ViewBuilder
    private func countdown(
        _ state: AlarmPresentationState
    ) -> some View {
        switch state.mode {
        case .countdown(let timer):
            Text(
                timerInterval: timer.startDate...timer.fireDate,
                countsDown: true
            )
            .monospacedDigit()
        case .paused:
            Text("Paused")

        case .alert:
            Text("Time's up")
        
        @unknown default:
            Label("Catodoro", systemImage: "pawprint.fill")
        }
    }
}

@available(iOS 26.0, *)
#Preview(as: .systemSmall) {
    CatodoroWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
