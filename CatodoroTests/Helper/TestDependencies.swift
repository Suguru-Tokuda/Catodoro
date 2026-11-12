//
//  TestDependencies.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation
@testable import Catodoro

/// An `AppDependencies` built from mocks, keeping typed references to each mock.
/// Preferences live in a throwaway UserDefaults suite; call `tearDown()` to remove it.
@MainActor
final class TestDependencies {
    let suiteName = "CatodoroTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let preferences: CatodoroPreferences
    let coreDataManager = InMemoryPresetStore()
    let syncLifecycleManager = MockSyncLifecycleManager()
    let hapticsManager = MockHapticsManager()
    let countdown = MockCountdown()
    let liveActivityManager = MockLiveActivityManager()
    let app: AppDependencies

    init(hasCompletedOnboarding: Bool = true) {
        defaults = UserDefaults(suiteName: suiteName)!
        preferences = CatodoroPreferences(userDefaults: defaults)
        if hasCompletedOnboarding {
            preferences.completeOnboarding(syncEnabled: false)
        }
        app = AppDependencies(preferences: preferences,
                              coreDataManager: coreDataManager,
                              syncLifecycleManager: syncLifecycleManager,
                              hapticsManager: hapticsManager,
                              countdown: countdown,
                              liveActivityManager: liveActivityManager)
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
