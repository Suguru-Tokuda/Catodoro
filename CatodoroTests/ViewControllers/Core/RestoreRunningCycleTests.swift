//
//  RestoreRunningCycleTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

/// After a relaunch, `TabCoordinator` puts the timer screen back for a cycle the engine restored.
@MainActor
final class RestoreRunningCycleTests: XCTestCase {
    private var dependencies: TestDependencies!

    override func setUp() async throws {
        try await super.setUp()
        dependencies = TestDependencies()
    }

    override func tearDown() async throws {
        dependencies.tearDown()
        dependencies = nil
        try await super.tearDown()
    }

    private func restoredSession() -> CycleSession {
        .test(steps: CycleStep.cycle(intervals: 2, focus: 1500, breakDuration: 300),
              index: 1,
              state: .running(endDate: Date() + 120))
    }

    private func timerNavigation(_ tabs: TabCoordinator) throws -> UINavigationController {
        try XCTUnwrap(tabs.testHooks.timerCoordinator?.navigationController)
    }

    func test_runningCycle_expectTimerTabShowsItWithoutStartingANewOne() async throws {
        dependencies.countdown.session = restoredSession()
        let tabs = TabCoordinator(dependencies: dependencies.app)

        tabs.start()

        let navigation = try timerNavigation(tabs)
        await waitUntil { navigation.topViewController is TimerViewController }
        XCTAssertEqual(navigation.viewControllers.count, 2, "setup screen stays underneath")
        XCTAssertTrue(navigation.viewControllers.first is TimerConfigViewController)
        XCTAssertEqual(tabs.currentPage(), .timer)
        XCTAssertTrue(dependencies.countdown.startedSteps.isEmpty)
    }

    func test_runningCycle_expectReconciledBeforeShowing() async throws {
        dependencies.countdown.session = restoredSession()
        let tabs = TabCoordinator(dependencies: dependencies.app)

        tabs.start()

        let navigation = try timerNavigation(tabs)
        await waitUntil { navigation.topViewController is TimerViewController }
        XCTAssertGreaterThanOrEqual(dependencies.countdown.reconcileCount, 1)
    }

    func test_runningCycle_expectTimerTabSelectedEvenIfAnotherWasPicked() async throws {
        dependencies.countdown.session = restoredSession()
        let tabs = TabCoordinator(dependencies: dependencies.app)
        tabs.start()
        tabs.selectPage(.presets)

        let navigation = try timerNavigation(tabs)
        await waitUntil { navigation.topViewController is TimerViewController }

        XCTAssertEqual(tabs.currentPage(), .timer)
    }

    func test_noCycle_expectSetupScreenOnly() async throws {
        let tabs = TabCoordinator(dependencies: dependencies.app)

        tabs.start()
        await waitUntil { self.dependencies.countdown.reconcileCount == 1 }
        await settle()

        let navigation = try timerNavigation(tabs)
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.topViewController is TimerConfigViewController)
    }

    func test_cycleEndedWhileAppWasGone_expectSetupScreenOnly() async throws {
        dependencies.countdown.session = restoredSession()
        dependencies.countdown.endsSessionOnReconcile = true
        let tabs = TabCoordinator(dependencies: dependencies.app)

        tabs.start()
        await waitUntil { self.dependencies.countdown.reconcileCount == 1 }
        await settle()

        let navigation = try timerNavigation(tabs)
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.topViewController is TimerConfigViewController)
    }

    func test_showRunningCycle_expectRestoredScreenEndsCycleOnStop() async throws {
        let session = restoredSession()
        dependencies.countdown.session = session
        let navigation = UINavigationController()
        let coordinator = TimerCoordiantor(navigationController: navigation, dependencies: dependencies.app)
        coordinator.start()

        coordinator.showRunningCycle(session)

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertTrue(timer.delegate === coordinator)
        dependencies.countdown.send(nil)   // the engine reports the cycle ended
        await waitUntil { navigation.topViewController is TimerConfigViewController }
    }
}
