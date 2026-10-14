//
//  CatodoroCoreDataManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/22/24.
//

import CoreData
import Foundation

enum CoreDataError: Error {
    case get
    case save
    case delete
}

protocol CatodoroCoreDataManaging {
    func getPresets() async throws -> [PresetModel]
    func getPreset(id: String) async throws -> PresetModel?
    func savePreset(_ preset: PresetModel) async throws
    func deletePreset(_ id: String) async throws
}

class CatodoroCoreDataManager: CatodoroCoreDataManaging {

    private let writeContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        writeContext = context
    }

    func getPreset(id: String) async throws -> PresetModel? {
        let context = writeContext
        return try await context.perform {
            guard context.persistentStoreCoordinator?.persistentStores.isEmpty == false else {
                throw CoreDataError.get
            }
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            guard let uuid = UUID(uuidString: id) else {
                throw CoreDataError.get
            }
            request.predicate = NSPredicate(format: "id == %@", uuid as NSUUID)

            do {
                if let presetEntity = try context.fetch(request).first {
                    return .init(from: presetEntity)
                }
                return nil
            } catch {
                throw CoreDataError.get
            }
        }
    }

    func getPresets() async throws -> [PresetModel] {
        let context = writeContext
        return try await context.perform {
            guard context.persistentStoreCoordinator?.persistentStores.isEmpty == false else {
                throw CoreDataError.get
            }
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()

            do {
                let allPresets = try context.fetch(request)
                return allPresets.map { PresetModel(from: $0) }
            } catch {
                throw CoreDataError.get
            }
        }
    }

    func savePreset(_ preset: PresetModel) async throws {
        let context = writeContext
        try await context.perform {
            guard context.persistentStoreCoordinator?.persistentStores.isEmpty == false else {
                throw CoreDataError.save
            }
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", preset.id as NSUUID)

            do {
                let presetEntity = try context.fetch(request).first ?? PresetEntity(context: context)
                presetEntity.name = preset.name
                presetEntity.imageIdentifier = preset.imageIdentifier
                presetEntity.id = preset.id
                presetEntity.totalDuration = Double(preset.totalDuration)
                presetEntity.intervalDuration = Double(preset.intervalDuration)
                presetEntity.intervals = Int64(preset.intervals)

                try context.save()
            } catch {
                context.rollback()
                throw CoreDataError.save
            }
        }
    }

    func deletePreset(_ id: String) async throws {
        let context = writeContext
        try await context.perform {
            guard context.persistentStoreCoordinator?.persistentStores.isEmpty == false else {
                throw CoreDataError.delete
            }
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            guard let uuid = UUID(uuidString: id) else {
                throw CoreDataError.delete
            }
            request.predicate = NSPredicate(format: "id == %@", uuid as NSUUID)

            do {
                let allPresets = try context.fetch(request)
                allPresets.forEach(context.delete)
                try context.save()
            } catch {
                context.rollback()
                throw CoreDataError.delete
            }
        }
    }
}
