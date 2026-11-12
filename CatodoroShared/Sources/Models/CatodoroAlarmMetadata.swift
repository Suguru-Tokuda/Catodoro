//
//  CatodoroAlarmMetadata.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/9/26.
//

import AlarmKit

public enum CountdownPhase: String, Codable, Hashable, Sendable {
    case focus, catnap

    public var isBreak: Bool { self == .catnap }
}

@available(iOS 26.0, *)
public struct CatodoroAlarmMetadata: AlarmMetadata {
    public var phase: CountdownPhase
    public var interval: Int
    public var totalIntervals: Int
    public var isLastStep: Bool
    public var phaseDuration: TimeInterval      // new: progress bar
    public var accentCode: String?              // new: user's color

    public init(phase: CountdownPhase,
                interval: Int,
                totalIntervals: Int,
                isLastStep: Bool,
                phaseDuration: TimeInterval,
                accentCode: String?
    ) {
        self.phase = phase
        self.interval = interval
        self.totalIntervals = totalIntervals
        self.isLastStep = isLastStep
        self.phaseDuration = phaseDuration
        self.accentCode = accentCode
    }
}
