//
//  HapticsDependencyTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/5/26.
//

import Combine
import XCTest
@testable import Catodoro

/// Verifies the shared HapticsManager reaches every coordinator that can start a timer.
@MainActor
final class HapticsDependencyTests: XCTestCase {
    func test_tabCoordinator_passesHapticsToTimerAndPresetsCoordinators() throws {
        let haptics = MockHapticsManager()
        let tabs = TabCoordinator(preferences: nil, liveActivityManager: nil,
                                  hapticsManager: haptics, coreDataManager: InMemoryPresetStore())

        tabs.start()

        let timerHaptics = try XCTUnwrap(tabs.testHooks.timerCoordinator?.hapticsManager as? MockHapticsManager)
        let presetsHaptics = try XCTUnwrap(tabs.testHooks.presetsCoordiantor?.hapticsManager as? MockHapticsManager)
        XCTAssertTrue(timerHaptics === haptics)
        XCTAssertTrue(presetsHaptics === haptics)
    }

    func test_mainCoordinator_passesHapticsThroughToTimerTab() throws {
        let domain = "HapticsDependencyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: domain))
        defer { defaults.removePersistentDomain(forName: domain) }
        let preferences = CatodoroPreferences(userDefaults: defaults)
        preferences.completeOnboarding(syncEnabled: false)
        let haptics = MockHapticsManager()
        let coordinator = MainCoordinator(preferences: preferences, liveActivityManager: nil,
                                          hapticsManager: haptics,
                                          coreDataManager: InMemoryPresetStore(),
                                          syncLifecycleManager: LifecycleStub())

        coordinator.start()

        let tabs = try XCTUnwrap(coordinator.childCoordinators.first as? TabCoordinator)
        let timerHaptics = try XCTUnwrap(tabs.testHooks.timerCoordinator?.hapticsManager as? MockHapticsManager)
        XCTAssertTrue(timerHaptics === haptics)
    }

    func test_coordinatorsWithoutHaptics_stillBuildTimerScreen() throws {
        let navigation = UINavigationController()
        let coordinator = TimerCoordiantor(navigationController: navigation, coreDataManager: InMemoryPresetStore())

        coordinator.navigateToTimerView(viewModel: TimerConfigViewModel(coreDataManager: InMemoryPresetStore()))

        XCTAssertNil(coordinator.hapticsManager)
        XCTAssertTrue(navigation.topViewController is TimerViewController)
    }
}

@MainActor
private final class LifecycleStub: SyncLifecycleManaging {
    @Published var syncStatus = SyncStatus(isEnabled: false)
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> {
        $syncStatus.eraseToAnyPublisher()
    }

    func start() {}
    func stop() async {}
    func setSyncEnabled(_ enabled: Bool) async throws { syncStatus.isEnabled = enabled }
}
