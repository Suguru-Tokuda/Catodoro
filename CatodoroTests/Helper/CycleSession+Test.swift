//
//  CycleSession+Test.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation
@testable import Catodoro

extension CycleSession {
    /// A session for feeding view models without a real engine.
    static func test(id: UUID = UUID(),
                     alarmID: UUID = UUID(),
                     steps: [CycleStep],
                     index: Int = 0,
                     backend: Backend = .liveActivity,
                     state: State) -> CycleSession {
        CycleSession(id: id, alarmID: alarmID, steps: steps, index: index, backend: backend, state: state)
    }

    /// The same cycle moved to `index` with a fresh alarm ID, the way the engine advances.
    func moved(to index: Int, state: State) -> CycleSession {
        var next = self
        next.index = index
        next.alarmID = UUID()
        next.state = state
        return next
    }

    func with(state: State) -> CycleSession {
        var next = self
        next.state = state
        return next
    }
}
