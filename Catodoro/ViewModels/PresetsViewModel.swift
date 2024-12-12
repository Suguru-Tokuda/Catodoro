//
//  PresetsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import Foundation

class PresetsViewModel {
    var presets: [PresetModel] = []

    init(presets: [PresetModel] = []) {
        self.presets = presets
        for _ in 0..<20 {
            self.presets.append(.init(id: UUID(),
                                      totalDuration: 120,
                                      intervalDuration: 60,
                                      intervals: 5))
        }
    }
}
