import CloudKit
import CoreData
import XCTest
@testable import Catodoro

@MainActor
final class CoreDataPresetSyncStoreTests: XCTestCase {
    func test_saveAcknowledgementPreservesNewerEditThenClearsMatchingRevision() async throws {
        let (container, context, store, manager) = try await makeSystem()
        _ = container
        let id = UUID()
        try await manager.savePreset(preset(id, duration: 1500))
        let recordID = cloudID(id)
        let fetched1 = try await store.uploadSnapshot(for: recordID)
        let first = try XCTUnwrap(fetched1)
        try await manager.savePreset(preset(id, duration: 1800))
        let newer = try await store.pendingChanges()
        try await store.acknowledgeSavedRecord(first.record, sentChange: first.change)
        let fetched2 = try await store.pendingChanges()
        XCTAssertEqual(fetched2, newer)
        let local = try await manager.getPresets()
        XCTAssertEqual(local.first?.totalDuration, 1800)
        let fetched3 = try await store.uploadSnapshot(for: recordID)
        let current = try XCTUnwrap(fetched3)
        try await store.acknowledgeSavedRecord(current.record, sentChange: current.change)
        let fetched4 = try await store.pendingChanges().isEmpty
        XCTAssertTrue(fetched4)
        let caches = try await context.perform { try context.count(for: LocalCloudRecord.fetchRequest()) }
        XCTAssertEqual(caches, 1)
    }

    func test_deleteAcknowledgementPreservesRecreatedPresetAndItsSave() async throws {
        let (_, context, store, manager) = try await makeSystem()
        let id = UUID(), recordID = cloudID(id)
        try await manager.savePreset(preset(id, duration: 1500))
        try await store.cacheServerRecord(CKRecord(recordType: "Preset", recordID: recordID))
        try await manager.deletePreset(id.uuidString)
        let fetched5 = try await store.pendingChanges()
        let sent = try XCTUnwrap(fetched5.first)
        try await manager.savePreset(preset(id, duration: 1800))
        let newer = try await store.pendingChanges()
        try await store.acknowledgeDeletedRecord(recordID, sentChange: sent)
        let fetched6 = try await store.pendingChanges()
        XCTAssertEqual(fetched6, newer)
        let fetched7 = try await manager.getPresets().count
        XCTAssertEqual(fetched7, 1)
        let caches = try await context.perform { try context.count(for: LocalCloudRecord.fetchRequest()) }
        XCTAssertEqual(caches, 0)
    }

    func test_matchingDeleteAcknowledgementClearsPendingWork() async throws {
        let (_, _, store, manager) = try await makeSystem()
        let id = UUID()
        try await manager.savePreset(preset(id, duration: 1500))
        try await manager.deletePreset(id.uuidString)
        let fetched8 = try await store.pendingChanges()
        let sent = try XCTUnwrap(fetched8.first)
        try await store.acknowledgeDeletedRecord(cloudID(id), sentChange: sent)
        let fetched9 = try await store.pendingChanges().isEmpty
        XCTAssertTrue(fetched9)
        let fetched10 = try await manager.getPresets().isEmpty
        XCTAssertTrue(fetched10)
    }

    func test_zoneRecoveryPreservesPendingRevisionsAndEnrollsUnqueuedPresets() async throws {
        let (_, context, store, manager) = try await makeSystem()
        let existing = UUID(), unqueued = UUID()
        try await manager.savePreset(preset(existing, duration: 1500))
        let original = try await store.pendingChanges()
        try await context.perform {
            let row = PresetEntity(context: context)
            row.id = unqueued
            row.totalDuration = 1200
            try context.save()
        }
        try await store.cacheServerRecord(CKRecord(recordType: "Preset", recordID: cloudID(existing)))
        try await store.queueuAllPresets(clearServerRecord: true)
        let actions = try await store.pendingChanges()
        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(actions.first { $0.id == existing.uuidString }, original.first)
        XCTAssertEqual(actions.first { $0.id == unqueued.uuidString }?.action, .upsert)
        XCTAssertFalse(actions.first { $0.id == unqueued.uuidString }!.revision.isEmpty)
        let caches = try await context.perform { try context.count(for: LocalCloudRecord.fetchRequest()) }
        XCTAssertEqual(caches, 0)
        try await store.queueuAllPresets(clearServerRecord: false)
        let fetched11 = try await store.pendingChanges().map(\.revision)
        XCTAssertEqual(Set(fetched11), Set(actions.map(\.revision)))
    }

    func test_bootstrapEnrollsExistingPresetsAndPersistsMarker() async throws {
        let (_, context, store, _) = try await makeSystem()
        let ids = [UUID(), UUID()]
        try await context.perform {
            for id in ids {
                let row = PresetEntity(context: context)
                row.id = id
                row.totalDuration = 1500
            }
            try context.save()
        }

        try await store.bootstrapSyncIfNeeded()

        let actions = try await store.pendingChanges()
        XCTAssertEqual(Set(actions.map(\.id)), Set(ids.map(\.uuidString)))
        XCTAssertTrue(actions.allSatisfy { $0.action == .upsert && !$0.revision.isEmpty })
        XCTAssertEqual(Set(actions.map(\.revision)).count, 2)
        let marker = try await bootstrapMarkers(in: context)
        XCTAssertEqual(marker, [Data([1])])
    }

    func test_bootstrapPreservesExistingSaveAndDeleteRevisions() async throws {
        let (_, context, store, manager) = try await makeSystem()
        let saved = UUID(), deleted = UUID(), unqueued = UUID()
        try await manager.savePreset(preset(saved, duration: 1500))
        try await manager.savePreset(preset(deleted, duration: 1500))
        try await manager.deletePreset(deleted.uuidString)
        let original = try await store.pendingChanges()
        try await context.perform {
            let row = PresetEntity(context: context)
            row.id = unqueued
            row.totalDuration = 1200
            try context.save()
        }

        try await store.bootstrapSyncIfNeeded()

        let actions = try await store.pendingChanges()
        XCTAssertEqual(actions.count, 3)
        for old in original {
            XCTAssertEqual(actions.first { $0.id == old.id }, old)
        }
        XCTAssertEqual(actions.first { $0.id == unqueued.uuidString }?.action, .upsert)
    }

    func test_bootstrapDoesNotReenrollAcknowledgedPresets() async throws {
        let (_, context, store, _) = try await makeSystem()
        let id = UUID()
        try await context.perform {
            let row = PresetEntity(context: context)
            row.id = id
            row.totalDuration = 1500
            try context.save()
        }
        try await store.bootstrapSyncIfNeeded()
        let firstSnapshot = try await store.uploadSnapshot(for: cloudID(id))
        let snapshot = try XCTUnwrap(firstSnapshot)
        try await store.acknowledgeSavedRecord(snapshot.record, sentChange: snapshot.change)

        // A new adapter must honor the persisted marker too.
        let restoredStore = CoreDataPresetSyncStore(context: context)
        try await restoredStore.bootstrapSyncIfNeeded()
        let actions = try await restoredStore.pendingChanges()
        XCTAssertTrue(actions.isEmpty)
        let markers = try await bootstrapMarkers(in: context)
        XCTAssertEqual(markers.count, 1)
    }

    func test_invalidPresetRollsBackBootstrapAndAllowsRetry() async throws {
        let (_, context, store, _) = try await makeSystem()
        let validID = UUID()
        try await context.perform {
            let valid = PresetEntity(context: context)
            valid.id = validID
            valid.totalDuration = 1500
            let invalid = PresetEntity(context: context)
            invalid.totalDuration = 1200
            try context.save()
        }

        do {
            try await store.bootstrapSyncIfNeeded()
            XCTFail("Expected invalid preset ID to reject bootstrap")
        } catch {
            XCTAssertTrue(error is SyncError)
        }

        let actions = try await store.pendingChanges()
        let markers = try await bootstrapMarkers(in: context)
        let hasChanges = await context.perform { context.hasChanges }
        XCTAssertTrue(actions.isEmpty)
        XCTAssertTrue(markers.isEmpty)
        XCTAssertFalse(hasChanges)

        try await context.perform {
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == nil")
            let invalid = try XCTUnwrap(context.fetch(request).first)
            invalid.id = UUID()
            try context.save()
        }
        try await store.bootstrapSyncIfNeeded()
        let retried = try await store.pendingChanges()
        let retryMarkers = try await bootstrapMarkers(in: context)
        XCTAssertEqual(retried.count, 2)
        XCTAssertEqual(retryMarkers, [Data([1])])
    }

    func test_accountBindingPersistsAndSameAccountDoesNotDuplicateMetadata() async throws {
        let (_, context, store, _) = try await makeSystem()
        try await store.bindSyncAccount("account-A")
        let restored = CoreDataPresetSyncStore(context: context)
        try await restored.bindSyncAccount("account-A")
        let bindings = try await accountBindings(in: context)
        XCTAssertEqual(bindings, [Data("account-A".utf8)])
    }

    func test_differentAccountPreservesOriginalBindingAndPendingChanges() async throws {
        let (_, context, store, manager) = try await makeSystem()
        try await manager.savePreset(preset(UUID(), duration: 1500))
        let original = try await store.pendingChanges()
        try await store.bindSyncAccount("account-A")

        do {
            try await store.bindSyncAccount("account-B")
            XCTFail("Different account must be rejected")
        } catch SyncError.differentAccount {} catch {
            XCTFail("Unexpected error: \(error)")
        }

        let bindings = try await accountBindings(in: context)
        let pending = try await store.pendingChanges()
        let presets = try await manager.getPresets()
        let dirty = await context.perform { context.hasChanges }
        XCTAssertEqual(bindings, [Data("account-A".utf8)])
        XCTAssertEqual(pending, original)
        XCTAssertEqual(presets.count, 1)
        XCTAssertFalse(dirty)
    }

    func test_malformedAccountMetadataIsRejectedWithoutOverwritingIt() async throws {
        for data in [nil, Data([0xff])] as [Data?] {
            let (_, context, store, _) = try await makeSystem()
            try await context.perform {
                let row = LocalSyncMetadata(context: context)
                row.key = "syncAccountID"
                row.data = data
                try context.save()
            }

            do {
                try await store.bindSyncAccount("account-A")
                XCTFail("Malformed account metadata must be rejected")
            } catch SyncError.invalidMetadata {} catch {
                XCTFail("Unexpected error: \(error)")
            }

            let retained = try await context.perform { () throws -> [Data?] in
                let request: NSFetchRequest<LocalSyncMetadata> = LocalSyncMetadata.fetchRequest()
                request.predicate = NSPredicate(format: "key == %@", "syncAccountID")
                return try context.fetch(request).map(\.data)
            }
            XCTAssertEqual(retained, [data])
        }
    }

    private func accountBindings(in context: NSManagedObjectContext) async throws -> [Data] {
        try await context.perform {
            let request: NSFetchRequest<LocalSyncMetadata> = LocalSyncMetadata.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@", "syncAccountID")
            return try context.fetch(request).compactMap(\.data)
        }
    }

    private func bootstrapMarkers(in context: NSManagedObjectContext) async throws -> [Data] {
        try await context.perform {
            let request: NSFetchRequest<LocalSyncMetadata> = LocalSyncMetadata.fetchRequest()
            request.predicate = NSPredicate(format: "key == %@", "presetSyncBootstrap")
            return try context.fetch(request).compactMap(\.data)
        }
    }

    private func preset(_ id: UUID, duration: TimeInterval) -> PresetModel {
        PresetModel(id: id, totalDuration: duration, intervalDuration: 300, intervals: 4)
    }
    private func cloudID(_ id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString, zoneID: CKRecordZone.ID(zoneName: "Presets"))
    }
    private func makeSystem() async throws -> (NSPersistentContainer, NSManagedObjectContext, CoreDataPresetSyncStore, CatodoroCoreDataManager) {
        let container = NSPersistentContainer(name: "CatodoroCoreData")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
        let context = container.newBackgroundContext()
        return (container, context, CoreDataPresetSyncStore(context: context), CatodoroCoreDataManager(context: context))
    }
}
