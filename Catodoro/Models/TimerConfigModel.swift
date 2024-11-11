//
//  TimerConfigModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Foundation

struct TimerConfigModel {
    let id: UUID
    let title: String
    var mainTimer: TimerModel
    var interval: TimerModel
    var numberOfIntervals: Int

    init (id: UUID = .init(),
          title: String = "",
          mainTimer: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          breakTimer: TimerModel = .init(hours: 0, minutes: 0, seconds: 0),
          repeats: Int = 1) {
        self.id = id
        self.title = title
        self.mainTimer = mainTimer
        self.interval = breakTimer
        self.numberOfIntervals = repeats
    }
}
