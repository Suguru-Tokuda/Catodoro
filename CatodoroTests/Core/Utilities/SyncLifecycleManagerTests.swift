import CloudKit
import UIKit
import Combine
import CoreData
import XCTest
@testable import Catodoro

@MainActor
final class SyncLifecycleManagerTests: XCTestCase {
    func test_startIsIdempotentAndRestoresSavedOptIn() async {
        let preferences = MockPreferences()
        preferences.syncEnabled = true
        let persistence = CloudPersistenceMock()
        let restored = expectation(description: "Restored mirroring")
        persistence.onChange = { restored.fulfill() }
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        manager.start()
        manager.start()
        await fulfillment(of: [restored], timeout: 1)
        XCTAssertEqual(persistence.requests, [true])
        XCTAssertTrue(manager.syncStatus.isEnabled)
        XCTAssertNil(manager.syncStatus.lastSuccessfulTransfer)
        await manager.stop()
    }

    func test_localStartupDoesNotEnableMirroring() async {
        let preferences = MockPreferences()
        let persistence = CloudPersistenceMock()
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        let noActivation = expectation(description: "Local startup")
        persistence.onChange = { noActivation.fulfill() }
        manager.start()
        await fulfillment(of: [noActivation], timeout: 0.1)
        await manager.stop()
        XCTAssertEqual(persistence.requests, [false])
    }

    func test_toggleUpdatesPreferenceAndPublishesStatusOnlyAfterSuccess() async throws {
        let preferences = MockPreferences()
        let persistence = CloudPersistenceMock()
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        var values: [Bool] = []
        let subscription = manager.syncStatusPublisher.sink { values.append($0.isEnabled) }
        try await manager.setSyncEnabled(true)
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertEqual(values.last, true)
        try await manager.setSyncEnabled(false)
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertEqual(values.last, false)
        XCTAssertEqual(persistence.requests, [true, false])
        withExtendedLifetime(subscription) {}
    }

    func test_failedTogglePreservesPreviousPreferenceAndSurfacesError() async {
        let preferences = MockPreferences()
        let persistence = CloudPersistenceMock()
        persistence.error = NSError(domain: "Test", code: 1)
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        do { try await manager.setSyncEnabled(true); XCTFail("Expected load failure") } catch {}
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertFalse(manager.syncStatus.isEnabled)
        XCTAssertNotNil(manager.syncStatus.errorMessage)
    }

    func test_importAndExportOverlapUntilBothFinish() async throws {
        let manager = SyncLifecycleManager(preferences: MockPreferences(), persistence: CloudPersistenceMock(), accountStatus: { .available })
        try await manager.setSyncEnabled(true)
        let first = UUID(), second = UUID(), date = Date()
        manager.updateEvent(id: first, type: .import, endDate: nil, succeeded: false, error: nil)
        manager.updateEvent(id: second, type: .export, endDate: nil, succeeded: false, error: nil)
        manager.updateEvent(id: first, type: .import, endDate: date, succeeded: true, error: nil)
        XCTAssertTrue(manager.syncStatus.isSyncing)
        XCTAssertEqual(manager.syncStatus.lastSuccessfulTransfer, date)
        manager.updateEvent(id: second, type: .export, endDate: date, succeeded: true, error: nil)
        XCTAssertFalse(manager.syncStatus.isSyncing)
    }

    func test_setupDoesNotClaimSuccessfulTransferAndErrorsAreReported() async throws {
        let manager = SyncLifecycleManager(preferences: MockPreferences(), persistence: CloudPersistenceMock(), accountStatus: { .available })
        try await manager.setSyncEnabled(true)
        manager.updateEvent(id: UUID(), type: .setup, endDate: Date(), succeeded: true, error: nil)
        XCTAssertNil(manager.syncStatus.lastSuccessfulTransfer)
        manager.updateEvent(id: UUID(), type: .export, endDate: Date(), succeeded: false,
                            error: NSError(domain: "Offline", code: 1))
        XCTAssertNotNil(manager.syncStatus.errorMessage)
        manager.updateEvent(id: UUID(), type: .export, endDate: Date(), succeeded: true, error: nil)
        XCTAssertNil(manager.syncStatus.errorMessage)
    }

    func test_disabledModeIgnoresLateEvents() async throws {
        let manager = SyncLifecycleManager(preferences: MockPreferences(), persistence: CloudPersistenceMock(), accountStatus: { .available })
        try await manager.setSyncEnabled(true)
        try await manager.setSyncEnabled(false)
        manager.updateEvent(id: UUID(), type: .export, endDate: nil, succeeded: false, error: nil)
        XCTAssertFalse(manager.syncStatus.isSyncing)
    }

    func test_settingsUsesLifecycleForLiveTogglesAndDisplaysLoadFailure() async {
        let preferences = MockPreferences()
        let persistence = CloudPersistenceMock()
        let lifecycle = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        let model = SettingsViewModel(preferences: preferences, activitiesAuthorized: { false },
                                      syncLifecycleManager: lifecycle)
        XCTAssertTrue(model.state.syncAvailable)
        await model.setSyncEnabled(true)
        XCTAssertTrue(model.state.syncEnabled)
        XCTAssertFalse(model.state.syncBusy)
        persistence.error = NSError(domain: "Test", code: 2)
        await model.setSyncEnabled(false)
        XCTAssertTrue(model.state.syncEnabled)
        XCTAssertEqual(model.state.syncMessage, persistence.error?.localizedDescription)
        XCTAssertTrue(preferences.syncEnabled)
        persistence.error = nil
        await model.setSyncEnabled(false)
        XCTAssertFalse(model.state.syncEnabled)
        XCTAssertFalse(preferences.syncEnabled)
    }

    func test_unavailableAccountTurnsSwitchOffAndDisablesItWithoutLosingOptIn() async {
        let preferences = MockPreferences()
        preferences.syncEnabled = true
        for status in [CKAccountStatus.noAccount, .restricted, .temporarilyUnavailable, .couldNotDetermine] {
            let persistence = CloudPersistenceMock()
            let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence,
                                               accountStatus: { status })
            let model = SettingsViewModel(preferences: preferences, activitiesAuthorized: { true },
                                          syncLifecycleManager: manager)
            await manager.refreshAvailability()
            model.refresh()
            XCTAssertFalse(model.state.syncEnabled)
            XCTAssertFalse(model.state.syncToggleEnabled)
            XCTAssertTrue(preferences.syncEnabled)
            XCTAssertEqual(persistence.requests, [false])
            XCTAssertNotNil(manager.syncStatus.errorMessage)
        }
    }

    func test_foregroundAndAccountChangeRefreshAvailabilityAndRestoreSavedChoice() async {
        let preferences = MockPreferences()
        preferences.syncEnabled = true
        let persistence = CloudPersistenceMock()
        let center = NotificationCenter()
        var status = CKAccountStatus.available
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence,
                                           notificationCenter: center, accountStatus: { status })
        let started = expectation(description: "Initial availability checked")
        let first = manager.syncStatusPublisher.first {
            $0.isEnabled && !$0.isCheckingAvailability
        }.sink { _ in started.fulfill() }
        manager.start()
        await fulfillment(of: [started], timeout: 1)
        status = .noAccount
        let unavailable = expectation(description: "Foreground disables unavailable sync")
        let second = manager.syncStatusPublisher.first {
            !$0.isAvailable && !$0.isCheckingAvailability && $0.errorMessage != nil
        }.sink { _ in unavailable.fulfill() }
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        await fulfillment(of: [unavailable], timeout: 1)
        XCTAssertFalse(manager.syncStatus.isEnabled)
        XCTAssertTrue(preferences.syncEnabled)

        status = .available
        let restored = expectation(description: "Account access restores saved sync")
        let third = manager.syncStatusPublisher.first {
            $0.isEnabled && !$0.isCheckingAvailability
        }.sink { _ in restored.fulfill() }
        center.post(name: .CKAccountChanged, object: nil)
        await fulfillment(of: [restored], timeout: 1)
        XCTAssertEqual(persistence.requests, [true, false, true])
        XCTAssertNil(manager.syncStatus.errorMessage)
        await manager.stop()
        withExtendedLifetime([first, second, third]) {}
    }

    func test_accountCheckFailureDoesNotErasePreferenceAndCanRecover() async {
        let preferences = MockPreferences()
        preferences.syncEnabled = true
        let persistence = CloudPersistenceMock()
        var fail = true
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: {
            if fail { throw NSError(domain: "Offline", code: 1) }
            return .available
        })
        await manager.refreshAvailability()
        XCTAssertFalse(manager.syncStatus.isAvailable)
        XCTAssertFalse(manager.syncStatus.isEnabled)
        XCTAssertTrue(preferences.syncEnabled)
        fail = false
        await manager.refreshAvailability()
        XCTAssertTrue(manager.syncStatus.isAvailable)
        XCTAssertTrue(manager.syncStatus.isEnabled)
    }

    func test_oldAvailabilityResultCannotReenableAfterUserTurnsSyncOff() async throws {
        let preferences = MockPreferences()
        preferences.syncEnabled = true
        let persistence = CloudPersistenceMock()
        let checking = expectation(description: "Availability check suspended")
        var continuation: CheckedContinuation<CKAccountStatus, Error>?
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: {
            try await withCheckedThrowingContinuation { pending in
                continuation = pending
                checking.fulfill()
            }
        })
        let task = Task { await manager.refreshAvailability() }
        await fulfillment(of: [checking], timeout: 1)
        try await manager.setSyncEnabled(false)
        continuation?.resume(returning: .available)
        await task.value
        XCTAssertFalse(preferences.syncEnabled)
        XCTAssertFalse(manager.syncStatus.isEnabled)
        XCTAssertFalse(manager.syncStatus.isCheckingAvailability)
        XCTAssertEqual(persistence.requests, [false])
    }

    func test_stoppingObservationPreservesPreferenceAndMirroring() async throws {
        let preferences = MockPreferences()
        let persistence = CloudPersistenceMock()
        let manager = SyncLifecycleManager(preferences: preferences, persistence: persistence, accountStatus: { .available })
        try await manager.setSyncEnabled(true)
        await manager.stop()
        XCTAssertTrue(preferences.syncEnabled)
        XCTAssertEqual(persistence.requests, [true])
    }
}

private final class CloudPersistenceMock: CloudSyncPersistence {
    var requests: [Bool] = []
    var error: Error?
    var onChange: (() -> Void)?
    func setCloudSyncEnabled(_ enabled: Bool) async throws {
        requests.append(enabled)
        onChange?()
        if let error { throw error }
    }
}
