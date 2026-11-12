//
//  EndCycleIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/9/26.
//

import AppIntents
import CatodoroShared

struct EndCycleIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "End Cycle"
    static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() {
        self.alarmID = ""
    }

    init(alarmID: String) {
        self.alarmID = alarmID
    }

    func perform() async throws -> some IntentResult {
        await CountdownIntentRouter.handler?.endCycle(from: alarmID)
        return .result()
    }
}
