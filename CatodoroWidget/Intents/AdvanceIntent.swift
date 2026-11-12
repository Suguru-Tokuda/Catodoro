//
//  AdvanceIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/9/26.
//

import AppIntents
import CatodoroShared

struct AdvanceIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Next phase"
    static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.advance(from: alarmID)
        return .result()
    }
}
