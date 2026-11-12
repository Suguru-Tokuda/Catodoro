//
//  MockCountdown.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation
@testable import Catodoro

/// Stands in for `CountdownService`.
///
/// - `start(steps:)` returns `startID` (or throws `startError`) and records the steps.
/// - `currentSession()` returns `session`; `send(_:)` sets it and pushes it to every
///   `sessionUpdates()` stream, like the engine does after a change.
/// - Cycle controls are recorded in `calls` and throw `actionError` when set.
/// - `requestAuthorization(for:)` answers `isAuthorized` and records the backend.
///
/// Calls arrive from whichever executor the caller uses, so state sits behind a lock.
final class MockCountdown: CountdownControlling, @unchecked Sendable {
    enum Call: Equatable {
        case togglePauseResume(String)
        case pause(String?)
        case resume(String?)
        case advance(String)
        case skipBreak(String)
        case endCycle(String)
        case restartCycle(String)
    }

    private let lock = NSLock()
    private var _isAuthorized = true
    private var _requestedBackends: [CycleSession.Backend] = []
    private var _startID = UUID()
    private var _startError: Error?
    private var _startedSteps: [[CycleStep]] = []
    private var _session: CycleSession?
    private var _calls: [Call] = []
    private var _actionError: Error?
    private var _reconcileCount = 0
    private var _endsSessionOnReconcile = false
    private var continuations: [AsyncStream<CycleSession?>.Continuation] = []

    var isAuthorized: Bool {
        get { locked { _isAuthorized } }
        set { locked { _isAuthorized = newValue } }
    }
    var requestedBackends: [CycleSession.Backend] { locked { _requestedBackends } }
    var startID: UUID {
        get { locked { _startID } }
        set { locked { _startID = newValue } }
    }
    var startError: Error? {
        get { locked { _startError } }
        set { locked { _startError = newValue } }
    }
    var startedSteps: [[CycleStep]] { locked { _startedSteps } }
    var session: CycleSession? {
        get { locked { _session } }
        set { locked { _session = newValue } }
    }
    var calls: [Call] { locked { _calls } }
    var actionError: Error? {
        get { locked { _actionError } }
        set { locked { _actionError = newValue } }
    }
    var reconcileCount: Int { locked { _reconcileCount } }
    /// Simulates a cycle that ended while the app was gone: `reconcile()` clears the session.
    var endsSessionOnReconcile: Bool {
        get { locked { _endsSessionOnReconcile } }
        set { locked { _endsSessionOnReconcile = newValue } }
    }

    /// Sets the current session and delivers it to all observers.
    func send(_ session: CycleSession?) {
        let streams: [AsyncStream<CycleSession?>.Continuation] = locked {
            _session = session
            return continuations
        }
        streams.forEach { $0.yield(session) }
    }

    // MARK: CountdownControlling

    func requestAuthorization(for backend: CycleSession.Backend) async -> Bool {
        locked {
            _requestedBackends.append(backend)
            return _isAuthorized
        }
    }

    func start(steps: [CycleStep]) async throws -> UUID {
        try locked {
            _startedSteps.append(steps)
            if let _startError { throw _startError }
            return _startID
        }
    }

    func reconcile() async {
        locked {
            _reconcileCount += 1
            if _endsSessionOnReconcile { _session = nil }
        }
    }

    func currentSession() async -> CycleSession? { session }

    func sessionUpdates() -> AsyncStream<CycleSession?> {
        AsyncStream { continuation in
            locked { continuations.append(continuation) }
        }
    }

    // MARK: CountdownIntentHandling

    func togglePauseResume(alarmID: String) async throws { try record(.togglePauseResume(alarmID)) }
    func pause(alarmID: String?) async throws { try record(.pause(alarmID)) }
    func resume(alarmID: String?) async throws { try record(.resume(alarmID)) }
    func advance(from alarmID: String) async throws { try record(.advance(alarmID)) }
    func skipBreak(from alarmID: String) async throws { try record(.skipBreak(alarmID)) }
    func endCycle(from alarmID: String) async { try? record(.endCycle(alarmID), throwing: false) }
    func restartCycle(from alarmID: String) async throws { try record(.restartCycle(alarmID)) }

    private func record(_ call: Call, throwing: Bool = true) throws {
        try locked {
            _calls.append(call)
            if throwing, let _actionError { throw _actionError }
        }
    }

    private func locked<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
