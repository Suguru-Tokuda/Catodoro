import Foundation

@MainActor
final class AppDependencies {
    let preferences: CatodoroPreferences
    let persistentController: CatodoroPersistentController
    let coreDataManager: CatodoroCoreDataManaging
    let syncLifecycleManager: SyncLifecycleManaging

    init(preferences: CatodoroPreferences = CatodoroPreferences()) {
        self.preferences = preferences
        let persistence = CatodoroPersistentController()
        persistentController = persistence
        coreDataManager = CatodoroCoreDataManager(context: persistence.writeContext)
        syncLifecycleManager = SyncLifecycleManager(preferences: preferences, persistence: persistence)
    }
}
