//
//  CountdownEngineBreakTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

/// Which focus alarms get a system "Start break" countdown (`postAlert`).
@MainActor
final class CountdownEngineBreakTests: XCTestCase {
    func test_focusFollowedByBreak_expectBreakLength() {
        let steps = CycleStep.cycle(intervals: 3, focus: 1500, breakDuration: 300)

        XCTAssertEqual(CountdownEngine.breakDuration(after: 0, in: steps), 300, "focus #1 → break")
        XCTAssertEqual(CountdownEngine.breakDuration(after: 2, in: steps), 300, "focus #2 → break")
    }

    func test_breakStep_expectNone() {
        let steps = CycleStep.cycle(intervals: 3, focus: 1500, breakDuration: 300)

        XCTAssertNil(CountdownEngine.breakDuration(after: 1, in: steps))
    }

    func test_lastFocus_expectNone() {
        let steps = CycleStep.cycle(intervals: 2, focus: 1500, breakDuration: 300)

        XCTAssertTrue(steps[2].isLastStep)
        XCTAssertNil(CountdownEngine.breakDuration(after: 2, in: steps))
    }

    func test_noBreaksConfigured_expectNone() {
        let steps = CycleStep.cycle(intervals: 3, focus: 1500, breakDuration: 0)

        for index in steps.indices {
            XCTAssertNil(CountdownEngine.breakDuration(after: index, in: steps), "step \(index)")
        }
    }

    func test_outOfRange_expectNone() {
        let steps = CycleStep.cycle(intervals: 2, focus: 1500, breakDuration: 300)

        XCTAssertNil(CountdownEngine.breakDuration(after: -1, in: steps))
        XCTAssertNil(CountdownEngine.breakDuration(after: steps.count, in: steps))
    }
}
