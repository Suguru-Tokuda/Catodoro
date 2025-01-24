//
//  StopTimerIntent.swift
//  CatodoroWidgetExtension
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents
import Foundation

struct StopTimerIntent: AppIntent & LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop Timer"

    func perform() async throws -> some  IntentResult {
        NotificationCenter.default.post(name: .stopTimerActionTriggered,
                                        object: nil)
        return .result()
    }
}
