//
//  TimerConfigViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

protocol TimerConfigViewModelProtocol {
    var timerModel: TimerConfigModel { get set }
    var isValidSelection: Bool { get }
    func addPreset() async throws
}

class TimerConfigViewModel: TimerConfigViewModelProtocol {
    var timerModel: TimerConfigModel
    private var coreDataManager: CatodoroCoreDataManaging?

    init(timerModel: TimerConfigModel = .init(),
         coreDataManager: CatodoroCoreDataManaging? = CatodoroCoreDataManager()) {
        self.timerModel = timerModel
        self.coreDataManager = coreDataManager
    }

    var isValidSelection: Bool {
        timerModel.mainTimer.duration > 0
    }

    func addPreset() async throws {
        let preset = PresetModel(id: timerModel.id,
                                 totalDuration: timerModel.mainTimer.duration,
                                 intervalDuration: timerModel.interval.duration,
                                 intervals: timerModel.intervals)
        do {
            try await coreDataManager?.savePreset(preset)
        } catch {
            throw error
        }
    }
}
