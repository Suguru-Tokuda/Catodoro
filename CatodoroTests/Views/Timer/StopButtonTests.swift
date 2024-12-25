//
//  StopButtonTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

class StopButtonTests: XCTestCase {

    func test_init_shouldHaveCorrectImageConfiguration() {
        // Arrange
        let button = StopButton()

        // Act
        let image = button.image(for: .normal)

        // Assert
        XCTAssertNotNil(image, "Button should have an image for the normal state.")
        XCTAssertEqual(image?.size, CGSize(width: 80, height: 80), "Button image should be resized to 80x80.")
    }

    func test_init_shouldAddTargetForTouchUpInside() {
        // Arrange
        let button = StopButton()

        // Act
        let targets = button.allTargets
        let actions = button.actions(forTarget: button, forControlEvent: .touchUpInside)

        // Assert
        XCTAssertTrue(targets.contains(button), "Button should have itself as a target.")
        XCTAssertEqual(actions?.first, "handleButtonTap", "Button should call handleButtonTap on touch up inside.")
    }

    func test_handleButtonTap_shouldInvokeOnButtonTapClosure() {
        // Arrange
        let button = StopButton()
        let expectation = XCTestExpectation(description: "onButtonTap closure should be invoked")
        button.onButtonTap = {
            expectation.fulfill()
        }

        // Act
        button.sendActions(for: .touchUpInside)

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func test_buttonSize_shouldMatchConfiguredDimensions() {
        // Arrange
        let button = StopButton()

        // Act
        button.layoutIfNeeded() // Ensure layout updates

        // Assert
        XCTAssertEqual(button.buttonHeight, 80, "Button height should be 80.")
        XCTAssertEqual(button.buttonWidth, 80, "Button width should be 80.")
    }
}
