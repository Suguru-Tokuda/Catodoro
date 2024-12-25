//
//  PlayPauseButtonTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/24/24.
//

import XCTest
@testable import Catodoro

class PlayPauseButtonTests: XCTestCase {
    var imageConfig: UIImage.SymbolConfiguration!

    override func setUp() {
        super.setUp()
        imageConfig = .init(weight: .thin)
    }

    override func tearDown() {
        imageConfig = nil
        super.tearDown()
    }

    func test_init_withDefaultValues() {
        // Given
        let defaultHeight: CGFloat = 80
        let defaultWidth: CGFloat = 80

        // When
        let button = PlayPauseButton()

        // Then
        XCTAssertEqual(button.buttonHeight, defaultHeight)
        XCTAssertEqual(button.buttonWidth, defaultWidth)
        XCTAssertNotNil(button.image(for: .normal))
    }

    func test_init_withCustomValues() {
        // Given
        let customHeight: CGFloat = 100
        let customWidth: CGFloat = 100

        // When
        let button = PlayPauseButton(buttonHeight: customHeight, buttonWidth: customWidth)

        // Then
        XCTAssertEqual(button.buttonHeight, customHeight)
        XCTAssertEqual(button.buttonWidth, customWidth)
    }

    func test_configure_withPlayingStatus() {
        // Given
        let button = PlayPauseButton()

        // When
        button.configure(timerStatus: .playing)
        let buttonImage = button.image(for: .normal)

        // Check if the image is the expected "pause" system image
        let expectedImage = UIImage(systemName: "pause")?
            .withConfiguration(button.config)
            .resizedTo(CGSize(width: button.buttonWidth,
                              height: button.buttonHeight))
            .withTintColor(.white)
        XCTAssertEqual(buttonImage?.size, expectedImage?.size, "Image size does not match the expected size")
        XCTAssertEqual(buttonImage?.renderingMode, expectedImage?.renderingMode, "Image rendering mode does not match")
    }

    func test_configure_withPausedStatus() {
        // Given
        let button = PlayPauseButton()

        // When
        button.configure(timerStatus: .paused)
        let buttonImage = button.image(for: .normal)


        // Check if the image is the expected "pause" system image
        let expectedImage = UIImage(systemName: "play")?
            .withConfiguration(button.config)
            .resizedTo(CGSize(width: button.buttonWidth,
                              height: button.buttonHeight))
            .withTintColor(.white)
        XCTAssertEqual(buttonImage?.size, expectedImage?.size, "Image size does not match the expected size")
        XCTAssertEqual(buttonImage?.renderingMode, expectedImage?.renderingMode, "Image rendering mode does not match")

    }

    func test_onButtonTap_callbackTriggered() {
        // Given
        let expectation = self.expectation(description: "Button tap triggers callback")
        let button = PlayPauseButton()
        button.onButtonTap = {
            expectation.fulfill()
        }

        // When
        button.sendActions(for: .touchUpInside)

        // Then
        waitForExpectations(timeout: 1.0)
    }
}
