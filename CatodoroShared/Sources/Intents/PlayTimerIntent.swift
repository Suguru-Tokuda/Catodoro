//
//  PlayTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents

public struct PlayTimerIntent: AppIntent & LiveActivityIntent {
    public static let title: LocalizedStringResource = LocalizedStringResource("intents.playTimer", defaultValue: "Play Timer")
    public static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") public var alarmID: String

    public init() { alarmID = "" }
    public init(alarmID: String) { self.alarmID = alarmID }

    public func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.togglePauseResume(alarmID: alarmID)
        return .result()
    }
}
