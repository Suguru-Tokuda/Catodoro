//
//  CoordinatorConfigurationTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit
import XCTest
@testable import Catodoro

@MainActor
final class CoordinatorConfigurationTests: XCTestCase {
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

    func test_defaultTimerCoordinatorKeepsBottomBarVisible() throws {
        let navigation = UINavigationController()
        let coordinator = TimerCoordiantor(navigationController: navigation, dependencies: dependencies.app)

        coordinator.navigateToTimerView(viewModel: configViewModel())

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertFalse(timer.hidesBottomBarWhenPushed)
    }

    func test_timerCoordinatorPropagatesBothBottomBarConfigurationsAndReturnsToSetup() throws {
        for shouldHide in [false, true] {
            let navigation = UINavigationController()
            let coordinator = TimerCoordiantor(navigationController: navigation,
                                               configuration: .init(shouldHideBottomBarWhenTimerStart: shouldHide),
                                               dependencies: dependencies.app)
            coordinator.start()
            let setup = try XCTUnwrap(navigation.topViewController as? TimerConfigViewController)

            coordinator.didFinishConfiguring(viewModel: configViewModel())

            let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
            XCTAssertEqual(timer.hidesBottomBarWhenPushed, shouldHide)
            XCTAssertEqual(navigation.viewControllers.count, 2)

            coordinator.timerViewControllerDidFinish(timer)

            XCTAssertTrue(navigation.topViewController === setup)
            XCTAssertFalse(setup.hidesBottomBarWhenPushed)
        }
    }

    func test_timerScreenStartsCycleOnInjectedCountdown() async {
        let navigation = UINavigationController()
        let coordinator = TimerCoordiantor(navigationController: navigation, dependencies: dependencies.app)
        let config = TimerConfigModel(mainTimer: .init(hours: 0, minutes: 25, seconds: 0),
                                      interval: .init(hours: 0, minutes: 5, seconds: 0),
                                      intervals: 2)

        coordinator.navigateToTimerView(viewModel: TimerConfigViewModel(timerModel: config,
                                                                        coreDataManager: dependencies.coreDataManager))

        await waitUntil { self.dependencies.countdown.startedSteps.count == 1 }
        XCTAssertEqual(dependencies.countdown.startedSteps.first, config.cycleSteps)
    }

    func test_defaultPresetsCoordinatorKeepsBottomBarVisibleForPresetTimer() throws {
        let navigation = UINavigationController()
        let coordinator = PresetsCoordinator(navigationController: navigation, dependencies: dependencies.app)
        coordinator.start()
        let list = try XCTUnwrap(navigation.topViewController as? PresetsViewController)

        coordinator.presetsViewControllerDidSelectPreset(list, preset: preset())

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertFalse(timer.hidesBottomBarWhenPushed)
    }

    func test_presetsCoordinatorPropagatesBothConfigurationsAndReturnsToSameList() throws {
        for shouldHide in [false, true] {
            let navigation = UINavigationController()
            let coordinator = PresetsCoordinator(navigationController: navigation,
                                                 configuration: .init(shouldHideBottomBar: shouldHide),
                                                 dependencies: dependencies.app)
            coordinator.start()
            let list = try XCTUnwrap(navigation.topViewController as? PresetsViewController)

            coordinator.presetsViewControllerDidSelectPreset(list, preset: preset())

            let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
            let timerCoordinator = try XCTUnwrap(coordinator.childCoordinators.first as? TimerCoordiantor)
            XCTAssertTrue(timerCoordinator.navigationController === navigation)
            XCTAssertEqual(timer.hidesBottomBarWhenPushed, shouldHide)

            timerCoordinator.timerViewControllerDidFinish(timer)

            XCTAssertTrue(navigation.topViewController === list)
            XCTAssertEqual(navigation.viewControllers.count, 1)
        }
    }

    func test_timerControllerDefaultsToHidingBottomBarButAcceptsOverride() {
        let defaultTimer = TimerViewController(viewModel: timerViewModel(), preferences: MockPreferences())
        let visibleTimer = TimerViewController(viewModel: timerViewModel(), preferences: MockPreferences(),
                                               shouldHidesBottomBarWhen: false)
        XCTAssertTrue(defaultTimer.hidesBottomBarWhenPushed)
        XCTAssertFalse(visibleTimer.hidesBottomBarWhenPushed)
    }

    func test_presetEditorDefaultsToVisibleBottomBarButAcceptsOverride() {
        let defaultEditor = AddPresetViewController(viewModel: PresetEditorViewModel(coreDataManager: InMemoryPresetStore()))
        let hiddenEditor = AddPresetViewController(viewModel: PresetEditorViewModel(coreDataManager: InMemoryPresetStore()), shouldHideBottomBar: true)
        XCTAssertFalse(defaultEditor.hidesBottomBarWhenPushed)
        XCTAssertTrue(hiddenEditor.hidesBottomBarWhenPushed)
    }

    func test_tabCoordinatorOptsFocusIntoHidingBottomBarWithoutSwitchingTabs() throws {
        let tabs = TabCoordinator(dependencies: dependencies.app)
        tabs.start()
        tabs.selectPage(.timer)
        let coordinator = try XCTUnwrap(tabs.testHooks.timerCoordinator)
        let navigation = try XCTUnwrap(coordinator.navigationController as? BaseNavigationController)
        // Off-screen navigation does not deliver the initial didShow callback.
        navigation.testHooks.isNewViewControllerBeingAdded = false

        coordinator.didFinishConfiguring(viewModel: configViewModel())

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertTrue(timer.hidesBottomBarWhenPushed)
        XCTAssertEqual(tabs.currentPage(), .timer)
    }

    func test_tabCoordinatorBuildsSettingsTabFromDependencies() throws {
        let tabs = TabCoordinator(dependencies: dependencies.app)
        tabs.start()
        tabs.selectPage(.settings)

        let settingsNavigation = try XCTUnwrap(tabs.tabBarController.viewControllers?.compactMap { $0 as? UINavigationController }
            .first { $0.viewControllers.first is SettingsViewController })
        XCTAssertNotNil(settingsNavigation)
        XCTAssertEqual(tabs.currentPage(), .settings)
    }

    // MARK: Helpers

    private func configViewModel() -> TimerConfigViewModel {
        TimerConfigViewModel(coreDataManager: dependencies.coreDataManager)
    }

    private func timerViewModel() -> TimerViewModel {
        TimerViewModel(countdown: MockCountdown(), audioManager: MockAudioManager(), preferences: nil,
                       hapticsManager: MockHapticsManager(), schedulesTicks: false)
    }

    private func preset() -> PresetModel {
        PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 4)
    }
}
