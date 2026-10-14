//
//  PresetSyncCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import Combine
import CloudKit

@MainActor
protocol LocalChangesNotifying: AnyObject {
    func localChangeDidCommit() async
}

@MainActor
final class PresetSyncCoordinator: CKSyncEngineDelegate {
    private enum Constants {
        static let zoneName = "Presets"
    }

    var onAccountChange: (() -> Void)?

    private let container: CKContainer
    private let store: PresetSyncStore

    private var engine: CKSyncEngine?
    private var inFlight: [CKRecord.ID: PendingPresetChange] = [:]
    private var activationGeneration = 0
    private var activationTask: Task<Void, Error>?
    private var activationRetryTask: Task<Void, Never>?

    private(set) var lastError: Error?

    @Published private(set) var isFetching = false
    @Published private(set) var isSending = false

    var activityPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest($isFetching, $isSending)
            .map { $0 || $1 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: Constants.zoneName)
    }

    init(container: CKContainer, store: PresetSyncStore) {
        self.container = container
        self.store = store
    }

    func enqueueLocalChanges(
        retrying recordIDs: Set<CKRecord.ID> = [],
        retryingZones zoneIDs: Set<CKRecordZone.ID> = []
    ) async throws {
        guard let engine else { return }

        let changes = try await store.pendingChanges()

        guard self.engine === engine else { return }

        let desired = Set<CKSyncEngine.PendingRecordZoneChange>(
            changes.map { change in
                let recordID = CKRecord.ID(
                    recordName: change.id,
                    zoneID: zoneID
                )

                switch change.action {
                case .upsert:
                    return .saveRecord(recordID)

                case .delete:
                    return .deleteRecord(recordID)
                }
            }
        )

        let queued = Set(
            engine.state.pendingRecordZoneChanges.filter { operation in
                switch operation {
                case .saveRecord(let id), .deleteRecord(let id):
                    return id.zoneID == zoneID

                @unknown default:
                    return false
                }
            }
        )

        let retries = Set(desired.filter { oepration in
            guard case .saveRecord(let id) = oepration else {
                return false
            }

            return recordIDs.contains(id) || zoneIDs.contains(id.zoneID)
        })

        let removals = queued.subtracting(desired)
            .union(queued.intersection(retries))
        let additions = (desired).subtracting(queued)
            .union(retries)

        if !removals.isEmpty {
            engine.state.remove(
                pendingRecordZoneChanges: Array(removals)
            )
        }

        if !additions.isEmpty {
            engine.state.add(
                pendingRecordZoneChanges: Array(additions)
            )
        }
    }

    func syncNow() async throws {
        guard let engine else { return }

        try await engine.fetchChanges()

        guard self.engine === engine else { return }

        try await enqueueLocalChanges()

        guard self.engine === engine else { return }

        try await engine.sendChanges()
    }

    
    private func resetActivity() {
        isFetching = false
        isSending = false
    }
}

// Activation Logics

extension PresetSyncCoordinator {
    private func activateSync(generation: Int) async throws {
        do {
            let status = try await container.accountStatus()

            try checkActivation(generation)

            guard status == .available else {
                throw SyncError.iCloudUnavailable
            }

            let accountID = try await container.userRecordID().recordName
            try checkActivation(generation)

            try await store.bindSyncAccount(accountID)
            try checkActivation(generation)

            try await store.bootstrapSyncIfNeeded()
            try checkActivation(generation)

            let state = try await store.loadEngineState()
            try checkActivation(generation)

            let latestAccountID = try await container.userRecordID().recordName
            try checkActivation(generation)

            guard latestAccountID == accountID else {
                throw SyncError.differentAccount
            }

            var configuration = CKSyncEngine.Configuration(
                database: container.privateCloudDatabase,
                stateSerialization: state,
                delegate: self
            )
            configuration.automaticallySync = true

            let syncEngine = CKSyncEngine(configuration)
            engine = syncEngine

            syncEngine.state.add(pendingDatabaseChanges: [
                .saveZone(CKRecordZone(zoneID: zoneID))
            ])

            try await syncEngine.fetchChanges()

            try checkActivation(generation)

            guard engine === syncEngine else {
                throw CancellationError()
            }

            try await enqueueLocalChanges()
            try checkActivation(generation)
            lastError = nil
        } catch {
            guard generation == activationGeneration,
                  !Task.isCancelled else {
                throw CancellationError()
            }

            // Detach the failed engine before awaiting cancellation
            let failedEngine = engine
            engine = nil
            inFlight.removeAll()
            resetActivity()

            await failedEngine?.cancelOperations()            

            // A new enable/disable request may have occurred while awaiting.
            try checkActivation(generation)

            lastError = error
            throw error
        }
    }

    private func checkActivation(_ generation: Int) throws {
        try Task.checkCancellation()

        guard generation == activationGeneration else {
            throw CancellationError()
        }
    }

    private func scheduleActivationRetry(
        generation: Int,
        error: Error
    ) {
        guard generation == activationGeneration,
              activationRetryTask == nil,
              isRetryableActivationError(error) else {
            return
        }

        activationRetryTask = Task { @MainActor [weak self] in
            var backoff: TimeInterval = 5
            var delay = max(
                backoff,
                (error as? CKError)?.retryAfterSeconds ?? 0
            )

            defer {
                if let self,
                   self.activationGeneration == generation {
                    self.activationRetryTask = nil
                }
            }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(delay * 1_000_000_000)
                    )
                } catch {
                    return
                }

                guard let self,
                      generation == self.activationGeneration else {
                    return
                }

                do {
                    try await self.enableSync()
                    return
                } catch is CancellationError {
                    return
                } catch {
                    guard self.isRetryableActivationError(error) else {
                        return
                    }

                    backoff = min(backoff * 2, 60)
                    delay = max(
                        backoff,
                        (error as? CKError)?.retryAfterSeconds ?? 0
                    )
                }
            }
        }
    }

    private func isRetryableActivationError(_ error: Error) -> Bool {
        guard let error = error as? CKError else { return false }

        switch error.code {
        case .networkFailure,
             .networkUnavailable,
             .zoneBusy,
             .serviceUnavailable,
             .requestRateLimited:
            return true

        default:
            return false
        }
    }
}

extension PresetSyncCoordinator {
    func handleEvent(
        _ event: CKSyncEngine.Event,
        syncEngine: CKSyncEngine
    ) async {
        guard engine === syncEngine else { return }

        do {
            switch event {
            case .stateUpdate(let update):
                try await store.saveEngineState(update.stateSerialization)

            case .fetchedRecordZoneChanges(let changes):
                try await store.merge(
                    records: changes.modifications.map(\.record),
                    deletedIDs: changes.deletions.map(\.recordID)
                )

            case .fetchedDatabaseChanges(let changes):
                guard changes.deletions.contains(where: { $0.zoneID == zoneID }) else {
                    break
                }

                try await store.queueuAllPresets(clearServerRecord: true)

                guard engine === syncEngine else { return }

                syncEngine.state.add(pendingDatabaseChanges: [
                    .saveZone(CKRecordZone(zoneID: zoneID))
                ])

                try await enqueueLocalChanges(
                    retryingZones: [zoneID]
                )

            case .sentRecordZoneChanges(let results):
                try await processSentRecords(
                    savedRecords: results.savedRecords,
                    deletedRecordIDs: results.deletedRecordIDs,
                    failedRecordSaves: results.failedRecordSaves.map { (record: $0.record, error: $0.error) },
                    failedRecordDeletes: results.failedRecordDeletes,
                    syncEngine: syncEngine
                )

            case .accountChange:
                onAccountChange?()

            case .willFetchChanges:
                isFetching = true

            case .didFetchChanges:
                isFetching = false

            case .willSendChanges:
                isSending = true

            case .didSendChanges:
                isSending = false

            default:
                break
            }
        } catch {
            lastError = error
        }
    }

    private func processSentRecords(
        savedRecords: [CKRecord],
        deletedRecordIDs: [CKRecord.ID],
        failedRecordSaves: [(record: CKRecord, error: CKError)],
        failedRecordDeletes: [CKRecord.ID: CKError],
        syncEngine: CKSyncEngine
    ) async throws {
        guard engine === syncEngine else { return }
        var acknowledgementFailed = false

        for record in savedRecords {
            guard let sentChange = inFlight[record.recordID] else {
                continue
            }

            do {
                try await store.acknowledgeSavedRecord(
                    record,
                    sentChange: sentChange
                )

                guard engine === syncEngine else { return }

                inFlight.removeValue(forKey: record.recordID)
            } catch {
                guard engine === syncEngine else { return }

                lastError = error
                acknowledgementFailed = true
                // Keep tracking; the store rolled back its transaction.
            }
        }

        for id in deletedRecordIDs {
            guard let sentChange = inFlight[id] else {
                continue
            }

            do {
                try await store.acknowledgeDeletedRecord(
                    id,
                    sentChange: sentChange
                )

                guard engine === syncEngine else { return }

                inFlight.removeValue(forKey: id)
            } catch {
                guard engine === syncEngine else { return }

                lastError = error
                acknowledgementFailed = true
            }
        }

        var repairedRecordIDs = Set<CKRecord.ID>()
        var recoveredZones = Set<CKRecordZone.ID>()

        for failure in failedRecordSaves {
            inFlight.removeValue(forKey: failure.record.recordID)

            switch failure.error.code {
            case .serverRecordChanged:
                guard let serverRecord = failure.error.serverRecord else {
                    lastError = failure.error
                    continue
                }

                try await store.cacheServerRecord(serverRecord)

                guard engine === syncEngine else { return }

                repairedRecordIDs.insert(serverRecord.recordID)

                // Preserve the local pending action.
                // The final enqueueLocalChanges() will requeue it.
            case .unknownItem:
                try await store.clearServerRecord(failure.record.recordID)

                guard engine === syncEngine else { return }

                repairedRecordIDs.insert(failure.record.recordID)

            case .zoneNotFound:
                let zoneID = failure.record.recordID.zoneID

                guard recoveredZones.insert(zoneID).inserted else {
                    continue
                }

                try await store.queueuAllPresets(clearServerRecord: true)

                guard engine === syncEngine else { return }

                syncEngine.state.add(pendingDatabaseChanges: [
                    .saveZone(
                        CKRecordZone(zoneID: failure.record.recordID.zoneID)
                    )
                ])

            case .networkFailure, .networkUnavailable, .zoneBusy,
                    .serviceUnavailable, .notAuthenticated, .operationCancelled:
                lastError = failure.error

            default:
                lastError = failure.error
            }
        }

        for (id, error) in failedRecordDeletes {
            if error.code == .unknownItem {
                guard let sentChange = inFlight[id] else { continue }

                do {
                    try await store.acknowledgeDeletedRecord(
                        id,
                        sentChange: sentChange
                    )

                    guard engine === syncEngine else { return }

                    inFlight.removeValue(forKey: id)
                } catch {
                    guard engine === syncEngine else { return }

                    lastError = error
                    acknowledgementFailed = true
                }
            } else {
                inFlight.removeValue(forKey: id)
                lastError = error
            }
        }

        guard engine === syncEngine else { return }

        // Avoid repeatedly uploading while local persistence is failing.
        if !acknowledgementFailed {
            try await enqueueLocalChanges(
                retrying: repairedRecordIDs,
                retryingZones: recoveredZones
            )
        }
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        do {
            guard engine === syncEngine else { return nil }

            let changes = syncEngine.state.pendingRecordZoneChanges.filter {
                context.options.scope.contains($0)
            }

            guard !changes.isEmpty else { return nil }

            let pending = try await store.pendingChanges()

            guard engine === syncEngine else { return nil }

            let pendingByID = Dictionary(
                uniqueKeysWithValues: pending.map { ($0.id, $0) }
            )

            var batchChanges: [CKSyncEngine.PendingRecordZoneChange] = []

            for operation in changes {
                switch operation {
                case .saveRecord(let recordID):
                    if let change = pendingByID[recordID.recordName],
                       change.action == .upsert {
                        batchChanges.append(operation)
                    } else {
                        syncEngine.state.remove(
                            pendingRecordZoneChanges: [operation]
                        )

                        if pendingByID[recordID.recordName]?.action == .delete {
                            syncEngine.state.add(
                                pendingRecordZoneChanges: [.deleteRecord(recordID)]
                            )
                        }
                    }

                case .deleteRecord(let recordID):
                    if let change = pendingByID[recordID.recordName],
                       change.action == .delete {
                        inFlight[recordID] = change
                        batchChanges.append(operation)
                    } else {
                        syncEngine.state.remove(
                            pendingRecordZoneChanges: [operation]
                        )

                        if pendingByID[recordID.recordName]?.action == .upsert {
                            syncEngine.state.add(
                                pendingRecordZoneChanges: [.saveRecord(recordID)]
                            )
                        }
                    }

                @unknown default:
                    break
                }
            }

            guard !batchChanges.isEmpty else { return nil }

            return await CKSyncEngine.RecordZoneChangeBatch(
                pendingChanges: batchChanges
            ) { recordId in
                await self.recordForUpload(recordId, syncEngine: syncEngine)
            }
        } catch {
            lastError = error
            return nil
        }
    }

    @MainActor
    private func recordForUpload(_ recordId: CKRecord.ID, syncEngine: CKSyncEngine) async -> CKRecord? {
        guard engine === syncEngine else { return nil }

        do {
            let snapshot = try await store.uploadSnapshot(for: recordId)

            guard engine === syncEngine else { return nil }
            guard let snapshot else {
                let pendingChanges = try await store.pendingChanges()

                guard engine === syncEngine else { return nil }
                // Read the current pending change for recordId
                // Recheck engine identity

                let pendingAction = pendingChanges.first(where: { $0.id == recordId.recordName })

                switch pendingAction?.action {
                case .delete:
                    syncEngine.state.remove(
                        pendingRecordZoneChanges: [.saveRecord(recordId)]
                    )
                    syncEngine.state.add(
                        pendingRecordZoneChanges: [.deleteRecord(recordId)]
                    )

                case .upsert:
                    // The queueu says save, but no upload snaphot exists.
                    // Preserve the pending action and report the inconsistency.
                    lastError = SyncError.invalidMetadata

                case nil:
                    syncEngine.state.remove(
                        pendingRecordZoneChanges: [.saveRecord(recordId)]
                    )
                }

                return nil
            }

            inFlight[recordId] = snapshot.change
            return snapshot.record
        } catch {
            if engine === syncEngine {
                lastError = error
            }

            return nil
        }
    }
}

extension PresetSyncCoordinator: LocalChangesNotifying {
    func localChangeDidCommit() async {
        do {
            try await enqueueLocalChanges()
        } catch {
            lastError = error
        }
    }
}

extension PresetSyncCoordinator: OnboardingSyncControlling {
    func enableSync() async throws {
        // Wait for activation, even if it already created an engine.
        if let activationTask {
            try await activationTask.value
            return
        }

        guard engine == nil else { return }

        let generation = activationGeneration

        let task = Task { @MainActor in
            try await self.activateSync(generation: generation)
        }

        activationTask = task

        defer {
            if activationGeneration == generation {
                activationTask = nil
            }
        }

        do {
            try await task.value
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            scheduleActivationRetry(
                generation: generation,
                error: error
            )
            throw error
        }
    }

    func disableSync() async {
        activationGeneration += 1
        activationTask?.cancel()
        activationTask = nil
        activationRetryTask?.cancel()
        activationRetryTask = nil
        resetActivity()

        let previous = engine
        engine = nil
        inFlight.removeAll()

        await previous?.cancelOperations()
    }
}

#if DEBUG
extension PresetSyncCoordinator {
    var testHooks: TestHooks { TestHooks(target: self) }

    @MainActor
    struct TestHooks {
        let target: PresetSyncCoordinator

        func attach(_ engine: CKSyncEngine) { target.engine = engine }
        func track(_ change: PendingPresetChange, for id: CKRecord.ID) { target.inFlight[id] = change }
        var trackedIDs: Set<CKRecord.ID> { Set(target.inFlight.keys) }

        func process(
            saved: [CKRecord] = [],
            deleted: [CKRecord.ID] = [],
            failedSaves: [(record: CKRecord, error: CKError)] = [],
            failedDeletes: [CKRecord.ID: CKError] = [:],
            engine: CKSyncEngine
        ) async throws {
            try await target.processSentRecords(
                savedRecords: saved, deletedRecordIDs: deleted,
                failedRecordSaves: failedSaves, failedRecordDeletes: failedDeletes,
                syncEngine: engine
            )
        }
    }
}
#endif
