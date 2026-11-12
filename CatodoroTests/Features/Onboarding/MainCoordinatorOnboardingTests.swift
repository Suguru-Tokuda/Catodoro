import XCTest
@testable import Catodoro

@MainActor
final class MainCoordinatorOnboardingTests: XCTestCase {
    func test_firstLaunchPagesFromSyncToAlertThenShowsTabs() async throws {
        let dependencies = TestDependencies(hasCompletedOnboarding: false)
        defer { dependencies.tearDown() }
        let coordinator = MainCoordinator(dependencies: dependencies.app)

        coordinator.start()

        let pages = try onboardingPages(in: coordinator)
        pages.loadViewIfNeeded()
        XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1)
        XCTAssertTrue(coordinator.childCoordinators.first is OnboardingCoordinator)
        XCTAssertEqual(pages.currentIndex, OnboardingCoordinator.Step.sync.rawValue)
        let sync = try XCTUnwrap(pages.testHooks.visiblePage as? OnboardingViewController)

        await sync.testHooks.viewModel.continueLocally()

        XCTAssertEqual(pages.currentIndex, OnboardingCoordinator.Step.alert.rawValue)
        let alert = try XCTUnwrap(pages.testHooks.pages[pages.currentIndex] as? AlertOnboardingViewController)
        XCTAssertTrue(coordinator.navigationController.topViewController === pages, "paged, not pushed")
        XCTAssertFalse(dependencies.preferences.hasCompletedOnboarding)

        alert.loadViewIfNeeded()
        alert.testHooks.alertOnboardingView.testHooks.allowButton.sendActions(for: .touchUpInside)

        await waitUntil { coordinator.childCoordinators.first is TabCoordinator }
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        XCTAssertTrue(coordinator.navigationController.topViewController is UITabBarController)
        XCTAssertTrue(dependencies.preferences.hasCompletedOnboarding)
        XCTAssertFalse(dependencies.preferences.syncEnabled)
        XCTAssertEqual(dependencies.countdown.requestedBackends, [AlertOnboardingViewModel.Kind.current.alertStyle.backend])
    }

    func test_quittingBeforeAlertStep_expectOnboardingShownAgain() async throws {
        let dependencies = TestDependencies(hasCompletedOnboarding: false)
        defer { dependencies.tearDown() }
        let first = MainCoordinator(dependencies: dependencies.app)
        first.start()
        let pages = try onboardingPages(in: first)
        pages.loadViewIfNeeded()
        let sync = try XCTUnwrap(pages.testHooks.visiblePage as? OnboardingViewController)
        await sync.testHooks.viewModel.continueLocally()

        // Next launch with the same preferences.
        let relaunch = MainCoordinator(dependencies: dependencies.app)
        relaunch.start()

        let relaunchedPages = try onboardingPages(in: relaunch)
        XCTAssertEqual(relaunchedPages.currentIndex, OnboardingCoordinator.Step.sync.rawValue)
    }

    func test_alertStepNotNow_expectTabsWithDefaultAlertStyle() throws {
        let dependencies = TestDependencies(hasCompletedOnboarding: false)
        defer { dependencies.tearDown() }
        let coordinator = MainCoordinator(dependencies: dependencies.app)
        coordinator.start()
        let onboarding = try XCTUnwrap(coordinator.childCoordinators.first as? OnboardingCoordinator)
        let pages = try onboardingPages(in: coordinator)
        pages.loadViewIfNeeded()

        onboarding.show(.alert)
        let alert = try XCTUnwrap(pages.testHooks.pages[pages.currentIndex] as? AlertOnboardingViewController)
        alert.loadViewIfNeeded()
        alert.testHooks.alertOnboardingView.testHooks.notNowButton.sendActions(for: .touchUpInside)

        XCTAssertTrue(coordinator.childCoordinators.first is TabCoordinator)
        XCTAssertEqual(dependencies.preferences.alertStyle, .liveActivity)
        XCTAssertTrue(dependencies.countdown.requestedBackends.isEmpty)
    }

    func test_completedOnboardingStartsTabsWithoutCloudActivation() {
        let dependencies = TestDependencies(hasCompletedOnboarding: true)
        defer { dependencies.tearDown() }
        let coordinator = MainCoordinator(dependencies: dependencies.app)

        coordinator.start()

        XCTAssertTrue(coordinator.navigationController.topViewController is UITabBarController)
        XCTAssertEqual(dependencies.syncLifecycleManager.startCount, 1)
    }

    private func onboardingPages(in coordinator: MainCoordinator) throws -> OnboardingPageViewController {
        try XCTUnwrap(coordinator.navigationController.topViewController as? OnboardingPageViewController)
    }
}
