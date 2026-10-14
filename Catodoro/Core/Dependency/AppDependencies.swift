import CloudKit

@MainActor
final class AppDependencies {
    let preferences = CatodoroPreferences()
    let syncCoordinator: PresetSyncCoordinator
    let coreDataManager: CatodoroCoreDataManaging
    let syncLifecycleManager: SyncLifecycleManaging

    init(cloudContainer: CKContainer = CKContainer(identifier: "iCloud.com.stokuda.catodoro")) {
        let container = CatodoroPersistentController.shared.container
        let context = container.newBackgroundContext()
        let syncStore = CoreDataPresetSyncStore(context: context)
        let syncCoordinator = PresetSyncCoordinator(container: cloudContainer, store: syncStore)
        
        let lifecycle = SyncLifecycleManager(preferences: preferences, sync: syncCoordinator)
        self.syncCoordinator = syncCoordinator
        coreDataManager = CatodoroCoreDataManager(context: context, notifier: syncCoordinator)
        syncLifecycleManager = lifecycle

        syncCoordinator.onAccountChange = { [weak lifecycle] in
            lifecycle?.accountDidChange()
        }
    }
}
