//
//  LiveActivityStaleDateTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/12/26.
//

import CatodoroShared
import XCTest
@testable import Catodoro

final class LiveActivityStaleDateTests: XCTestCase {
    private let end = Date(timeIntervalSince1970: 1_000)

    func test_playing_expectStaleOneSecondAfterPhaseEnds() {
        XCTAssertEqual(LiveActivityManager.staleDate(for: .playing, endTime: end), end.addingTimeInterval(1))
    }

    func test_pausedOrFinished_expectNeverStale() {
        XCTAssertNil(LiveActivityManager.staleDate(for: .paused, endTime: end))
        XCTAssertNil(LiveActivityManager.staleDate(for: .finished, endTime: end))
    }
}
