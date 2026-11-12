//
//  RepeatTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/26/25.
//

import AppIntents
import Foundation

public struct RepeatTimerIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = LocalizedStringResource("intents.repeatTimer", defaultValue: "Repeat Timer")
    public static let isDiscoverable = false

    @Parameter(title: "Alarm ID") public var alarmID: String

    public init() { alarmID = "" }
    public init(alarmID: String) { self.alarmID = alarmID }

    public func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.restartCycle(from: alarmID)
        return .result()
    }
}
