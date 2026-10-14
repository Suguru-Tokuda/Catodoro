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
    func test_defaultTimerCoordinatorKeepsBottomBarVisible() throws {
        let navigation = UINavigationController()
        let coordinator = TimerCoordiantor(navigationController: navigation, coreDataManager: InMemoryPresetStore())

        coordinator.navigateToTimerView(viewModel: TimerConfigViewModel(coreDataManager: InMemoryPresetStore()))

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertFalse(timer.hidesBottomBarWhenPushed)
    }

    func test_timerCoordinatorPropagatesBothBottomBarConfigurationsAndReturnsToSetup() throws {
        for shouldHide in [false, true] {
            let navigation = UINavigationController()
            let coordinator = TimerCoordiantor(navigationController: navigation,
                                               configuration: .init(shouldHideBottomBarWhenTimerStart: shouldHide), coreDataManager: InMemoryPresetStore())
            coordinator.start()
            let setup = try XCTUnwrap(navigation.topViewController as? TimerConfigViewController)

            coordinator.didFinishConfiguring(viewModel: TimerConfigViewModel(coreDataManager: InMemoryPresetStore()))

            let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
            XCTAssertEqual(timer.hidesBottomBarWhenPushed, shouldHide)
            XCTAssertEqual(navigation.viewControllers.count, 2)

            coordinator.timerViewControllerDidFinish(timer)

            XCTAssertTrue(navigation.topViewController === setup)
            XCTAssertFalse(setup.hidesBottomBarWhenPushed)
        }
    }

    func test_defaultPresetsCoordinatorKeepsBottomBarVisibleForPresetTimer() throws {
        let navigation = UINavigationController()
        let coordinator = PresetsCoordinator(navigationController: navigation, coreDataManager: InMemoryPresetStore())
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
                                                 configuration: .init(shouldHideBottomBar: shouldHide), coreDataManager: InMemoryPresetStore())
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
        let defaultTimer = TimerViewController(preferences: nil, liveActivityManager: nil)
        let visibleTimer = TimerViewController(preferences: nil, liveActivityManager: nil,
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
        let tabs = TabCoordinator(preferences: nil, liveActivityManager: nil, coreDataManager: InMemoryPresetStore())
        tabs.start()
        tabs.selectPage(.timer)
        let coordinator = try XCTUnwrap(tabs.timerCoordinator)
        let navigation = try XCTUnwrap(coordinator.navigationController as? BaseNavigationController)
        // Off-screen navigation does not deliver the initial didShow callback.
        navigation.isNewViewControllerBeingAdded = false

        coordinator.didFinishConfiguring(viewModel: TimerConfigViewModel(coreDataManager: InMemoryPresetStore()))

        let timer = try XCTUnwrap(navigation.topViewController as? TimerViewController)
        XCTAssertTrue(timer.hidesBottomBarWhenPushed)
        XCTAssertEqual(tabs.currentPage(), .timer)
    }

    private func preset() -> PresetModel {
        PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 4)
    }
}
