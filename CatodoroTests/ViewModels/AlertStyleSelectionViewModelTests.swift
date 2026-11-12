//
//  AlertStyleSelectionViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

@MainActor
final class AlertStyleSelectionViewModelTests: XCTestCase {
    private var preferences: MockPreferences!
    private var countdown: MockCountdown!
    private var viewModel: AlertStyleSelectionViewModel!

    override func setUp() async throws {
        try await super.setUp()
        preferences = MockPreferences()
        countdown = MockCountdown()
        viewModel = AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown)
    }

    override func tearDown() async throws {
        viewModel = nil
        countdown = nil
        preferences = nil
        try await super.tearDown()
    }

    func test_init_expectAvailableStylesWithSavedOneSelected() {
        XCTAssertEqual(viewModel.options.map(\.id), AlertStyle.availableCases().map(\.rawValue))
        XCTAssertEqual(viewModel.selectedStyle, .liveActivity)
    }

    func test_selectLiveActivity_expectSavedWithoutAskingPermission() async throws {
        preferences.alertStyle = .notification
        viewModel = AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown)

        let result = await viewModel.selectOption(at: try index(of: .liveActivity))

        XCTAssertEqual(result, .saved(.liveActivity))
        XCTAssertEqual(preferences.alertStyle, .liveActivity)
        XCTAssertTrue(countdown.requestedBackends.isEmpty)
    }

    func test_selectAlarm_whenGranted_expectSaved() async throws {
        countdown.isAuthorized = true

        let result = await viewModel.selectOption(at: try index(of: .alarm))

        XCTAssertEqual(result, .saved(.alarm))
        XCTAssertEqual(countdown.requestedBackends, [AlertStyle.alarm.backend])
        XCTAssertEqual(preferences.alertStyle, .alarm)
        XCTAssertEqual(viewModel.selectedStyle, .alarm)
    }

    func test_selectNotification_whenDenied_expectPreviousChoiceKept() async throws {
        countdown.isAuthorized = false

        let result = await viewModel.selectOption(at: try index(of: .notification))

        XCTAssertEqual(result, .permissionDenied(.notification))
        XCTAssertEqual(countdown.requestedBackends, [AlertStyle.notification.backend])
        XCTAssertEqual(preferences.alertStyle, .liveActivity)
        XCTAssertEqual(viewModel.selectedStyle, .liveActivity)
    }

    func test_selectOption_outOfRange_expectIgnored() async {
        let result = await viewModel.selectOption(at: -1)

        XCTAssertEqual(result, .ignored)
        XCTAssertTrue(countdown.requestedBackends.isEmpty)
    }

    // MARK: Before iOS 26

    func test_withoutAlarmKit_expectAlarmOptionHidden() {
        viewModel = AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown, alarmKitAvailable: false)

        XCTAssertEqual(viewModel.options.map(\.id), [AlertStyle.notification.rawValue, AlertStyle.liveActivity.rawValue])
    }

    func test_withoutAlarmKit_savedAlarm_expectNotificationShownSelected() {
        preferences.alertStyle = .alarm

        viewModel = AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown, alarmKitAvailable: false)

        XCTAssertEqual(viewModel.selectedStyle, .notification)
        XCTAssertEqual(viewModel.options.filter(\.selected).count, 1)
    }

    func test_withAlarmKit_expectAllStylesOffered() {
        viewModel = AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown, alarmKitAvailable: true)

        XCTAssertEqual(viewModel.options.map(\.id), AlertStyle.allCases.map(\.rawValue))
    }

    private func index(of style: AlertStyle) throws -> Int {
        try XCTUnwrap(viewModel.options.firstIndex { $0.id == style.rawValue })
    }
}
