//
//  PresetModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import Foundation

struct PresetModel: Equatable {
    let id: UUID
    let totalDuration: TimeInterval
    let intervalDuration: TimeInterval
    let intervals: Int

    init(id: UUID, totalDuration: TimeInterval, intervalDuration: TimeInterval, intervals: Int) {
        self.id = id
        self.totalDuration = totalDuration
        self.intervalDuration = intervalDuration
        self.intervals = intervals
    }

    init(from entity: PresetEntity) {
        id = entity.id ?? .init()
        totalDuration = TimeInterval(entity.totalDuration)
        intervalDuration = TimeInterval(entity.intervalDuration)
        intervals = Int(entity.intervals)
    }
}
