//
//  PawButtonTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/24/24.
//

import XCTest
@testable import Catodoro

class PawButtonTests: XCTestCase {
    func test_initWithCoder_expectNil() {
        let pawButton = PawButton(coder: .init())
        XCTAssertNil(pawButton)
    }

    func test_init_expectTitleIsSet() {
        // Given
        let title = "Test Title"

        // When
        let pawButton = PawButton(title: title)

        // Then
        XCTAssertEqual(pawButton.testHooks.label.text, title)
    }

    func test_stackView_expectContainsSubviews() {
        // Given
        let pawButton = PawButton(title: "Title")

        // When
        let stackSubviews = pawButton.testHooks.stackView.arrangedSubviews

        // Then
        XCTAssertTrue(stackSubviews.contains(pawButton.testHooks.label))
        XCTAssertTrue(stackSubviews.contains(pawButton.testHooks.pawImage))
    }

    func test_stackViewLayoutConstraints_expectCorrectConstraints() {
        // Given
        let pawButton = PawButton(title: "Title")

        // When
        let stackConstraints = pawButton.constraints.filter { constraint in
            constraint.firstItem === pawButton.testHooks.stackView
        }

        // Then
        XCTAssertTrue(stackConstraints.contains(where: { $0.firstAttribute == .top && $0.secondItem === pawButton }))
        XCTAssertTrue(stackConstraints.contains(where: { $0.firstAttribute == .bottom && $0.secondItem === pawButton }))
        XCTAssertTrue(stackConstraints.contains(where: { $0.firstAttribute == .leading && $0.secondItem === pawButton }))
        XCTAssertTrue(stackConstraints.contains(where: { $0.firstAttribute == .trailing && $0.secondItem === pawButton }))
    }

    func test_pawImageDimensions_expectCorrectSize() {
        // Given
        let pawButton = PawButton(title: "Title")

        // When
        let heightConstraint = pawButton.testHooks.pawImage.constraints.first { $0.firstAttribute == .height }
        let widthConstraint = pawButton.testHooks.pawImage.constraints.first { $0.firstAttribute == .width }

        // Then
        XCTAssertEqual(heightConstraint?.constant, 48)
        XCTAssertEqual(widthConstraint?.constant, 52)
    }

    func test_setColor_expectTintColorUpdated() {
        // Given
        let pawButton = PawButton(title: "Title")
        let testColor = UIColor.red

        // When
        pawButton.setColor(testColor, for: .normal)

        // Then
        XCTAssertEqual(pawButton.testHooks.pawImage.tintColor, testColor)
    }
}
