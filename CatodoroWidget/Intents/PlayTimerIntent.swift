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
    
    @MainActor
    func perform() async throws -> some IntentResult {
        try await TimerController.shared.togglePauseResume()
        return .result()
    }
}
