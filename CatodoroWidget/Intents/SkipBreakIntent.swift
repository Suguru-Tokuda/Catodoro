//
//  SkipBreakIntent.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import AppIntents
import CatodoroShared
import Foundation

struct SkipBreakIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip break"

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .skipBreakActionTriggered, object: nil)
        return .result()
    }
}
