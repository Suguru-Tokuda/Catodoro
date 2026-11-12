//
//  StopTimerIntent.swift
//  CatodoroWidgetExtension
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents

public struct StopTimerIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = LocalizedStringResource("intents.stopTimer", defaultValue: "Stop Timer")
    public static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") public var alarmID: String

    public init() { alarmID = "" }
    public init(alarmID: String) { self.alarmID = alarmID }

    public func perform() async throws -> some  IntentResult {
        await CountdownIntentRouter.handler?.endCycle(from: alarmID)
        return .result()
    }
}
