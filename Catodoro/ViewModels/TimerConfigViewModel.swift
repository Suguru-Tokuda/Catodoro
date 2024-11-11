//
//  TimerConfigViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

class TimerConfigViewModel {
    var timerModel: TimerConfigModel

    init(timerModel: TimerConfigModel = .init()) {
        self.timerModel = timerModel
    }

    var isValidSelection: Bool {
        timerModel.mainTimer.duration > 0
    }
}
