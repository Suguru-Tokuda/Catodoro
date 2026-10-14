import Combine
import XCTest
@testable import Catodoro

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func test_localChoiceCompletesWithoutEnablingSync() async {
        let (preferences, defaults, domain) = makePreferences()
        defer { defaults.removePersistentDomain(forName: domain) }
        let sync = MockOnboardingSync()
        let model = OnboardingViewModel(lifecycle: sync, preferences: preferences)
        var completed = false
        model.onComplete = { completed = true }
        await model.continueLocally()
        XCTAssertTrue(completed)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertEqual(sync.enableCount, 0)
        XCTAssertEqual(sync.disableCount, 1)
        XCTAssertTrue(CatodoroPreferences(userDefaults: defaults).hasCompletedOnboarding)
    }

    func test_cloudSuccessPersistsChoiceAndCompletes() async {
        let (preferences, defaults, domain) = makePreferences()
        defer { defaults.removePersistentDomain(forName: domain) }
        let sync = MockOnboardingSync()
        let model = OnboardingViewModel(lifecycle: sync, preferences: preferences)
        var completed = false
        model.onComplete = { completed = true }
        await model.enableSync()
        XCTAssertTrue(completed)
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertFalse(model.isBusy)
    }

    func test_failureDoesNotCompleteAndAllowsRetry() async {
        let (preferences, defaults, domain) = makePreferences()
        defer { defaults.removePersistentDomain(forName: domain) }
        let sync = MockOnboardingSync()
        sync.shouldFail = true
        let model = OnboardingViewModel(lifecycle: sync, preferences: preferences)
        await model.enableSync()
        XCTAssertFalse(preferences.hasCompletedOnboarding)
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(sync.disableCount, 0)
        XCTAssertFalse(model.isBusy)
        sync.shouldFail = false
        await model.enableSync()
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertNil(model.errorMessage)
    }

    func test_cancelledChoiceDoesNotCompleteOrDisplayFailure() async {
        for enabled in [true, false] {
            let (preferences, defaults, domain) = makePreferences()
            defer { defaults.removePersistentDomain(forName: domain) }
            let lifecycle = MockOnboardingSync()
            lifecycle.cancellation = true
            let model = OnboardingViewModel(lifecycle: lifecycle, preferences: preferences)
            var completed = false
            model.onComplete = { completed = true }
            if enabled { await model.enableSync() } else { await model.continueLocally() }
            XCTAssertEqual(lifecycle.requests, [enabled])
            XCTAssertFalse(completed)
            XCTAssertFalse(preferences.hasCompletedOnboarding)
            XCTAssertNil(model.errorMessage)
            XCTAssertFalse(model.isBusy)
        }
    }

    func test_localChoiceFailureDoesNotCompleteAndCanRetry() async {
        let (preferences, defaults, domain) = makePreferences()
        defer { defaults.removePersistentDomain(forName: domain) }
        let lifecycle = MockOnboardingSync()
        lifecycle.shouldFail = true
        let model = OnboardingViewModel(lifecycle: lifecycle, preferences: preferences)
        var completed = false
        model.onComplete = { completed = true }
        await model.continueLocally()
        XCTAssertFalse(completed)
        XCTAssertFalse(preferences.hasCompletedOnboarding)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isBusy)
        lifecycle.shouldFail = false
        await model.continueLocally()
        XCTAssertTrue(completed)
        XCTAssertEqual(lifecycle.requests, [false, false])
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertNil(model.errorMessage)
    }

    private func makePreferences() -> (CatodoroPreferences, UserDefaults, String) {
        let domain = "OnboardingTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        return (CatodoroPreferences(userDefaults: defaults), defaults, domain)
    }
}

@MainActor
private final class MockOnboardingSync: SyncLifecycleManaging {
    @Published var syncStatus = SyncStatus(
        isEnabled: false
    )
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> {
        $syncStatus.eraseToAnyPublisher()
    }

    var shouldFail = false
    var enableCount = 0
    var disableCount = 0
    var cancellation = false
    var requests: [Bool] = []
    func start() {}
    func stop() async {}
    func setSyncEnabled(_ enabled: Bool) async throws {
        requests.append(enabled)
        if enabled { enableCount += 1 } else { disableCount += 1 }
        if cancellation { throw CancellationError() }
        if shouldFail { throw NSError(domain: "Test", code: 1) }
        syncStatus.isEnabled = enabled
    }
}
