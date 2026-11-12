//
//  CountdownService.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/7/26.
//

import ActivityKit
import AlarmKit
import CatodoroShared
import Combine
import SwiftUI
import UserNotifications

enum CountdownError: LocalizedError {
    case alreadyRunning
    case alarmKitUnavailable
    case invalidSteps
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            AppStrings.CountdownErrors.alreadyRunning
        case .alarmKitUnavailable:
            AppStrings.CountdownErrors.alarmKitUnavailable
        case .invalidSteps:
            AppStrings.CountdownErrors.invalidSteps
        case .notAuthorized:
            AppStrings.CountdownErrors.notAuthorized
        }
    }
}

protocol CountdownControlling: CountdownIntentHandling {
    func start(steps: [CycleStep]) async throws -> UUID
    func reconcile() async
    /// Asks for the permission a backend needs. `.liveActivity` needs none and returns true.
    func requestAuthorization(for backend: CycleSession.Backend) async -> Bool
    func currentSession() async -> CycleSession?
    func sessionUpdates() -> AsyncStream<CycleSession?>
}

final class CountdownService: CountdownControlling {
    private let countdownEngine: CountdownEngine

    init(countdownEngine: CountdownEngine) {
        self.countdownEngine = countdownEngine
    }

    func start(steps: [CycleStep]) async throws -> UUID {
        try await countdownEngine.start(steps: steps)
    }
    
    func requestAuthorization(for backend: CycleSession.Backend) async -> Bool {
        await countdownEngine.requestAuthorization(for: backend)
    }

    func reconcile() async {
        await countdownEngine.reconcile()
    }
    
    func currentSession() async -> CycleSession? {
        await countdownEngine.session
    }
    
    func sessionUpdates() -> AsyncStream<CycleSession?> {
        AsyncStream { continuation in
            let task = Task { @MainActor [countdownEngine] in
                for await session in countdownEngine.$session.values {
                    continuation.yield(session)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    func pause(alarmID: String?) async throws {
        try await countdownEngine.pause(alarmID: alarmID)
    }
    
    func resume(alarmID: String?) async throws {
        try await countdownEngine.resume(alarmID: alarmID)
    }
    
    func stop(alarmID: String?) async {
        await countdownEngine.stop(alarmID: alarmID)
    }

    func togglePauseResume(alarmID: String) async throws {
        try await countdownEngine.togglePauseResume(alarmID: alarmID)
    }
    
    func advance(from alarmID: String) async throws {
        try await countdownEngine.advance(from: alarmID)
    }
    
    func skipBreak(from alarmID: String) async throws {
        try await countdownEngine.skipBreak(from: alarmID)
    }
    
    func endCycle(from alarmID: String) async {
        await countdownEngine.stop(alarmID: alarmID)
    }
    
    func restartCycle(from alarmID: String) async throws {
        try await countdownEngine.restartCycle(from: alarmID)
    }
}
