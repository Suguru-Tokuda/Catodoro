//
//  SettingsSelectionViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import UIKit
import XCTest
@testable import Catodoro

@MainActor
final class SettingsSelectionViewControllerTests: XCTestCase {
    private struct PreviewError: Error {}

    private var preferences: MockPreferences!
    private var spy: SelectionDelegateSpy!

    override func setUp() async throws {
        try await super.setUp()
        preferences = MockPreferences()
        spy = SelectionDelegateSpy()
    }

    override func tearDown() async throws {
        spy = nil
        preferences = nil
        try await super.tearDown()
    }

    // MARK: Color

    func test_colorScreen_listsColorsWithSavedOneSelected() throws {
        preferences.color = ColorOptions.neonOrange.code
        let screen = ColorSelectionViewController(viewModel: ColorSelectionViewModel(preferences: preferences),
                                                  titleLabelText: "Color")
        _ = screen.view

        XCTAssertEqual(screen.tableView(screen.optionTableView, numberOfRowsInSection: 0), ColorOptions.allCases.count)
        for (row, color) in ColorOptions.allCases.enumerated() {
            let cell = try XCTUnwrap(cell(row, in: screen))
            XCTAssertEqual(cell.testHooks.optionLabel.text, color.title)
            XCTAssertEqual(cell.testHooks.selectedIcon.alpha, color == .neonOrange ? 1 : 0, color.title)
        }
    }

    func test_colorScreen_selectingSavesThenAsksToFinish() async throws {
        let screen = ColorSelectionViewController(viewModel: ColorSelectionViewModel(preferences: preferences),
                                                  titleLabelText: "Color")
        screen.delegate = spy
        _ = screen.view
        let row = try XCTUnwrap(ColorOptions.allCases.firstIndex(of: .neonGreen))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))

        XCTAssertEqual(preferences.color, ColorOptions.neonGreen.code)
        XCTAssertEqual(cell(row, in: screen)?.testHooks.selectedIcon.alpha, 1)
        XCTAssertTrue(spy.events.isEmpty, "waits briefly so the selection is visible")
        await waitUntil { self.spy.events == ["colorFinish"] }
    }

    // MARK: Sound

    func test_soundScreen_selectingSavesAndPreviews() async throws {
        let audio = MockAudioManager()
        let screen = SoundSelectionViewController(viewModel: SoundSelectionViewModel(preferences: preferences,
                                                                                     audioManager: audio),
                                                  titleLabelText: "Sound")
        _ = screen.view
        let row = try XCTUnwrap(SoundOptions.allCases.firstIndex(of: .kitty))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))
        await flushAudioQueue()

        XCTAssertEqual(preferences.sound, SoundOptions.kitty.id)
        XCTAssertEqual(cell(row, in: screen)?.testHooks.selectedIcon.alpha, 1)
        XCTAssertEqual(audio.playedFileName, SoundOptions.kitty.fileName)
        XCTAssertEqual(audio.playCount, 1)
    }

    func test_soundScreen_doneAsksToFinish() throws {
        let screen = SoundSelectionViewController(viewModel: SoundSelectionViewModel(preferences: preferences,
                                                                                     audioManager: MockAudioManager()),
                                                  titleLabelText: "Sound")
        screen.delegate = spy
        _ = screen.view

        try tapDone(on: screen)

        XCTAssertEqual(spy.events, ["soundFinish"])
    }

    func test_soundScreen_wiresPreviewFailureCallback() throws {
        let audio = MockAudioManager()
        audio.playbackError = PreviewError()
        let viewModel = SoundSelectionViewModel(preferences: preferences, audioManager: audio)
        let screen = SoundSelectionViewController(viewModel: viewModel, titleLabelText: "Sound")

        _ = screen.view

        XCTAssertNotNil(viewModel.onPreviewFailed, "the screen shows an alert when a preview fails")
    }

    // MARK: Alert style

    func test_alertStyleScreen_listsStylesWithSavedOneSelected() throws {
        preferences.alertStyle = .notification
        let screen = alertStyleScreen(countdown: MockCountdown())

        XCTAssertEqual(screen.tableView(screen.optionTableView, numberOfRowsInSection: 0), AlertStyle.allCases.count)
        for (row, style) in AlertStyle.allCases.enumerated() {
            let cell = try XCTUnwrap(cell(row, in: screen))
            XCTAssertEqual(cell.testHooks.optionLabel.text, style.title)
            XCTAssertEqual(cell.testHooks.selectedIcon.alpha, style == .notification ? 1 : 0, style.rawValue)
        }
    }

    func test_alertStyleScreen_grantedPermission_expectSavedAndShown() async throws {
        let countdown = MockCountdown()
        countdown.isAuthorized = true
        let screen = alertStyleScreen(countdown: countdown)
        let row = try XCTUnwrap(AlertStyle.allCases.firstIndex(of: .alarm))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))

        await waitUntil { self.preferences.alertStyle == .alarm }
        await waitUntil { self.cell(row, in: screen)?.testHooks.selectedIcon.alpha == 1 }
    }

    func test_alertStyleScreen_deniedPermission_expectPreviousChoiceKept() async throws {
        let countdown = MockCountdown()
        countdown.isAuthorized = false
        let screen = alertStyleScreen(countdown: countdown)
        let alarmRow = try XCTUnwrap(AlertStyle.allCases.firstIndex(of: .alarm))
        let liveActivityRow = try XCTUnwrap(AlertStyle.allCases.firstIndex(of: .liveActivity))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: alarmRow, section: 0))

        await waitUntil { countdown.requestedBackends.count == 1 }
        await settle()
        XCTAssertEqual(preferences.alertStyle, .liveActivity)
        XCTAssertEqual(cell(alarmRow, in: screen)?.testHooks.selectedIcon.alpha, 0)
        XCTAssertEqual(cell(liveActivityRow, in: screen)?.testHooks.selectedIcon.alpha, 1)
    }

    func test_alertStyleScreen_tapsWhileAskingPermission_expectOneRequest() async throws {
        let countdown = MockCountdown()
        let screen = alertStyleScreen(countdown: countdown)
        let row = try XCTUnwrap(AlertStyle.allCases.firstIndex(of: .notification))

        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))
        screen.tableView(screen.optionTableView, didSelectRowAt: IndexPath(row: row, section: 0))

        await waitUntil { self.preferences.alertStyle == .notification }
        await settle()
        XCTAssertEqual(countdown.requestedBackends.count, 1)
    }

    func test_alertStyleScreen_doneAsksToFinish() throws {
        let screen = alertStyleScreen(countdown: nil)
        screen.delegate = spy

        try tapDone(on: screen)

        XCTAssertEqual(spy.events, ["alertStyleFinish"])
    }

    // MARK: Helpers

    private func alertStyleScreen(countdown: CountdownControlling?) -> AlertStyleSelectionViewController {
        let screen = AlertStyleSelectionViewController(
            viewModel: AlertStyleSelectionViewModel(preferences: preferences, countdown: countdown),
            titleLabelText: "Alarm"
        )
        _ = screen.view
        return screen
    }

    private func cell(_ row: Int, in screen: BaseOptionSelectionViewController & UITableViewDataSource) -> OptionSelectionViewCell? {
        screen.tableView(screen.optionTableView, cellForRowAt: IndexPath(row: row, section: 0)) as? OptionSelectionViewCell
    }

    private func tapDone(on screen: UIViewController) throws {
        let done = try XCTUnwrap(screen.navigationItem.rightBarButtonItem)
        let action = try XCTUnwrap(done.action)
        UIApplication.shared.sendAction(action, to: done.target, from: done, for: nil)
    }
}

private final class SelectionDelegateSpy: ColorSelectionViewControllerDelegate,
                                          SoundSelectionViewControllerDelegate,
                                          AlertStyleSelectionViewControllerDelegate {
    private(set) var events: [String] = []

    func colorSelectionViewControllerDidFinish(_ viewController: ColorSelectionViewController) { events.append("colorFinish") }
    func colorSelectionViewControllerDidClose(_ viewController: ColorSelectionViewController) { events.append("colorClose") }
    func soundSelectionViewControllerDidFinish(_ viewController: SoundSelectionViewController) { events.append("soundFinish") }
    func soundSelectionViewControllerDidClose(_ viewController: SoundSelectionViewController) { events.append("soundClose") }
    func alertStyleSelectionViewControllerDidFinish(_ viewController: AlertStyleSelectionViewController) { events.append("alertStyleFinish") }
    func alertStyleSelectionViewControllerDidClose(_ viewController: AlertStyleSelectionViewController) { events.append("alertStyleClose") }
}
