import CloudKit
import Combine
import UIKit
import XCTest
@testable import Catodoro

@MainActor
final class SyncLifecycleManagerTests: XCTestCase {
    func test_statusPublisherImmediatelyReflectsSavedPreferenceWithoutClaimingCompletedSync() {
        for enabled in [true, false] {
            let preferences = MockPreferences()
            preferences.syncEnabled = enabled
            let manager = SyncLifecycleManager(
                preferences: preferences,
                sync: LifecycleSyncMock(),
                notificationCenter: NotificationCenter()
            )
            var values: [SyncStatus] = []
            let subscription = manager.syncStatusPublisher.sink { values.append($0) }
            XCTAssertEqual(values.count, 1)
            XCTAssertEqual(values.first?.isEnabled, enabled)
            XCTAssertEqual(manager.syncStatus.isEnabled, enabled)
            XCTAssertEqual(values.first?.isSyncing, false)
            XCTAssertNil(values.first?.lastSuccessfulCheck)
            XCTAssertNil(values.first?.errorMessage)
            withExtendedLifetime(subscription) {}
        }
    }

    func test_startIsIdempotentAndRestoresEnabledSync() async {
        let (manager, preferences, sync, _) = makeSystem()
        preferences.syncEnabled = true
        let enabled = expectation(description: "Startup restoration")
        sync.onEnable = { enabled.fulfill() }
        manager.start()
        manager.start()
        await fulfillment(of: [enabled], timeout: 1)
        XCTAssertEqual(sync.enableCount, 1)
        await manager.stop()
    }

    func test_startAndForegroundLeaveDisabledSyncAlone() async {
        let (manager, _, sync, center) = makeSystem()
        let enabled = expectation(description: "No activation while disabled")
        enabled.isInverted = true
        sync.onEnable = { enabled.fulfill() }
        manager.start()
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await fulfillment(of: [enabled], timeout: 0.1)
        XCTAssertEqual(sync.enableCount, 0)
        await manager.stop()
    }

    func test_foregroundRetriesPreviouslyFailedRestoration() async {
        let (manager, preferences, sync, center) = makeSystem()
        preferences.syncEnabled = true
        sync.error = SyncError.iCloudUnavailable
        let initial = expectation(description: "Initial attempt")
        sync.onEnable = { initial.fulfill() }
        manager.start()
        await fulfillment(of: [initial], timeout: 1)
        XCTAssertNotNil(manager.lastError)
        XCTAssertTrue(preferences.syncEnabled)
        sync.error = nil
        let retry = expectation(description: "Foreground retry")
        sync.onEnable = { retry.fulfill() }
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await fulfillment(of: [retry], timeout: 1)
        XCTAssertEqual(sync.enableCount, 2)
        XCTAssertNil(manager.lastError)
        await manager.stop()
    }

    func test_togglePersistsIntentAndPreservesEnabledPreferenceOnFailure() async throws {
        let (manager, preferences, sync, _) = makeSystem()
        sync.error = SyncError.iCloudUnavailable
        do {
            try await manager.setSyncEnabled(true)
            XCTFail("Expected activation failure")
        } catch {}
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertNotNil(manager.lastError)
        try await manager.setSyncEnabled(false)
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertEqual(sync.disableCount, 1)
        XCTAssertNil(manager.lastError)
    }

    func test_accountChangeRevalidatesAndResumesSameAccount() async {
        let (manager, preferences, sync, center) = makeSystem()
        let startup = expectation(description: "Disabled startup stays local")
        startup.isInverted = true
        sync.onEnable = { startup.fulfill() }
        manager.start()
        await fulfillment(of: [startup], timeout: 0.1)
        preferences.syncEnabled = true
        let resumed = expectation(description: "Account revalidation")
        sync.onEnable = { resumed.fulfill() }
        center.post(name: .CKAccountChanged, object: nil)
        await fulfillment(of: [resumed], timeout: 1)
        XCTAssertEqual(sync.disableCount, 1)
        XCTAssertEqual(sync.enableCount, 1)
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertNil(manager.lastError)
        await manager.stop()
    }

    func test_differentAccountSurfacesRejectionWithoutChangingPreference() async {
        let (manager, preferences, sync, _) = makeSystem()
        manager.start()
        preferences.syncEnabled = true
        sync.error = SyncError.differentAccount
        let attempted = expectation(description: "Validate different account")
        sync.onEnable = { attempted.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [attempted], timeout: 1)
        guard case SyncError.differentAccount? = manager.lastError else {
            return XCTFail("Expected different-account rejection")
        }
        XCTAssertTrue(preferences.syncEnabled)
        await manager.stop()
    }

    func test_duplicateAccountSignalsAndForegroundShareOneRecovery() async {
        let (manager, preferences, sync, center) = makeSystem()
        manager.start()
        preferences.syncEnabled = true
        sync.suspendDisable = true
        let paused = expectation(description: "Recovery pauses engine")
        sync.onDisable = { paused.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [paused], timeout: 1)
        manager.accountDidChange()
        center.post(name: .CKAccountChanged, object: nil)
        let premature = expectation(description: "Foreground waits for recovery")
        premature.isInverted = true
        sync.onEnable = { premature.fulfill() }
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await fulfillment(of: [premature], timeout: 0.1)
        XCTAssertEqual(sync.disableCount, 1)
        let resumed = expectation(description: "Single recovery resumes")
        sync.onEnable = { resumed.fulfill() }
        sync.resumeDisable(at: 0)
        await fulfillment(of: [resumed], timeout: 1)
        sync.onDisable = nil
        sync.suspendDisable = false
        await manager.stop()
    }

    func test_stopDuringDisablePreventsRecoveryActivation() async {
        let (manager, preferences, sync, _) = makeSystem()
        manager.start()
        preferences.syncEnabled = true
        sync.suspendDisable = true
        let paused = expectation(description: "Disable suspended")
        sync.onDisable = { paused.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [paused], timeout: 1)
        sync.onDisable = nil
        sync.suspendDisable = false
        await manager.stop()
        let resumed = expectation(description: "Stopped recovery must not activate")
        resumed.isInverted = true
        sync.onEnable = { resumed.fulfill() }
        sync.resumeDisable(at: 0)
        await fulfillment(of: [resumed], timeout: 0.1)
        XCTAssertTrue(preferences.syncEnabled)
    }

    func test_oldRecoveryCleanupDoesNotClearRestartedRecovery() async {
        let (manager, preferences, sync, _) = makeSystem()
        manager.start()
        preferences.syncEnabled = true
        sync.suspendDisable = true
        let first = expectation(description: "Old recovery suspended")
        sync.onDisable = { first.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [first], timeout: 1)
        sync.onDisable = nil
        sync.suspendDisable = false
        await manager.stop()
        sync.suspendDisable = true
        manager.start()
        let second = expectation(description: "New recovery suspended")
        sync.onDisable = { second.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [second], timeout: 1)
        let noActivation = expectation(description: "Old recovery cannot resume")
        noActivation.isInverted = true
        sync.onEnable = { noActivation.fulfill() }
        sync.resumeDisable(at: 0)
        await fulfillment(of: [noActivation], timeout: 0.1)
        manager.accountDidChange()
        XCTAssertEqual(sync.disableCount, 3)
        let resumed = expectation(description: "New recovery resumes")
        sync.onEnable = { resumed.fulfill() }
        sync.resumeDisable(at: 1)
        await fulfillment(of: [resumed], timeout: 1)
        sync.onDisable = nil
        sync.suspendDisable = false
        await manager.stop()
    }

    func test_stopDuringEnableCancelsUnderlyingActivationAndPreservesPreference() async {
        let (manager, preferences, sync, _) = makeSystem()
        manager.start()
        preferences.syncEnabled = true
        sync.suspendEnable = true
        let started = expectation(description: "Recovery activation suspended")
        sync.onEnable = { started.fulfill() }
        manager.accountDidChange()
        await fulfillment(of: [started], timeout: 1)
        let completed = expectation(description: "Underlying activation exits")
        sync.onEnableCompleted = { completed.fulfill() }
        await manager.stop()
        await fulfillment(of: [completed], timeout: 1)
        XCTAssertEqual(sync.disableCount, 2)
        XCTAssertFalse(sync.isActive)
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertNil(manager.lastError)
    }

    func test_stopRemovesObserversDisablesEngineAndPreservesPreference() async throws {
        let (manager, preferences, sync, center) = makeSystem()
        manager.start()
        try await manager.setSyncEnabled(true)
        await manager.stop()
        let event = expectation(description: "No events after observation stops")
        event.isInverted = true
        sync.onEnable = { event.fulfill() }
        sync.onDisable = { event.fulfill() }
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        center.post(name: .CKAccountChanged, object: nil)
        await fulfillment(of: [event], timeout: 0.1)
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertEqual(sync.disableCount, 1)
    }

    func test_disableSupersedesSuspendedEnable() async throws {
        let (manager, preferences, sync, _) = makeSystem()
        let started = expectation(description: "Enable suspended")
        sync.suspendEnable = true
        sync.onEnable = { started.fulfill() }
        let task = Task { try await manager.setSyncEnabled(true) }
        await fulfillment(of: [started], timeout: 1)
        try await manager.setSyncEnabled(false)
        sync.resumeEnable()
        do {
            try await task.value
            XCTFail("Superseded enable must report cancellation")
        } catch is CancellationError {} catch { XCTFail("Unexpected error: \(error)") }
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertNil(manager.lastError)
    }

    private func makeSystem() -> (SyncLifecycleManager, MockPreferences, LifecycleSyncMock, NotificationCenter) {
        let preferences = MockPreferences()
        let sync = LifecycleSyncMock()
        let center = NotificationCenter()
        return (SyncLifecycleManager(preferences: preferences, sync: sync, notificationCenter: center), preferences, sync, center)
    }
}

@MainActor
private final class LifecycleSyncMock: OnboardingSyncControlling {
    var enableCount = 0
    var disableCount = 0
    var error: Error?
    var onEnable: (() -> Void)?
    var onDisable: (() -> Void)?
    var suspendDisable = false
    var onEnableCompleted: (() -> Void)?
    private var disableContinuations: [CheckedContinuation<Void, Never>?] = []
    var suspendEnable = false
    private var continuation: CheckedContinuation<Void, Error>?
    private(set) var isActive = false

    func enableSync() async throws {
        enableCount += 1
        defer { onEnableCompleted?() }
        if suspendEnable {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                onEnable?()
            }
        } else {
            onEnable?()
        }
        if let error { throw error }
        isActive = true
    }
    func resumeEnable() {
        continuation?.resume()
        continuation = nil
    }
    func disableSync() async {
        disableCount += 1
        isActive = false
        continuation?.resume(throwing: CancellationError())
        continuation = nil
        if suspendDisable {
            await withCheckedContinuation { continuation in
                disableContinuations.append(continuation)
                onDisable?()
            }
        } else {
            onDisable?()
        }
    }
    func resumeDisable(at index: Int) {
        disableContinuations[index]?.resume()
        disableContinuations[index] = nil
    }
}
