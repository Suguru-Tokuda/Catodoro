//
//  StopTimerIntent.swift
//  CatodoroWidgetExtension
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents
import CatodoroShared

struct StopTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = LocalizedStringResource("intents.stopTimer", defaultValue: "Stop Timer")
    static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() { alarmID = "" }
    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some  IntentResult {
        await CountdownIntentRouter.handler?.endCycle(from: alarmID)
        return .result()
    }
}
