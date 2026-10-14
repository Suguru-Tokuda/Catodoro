//
//  CoreDataPresetSyncStore.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import CoreData
import CloudKit

struct PendingPresetChange: Equatable, Sendable {
    let id: String
    let action: PendingActions
    let revision: String
}

struct PresetUploadSnapshot {
    let record: CKRecord
    let change: PendingPresetChange
}

protocol PresetSyncStore: AnyObject {
    func loadEngineState() async throws -> CKSyncEngine.State.Serialization?
    func saveEngineState(_ state: CKSyncEngine.State.Serialization) async throws
    func pendingChanges() async throws -> [PendingPresetChange]
    func uploadSnapshot(for id: CKRecord.ID) async throws -> PresetUploadSnapshot?
    func merge(records: [CKRecord], deletedIDs: [CKRecord.ID]) async throws
    func acknowledgeSavedRecord(_ record: CKRecord, sentChange: PendingPresetChange) async throws
    func acknowledgeDeletedRecord(_ id: CKRecord.ID, sentChange: PendingPresetChange) async throws
    func cacheServerRecord(_ record: CKRecord) async throws
    func clearServerRecord(_ id: CKRecord.ID) async throws
    func queueuAllPresets(clearServerRecord: Bool) async throws
    func bootstrapSyncIfNeeded() async throws
    func bindSyncAccount(_ accountID: String) async throws
}

enum LocalSyncMetadataKeys: String {
    case ckSyncState
    case presetSyncBootstrap
    case syncAccountID
}

final class CoreDataPresetSyncStore: PresetSyncStore {
    private enum Constants {
        static let preset = "Preset"
        static let presets = "Presets"

        static let upsert = "upsert"
        static let delete = "delete"
    }

    private enum Keys {
        static let name = "name"
        static let imageIdentifier = "imageIdentifier"
        static let totalDuration = "totalDuration"
        static let intervalDuration = "intervalDuration"
        static let intervals = "intervals"
    }

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func loadEngineState() async throws -> CKSyncEngine.State.Serialization? {
        let context = self.context
        return try await context.perform {
            guard let localSyncMetadata = try Self.getLocalSyncMetadata(key: LocalSyncMetadataKeys.ckSyncState.rawValue, in: context) else {
                return nil
            }

            guard let data = localSyncMetadata.data else {
                throw SyncError.invalidMetadata
            }

            return try JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
        }
    }

    func saveEngineState(_ state: CKSyncEngine.State.Serialization) async throws {
        let context = self.context
        return try await context.perform {
            do {
                let data = try JSONEncoder().encode(state)

                let metadata = try Self.getLocalSyncMetadata(key: LocalSyncMetadataKeys.ckSyncState.rawValue, in: context) ?? LocalSyncMetadata(context: context)
                metadata.key = LocalSyncMetadataKeys.ckSyncState.rawValue
                metadata.data = data

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func pendingChanges() async throws -> [PendingPresetChange] {
        let context = self.context
        return try await context.perform {
            let request: NSFetchRequest<LocalSyncAction> = LocalSyncAction.fetchRequest()
            let rows = try context.fetch(request)

            return try rows.map { row in
                guard let id = row.id,
                      let rawAction = row.action,
                      let action = PendingActions(rawValue: rawAction),
                      let revision = row.revision else {
                    throw SyncError.invalidMetadata
                }

                return PendingPresetChange(id: id, action: action, revision: revision)
            }
        }
    }

    func uploadSnapshot(for id: CKRecord.ID) async throws -> PresetUploadSnapshot? {
        let context = self.context
        return try await context.perform { () throws -> PresetUploadSnapshot? in
            guard let presetId = UUID(uuidString: id.recordName) else {
                throw SyncError.invalidMetadata
            }

            let presetRequest: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            presetRequest.predicate = NSPredicate(format: "id == %@", presetId as NSUUID)
            presetRequest.fetchLimit = 1

            guard let preset = try context.fetch(presetRequest).first else {
                return nil
            }

            let cached = try Self.getCachedCloudRecord(for: id.recordName, in: context)

            let record: CKRecord

            if let data = cached?.data {
                let decoder = try NSKeyedUnarchiver(forReadingFrom: data)
                decoder.requiresSecureCoding = true
                defer { decoder.finishDecoding() }

                guard let restored = CKRecord(coder: decoder),
                      restored.recordID == id,
                      restored.recordType == Constants.preset else {
                    throw SyncError.invalidMetadata
                }

                record = restored
            } else {
                record = CKRecord(recordType: Constants.preset, recordID: id)
            }

            record[Keys.name] = preset.name as CKRecordValue?
            record[Keys.imageIdentifier] = preset.imageIdentifier as CKRecordValue?
            record[Keys.totalDuration] = NSNumber(value: preset.totalDuration)
            record[Keys.intervalDuration] = NSNumber(value: preset.intervalDuration)
            record[Keys.intervals] = NSNumber(value: preset.intervals)

            guard let pendingRow = try Self.getPendingChange(for: record.recordID.recordName, in: context) else {
                return nil
            }

            guard let rawAction = pendingRow.action,
                  let action = PendingActions(rawValue: rawAction),
                  let revision = pendingRow.revision else {
                throw SyncError.invalidMetadata
            }

            guard action == .upsert else {
                return nil // A deletion needs no upload record.
            }

            let pendingChange = PendingPresetChange(
                id: id.recordName,
                action: action,
                revision: revision
            )

            return PresetUploadSnapshot(
                record: record,
                change: pendingChange
            )
        }
    }

    func merge(records: [CKRecord], deletedIDs: [CKRecord.ID]) async throws {
        let context = self.context
        try await context.perform {
            do {
                let zoneId = CKRecordZone.ID(zoneName: Constants.presets)

                let pendingRequest: NSFetchRequest<LocalSyncAction> = LocalSyncAction.fetchRequest()
                let pendingIds = Set(
                    try context.fetch(pendingRequest).compactMap(\.id)
                )

                for record in records {
                    guard record.recordID.zoneID == zoneId,
                          record.recordType == Constants.preset else {
                        continue
                    }

                    let id = record.recordID.recordName

                    guard let uuid = UUID(uuidString: id),
                          let totalDuration = record[Keys.totalDuration] as? NSNumber,
                          let intervalDuration = record[Keys.intervalDuration] as? NSNumber,
                          let intervals = record[Keys.intervals] as? NSNumber else {
                        throw SyncError.invalidMetadata
                    }

                    let cache = try Self.getCachedCloudRecord(for: id, in: context) ?? LocalCloudRecord(context: context)

                    let encoder = NSKeyedArchiver(requiringSecureCoding: true)
                    record.encodeSystemFields(with: encoder)
                    encoder.finishEncoding()

                    cache.id = id
                    cache.data = encoder.encodedData

                    // A pending save or deletion takes precedence locally.
                    guard !pendingIds.contains(id) else { continue }

                    let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "id == %@",
                        uuid as NSUUID
                    )
                    request.fetchLimit = 1

                    let preset = try context.fetch(request).first ?? PresetEntity(context: context)

                    preset.id = uuid
                    preset.name = record[Keys.name] as? String
                    preset.imageIdentifier = record[Keys.imageIdentifier] as? String
                    preset.totalDuration = totalDuration.doubleValue
                    preset.intervalDuration = intervalDuration.doubleValue
                    preset.intervals = intervals.int64Value
                }

                for recordId in deletedIDs where recordId.zoneID == zoneId {
                    let id = recordId.recordName

                    guard let uuid = UUID(uuidString: id) else {
                        throw SyncError.invalidMetadata
                    }

                    let cachedRequest: NSFetchRequest<LocalCloudRecord> = LocalCloudRecord.fetchRequest()
                    cachedRequest.predicate = NSPredicate(format: "id == %@", id)

                    for cache in try context.fetch(cachedRequest) {
                        context.delete(cache)
                    }

                    guard !pendingIds.contains(id) else { continue }

                    let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
                    request.predicate = NSPredicate(
                        format: "id == %@",
                        uuid as NSUUID
                    )

                    for preset in try context.fetch(request) {
                        context.delete(preset)
                    }
                }

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func acknowledgeSavedRecord(
        _ record: CKRecord,
        sentChange: PendingPresetChange
    ) async throws {
        let context = context
        try await context.perform {
            do {
                guard record.recordID.recordName == sentChange.id,
                      record.recordID.zoneID == CKRecordZone.ID(zoneName: Constants.presets),
                      record.recordType == Constants.preset,
                      sentChange.action == .upsert else {
                    throw SyncError.invalidMetadata
                }

                let cache = try Self.getCachedCloudRecord(
                    for: record.recordID.recordName,
                    in: context
                ) ?? LocalCloudRecord(context: context)

                let encoder = NSKeyedArchiver(requiringSecureCoding: true)
                record.encodeSystemFields(with: encoder)
                encoder.finishEncoding()

                cache.id = record.recordID.recordName
                cache.data = encoder.encodedData

                if let pending = try Self.getPendingChange(
                    for: record.recordID.recordName,
                    in: context
                ),
                   pending.action == sentChange.action.rawValue,
                   pending.revision == sentChange.revision {
                    context.delete(pending)
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func acknowledgeDeletedRecord(
        _ id: CKRecord.ID,
        sentChange: PendingPresetChange
    ) async throws {
        let context = context
        try await context.perform {
            do {
                guard id.recordName == sentChange.id,
                      id.zoneID == CKRecordZone.ID(zoneName: Constants.presets),
                      sentChange.action == .delete else {
                    throw SyncError.invalidMetadata
                }

                if let cache = try Self.getCachedCloudRecord(
                    for: id.recordName,
                    in: context
                ) {
                    context.delete(cache)
                }

                if let pending = try Self.getPendingChange(
                    for: id.recordName,
                    in: context
                ),
                   pending.action == PendingActions.delete.rawValue,
                   pending.revision == sentChange.revision {
                    context.delete(pending)
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func cacheServerRecord(_ record: CKRecord) async throws {
        let context = self.context

        try await context.perform {
            do {
                guard record.recordID.zoneID == CKRecordZone.ID(zoneName: Constants.presets),
                      record.recordType == Constants.preset else {
                    throw SyncError.invalidMetadata
                }

                let cache = try Self.getCachedCloudRecord(
                    for: record.recordID.recordName,
                    in: context
                ) ?? LocalCloudRecord(context: context)

                let encoder = NSKeyedArchiver(requiringSecureCoding: true)
                record.encodeSystemFields(with: encoder)
                encoder.finishEncoding()

                cache.id = record.recordID.recordName
                cache.data = encoder.encodedData

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func clearServerRecord(_ id: CKRecord.ID) async throws {
        let context = self.context

        try await context.perform {
            do {
                guard id.zoneID == CKRecordZone.ID(zoneName: Constants.presets) else {
                    throw SyncError.invalidMetadata
                }

                if let cached = try Self.getCachedCloudRecord(
                    for: id.recordName,
                    in: context
                ) {
                    context.delete(cached)
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func queueuAllPresets(clearServerRecord: Bool) async throws {
        let context = self.context
        
        try await context.perform {
            do {
                if clearServerRecord {
                   let cached = try Self.getAllCachedCloudRecord(in: context)
                      if !cached.isEmpty {
                          for cache in cached {
                              context.delete(cache)
                          }
                   }
                }

                let presetRequest: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
                let presets = try context.fetch(presetRequest)

                let pendingActionsRequest: NSFetchRequest<LocalSyncAction> = LocalSyncAction.fetchRequest()
                let pendingActions = try context.fetch(pendingActionsRequest)
                let pendingActionIds: Set<String> = Set(pendingActions.compactMap(\.id))

                for preset in presets {
                    guard let id = preset.id?.uuidString,
                          !id.isEmpty,
                          !pendingActionIds.contains(id) else {
                        continue
                    }

                    let newAction = LocalSyncAction(context: context)

                    newAction.id = id
                    newAction.action = PendingActions.upsert.rawValue
                    newAction.revision = UUID().uuidString
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    // Prepares existing local presets for their fist sync.
    func bootstrapSyncIfNeeded() async throws {
        let context = context

        try await context.perform {
            do {
                guard try Self.getLocalSyncMetadata(
                    key: LocalSyncMetadataKeys.presetSyncBootstrap.rawValue,
                    in: context
                ) == nil else {
                    return
                }

                let presetRequest: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
                let presets = try context.fetch(presetRequest)

                let pendingActions = try Self.getAllPendingChanges(in: context)
                let presetIdsInAction = Set(pendingActions.compactMap(\.id))

                let newPresets = presets.filter { !presetIdsInAction.contains($0.id?.uuidString ?? "") }

                for preset in newPresets {
                    guard let id = preset.id?.uuidString else {
                        throw SyncError.invalidMetadata
                    }

                    let newAction = LocalSyncAction(context: context)

                    newAction.id = id
                    newAction.action = PendingActions.upsert.rawValue
                    newAction.revision = UUID().uuidString
                }

                let marker = LocalSyncMetadata(context: context)
                marker.key = LocalSyncMetadataKeys.presetSyncBootstrap.rawValue
                marker.data = Data([1])
                
                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func bindSyncAccount(_ accountID: String) async throws {
        let context = context

        try await context.perform {
            do {
                let key = LocalSyncMetadataKeys.syncAccountID.rawValue

                if let metadata = try Self.getLocalSyncMetadata(key: key, in: context) {
                    guard let data = metadata.data,
                          let storedAccountID = String(data: data, encoding: .utf8) else {
                        throw SyncError.invalidMetadata
                    }

                    guard storedAccountID == accountID else {
                        throw SyncError.differentAccount
                    }
                } else {
                    let metadata = LocalSyncMetadata(context: context)
                    metadata.key = key
                    metadata.data = Data(accountID.utf8)
                    try context.save()
                }
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}

extension CoreDataPresetSyncStore {
    private static func getLocalSyncMetadata(key: String, in context: NSManagedObjectContext) throws -> LocalSyncMetadata? {
        // Called only from the context's perform closure.
        let request: NSFetchRequest<LocalSyncMetadata> = LocalSyncMetadata.fetchRequest()
        request.predicate = NSPredicate(format: "key == %@", key)
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    private static func getCachedCloudRecord(for id: String, in context: NSManagedObjectContext) throws -> LocalCloudRecord? {
        let cacheRequest: NSFetchRequest<LocalCloudRecord> = LocalCloudRecord.fetchRequest()
        cacheRequest.predicate = NSPredicate(format: "id == %@", id)
        cacheRequest.fetchLimit = 1

        return try context.fetch(cacheRequest).first
    }

    private static func getAllCachedCloudRecord(in context: NSManagedObjectContext) throws -> [LocalCloudRecord] {
        let cacheRequest: NSFetchRequest<LocalCloudRecord> = LocalCloudRecord.fetchRequest()
        return try context.fetch(cacheRequest)
    }

    private static func getPendingChange(
        for id: String,
        in context: NSManagedObjectContext
    ) throws -> LocalSyncAction? {
        let request: NSFetchRequest<LocalSyncAction> =
            LocalSyncAction.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

    private static func getAllPendingChanges(in context: NSManagedObjectContext) throws -> [LocalSyncAction] {
        let request: NSFetchRequest<LocalSyncAction> = LocalSyncAction.fetchRequest()
        return try context.fetch(request)
    }
}
