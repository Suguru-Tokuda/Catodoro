import CloudKit
import UIKit
import Combine
import CoreData
import Foundation

struct SyncStatus {
    var isEnabled: Bool
    var isSyncing = false
    var isAvailable = false
    var isCheckingAvailability = false
    // Core Data doesn't expose a reliable pending-record count or a "fully synced" state.
    var lastSuccessfulTransfer: Date?
    var errorMessage: String?
}

@MainActor
protocol SyncLifecycleManaging: AnyObject {
    func start()
    func stop() async
    func setSyncEnabled(_ enabled: Bool) async throws
    var syncStatus: SyncStatus { get }
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }
}

/// Owns the app's opt-in setting and reports Core Data mirroring events.
/// Core Data owns scheduling, account changes, retries, and conflict resolution.
@MainActor
final class SyncLifecycleManager: SyncLifecycleManaging {
    @Published private(set) var syncStatus: SyncStatus
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { $syncStatus.eraseToAnyPublisher() }
    private let preferences: CatodoroPreferencesProtocol
    private let persistence: CloudSyncPersistence
    private let notificationCenter: NotificationCenter
    private let eventSource: NSPersistentCloudKitContainer?
    private var subscription: AnyCancellable?
    private var availabilitySubscriptions = Set<AnyCancellable>()
    private let accountStatus: @MainActor () async throws -> CKAccountStatus
    private var startupTask: Task<Void, Never>?
    private var isStarted = false
    private var generation = 0
    private var activeEvents = Set<UUID>()

    init(preferences: CatodoroPreferencesProtocol, persistence: CloudSyncPersistence,
         notificationCenter: NotificationCenter = .default,
         accountStatus: @escaping @MainActor () async throws -> CKAccountStatus = {
             try await CKContainer(identifier: CatodoroPersistentController.cloudContainerIdentifier).accountStatus()
         }) {
        self.accountStatus = accountStatus
        self.preferences = preferences
        self.persistence = persistence
        self.notificationCenter = notificationCenter
        eventSource = (persistence as? CatodoroPersistentController)?.container
        syncStatus = SyncStatus(isEnabled: false)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        if let eventSource {
            subscription = notificationCenter.publisher(
                for: NSPersistentCloudKitContainer.eventChangedNotification, object: eventSource
            ).receive(on: DispatchQueue.main).sink { [weak self] notification in
                guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                        as? NSPersistentCloudKitContainer.Event else { return }
                Task { @MainActor [weak self] in
                    guard let self, self.isStarted else { return }
                    updateEvent(id: event.identifier,
                                type: event.type,
                                endDate: event.endDate,
                                succeeded: event.succeeded,
                                error: event.error
                    )
                }
            }
        }
        for name in [UIApplication.didBecomeActiveNotification, .CKAccountChanged] {
            notificationCenter.publisher(for: name)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.scheduleAvailabilityRefresh() }
                .store(in: &availabilitySubscriptions)
        }
        scheduleAvailabilityRefresh()
    }

    private func scheduleAvailabilityRefresh() {
        guard isStarted else { return }
        startupTask?.cancel()
        startupTask = Task { [weak self] in
            guard let self, !Task.isCancelled, isStarted else { return }
            await refreshAvailability()
        }
    }

    func refreshAvailability() async {
        generation += 1
        let request = generation
        var accountWasChecked = false
        syncStatus.isCheckingAvailability = true
        defer {
            if request == generation { syncStatus.isCheckingAvailability = false }
        }
        do {
            let status = try await accountStatus()
            try Task.checkCancellation()
            guard request == generation else { return }
            accountWasChecked = true
            syncStatus.isAvailable = status == .available
            let enabled = syncStatus.isAvailable && preferences.syncEnabled
            if !enabled {
                syncStatus.isEnabled = false
                activeEvents.removeAll()
                syncStatus.isSyncing = false
            }
            try await persistence.setCloudSyncEnabled(enabled)
            guard request == generation, !Task.isCancelled else { return }
            syncStatus.isEnabled = enabled
            syncStatus.errorMessage = Self.unavailabilityMessage(for: status)
        } catch is CancellationError {
            // Superseded check; retain the saved preference.
        } catch {
            guard request == generation else { return }
            if !accountWasChecked {
                syncStatus.isAvailable = false
                syncStatus.isEnabled = false
                activeEvents.removeAll()
                syncStatus.isSyncing = false
            }
            syncStatus.errorMessage = error.localizedDescription
        }
    }

    func stop() async {
        isStarted = false
        startupTask?.cancel()
        startupTask = nil
        subscription = nil
        availabilitySubscriptions.removeAll()
        activeEvents.removeAll()
        syncStatus.isSyncing = false
        // Stopping observation doesn't change the user's mirroring preference.
    }

    func setSyncEnabled(_ enabled: Bool) async throws {
        generation += 1
        let request = generation
        var accountWasChecked = !enabled
        defer {
            if request == generation { syncStatus.isCheckingAvailability = false }
        }
        do {
            if enabled {
                syncStatus.isCheckingAvailability = true
                let status = try await accountStatus()
                try Task.checkCancellation()
                guard request == generation else { throw CancellationError() }
                accountWasChecked = true
                syncStatus.isAvailable = status == .available
                if let message = Self.unavailabilityMessage(for: status) {
                    syncStatus.isEnabled = false
                    try await persistence.setCloudSyncEnabled(false)
                    throw ICloudUnavailableError(message: message)
                }
            }
            try await persistence.setCloudSyncEnabled(enabled)
            guard request == generation else { throw CancellationError() }
            preferences.setSyncEnabled(enabled)
            syncStatus.isEnabled = enabled
            syncStatus.errorMessage = nil
            if !enabled {
                activeEvents.removeAll()
                syncStatus.isSyncing = false
            }
        } catch {
            if request == generation, !(error is CancellationError) {
                if !accountWasChecked {
                    syncStatus.isAvailable = false
                    syncStatus.isEnabled = false
                    activeEvents.removeAll()
                    syncStatus.isSyncing = false
                }
                syncStatus.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    private static func unavailabilityMessage(for status: CKAccountStatus) -> String? {
        switch status {
        case .available: return nil
        case .noAccount:
            return "iCloud is unavailable. Sign in to iCloud and enable Catodoro in iOS iCloud Settings."
        case .restricted:
            return "iCloud access is restricted. Check your device’s iCloud restrictions."
        case .temporarilyUnavailable, .couldNotDetermine:
            return "iCloud is temporarily unavailable. Catodoro will check again when you return to the app."
        @unknown default:
            return "iCloud is unavailable right now. Your presets remain available locally."
        }
    }

    func updateEvent(id: UUID, type: NSPersistentCloudKitContainer.EventType,
                     endDate: Date?, succeeded: Bool, error: Error?) {
        guard syncStatus.isEnabled, syncStatus.isAvailable else { return }
        if let endDate {
            activeEvents.remove(id)
            if let error {
                syncStatus.errorMessage = error.localizedDescription
            } else if succeeded, type != .setup {
                syncStatus.lastSuccessfulTransfer = endDate
                syncStatus.errorMessage = nil
            }
        } else {
            activeEvents.insert(id)
        }
        syncStatus.isSyncing = !activeEvents.isEmpty
    }
}

private struct ICloudUnavailableError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
