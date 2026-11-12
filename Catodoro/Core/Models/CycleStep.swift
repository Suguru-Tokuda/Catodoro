//
//  CycleStep.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/9/26.
//

import Foundation
import CatodoroShared

struct CycleStep: Codable, Equatable {
    let phase: CountdownPhase
    let duration: TimeInterval
    let interval: Int
    let totalIntervals: Int
    var isLastStep: Bool
}

extension CycleStep {
    static func cycle(intervals: Int,
                      focus: TimeInterval,
                      breakDuration: TimeInterval) -> [CycleStep] {
        let intervals = max(1, intervals)
        var steps: [CycleStep] = []

        for interval in 1...intervals {
            steps.append(CycleStep(
                phase: .focus,
                duration: focus,
                interval: interval,
                totalIntervals: intervals,
                isLastStep: interval == intervals
            ))

            if interval < intervals, breakDuration > 0 {
                steps.append(CycleStep(
                    phase: .catnap,
                    duration: breakDuration,
                    interval: interval,
                    totalIntervals: intervals,
                    isLastStep: false
                ))
            }
        }

        return steps
    }

    static func cycle(from config: TimerConfigModel) -> [CycleStep] {
        cycle(intervals: config.intervals,
              focus: config.mainTimer.duration,
              breakDuration: config.interval.duration
        )
    }
}
