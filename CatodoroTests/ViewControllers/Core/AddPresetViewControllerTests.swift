//
//  AddPresetViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import CoreData
import XCTest
@testable import Catodoro

@MainActor
final class AddPresetViewControllerTests: XCTestCase {
    func test_editorRequiresNameAndTrimsItWhenSaving() async throws {
        let store = RecordingPresetStore()
        let model = PresetEditorViewModel(coreDataManager: store)
        XCTAssertFalse(model.canSave)
        model.name = "   Study time \n"
        model.pose = .stretching
        XCTAssertTrue(model.canSave)
        try await model.save()
        XCTAssertEqual(store.saved?.name, "Study time")
        XCTAssertEqual(store.saved?.imageIdentifier, "CatStretching")
        XCTAssertEqual(store.saved?.intervals, 4)
    }

    func test_editPreservesIdentifierAndExistingRoutine() async throws {
        let store = RecordingPresetStore()
        let preset = PresetModel(id: UUID(), totalDuration: 3000, intervalDuration: 600, intervals: 3, name: "Read", imageIdentifier: "CatSleeping")
        let model = PresetEditorViewModel(preset: preset, coreDataManager: store)
        XCTAssertEqual(model.pose, .sleeping)
        model.name = "Reading hour"
        try await model.save()
        XCTAssertEqual(store.saved?.id, preset.id)
        XCTAssertEqual(store.saved?.totalDuration, 3000)
        XCTAssertEqual(store.saved?.name, "Reading hour")
    }

    func test_failedSaveKeepsDraftAndAllowsRetry() async {
        let store = RecordingPresetStore()
        store.shouldFail = true
        let model = PresetEditorViewModel(coreDataManager: store)
        model.name = "Work"
        do {
            try await model.save()
            XCTFail("Expected save failure")
        } catch {
            XCTAssertEqual(model.name, "Work")
            XCTAssertTrue(model.canSave)
        }
    }

    func test_coreDataMigratesLegacyPresetAndPersistsNameAndImage() async throws {
        let bundle = Bundle(for: CatodoroCoreDataManager.self)
        let directory = try XCTUnwrap(bundle.url(forResource: "CatodoroCoreData", withExtension: "momd"))
        let legacyModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: directory.appendingPathComponent("CatodoroCoreData.mom")))
        let currentModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: directory))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".sqlite")
        defer {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(atPath: url.path + suffix)
            }
        }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: legacyModel)
        let legacyStore = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        let entity = NSEntityDescription.insertNewObject(forEntityName: "PresetEntity", into: context)
        let id = UUID()
        entity.setValue(id, forKey: "id")
        entity.setValue(1500.0, forKey: "totalDuration")
        entity.setValue(300.0, forKey: "intervalDuration")
        entity.setValue(4, forKey: "intervals")
        try context.save()
        try coordinator.remove(legacyStore)

        let container = NSPersistentContainer(name: "CatodoroCoreData", managedObjectModel: currentModel)
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        let manager = CatodoroCoreDataManager(context: container.newBackgroundContext())
        let records = try await manager.getPresets()
        let migrated = try XCTUnwrap(records.first)
        XCTAssertEqual(migrated.id, id)
        XCTAssertEqual(migrated.displayName, "25 min focus")
        XCTAssertEqual(migrated.catPose, .sitting)
        let updated = PresetModel(id: id, totalDuration: 1500, intervalDuration: 300, intervals: 4, name: "Study", imageIdentifier: "CatPlayful")
        try await manager.savePreset(updated)
        let reloaded = try await manager.getPresets()
        XCTAssertEqual(reloaded, [updated])
        try await manager.deletePreset(id.uuidString)
        let remaining = try await manager.getPresets()
        XCTAssertTrue(remaining.isEmpty)
    }
}

private final class RecordingPresetStore: CatodoroCoreDataManaging {
    var saved: PresetModel?
    var shouldFail = false

    func getPresets() async throws -> [PresetModel] {
        saved.map { [$0] } ?? []
    }

    func getPreset(id: String) async throws -> PresetModel? {
        saved
    }

    func savePreset(_ preset: PresetModel) async throws {
        if shouldFail {
            throw CoreDataError.save
        }

        saved = preset
    }

    func deletePreset(_ id: String) async throws {
        saved = nil
    }
}
