//
//  CountdownBackendResolutionTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

/// Starting a timer must never show a permission prompt for a fallback style.
@MainActor
final class CountdownBackendResolutionTests: XCTestCase {
    private final class Recorder {
        var statuses: [CycleSession.Backend: AuthorizationStatus] = [:]
        var grantsOnRequest = true
        var requested: [CycleSession.Backend] = []
    }

    private func resolve(_ preferred: CycleSession.Backend, _ recorder: Recorder) async -> CycleSession.Backend {
        await CountdownEngine.resolveBackend(
            preferred: preferred,
            status: { recorder.statuses[$0] ?? ($0 == .liveActivity ? .authorized : .notDetermined) },
            request: { backend in
                recorder.requested.append(backend)
                return recorder.grantsOnRequest
            }
        )
    }

    func test_fallbackOrder() {
        XCTAssertEqual(CountdownEngine.fallbackOrder(for: .alarmKit), [.alarmKit, .notification, .liveActivity])
        XCTAssertEqual(CountdownEngine.fallbackOrder(for: .notification), [.notification, .liveActivity])
        XCTAssertEqual(CountdownEngine.fallbackOrder(for: .liveActivity), [.liveActivity])
    }

    func test_preferredAllowed_expectUsedWithoutPrompt() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .authorized

        let backend = await resolve(.alarmKit, recorder)

        XCTAssertEqual(backend, .alarmKit)
        XCTAssertTrue(recorder.requested.isEmpty)
    }

    func test_alarmDenied_notificationsNeverAsked_expectLiveActivityAndNoPrompt() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .denied
        recorder.statuses[.notification] = .notDetermined

        let backend = await resolve(.alarmKit, recorder)

        XCTAssertEqual(backend, .liveActivity)
        XCTAssertTrue(recorder.requested.isEmpty, "no surprise notification prompt")
    }

    func test_alarmDenied_notificationsAllowed_expectNotification() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .denied
        recorder.statuses[.notification] = .authorized

        let backend = await resolve(.alarmKit, recorder)

        XCTAssertEqual(backend, .notification)
        XCTAssertTrue(recorder.requested.isEmpty)
    }

    func test_preferredNeverAsked_expectPromptForItOnly() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .notDetermined
        recorder.grantsOnRequest = true

        let backend = await resolve(.alarmKit, recorder)

        XCTAssertEqual(backend, .alarmKit)
        XCTAssertEqual(recorder.requested, [.alarmKit])
    }

    func test_preferredRefusedAtPrompt_expectFallbackWithoutAnotherPrompt() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .notDetermined
        recorder.statuses[.notification] = .notDetermined
        recorder.grantsOnRequest = false

        let backend = await resolve(.alarmKit, recorder)

        XCTAssertEqual(backend, .liveActivity)
        XCTAssertEqual(recorder.requested, [.alarmKit], "only the chosen style is ever prompted for")
    }

    func test_notificationPreferredNeverAsked_expectPromptAndUse() async {
        let recorder = Recorder()
        recorder.statuses[.notification] = .notDetermined

        let backend = await resolve(.notification, recorder)

        XCTAssertEqual(backend, .notification)
        XCTAssertEqual(recorder.requested, [.notification])
    }

    func test_liveActivityPreferred_expectNoChecksOrPrompts() async {
        let recorder = Recorder()
        recorder.statuses[.alarmKit] = .authorized
        recorder.statuses[.notification] = .authorized

        let backend = await resolve(.liveActivity, recorder)

        XCTAssertEqual(backend, .liveActivity)
        XCTAssertTrue(recorder.requested.isEmpty)
    }
}
