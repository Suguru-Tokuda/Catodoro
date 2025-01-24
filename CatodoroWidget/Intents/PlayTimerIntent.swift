//
//  PlayTimerIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/22/25.
//

import AppIntents
import CatodoroShared
import Foundation

struct PlayTimerIntent: AppIntent & LiveActivityIntent {
    static var title: LocalizedStringResource = "Play Timer"
    
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .playTimerActionTriggered, object: nil)
        return .result()
    }
}

