//
//  TimerController.swift
//  CatodoroShared
//
//  Created by Suguru Tokuda on 10/17/26.
//

import Foundation

@MainActor
public protocol ActiveTimer: AnyObject {
    func togglePauseResumeAndUpdateActivity() async
}

@MainActor
public final class TimerController {
    public static let shared = TimerController()

    public weak var activeTimer: (any ActiveTimer)?

    private init() {}

    public func togglePauseResume() async throws {
        guard let activeTimer else {
            throw TimerError.noActiveTimer
        }
        await activeTimer.togglePauseResumeAndUpdateActivity()
    }

    public enum TimerError: Error {
        case noActiveTimer
    }
}
