//
//  CountdownIntentHandling.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 11/7/26.
//

import Foundation

public protocol CountdownIntentHandling: Sendable {
    func togglePauseResume(alarmID: String) async throws
    func pause(alarmID: String?) async throws
    func resume(alarmID: String?) async throws
    func advance(from alarmID: String) async throws
    func skipBreak(from alarmID: String) async throws
    func endCycle(from alarmID: String) async
    func restartCycle(from alarmID: String) async throws
}

public enum CountdownIntentRouter {
    nonisolated(unsafe) public static var handler: (any CountdownIntentHandling)?
}
