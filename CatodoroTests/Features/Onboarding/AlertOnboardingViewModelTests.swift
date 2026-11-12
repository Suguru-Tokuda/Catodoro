//
//  AlertOnboardingViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class AlertOnboardingViewModelTests: XCTestCase {
    private var preferences: MockPreferences!
    private var countdown: MockCountdown!

    override func setUp() async throws {
        try await super.setUp()
        preferences = MockPreferences()
        countdown = MockCountdown()
    }

    override func tearDown() async throws {
        countdown = nil
        preferences = nil
        try await super.tearDown()
    }

    func test_currentKind_expectAlarmOnIOS26AndLater() {
        if #available(iOS 26, *) {
            XCTAssertEqual(AlertOnboardingViewModel.Kind.current, .alarm)
        } else {
            XCTAssertEqual(AlertOnboardingViewModel.Kind.current, .notification)
        }
    }

    func test_kind_expectMatchingAlertStyle() {
        XCTAssertEqual(AlertOnboardingViewModel.Kind.alarm.alertStyle, .alarm)
        XCTAssertEqual(AlertOnboardingViewModel.Kind.notification.alertStyle, .notification)
    }

    func test_allowAlarm_whenGranted_expectAlarmKitAskedStyleSavedAndFinished() async {
        let model = makeModel(kind: .alarm)
        var completed = false
        model.onComplete = { completed = true }

        await model.allow()

        XCTAssertEqual(countdown.requestedBackends, [.alarmKit])
        XCTAssertEqual(preferences.alertStyle, .alarm)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertTrue(completed)
        XCTAssertFalse(model.isBusy)
    }

    func test_allowNotification_whenGranted_expectNotificationAskedAndSaved() async {
        let model = makeModel(kind: .notification)

        await model.allow()

        XCTAssertEqual(countdown.requestedBackends, [.notification])
        XCTAssertEqual(preferences.alertStyle, .notification)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
    }

    func test_allow_whenDenied_expectDefaultStyleKeptAndStillFinished() async {
        countdown.isAuthorized = false
        let model = makeModel(kind: .alarm)
        var completed = false
        model.onComplete = { completed = true }

        await model.allow()

        XCTAssertEqual(preferences.alertStyle, .liveActivity)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertTrue(completed)
    }

    func test_allow_reportsBusyWhileAsking() async {
        let model = makeModel(kind: .alarm)
        var busyStates: [Bool] = []
        model.onStateChanged = { busyStates.append(model.isBusy) }

        await model.allow()

        XCTAssertEqual(busyStates, [true, false])
    }

    func test_skip_expectNoPromptAndFinished() {
        let model = makeModel(kind: .alarm)
        var completed = false
        model.onComplete = { completed = true }

        model.skip()

        XCTAssertTrue(countdown.requestedBackends.isEmpty)
        XCTAssertEqual(preferences.alertStyle, .liveActivity)
        XCTAssertTrue(preferences.hasCompletedOnboarding)
        XCTAssertTrue(completed)
    }

    func test_finish_expectSyncChoiceFromFirstStepKept() {
        for syncEnabled in [true, false] {
            preferences = MockPreferences()
            preferences.setSyncEnabled(syncEnabled)
            let model = makeModel(kind: .alarm)

            model.skip()

            XCTAssertEqual(preferences.syncEnabled, syncEnabled)
            XCTAssertTrue(preferences.hasCompletedOnboarding)
        }
    }

    private func makeModel(kind: AlertOnboardingViewModel.Kind) -> AlertOnboardingViewModel {
        AlertOnboardingViewModel(countdown: countdown, preferences: preferences, kind: kind)
    }
}
