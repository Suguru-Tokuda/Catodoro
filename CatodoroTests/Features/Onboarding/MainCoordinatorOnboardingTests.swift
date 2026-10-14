import Combine
import XCTest
@testable import Catodoro

@MainActor
final class MainCoordinatorOnboardingTests: XCTestCase {
    func test_firstLaunchShowsOnboardingAndCompletionReplacesItWithTabs() throws {
        let domain = "MainRoutingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let preferences = CatodoroPreferences(userDefaults: defaults)
        let coordinator = MainCoordinator(preferences: preferences, liveActivityManager: nil,
                                          coreDataManager: InMemoryPresetStore(),
                                          syncCoordinator: RoutingSyncMock(),
                                          syncLifecycleManager: RoutingLifecycleMock())
        coordinator.start()
        XCTAssertTrue(coordinator.navigationController.topViewController is OnboardingViewController)
        let onboarding = try XCTUnwrap(coordinator.childCoordinators.first as? OnboardingCoordinator)
        preferences.completeOnboarding(syncEnabled: false)
        onboarding.finish()
        XCTAssertEqual(coordinator.childCoordinators.count, 1)
        XCTAssertTrue(coordinator.childCoordinators.first is TabCoordinator)
        XCTAssertTrue(coordinator.navigationController.topViewController is UITabBarController)
    }

    func test_completedLocalOnboardingStartsTabsWithoutCloudActivation() {
        let domain = "MainRoutingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let preferences = CatodoroPreferences(userDefaults: defaults)
        preferences.completeOnboarding(syncEnabled: false)
        let sync = RoutingSyncMock()
        let lifecycle = RoutingLifecycleMock()
        let coordinator = MainCoordinator(preferences: preferences, liveActivityManager: nil,
                                          coreDataManager: InMemoryPresetStore(),
                                          syncCoordinator: sync,
                                          syncLifecycleManager: lifecycle)
        coordinator.start()
        XCTAssertTrue(coordinator.navigationController.topViewController is UITabBarController)
        XCTAssertEqual(sync.enableCount, 0)
        XCTAssertEqual(lifecycle.startCount, 1)
    }
}

@MainActor
private final class RoutingSyncMock: OnboardingSyncControlling {
    var enableCount = 0
    func enableSync() async throws { enableCount += 1 }
    func disableSync() async {}
}

@MainActor
private final class RoutingLifecycleMock: SyncLifecycleManaging {
    @Published var syncStatus = SyncStatus(
        isEnabled: false, isSyncing: false, pendingChangeCount: 0,
        lastSuccessfulCheck: nil, errorMessage: nil
    )
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> {
        $syncStatus.eraseToAnyPublisher()
    }

    var startCount = 0
    func start() { startCount += 1 }
    func stop() async {}
    func accountDidChange() {}
    func setSyncEnabled(_ enabled: Bool) async throws { syncStatus.isEnabled = enabled }
}
