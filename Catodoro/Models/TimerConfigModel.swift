//
//  TimerConfigModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

struct TimerConfigModel {
    let id: UUID
    var mainTimer: TimerModel
    var interval: TimerModel
    var intervals: Int

    init (id: UUID = .init(),
          mainTimer: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          interval: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          intervals: Int = 1) {
        self.id = id
        self.mainTimer = mainTimer
        self.interval = interval
        self.intervals = intervals
    }
}
