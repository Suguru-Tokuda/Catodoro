//
//  HapticsDependencyTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/5/26.
//

import XCTest
@testable import Catodoro

/// Verifies the shared haptics manager and countdown reach the timer screen
/// through every coordinator that can start a timer.
@MainActor
final class HapticsDependencyTests: XCTestCase {
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

    func test_mainCoordinator_passesDependenciesThroughToTimerTab() async throws {
        let coordinator = MainCoordinator(dependencies: dependencies.app)
        coordinator.start()
        // Let TabCoordinator's restore check finish while no session exists,
        // so it doesn't open a second timer screen for the one set up below.
        await settle()
        let tabs = try XCTUnwrap(coordinator.childCoordinators.first as? TabCoordinator)
        let timerCoordinator = try XCTUnwrap(tabs.testHooks.timerCoordinator)
        // Off-screen navigation never reports didShow, so BaseNavigationController would drop the push.
        (timerCoordinator.navigationController as? BaseNavigationController)?.testHooks.isNewViewControllerBeingAdded = false

        try await runOnePhaseChange { timerCoordinator.navigateToTimerView(viewModel: $0) }
    }

    func test_tabCoordinator_passesDependenciesToPresetsTimer() async throws {
        let tabs = TabCoordinator(dependencies: dependencies.app)
        tabs.start()
        await settle()   // see above
        let presets = try XCTUnwrap(tabs.testHooks.presetsCoordiantor)
        (presets.navigationController as? BaseNavigationController)?.testHooks.isNewViewControllerBeingAdded = false
        let list = try XCTUnwrap(presets.navigationController.viewControllers.last as? PresetsViewController)
        let preset = PresetModel(id: UUID(), totalDuration: 10, intervalDuration: 5, intervals: 2)

        try await runOnePhaseChange { _ in presets.presetsViewControllerDidSelectPreset(list, preset: preset) }
    }

    /// Opens the timer, then moves the cycle from focus to break and checks the
    /// injected haptics manager fired, which proves the screen uses the shared instances.
    private func runOnePhaseChange(open: (TimerConfigViewModel) -> Void) async throws {
        let countdown = dependencies.countdown
        let haptics = dependencies.hapticsManager
        let steps = CycleStep.cycle(intervals: 2, focus: 10, breakDuration: 5)
        let cycleID = UUID()
        let first = CycleSession.test(id: cycleID, steps: steps, state: .running(endDate: Date() + 10))
        countdown.startID = cycleID
        countdown.session = first

        open(TimerConfigViewModel(coreDataManager: dependencies.coreDataManager))

        await waitUntil { countdown.startedSteps.count == 1 }
        await settle()
        haptics.reset()

        countdown.send(first.moved(to: 1, state: .running(endDate: Date() + 5)))

        await waitUntil { haptics.startCount == 1 }
    }
}
