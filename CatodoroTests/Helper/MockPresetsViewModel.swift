//
//  MockPresetsViewModel.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import Combine
@testable import Catodoro
import Foundation

class MockPresetsViewModel: PresetsViewModelProtocol {   
    @Published var presets: [PresetModel] = []
    var coreDataError: CoreDataError?
    
    var presetsPublisher: AnyPublisher<[PresetModel], Never> {
        $presets.eraseToAnyPublisher()
    }
    
    // Track if loadPresets was called
    var didLoadPresets = false
    
    // Track if deletePrset was called
    var didDeletePreset = false
    var presetToDelete: PresetModel?
    
    // Simulate successful loading of presets
    func loadPresets() async {
        didLoadPresets = true
        // Simulate loading with a predefined set of presets
        presets = [PresetModel(id: UUID(), totalDuration: 0, intervalDuration: 0, intervals: 0),
                   PresetModel(id: UUID(), totalDuration: 0, intervalDuration: 0, intervals: 0)]
    }
    
    // Simulate a failed preset load with an error
    func loadPresetsWithError() async {
        didLoadPresets = true
        coreDataError = .get  // Assuming you have an enum like this for errors
    }
    
    // Simulate a successful preset deletion
    func deletePreset(_ preset: PresetModel) async {
        didDeletePreset = true
        presetToDelete = preset
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets.remove(at: index)
        }
    }
    
    // Simulate a failed preset deletion with an error
    func deletePrsetWithError(_ preset: PresetModel) async {
        didDeletePreset = true
        presetToDelete = preset
        coreDataError = .delete  // Assuming you have an enum like this for errors
    }
}
