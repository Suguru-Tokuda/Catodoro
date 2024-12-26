//
//  PresetsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import Combine
import Foundation

protocol PresetsViewModelProtocol {
    var presetsPublisher: AnyPublisher<[PresetModel], Never> { get }
    var presets: [PresetModel] { get }
    var coreDataError: CoreDataError? { get }
    
    func loadPresets() async
    func deletePreset(_ preset: PresetModel) async
}

class PresetsViewModel: PresetsViewModelProtocol {    
    @Published var presets: [PresetModel] = []
    var coreDataError: CoreDataError?
    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: - Dependencies

    private var coreDataManager: CatodoroCoreDataManaging?

    init(coreDataManager: CatodoroCoreDataManaging? = CatodoroCoreDataManager()) {
        self.coreDataManager = coreDataManager
    }

    func loadPresets() async {
        do {
            presets = try await self.coreDataManager?.getPresets() ?? []
        } catch {
            if let coreDataError = error as? CoreDataError {
                self.coreDataError = coreDataError
            }
        }
    }

    func deletePreset(_ preset: PresetModel) async {
        do {
            try await self.coreDataManager?.deletePreset(preset.id.uuidString)
            if let index = presets.firstIndex(where: { $0.id == preset.id }) {
                presets.remove(at: index)
            }
        } catch {
            if let coreDataError = error as? CoreDataError {
                self.coreDataError = coreDataError
            }
        }
    }

    var presetsPublisher: AnyPublisher<[PresetModel], Never> {
        $presets.eraseToAnyPublisher()
    }
}
