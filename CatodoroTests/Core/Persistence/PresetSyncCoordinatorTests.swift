import CloudKit
import XCTest
@testable import Catodoro

@MainActor
final class PresetSyncCoordinatorTests: XCTestCase {
    private let zone = CKRecordZone.ID(zoneName: "Presets")

    func test_reconciliationReplacesOppositeActionsAndRemovesStaleWork() async throws {
        let (coordinator, engine, store) = makeSystem()
        let save = id(), delete = id(), stale = id()
        store.pending = [change(save, .upsert), change(delete, .delete)]
        engine.state.add(pendingRecordZoneChanges: [.deleteRecord(save), .saveRecord(delete), .saveRecord(stale)])
        try await coordinator.enqueueLocalChanges()
        XCTAssertEqual(Set(engine.state.pendingRecordZoneChanges), [.saveRecord(save), .deleteRecord(delete)])
        await coordinator.disableSync()
    }

    func test_conflictCachesServerRecordPreservesRevisionAndClearsAttemptTracking() async throws {
        let (coordinator, engine, store) = makeSystem()
        let recordID = id(), pending = change(id(), .upsert)
        let local = PendingPresetChange(id: recordID.recordName, action: .upsert, revision: pending.revision)
        store.pending = [local]
        coordinator.testHooks.track(local, for: recordID)
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
        let record = CKRecord(recordType: "Preset", recordID: recordID)
        let error = CKError(.serverRecordChanged, userInfo: [CKRecordChangedErrorServerRecordKey: record])
        try await coordinator.testHooks.process(failedSaves: [(record, error)], engine: engine)
        XCTAssertEqual(store.cachedIDs, [recordID])
        XCTAssertEqual(store.pending, [local])
        XCTAssertTrue(coordinator.testHooks.trackedIDs.isEmpty)
        XCTAssertEqual(Set(engine.state.pendingRecordZoneChanges), [.saveRecord(recordID)])
        await coordinator.disableSync()
    }

    func test_acknowledgementFailureDoesNotSkipOtherSuccessesOrRequeueImmediately() async throws {
        let (coordinator, engine, store) = makeSystem()
        let first = id(), second = id()
        let a = change(first, .upsert), b = change(second, .upsert)
        store.pending = [a, b]
        store.failingAcknowledgement = first
        coordinator.testHooks.track(a, for: first)
        coordinator.testHooks.track(b, for: second)
        try await coordinator.testHooks.process(saved: [record(first), record(second)], engine: engine)
        XCTAssertEqual(store.acknowledged, [second])
        XCTAssertEqual(store.pending, [a])
        XCTAssertEqual(coordinator.testHooks.trackedIDs, [first])
        XCTAssertTrue(engine.state.pendingRecordZoneChanges.isEmpty)
        await coordinator.disableSync()
        XCTAssertTrue(coordinator.testHooks.trackedIDs.isEmpty)
        XCTAssertEqual(store.pending, [a])
    }

    func test_missingDeleteAcknowledgesButTemporaryFailurePreservesLocalWork() async throws {
        let (coordinator, engine, store) = makeSystem()
        let missing = id(), offline = id()
        let a = change(missing, .delete), b = change(offline, .delete)
        store.pending = [a, b]
        coordinator.testHooks.track(a, for: missing)
        coordinator.testHooks.track(b, for: offline)
        engine.state.add(pendingRecordZoneChanges: [.deleteRecord(offline)])
        try await coordinator.testHooks.process(failedDeletes: [missing: CKError(.unknownItem), offline: CKError(.networkUnavailable)], engine: engine)
        XCTAssertEqual(store.pending, [b])
        XCTAssertEqual(store.acknowledged, [missing])
        XCTAssertTrue(coordinator.testHooks.trackedIDs.isEmpty)
        XCTAssertEqual(Set(engine.state.pendingRecordZoneChanges), [.deleteRecord(offline)])
        await coordinator.disableSync()
    }

    func test_missingZoneRecoversOnceAndRetainsPendingSaves() async throws {
        let (coordinator, engine, store) = makeSystem()
        let a = id(), b = id()
        store.pending = [change(a, .upsert), change(b, .upsert)]
        try await coordinator.testHooks.process(failedSaves: [(record(a), CKError(.zoneNotFound)), (record(b), CKError(.zoneNotFound))], engine: engine)
        XCTAssertEqual(store.recoveryCount, 1)
        XCTAssertEqual(Set(engine.state.pendingRecordZoneChanges), [.saveRecord(a), .saveRecord(b)])
        XCTAssertFalse(engine.state.pendingDatabaseChanges.isEmpty)
        await coordinator.disableSync()
    }

    private func id() -> CKRecord.ID { CKRecord.ID(recordName: UUID().uuidString, zoneID: zone) }
    private func record(_ id: CKRecord.ID) -> CKRecord { CKRecord(recordType: "Preset", recordID: id) }
    private func change(_ id: CKRecord.ID, _ action: PendingActions) -> PendingPresetChange {
        PendingPresetChange(id: id.recordName, action: action, revision: UUID().uuidString)
    }
    private func makeSystem() -> (PresetSyncCoordinator, CKSyncEngine, SyncStoreMock) {
        let store = SyncStoreMock()
        let cloud = CKContainer(identifier: "iCloud.com.stokuda.catodoro")
        let coordinator = PresetSyncCoordinator(container: cloud, store: store)
        var config = CKSyncEngine.Configuration(database: cloud.privateCloudDatabase, stateSerialization: nil, delegate: coordinator)
        config.automaticallySync = false
        let engine = CKSyncEngine(config)
        coordinator.testHooks.attach(engine)
        return (coordinator, engine, store)
    }
}

private final class SyncStoreMock: PresetSyncStore {
    var pending: [PendingPresetChange] = []
    var cachedIDs: [CKRecord.ID] = []
    var acknowledged: [CKRecord.ID] = []
    var failingAcknowledgement: CKRecord.ID?
    var recoveryCount = 0
    func loadEngineState() async throws -> CKSyncEngine.State.Serialization? { nil }
    func saveEngineState(_ state: CKSyncEngine.State.Serialization) async throws {}
    func pendingChanges() async throws -> [PendingPresetChange] { pending }
    func uploadSnapshot(for id: CKRecord.ID) async throws -> PresetUploadSnapshot? { nil }
    func merge(records: [CKRecord], deletedIDs: [CKRecord.ID]) async throws {}
    func acknowledgeSavedRecord(_ record: CKRecord, sentChange: PendingPresetChange) async throws { try acknowledge(record.recordID, sentChange) }
    func acknowledgeDeletedRecord(_ id: CKRecord.ID, sentChange: PendingPresetChange) async throws { try acknowledge(id, sentChange) }
    private func acknowledge(_ id: CKRecord.ID, _ change: PendingPresetChange) throws {
        if id == failingAcknowledgement { throw SyncError.invalidMetadata }
        acknowledged.append(id)
        pending.removeAll { $0 == change }
    }
    func cacheServerRecord(_ record: CKRecord) async throws { cachedIDs.append(record.recordID) }
    func clearServerRecord(_ id: CKRecord.ID) async throws {}
    func queueuAllPresets(clearServerRecord: Bool) async throws { recoveryCount += 1 }
    func bootstrapSyncIfNeeded() async throws {}
    func bindSyncAccount(_ accountID: String) async throws {}
}
