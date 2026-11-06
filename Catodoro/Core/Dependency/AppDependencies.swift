import Foundation

@MainActor
final class AppDependencies {
    let preferences: CatodoroPreferences
    private let persistentController: CatodoroPersistentController
    let coreDataManager: CatodoroCoreDataManaging
    let syncLifecycleManager: SyncLifecycleManaging
    let hapticsManager: HapticsManaging

    init(preferences: CatodoroPreferences = CatodoroPreferences()) {
        self.preferences = preferences
        let persistence = CatodoroPersistentController()
        persistentController = persistence
        coreDataManager = CatodoroCoreDataManager(context: persistence.writeContext)
        syncLifecycleManager = SyncLifecycleManager(preferences: preferences, persistence: persistence)
        hapticsManager = HapticsManager()
    }
}
