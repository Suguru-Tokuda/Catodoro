//
//  SkipBreakIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import AppIntents

public struct SkipBreakIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = LocalizedStringResource("intents.skipBreak", defaultValue: "Skip break")
    public static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") public var alarmID: String

    public init() { alarmID = "" }
    public init(alarmID: String) { self.alarmID = alarmID }

    public func perform() async throws -> some IntentResult {
        try await CountdownIntentRouter.handler?.skipBreak(from: alarmID)
        return .result()
    }
}
