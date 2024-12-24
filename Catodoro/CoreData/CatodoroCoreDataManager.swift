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
    func getPreset(id: String) async throws -> PresetModel? {
        return try await CatodoroPersistentController.shared.container.performBackgroundTask { context in
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)

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
        return try await CatodoroPersistentController.shared.container.performBackgroundTask { context in
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
        try await CatodoroPersistentController.shared.container.performBackgroundTask { context in
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", preset.id.uuidString)

            do {
                let presetEntity = try context.fetch(request).first ?? PresetEntity(context: context)
                presetEntity.id = preset.id
                presetEntity.totalDuration = Double(preset.totalDuration)
                presetEntity.intervalDuration = Double(preset.intervalDuration)
                presetEntity.intervals = Int64(preset.intervals)

                try context.save()
            } catch {
                throw CoreDataError.save
            }
        }
    }

    func deletePreset(_ id: String) async throws {
        try await CatodoroPersistentController.shared.container.performBackgroundTask { context in
            let request: NSFetchRequest<PresetEntity> = PresetEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)

            do {
                let allPresets = try context.fetch(request)
                allPresets.forEach(context.delete)
                try context.save()
            } catch {
                throw CoreDataError.delete
            }
        }
    }
}
