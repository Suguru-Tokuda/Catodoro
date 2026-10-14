import CloudKit
import CoreData

protocol CloudSyncPersistence: AnyObject {
    func setCloudSyncEnabled(_ enabled: Bool) async throws
}

/// All app reads, writes, and store reloads run on writeContext's serial queue.
/// Callers return value models, never managed objects that survive a store reload.
final class CatodoroPersistentController: CloudSyncPersistence, @unchecked Sendable {
    static let cloudContainerIdentifier = "iCloud.com.stokuda.catodoro"
    static let preview = CatodoroPersistentController(inMemory: true)

    let container: NSPersistentCloudKitContainer
    let writeContext: NSManagedObjectContext
    private let cloudIdentifier: String?
    private let inMemory: Bool
    // Access only on writeContext's queue after initialization.
    private var syncEnabled = false

    init(inMemory: Bool = false, storeURL: URL? = nil,
         cloudIdentifier: String? = CatodoroPersistentController.cloudContainerIdentifier) {
        self.inMemory = inMemory
        self.cloudIdentifier = cloudIdentifier
        container = NSPersistentCloudKitContainer(name: "CatodoroCoreData")
        let description = container.persistentStoreDescriptions[0]
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            description.url = storeURL
        }
        // Start locally. The lifecycle manager restores the opt-in setting.
        description.cloudKitContainerOptions = nil
        description.shouldAddStoreAsynchronously = false
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        // Keep history on even while mirroring is off, including deletion tombstones.
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        do {
            try Self.loadStores(in: container)
        } catch {
            fatalError("Unable to load Catodoro's local store: \(error)")
        }

        writeContext = container.newBackgroundContext()
        writeContext.name = "Preset writer"
        writeContext.transactionAuthor = "Catodoro"
        writeContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        writeContext.automaticallyMergesChangesFromParent = true

        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func setCloudSyncEnabled(_ enabled: Bool) async throws {
        try Task.checkCancellation()
        let context = writeContext
        try await context.perform { [self] in
            guard syncEnabled != enabled else { return }
            // Preview stores never mirror; reopening /dev/null would discard their contents.
            if inMemory { syncEnabled = enabled; return }
            let description = container.persistentStoreDescriptions[0]
            let previousOptions = description.cloudKitContainerOptions
            if context.hasChanges { try context.save() }
            context.reset()
            // Removing the store tears down its mirroring delegate. The SQLite file stays intact.
            for store in container.persistentStoreCoordinator.persistentStores {
                try container.persistentStoreCoordinator.remove(store)
            }
            description.cloudKitContainerOptions = Self.cloudOptions(
                enabled: enabled && !inMemory, identifier: cloudIdentifier
            )
            do {
                try Self.loadStores(in: container)
                syncEnabled = enabled
            } catch {
                // Restore the previous configuration if reopening failed. Never delete the database.
                description.cloudKitContainerOptions = previousOptions
                try Self.loadStores(in: container)
                throw error
            }
        }
    }

    /// A nil identifier supports local-only stores and disk-backed tests without cloud traffic.
    static func cloudOptions(enabled: Bool, identifier: String?) -> NSPersistentCloudKitContainerOptions? {
        guard enabled, let identifier else { return nil }
        let options = NSPersistentCloudKitContainerOptions(containerIdentifier: identifier)
        options.databaseScope = .private
        return options
    }

    private static func loadStores(in container: NSPersistentContainer) throws {
        // shouldAddStoreAsynchronously is false: completion runs before this method returns.
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
    }
}
