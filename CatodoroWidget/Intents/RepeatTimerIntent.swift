//
//  RepeatTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/26/25.
//

import AppIntents
import CatodoroShared
import Foundation

struct RepeatTimerIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = LocalizedStringResource("intents.repeatTimer", defaultValue: "Repeat Timer")
    static let isDiscoverable = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() { alarmID = "" }
    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.restartCycle(from: alarmID)
        return .result()
    }
}
