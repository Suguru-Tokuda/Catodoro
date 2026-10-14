//
//  SyncLifecycleManager.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import CloudKit
import Combine
import UIKit

struct SyncStatus {
    var isEnabled: Bool
    var isSyncing: Bool
    var pendingChangeCount: Int
    var lastSuccessfulCheck: Date?
    var errorMessage: String?
}

@MainActor
protocol SyncLifecycleManaging: AnyObject {
    func start()
    func stop() async
    func setSyncEnabled(_ enabled: Bool) async throws
    func accountDidChange()

    var syncStatus: SyncStatus { get }
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }
}

final class SyncLifecycleManager: SyncLifecycleManaging {
    @Published private(set) var syncStatus: SyncStatus
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> {
        $syncStatus.eraseToAnyPublisher()
    }
    private let preferences: CatodoroPreferencesProtocol
    private let sync: OnboardingSyncControlling
    private let notificationCenter: NotificationCenter

    private var subscriptions = Set<AnyCancellable>()
    private var isStarted = false
    private var generation = 0
    private var accountRecoveryTask: Task<Void, Never>?
    private var accountRecoveryID: UUID?

    private(set) var lastError: Error?

    init(preferences: CatodoroPreferencesProtocol,
         sync: OnboardingSyncControlling,
         notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        self.preferences = preferences
        self.sync = sync
        self.syncStatus = SyncStatus(
            isEnabled: preferences.syncEnabled,
            isSyncing: false,
            pendingChangeCount: 0,
            lastSuccessfulCheck: nil,
            errorMessage: nil
        )
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true

        notificationCenter.publisher(
            for: UIApplication.didBecomeActiveNotification
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      isStarted,
                      preferences.syncEnabled,
                      accountRecoveryTask == nil else {
                    return
                }

                await restoreSyncIfEnabled()
            }
        }
        .store(in: &subscriptions)

        notificationCenter.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.accountDidChange()
                }
            }
            .store(in: &subscriptions)

        Task { [weak self] in
            guard let self, self.accountRecoveryTask == nil else { return }
            await self.restoreSyncIfEnabled()
        }
    }
    
    func stop()async {
        isStarted = false
        generation += 1
        subscriptions.removeAll()

        accountRecoveryTask?.cancel()
        accountRecoveryTask = nil
        accountRecoveryID = nil

        await sync.disableSync()
    }
    
    func setSyncEnabled(_ enabled: Bool) async throws {
        generation += 1
        let request = generation

        preferences.setSyncEnabled(enabled)

        if !enabled {
            await sync.disableSync()
            guard request == generation else { return }
            lastError = nil
            return
        }

        do {
            try await sync.enableSync()

            guard request == generation else {
                throw CancellationError()
            }

            lastError = nil
        } catch {
            if request == generation,
               !(error is CancellationError) {
                lastError = error
            }
            throw error
        }
    }

    func accountDidChange() {
        guard isStarted, accountRecoveryTask == nil else { return }

        let recoveryID = UUID()
        accountRecoveryID = recoveryID

        accountRecoveryTask = Task { @MainActor [weak self] in
            guard let self else { return }

            defer {
                if accountRecoveryID == recoveryID {
                    accountRecoveryTask = nil
                    accountRecoveryID = nil
                }
            }

            guard !Task.isCancelled,
                  accountRecoveryID == recoveryID else {
                return
            }

            await pauseForAccountChange()
        }
    }
}

// MARK: - Private functions

extension SyncLifecycleManager {
    private func restoreSyncIfEnabled() async {
        guard isStarted,
              preferences.syncEnabled else {
            return
        }

        let request = generation

        do {
            try await sync.enableSync()

            guard request == generation else { return }
            lastError = nil
        } catch is CancellationError {
            // Superseded request.
        } catch {
            guard request == generation else { return }
            lastError = error
        }
    }

    private func pauseForAccountChange() async {
        guard isStarted, !Task.isCancelled else { return }

        generation += 1
        let request = generation

        // Preserve the user's preference and all local data.
        await sync.disableSync()

        guard isStarted,
              !Task.isCancelled,
              request == generation,
              preferences.syncEnabled else {
            return
        }

        await restoreSyncIfEnabled()
    }
}
