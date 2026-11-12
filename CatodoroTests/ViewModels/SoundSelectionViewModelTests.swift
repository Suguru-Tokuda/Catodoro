//
//  SoundSelectionViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

final class SoundSelectionViewModelTests: XCTestCase {
    private struct PreviewError: Error {}

    private var preferences: MockPreferences!
    private var audioManager: MockAudioManager!
    private var viewModel: SoundSelectionViewModel!

    override func setUp() {
        super.setUp()
        preferences = MockPreferences()
        audioManager = MockAudioManager()
        viewModel = SoundSelectionViewModel(preferences: preferences, audioManager: audioManager)
    }

    override func tearDown() {
        viewModel = nil
        audioManager = nil
        preferences = nil
        super.tearDown()
    }

    func test_init_withNoSavedSound_expectDefaultSelected() {
        XCTAssertEqual(viewModel.options.map(\.id), SoundOptions.allCases.map(\.id))
        XCTAssertEqual(viewModel.selectedSound, .meowRegular)
    }

    func test_selectOption_expectSavedAndPreviewed() async throws {
        let index = try XCTUnwrap(viewModel.options.firstIndex { $0.id == SoundOptions.meowLoud.id })

        viewModel.selectOption(at: index)
        await flushAudioQueue()

        XCTAssertEqual(preferences.sound, SoundOptions.meowLoud.id)
        XCTAssertEqual(viewModel.selectedSound, .meowLoud)
        XCTAssertEqual(audioManager.commands, ["stop", "setup", "play"])
        XCTAssertEqual(audioManager.playedFileName, SoundOptions.meowLoud.fileName)
        XCTAssertEqual(audioManager.lastNumberOfLoops, 0)
    }

    func test_selectOption_whenPreviewFails_expectCallbackAndChoiceStillSaved() throws {
        audioManager.playbackError = PreviewError()
        let failed = expectation(description: "onPreviewFailed")
        viewModel.onPreviewFailed = { error in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertTrue(error is PreviewError)
            failed.fulfill()
        }
        let index = try XCTUnwrap(viewModel.options.firstIndex { $0.id == SoundOptions.hungry.id })

        viewModel.selectOption(at: index)

        wait(for: [failed], timeout: 1)
        XCTAssertEqual(preferences.sound, SoundOptions.hungry.id)
    }

    func test_stopPreview_expectStopSent() async {
        viewModel.stopPreview()
        await flushAudioQueue()

        XCTAssertEqual(audioManager.commands, ["stop"])
    }

    func test_initializeSoundOptionsWithUnknownId_expectDefaultSoundOption() {
        let sound = SoundOptions("unknown")

        XCTAssertEqual(sound, SoundOptions.meowRegular)
        XCTAssertEqual(sound.id, "meowRegular")
    }
}
