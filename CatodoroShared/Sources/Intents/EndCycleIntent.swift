//
//  EndCycleIntent.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/9/26.
//

import AppIntents

public struct EndCycleIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "End Cycle"
    public static let isDiscoverable: Bool = false

    @Parameter(title: "Alarm ID") public var alarmID: String

    public init() {
        self.alarmID = ""
    }

    public init(alarmID: String) {
        self.alarmID = alarmID
    }

    public func perform() async throws -> some IntentResult {
        await CountdownIntentRouter.handler?.endCycle(from: alarmID)
        return .result()
    }
}
