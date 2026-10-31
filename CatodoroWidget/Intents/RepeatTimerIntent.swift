//
//  RepeatTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/26/25.
//

import AppIntents
import CatodoroShared
import Foundation

struct RepeatTimerIntent: AppIntent & LiveActivityIntent {
    // App Intents metadata extraction requires a literal initializer here.
    static var title: LocalizedStringResource = LocalizedStringResource("intents.repeatTimer", defaultValue: "Repeat Timer")

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .repeatTimerActionTriggered, object: nil)
        return .result()
    }
}
