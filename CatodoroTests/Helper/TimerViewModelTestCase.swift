//
//  TimerViewModelTestCase.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Combine
import UIKit
import XCTest
@testable import Catodoro

/// Shared setup for `TimerViewModel` tests.
///
/// The view model only presents what `CountdownControlling` reports, so tests
/// start a cycle through `MockCountdown`, then push sessions with `deliver(_:)`
/// the way the engine would after each change.
///
/// The default cycle is 2 sessions of 10s focus with a 5s break:
/// index 0 focus #1 → index 1 break → index 2 focus #2 (last step).
@MainActor
class TimerViewModelTestCase: XCTestCase {
    var instant = Date(timeIntervalSince1970: 1000)
    var countdown: MockCountdown!
    var audio: MockAudioManager!
    var haptics: MockHapticsManager!
    var preferences: MockPreferences!
    var actions: [TimerActions] = []
    private var cancellables: Set<AnyCancellable> = []

    let cycleID = UUID()
    let config = TimerConfigModel(mainTimer: .init(hours: 0, minutes: 0, seconds: 10),
                                  interval: .init(hours: 0, minutes: 0, seconds: 5),
                                  intervals: 2)
    var steps: [CycleStep] { config.cycleSteps }

    override func setUp() async throws {
        try await super.setUp()
        countdown = MockCountdown()
        audio = MockAudioManager()
        haptics = MockHapticsManager()
        preferences = MockPreferences()
        actions = []
    }

    override func tearDown() async throws {
        cancellables.removeAll()
        countdown = nil
        audio = nil
        haptics = nil
        preferences = nil
        try await super.tearDown()
    }

    func makeViewModel() -> TimerViewModel {
        let model = TimerViewModel(countdown: countdown,
                                   audioManager: audio,
                                   preferences: preferences,
                                   hapticsManager: haptics,
                                   schedulesTicks: false,
                                   now: { [unowned self] in self.instant })
        model.timerActionSubject
            .dropFirst()
            .sink { [unowned self] in self.actions.append($0) }
            .store(in: &cancellables)
        return model
    }

    /// The first focus session, running from `instant`.
    func firstSession() -> CycleSession {
        .test(id: cycleID, steps: steps, state: .running(endDate: instant + 10))
    }

    /// Starts the default cycle and waits until it's on screen.
    /// Clears the audio and haptics calls made while setting up.
    @discardableResult
    func start(_ model: TimerViewModel) async -> CycleSession {
        let first = firstSession()
        countdown.startID = cycleID
        countdown.session = first

        model.configure(config: config)

        await waitUntil("cycle never shown") { model.testHooks.session == first }
        await flushAudioQueue()
        haptics.reset()
        audio.clearRecordedCalls()
        actions = []
        return first
    }

    /// Pushes a session from the engine and waits for the view model to show it.
    func deliver(_ session: CycleSession, to model: TimerViewModel,
                 file: StaticString = #filePath, line: UInt = #line) async {
        countdown.send(session)
        await waitUntil("session not applied", file: file, line: line) { model.testHooks.session == session }
        await flushAudioQueue()
    }

    /// Pushes "no session" (cycle ended) and waits for the view model to clear it.
    func deliverEnd(to model: TimerViewModel) async {
        countdown.send(nil)
        await waitUntil("end not applied") { model.testHooks.session == nil }
        await flushAudioQueue()
    }

    func setAppActive(_ isActive: Bool) {
        NotificationCenter.default.post(name: isActive ? UIApplication.didBecomeActiveNotification
                                                       : UIApplication.willResignActiveNotification,
                                        object: nil)
    }
}
