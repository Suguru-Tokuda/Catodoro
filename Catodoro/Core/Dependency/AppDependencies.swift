import Foundation

/// App-wide dependencies, created once in `AppDelegate` and passed to coordinators.
/// Coordinators read what they need from here; view models and view controllers
/// still receive their individual dependencies through their initializers.
///
/// Only the initializers are `@MainActor` (they create main-actor objects such as
/// `CountdownEngine` and `SyncLifecycleManager`). The stored properties are plain
/// `let`s so non-isolated coordinators can read them.
final class AppDependencies {
    let preferences: CatodoroPreferences
    private let persistentController: CatodoroPersistentController?
    let coreDataManager: CatodoroCoreDataManaging
    let syncLifecycleManager: SyncLifecycleManaging
    let hapticsManager: HapticsManaging
    let countdown: CountdownControlling
    let liveActivityManager: LiveActivityManaging

    @MainActor
    init(preferences: CatodoroPreferences = CatodoroPreferences()) {
        self.preferences = preferences
        let persistence = CatodoroPersistentController()
        persistentController = persistence
        coreDataManager = CatodoroCoreDataManager(context: persistence.writeContext)
        syncLifecycleManager = SyncLifecycleManager(preferences: preferences, persistence: persistence)
        hapticsManager = HapticsManager()
        liveActivityManager = LiveActivityManager()
        countdown = CountdownService(countdownEngine: CountdownEngine(
            liveActivityManager: liveActivityManager,
            preferences: preferences
        ))
        
    }

    /// Explicit dependencies, e.g. in-memory stores and mocks for tests.
    @MainActor
    init(preferences: CatodoroPreferences,
         coreDataManager: CatodoroCoreDataManaging,
         syncLifecycleManager: SyncLifecycleManaging,
         hapticsManager: HapticsManaging,
         countdown: CountdownControlling,
         liveActivityManager: LiveActivityManaging) {
        self.preferences = preferences
        self.persistentController = nil
        self.coreDataManager = coreDataManager
        self.syncLifecycleManager = syncLifecycleManager
        self.hapticsManager = hapticsManager
        self.countdown = countdown
        self.liveActivityManager = liveActivityManager
    }
}
