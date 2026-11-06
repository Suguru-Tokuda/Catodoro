//
//  CatodoroWidget.swift
//  CatodoroWidget
//
//  Created by Suguru Tokuda on 1/21/25.
//

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

struct CatodoroWidget: Widget {
    private let kind: String = "CatodoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CatodoroWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(AppStrings.Widget.myWidget)
        .description(AppStrings.Widget.thisIsAnExampleWidget)
    }
}

#Preview(as: .systemSmall) {
    CatodoroWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
