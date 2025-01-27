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
    static var title: LocalizedStringResource = "Repeat Timer"

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .repeatTimerActionTriggered, object: nil)
        return .result()
    }
}
