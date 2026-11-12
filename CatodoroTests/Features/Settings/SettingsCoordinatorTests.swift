//
//  SettingsCoordinatorTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import UIKit
import XCTest
@testable import Catodoro

@MainActor
final class SettingsCoordinatorTests: XCTestCase {
    private var dependencies: TestDependencies!
    private var navigation: UINavigationController!
    private var coordinator: SettingsCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        dependencies = TestDependencies()
        navigation = UINavigationController()
        coordinator = SettingsCoordinator(navigationController: navigation, dependencies: dependencies.app)
        coordinator.start()
    }

    override func tearDown() async throws {
        coordinator = nil
        navigation = nil
        dependencies.tearDown()
        dependencies = nil
        try await super.tearDown()
    }

    func test_start_expectSettingsScreenAsRoot() {
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertTrue(navigation.topViewController is SettingsViewController)
        XCTAssertTrue(coordinator.childCoordinators.isEmpty)
    }

    func test_selectingEachOption_expectMatchingChildAndScreen() {
        let cases: [(SettingOptions, Coordinator.Type, UIViewController.Type)] = [
            (.alertStyle, AlertStyleSelectionCoordinator.self, AlertStyleSelectionViewController.self),
            (.color, ColorSelectionCoordinator.self, ColorSelectionViewController.self),
            (.sound, SoundSelectionCoordinator.self, SoundSelectionViewController.self),
        ]

        for (option, coordinatorType, screenType) in cases {
            coordinator.onSettingMenuSelected(settingOption: option)

            let child = coordinator.childCoordinators.first
            XCTAssertEqual(coordinator.childCoordinators.count, 1, "\(option)")
            XCTAssertTrue(child.map { type(of: $0) == coordinatorType } ?? false, "\(option)")
            XCTAssertTrue(child?.navigationController === navigation, "children share the Settings stack")
            XCTAssertTrue(child?.finishDelegate === coordinator)
            XCTAssertEqual(navigation.viewControllers.count, 2, "\(option)")
            XCTAssertTrue(navigation.topViewController.map { type(of: $0) == screenType } ?? false, "\(option)")

            // Reset for the next option, as if the user went back.
            child?.finish()
            navigation.popToRootViewController(animated: false)
        }
    }

    func test_selectingTwiceQuickly_expectOnlyOneScreenPushed() {
        coordinator.onSettingMenuSelected(settingOption: .color)
        coordinator.onSettingMenuSelected(settingOption: .sound)

        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        XCTAssertTrue(coordinator.childCoordinators.first is ColorSelectionCoordinator)
        XCTAssertEqual(navigation.viewControllers.count, 2)
    }

    func test_childFinishing_expectRemovedAndNextSelectionAllowed() {
        coordinator.onSettingMenuSelected(settingOption: .color)
        let child = coordinator.childCoordinators.first
        navigation.popViewController(animated: false)

        child?.finish()

        XCTAssertTrue(coordinator.childCoordinators.isEmpty)

        coordinator.onSettingMenuSelected(settingOption: .sound)
        XCTAssertTrue(coordinator.childCoordinators.first is SoundSelectionCoordinator)
        XCTAssertTrue(navigation.topViewController is SoundSelectionViewController)
    }

    func test_finishingUnknownChild_expectOthersKept() {
        coordinator.onSettingMenuSelected(settingOption: .alertStyle)

        coordinator.coordinatorDidFinish(childCoordinator: MockCoordinator())

        XCTAssertEqual(coordinator.childCoordinators.count, 1)
    }
}

@MainActor
final class SettingsChildCoordinatorTests: XCTestCase {
    private var dependencies: TestDependencies!
    private var navigation: UINavigationController!
    private var root: UIViewController!
    private var finishSpy: FinishDelegateSpy!

    override func setUp() async throws {
        try await super.setUp()
        dependencies = TestDependencies()
        root = UIViewController()
        navigation = UINavigationController(rootViewController: root)
        finishSpy = FinishDelegateSpy()
    }

    override func tearDown() async throws {
        finishSpy = nil
        root = nil
        navigation = nil
        dependencies.tearDown()
        dependencies = nil
        try await super.tearDown()
    }

    // MARK: Color

    func test_colorCoordinator_startPushesScreenAndDoneReturnsToRoot() throws {
        let child = ColorSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        child.finishDelegate = finishSpy

        child.start()
        let screen = try XCTUnwrap(navigation.topViewController as? ColorSelectionViewController)
        XCTAssertTrue(screen.delegate === child)
        XCTAssertEqual(screen.title, AppStrings.Settings.color)

        child.colorSelectionViewControllerDidFinish(screen)
        XCTAssertTrue(navigation.topViewController === root)

        child.colorSelectionViewControllerDidClose(screen)
        XCTAssertTrue(finishSpy.finished.first === child)
    }

    func test_colorCoordinator_finishFromScreenNoLongerOnTop_expectNoPop() throws {
        let child = ColorSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        child.start()
        let screen = try XCTUnwrap(navigation.topViewController as? ColorSelectionViewController)
        let other = UIViewController()
        navigation.pushViewController(other, animated: false)

        child.colorSelectionViewControllerDidFinish(screen)

        XCTAssertTrue(navigation.topViewController === other)
    }

    // MARK: Sound

    func test_soundCoordinator_startPushesScreenAndDoneReturnsToRoot() throws {
        let child = SoundSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        child.finishDelegate = finishSpy

        child.start()
        let screen = try XCTUnwrap(navigation.topViewController as? SoundSelectionViewController)
        XCTAssertTrue(screen.delegate === child)
        XCTAssertEqual(screen.title, AppStrings.Settings.sound)

        child.soundSelectionViewControllerDidFinish(screen)
        XCTAssertTrue(navigation.topViewController === root)

        child.soundSelectionViewControllerDidClose(screen)
        XCTAssertTrue(finishSpy.finished.first === child)
    }

    // MARK: Alert style

    func test_alertStyleCoordinator_startPushesScreenAndDoneReturnsToRoot() throws {
        let child = AlertStyleSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        child.finishDelegate = finishSpy

        child.start()
        let screen = try XCTUnwrap(navigation.topViewController as? AlertStyleSelectionViewController)
        XCTAssertTrue(screen.delegate === child)
        XCTAssertEqual(screen.title, AppStrings.Settings.alarm)

        child.alertStyleSelectionViewControllerDidFinish(screen)
        XCTAssertTrue(navigation.topViewController === root)

        child.alertStyleSelectionViewControllerDidClose(screen)
        XCTAssertTrue(finishSpy.finished.first === child)
    }

    func test_alertStyleCoordinator_usesInjectedCountdownForPermission() async throws {
        dependencies.countdown.isAuthorized = false
        let child = AlertStyleSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        child.start()
        let screen = try XCTUnwrap(navigation.topViewController as? AlertStyleSelectionViewController)
        _ = screen.view
        let row = try XCTUnwrap(AlertStyle.allCases.firstIndex(of: .alarm))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))

        await waitUntil { !self.dependencies.countdown.requestedBackends.isEmpty }
        XCTAssertEqual(dependencies.countdown.requestedBackends, [AlertStyle.alarm.backend])
        XCTAssertEqual(dependencies.preferences.alertStyle, .liveActivity)
    }

    func test_childCoordinators_holdFinishDelegateWeakly() {
        let child = ColorSelectionCoordinator(navigationController: navigation, dependencies: dependencies.app)
        var spy: FinishDelegateSpy? = FinishDelegateSpy()
        child.finishDelegate = spy

        spy = nil

        XCTAssertNil(child.finishDelegate)
    }
}

final class FinishDelegateSpy: CoordinatorFinishDelegate {
    private(set) var finished: [Coordinator] = []

    func coordinatorDidFinish(childCoordinator: Coordinator) {
        finished.append(childCoordinator)
    }
}
