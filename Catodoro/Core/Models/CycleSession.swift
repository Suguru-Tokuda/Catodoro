//
//  CycleSession.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/9/26.
//

import Foundation

struct CycleSession: Sendable, Equatable, Codable {
    enum State: Sendable, Equatable, Codable {
        case running(endDate: Date)
        case paused(remaining: TimeInterval)
        case alerting
    }

    enum Backend: String, Codable {
        case alarmKit
        case liveActivity
        case notification
    }

    let id: UUID      // the whole cycle, never changes
    var alarmID: UUID // The current step's alarm, new for every phase
    var steps: [CycleStep]
    var index: Int
    let backend: Backend
    var state: State

    var step: CycleStep { steps[index] }
}
