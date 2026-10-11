//
//  PresetEditorViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import Foundation

@MainActor
final class PresetEditorViewModel {
    var onStateChanged: (() -> Void)?
    var name: String
    var pose: CatPose
    var configuration: TimerConfigModel
    private(set) var isSaving = false
    let isEditing: Bool
    private let coreDataManager: CatodoroCoreDataManaging

    init(preset: PresetModel? = nil, coreDataManager: CatodoroCoreDataManaging = CatodoroCoreDataManager()) {
        name = preset?.displayName ?? ""
        pose = preset?.catPose ?? .sitting
        configuration = preset?.configuration ?? .standard
        isEditing = preset != nil
        self.coreDataManager = coreDataManager
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && configuration.isValid && !isSaving
    }

    enum ValidationError: Error {
        case invalidPreset
    }

    func save() async throws {
        guard canSave else {
            throw ValidationError.invalidPreset
        }

        isSaving = true
        onStateChanged?()
        defer {
            isSaving = false
            onStateChanged?()
        }

        let preset = PresetModel(id: configuration.id,
                                 totalDuration: configuration.mainTimer.duration,
                                 intervalDuration: configuration.interval.duration,
                                 intervals: configuration.intervals,
                                 name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                 imageIdentifier: pose.rawValue)
        try await coreDataManager.savePreset(preset)
    }
}
