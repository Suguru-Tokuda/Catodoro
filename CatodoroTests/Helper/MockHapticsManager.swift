//
//  MockHapticsManager.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/5/26.
//

import Foundation
@testable import Catodoro

final class MockHapticsManager: HapticsManaging {
    /// Ordered record of calls, e.g. ["start", "stop"].
    private(set) var events: [String] = []
    var startError: Error?

    var startCount: Int { events.filter { $0 == "start" }.count }
    var stopCount: Int { events.filter { $0 == "stop" }.count }

    func start() throws {
        events.append("start")
        if let startError {
            throw startError
        }
    }

    func stop() {
        events.append("stop")
    }

    /// Clears calls made while setting a timer up, so tests only see what happens afterwards.
    func reset() {
        events.removeAll()
    }
}
