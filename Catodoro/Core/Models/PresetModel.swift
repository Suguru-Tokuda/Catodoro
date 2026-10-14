//
//  PresetModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import Foundation

struct PresetModel: Equatable {
    let name: String?
    let imageIdentifier: String?
    let id: UUID
    let totalDuration: TimeInterval
    let intervalDuration: TimeInterval
    let intervals: Int

    init(id: UUID, totalDuration: TimeInterval, intervalDuration: TimeInterval, intervals: Int, name: String? = nil, imageIdentifier: String? = nil) {
        self.name = name
        self.imageIdentifier = imageIdentifier
        self.id = id
        self.totalDuration = totalDuration
        self.intervalDuration = intervalDuration
        self.intervals = intervals
    }

    var displayName: String {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "\(TimerConfigModel.durationSummary(totalDuration)) focus" : trimmed
    }

    var catPose: CatPose {
        CatPose(rawValue: imageIdentifier ?? "") ?? .sitting
    }

    var configuration: TimerConfigModel {
        func timer(_ duration: TimeInterval) -> TimerModel {
            guard duration.isFinite, duration >= 0, duration < 86400 else {
                return .init(hours: 0, minutes: 0, seconds: 0)
            }

            let seconds = Int(duration)
            return .init(hours: seconds / 3600, minutes: seconds % 3600 / 60, seconds: seconds % 60)
        }

        return .init(id: id, mainTimer: timer(totalDuration), interval: timer(intervalDuration), intervals: intervals)
    }

    init(from entity: PresetEntity) {
        name = entity.name
        imageIdentifier = entity.imageIdentifier
        id = entity.id ?? .init()
        totalDuration = TimeInterval(entity.totalDuration)
        intervalDuration = TimeInterval(entity.intervalDuration)
        intervals = Int(entity.intervals)
    }
}
