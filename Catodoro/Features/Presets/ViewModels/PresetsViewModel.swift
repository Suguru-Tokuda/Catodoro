//
//  PresetsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import CoreData
import Combine
import Foundation

protocol PresetsViewModelProtocol {
    var presetsPublisher: AnyPublisher<[PresetModel], Never> { get }
    var loadingStatePublisher: AnyPublisher<LoadingState, Never> { get }
    var presets: [PresetModel] { get }
    var coreDataError: CoreDataError? { get }
    var loadingState: LoadingState { get }

    func loadPresets() async
    func deletePreset(_ preset: PresetModel) async
}

class PresetsViewModel: PresetsViewModelProtocol {
    @Published var presets: [PresetModel] = []
    @Published private(set) var loadingState: LoadingState = .idle
    var loadingStatePublisher: AnyPublisher<LoadingState, Never> {
        $loadingState.eraseToAnyPublisher()
    }
    var coreDataError: CoreDataError?
    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: - Dependencies

    private var coreDataManager: CatodoroCoreDataManaging?

    init(coreDataManager: CatodoroCoreDataManaging?) {
        self.coreDataManager = coreDataManager
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in await self?.loadPresets() }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func loadPresets() async {
        guard loadingState != .loading else { return }

        do {
            if presets.isEmpty {
                loadingState = .loading
            }

            let loaded = try await self.coreDataManager?.getPresets() ?? []
            coreDataError = nil
            presets = loaded.sorted(by: { $0.displayName < $1.displayName })
            loadingState = .loaded
        } catch {
            coreDataError = error as? CoreDataError ?? .get
            loadingState = .failed(error)
        }
    }

    func deletePreset(_ preset: PresetModel) async {
        do {
            try await self.coreDataManager?.deletePreset(preset.id.uuidString)
            await MainActor.run {
                self.coreDataError = nil
                self.presets.removeAll { $0.id == preset.id }
            }
        } catch {
            if let coreDataError = error as? CoreDataError {
                await MainActor.run {
                    self.coreDataError = coreDataError
                }
            }
        }
    }

    var presetsPublisher: AnyPublisher<[PresetModel], Never> {
        $presets.eraseToAnyPublisher()
    }
}
