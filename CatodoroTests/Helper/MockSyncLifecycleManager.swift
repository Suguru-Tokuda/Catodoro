//
//  MockSyncLifecycleManager.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Combine
@testable import Catodoro

final class MockSyncLifecycleManager: SyncLifecycleManaging {
    @Published var syncStatus = SyncStatus(isEnabled: false)
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { $syncStatus.eraseToAnyPublisher() }

    private(set) var startCount = 0

    func start() { startCount += 1 }
    func stop() async {}
    func setSyncEnabled(_ enabled: Bool) async throws { syncStatus.isEnabled = enabled }
}
