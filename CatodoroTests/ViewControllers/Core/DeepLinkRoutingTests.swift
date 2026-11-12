//
//  DeepLinkRoutingTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/12/26.
//

import CatodoroShared
import XCTest
@testable import Catodoro

/// A Live Activity tap (`catodoro://timer`) brings the running cycle's screen forward.
@MainActor
final class DeepLinkRoutingTests: XCTestCase {
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

    private func session() -> CycleSession {
        .test(steps: CycleStep.cycle(intervals: 2, focus: 1500, breakDuration: 300),
              state: .running(endDate: Date() + 600))
    }

    /// Tabs started with no cycle, so launch restore has nothing to show.
    private func startedTabs() async -> TabCoordinator {
        let tabs = TabCoordinator(dependencies: dependencies.app)
        tabs.start()
        await waitUntil { self.dependencies.countdown.reconcileCount == 1 }
        await settle()
        return tabs
    }

    private func timerScreens(in navigation: UINavigationController?) -> Int {
        navigation?.viewControllers.filter { $0 is TimerViewController }.count ?? 0
    }

    // MARK: TabCoordinator.showRunningCycle()

    func test_showRunningCycle_expectTimerTabWithTheCycle() async throws {
        let tabs = await startedTabs()
        tabs.selectPage(.settings)
        dependencies.countdown.session = session()

        tabs.showRunningCycle()

        let navigation = tabs.testHooks.timerCoordinator?.navigationController
        await waitUntil { navigation?.topViewController is TimerViewController }
        XCTAssertEqual(tabs.currentPage(), .timer)
        XCTAssertTrue(dependencies.countdown.startedSteps.isEmpty)
    }

    func test_showRunningCycle_twice_expectOneTimerScreen() async throws {
        let tabs = await startedTabs()
        dependencies.countdown.session = session()

        tabs.showRunningCycle()
        tabs.showRunningCycle()

        let navigation = tabs.testHooks.timerCoordinator?.navigationController
        await waitUntil { navigation?.topViewController is TimerViewController }
        await settle()
        XCTAssertEqual(timerScreens(in: navigation), 1)
    }

    func test_showRunningCycle_withNoCycle_expectNothingAdded() async throws {
        let tabs = await startedTabs()
        tabs.selectPage(.settings)

        tabs.showRunningCycle()
        await waitUntil { self.dependencies.countdown.reconcileCount == 2 }
        await settle()

        XCTAssertEqual(timerScreens(in: tabs.testHooks.timerCoordinator?.navigationController), 0)
    }

    func test_showRunningCycle_whenPresetsShowsTheTimer_expectPresetsTabAndNoSecondScreen() async throws {
        let tabs = await startedTabs()
        let presets = try XCTUnwrap(tabs.testHooks.presetsCoordiantor)
        // Off-screen navigation never reports didShow, so BaseNavigationController would drop the push.
        (presets.navigationController as? BaseNavigationController)?.testHooks.isNewViewControllerBeingAdded = false
        let list = try XCTUnwrap(presets.navigationController.viewControllers.last as? PresetsViewController)
        presets.presetsViewControllerDidSelectPreset(list, preset: PresetModel(id: UUID(), totalDuration: 1500,
                                                                              intervalDuration: 300, intervals: 2))
        XCTAssertTrue(presets.navigationController.topViewController is TimerViewController)
        dependencies.countdown.session = session()
        tabs.selectPage(.settings)

        tabs.showRunningCycle()
        await settle()

        XCTAssertEqual(tabs.currentPage(), .presets)
        XCTAssertEqual(timerScreens(in: tabs.testHooks.timerCoordinator?.navigationController), 0)
    }

    // MARK: MainCoordinator.handle(_:)

    func test_handleTimerURL_expectTimerScreen() async throws {
        let coordinator = MainCoordinator(dependencies: dependencies.app)
        coordinator.start()
        let tabs = try XCTUnwrap(coordinator.childCoordinators.first as? TabCoordinator)
        await waitUntil { self.dependencies.countdown.reconcileCount == 1 }
        await settle()
        dependencies.countdown.session = session()

        coordinator.handle(DeepLink.timer)

        let navigation = tabs.testHooks.timerCoordinator?.navigationController
        await waitUntil { navigation?.topViewController is TimerViewController }
    }

    func test_handleOtherURL_expectIgnored() async throws {
        let coordinator = MainCoordinator(dependencies: dependencies.app)
        coordinator.start()
        await waitUntil { self.dependencies.countdown.reconcileCount == 1 }
        await settle()

        coordinator.handle(try XCTUnwrap(URL(string: "catodoro://presets")))
        await settle()

        XCTAssertEqual(dependencies.countdown.reconcileCount, 1, "no restore for an unknown link")
    }

    func test_handleDuringOnboarding_expectIgnored() async throws {
        let onboarding = TestDependencies(hasCompletedOnboarding: false)
        defer { onboarding.tearDown() }
        onboarding.countdown.session = session()
        let coordinator = MainCoordinator(dependencies: onboarding.app)
        coordinator.start()

        coordinator.handle(DeepLink.timer)
        await settle()

        XCTAssertTrue(coordinator.childCoordinators.first is OnboardingCoordinator)
        XCTAssertEqual(onboarding.countdown.reconcileCount, 0)
        XCTAssertTrue(coordinator.navigationController.topViewController is OnboardingPageViewController)
    }
}
