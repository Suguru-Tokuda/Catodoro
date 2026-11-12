//
//  PlayTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents
import CatodoroShared

struct PlayTimerIntent: AppIntent & LiveActivityIntent {
    static let title: LocalizedStringResource = LocalizedStringResource("intents.playTimer", defaultValue: "Play Timer")
    static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") var alarmID: String

    init() { alarmID = "" }
    init(alarmID: String) { self.alarmID = alarmID }

    func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.togglePauseResume(alarmID: alarmID)
        return .result()
    }
}
