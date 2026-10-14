import CloudKit
import CoreData
import XCTest
@testable import Catodoro

@MainActor
final class CatodoroPersistentControllerTests: XCTestCase {
    func test_cloudConfigurationUsesPrivateDatabaseAndRequiresOptIn() throws {
        XCTAssertNil(CatodoroPersistentController.cloudOptions(enabled: false, identifier: "iCloud.test"))
        let options = try XCTUnwrap(CatodoroPersistentController.cloudOptions(enabled: true, identifier: "iCloud.test"))
        XCTAssertEqual(options.containerIdentifier, "iCloud.test")
        XCTAssertEqual(options.databaseScope, .private)
    }

    func test_diskStoreRetainsPresetsAndOfflineEditsAcrossLiveToggles() async throws {
        let url = temporaryURL()
        defer { removeDatabase(url) }
        // Suppress network mirroring while exercising the real SQLite unload/reload path.
        let persistence = CatodoroPersistentController(storeURL: url, cloudIdentifier: nil)
        let manager = CatodoroCoreDataManager(context: persistence.writeContext)
        let first = preset("First")
        try await manager.savePreset(first)
        let description = try XCTUnwrap(persistence.container.persistentStoreDescriptions.first)
        XCTAssertEqual(description.url, url)
        XCTAssertEqual(description.options[NSPersistentHistoryTrackingKey] as? NSNumber, true)
        XCTAssertNil(description.cloudKitContainerOptions)
        try await persistence.setCloudSyncEnabled(true)
        let initial = try await manager.getPresets()
        XCTAssertEqual(initial, [first])
        try await persistence.setCloudSyncEnabled(false)
        try await manager.deletePreset(first.id.uuidString)
        let second = preset("Offline")
        try await manager.savePreset(second)
        let updated = PresetModel(id: second.id, totalDuration: 3000, intervalDuration: 600,
                                  intervals: 2, name: "Edited offline", imageIdentifier: "CatSleeping")
        try await manager.savePreset(updated)
        let deletionCount = try await persistence.writeContext.perform {
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: Date.distantPast)
            request.resultType = .transactionsAndChanges
            let result = try persistence.writeContext.execute(request) as? NSPersistentHistoryResult
            let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
            return transactions.flatMap { $0.changes ?? [] }.filter { $0.changeType == .delete }.count
        }
        XCTAssertEqual(deletionCount, 1, "Offline deletions must remain in persistent history")
        try await persistence.setCloudSyncEnabled(true)
        let offline = try await manager.getPresets()
        XCTAssertEqual(offline, [updated])
        XCTAssertEqual(description.url, url)
        XCTAssertEqual(description.options[NSPersistentHistoryTrackingKey] as? NSNumber, true)
        try await close(persistence)
        let reopened = CatodoroPersistentController(storeURL: url, cloudIdentifier: nil)
        let freshManager = CatodoroCoreDataManager(context: reopened.writeContext)
        let restored = try await freshManager.getPresets()
        XCTAssertEqual(restored, [updated])
        try await close(reopened)
    }

    func test_v2MigrationPreservesPresetsAndRemovesEngineMetadata() async throws {
        let url = temporaryURL()
        defer { removeDatabase(url) }
        let bundle = Bundle(for: CatodoroCoreDataManager.self)
        let directory = try XCTUnwrap(bundle.url(forResource: "CatodoroCoreData", withExtension: "momd"))
        let model = try XCTUnwrap(NSManagedObjectModel(contentsOf: directory.appendingPathComponent("CatodoroCoreDataV2.mom")))
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let store = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let id = UUID()
        let row = NSEntityDescription.insertNewObject(forEntityName: "PresetEntity", into: context)
        row.setValue(id, forKey: "id")
        row.setValue("Existing", forKey: "name")
        row.setValue(1500.0, forKey: "totalDuration")
        row.setValue(4, forKey: "intervals")
        let metadata = NSEntityDescription.insertNewObject(forEntityName: "LocalSyncMetadata", into: context)
        metadata.setValue("ckSyncState", forKey: "key")
        metadata.setValue(Data([1, 2]), forKey: "data")
        try context.save()
        context.reset()
        try coordinator.remove(store)

        let persistence = CatodoroPersistentController(storeURL: url, cloudIdentifier: nil)
        let manager = CatodoroCoreDataManager(context: persistence.writeContext)
        let rows = try await manager.getPresets()
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.id, id)
        XCTAssertEqual(rows.first?.name, "Existing")
        XCTAssertEqual(Set(persistence.container.managedObjectModel.entities.compactMap(\.name)), ["PresetEntity"])
        try await close(persistence)
    }

    func test_savesAndReloadsShareOneSerialQueue() async throws {
        let url = temporaryURL()
        defer { removeDatabase(url) }
        let persistence = CatodoroPersistentController(storeURL: url, cloudIdentifier: nil)
        let manager = CatodoroCoreDataManager(context: persistence.writeContext)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                let model = preset("Preset \(index)")
                group.addTask { try await manager.savePreset(model) }
                group.addTask { try await persistence.setCloudSyncEnabled(index.isMultiple(of: 2)) }
            }
            try await group.waitForAll()
        }
        let rows = try await manager.getPresets()
        XCTAssertEqual(rows.count, 20)
        try await close(persistence)
    }

    private func preset(_ name: String) -> PresetModel {
        PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 4,
                    name: name, imageIdentifier: "CatSitting")
    }
    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
    }
    private func removeDatabase(_ url: URL) {
        for suffix in ["", "-wal", "-shm"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
    }
    private func close(_ persistence: CatodoroPersistentController) async throws {
        try await persistence.writeContext.perform {
            persistence.writeContext.reset()
            for store in persistence.container.persistentStoreCoordinator.persistentStores {
                try persistence.container.persistentStoreCoordinator.remove(store)
            }
        }
    }
}
