//
//  SkipBreakIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import AppIntents
import CatodoroShared

struct SkipBreakIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = LocalizedStringResource("intents.skipBreak", defaultValue: "Skip break")
    static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() { alarmID = "" }
    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.skipBreak(from: alarmID)
        return .result()
    }
}
