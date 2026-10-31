//
//  StopTimerIntent.swift
//  CatodoroWidgetExtension
//
//  Created by Suguru Tokuda on 1/22/25.
//

import CatodoroShared
import AppIntents
import Foundation

struct StopTimerIntent: AppIntent & LiveActivityIntent {
    // App Intents metadata extraction requires a literal initializer here.
    static var title: LocalizedStringResource = LocalizedStringResource("intents.stopTimer", defaultValue: "Stop Timer")

    @MainActor
    func perform() async throws -> some  IntentResult {
        NotificationCenter.default.post(name: .stopTimerActionTriggered,
                                        object: nil)
        return .result()
    }
}
