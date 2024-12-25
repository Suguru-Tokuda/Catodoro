//
//  TimePickerViewTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

class TimePickerViewTests: XCTestCase {

    func test_init_shouldInitializeTimeOptionsCorrectly() {
        // Arrange
        let minTime = 0
        let maxTime = 10
        let pickerView = TimePickerView(frame: .zero, min: minTime, max: maxTime)

        // Act
        let timeOptions = pickerView.timeOptions

        // Assert
        XCTAssertEqual(timeOptions.count, maxTime - minTime + 1, "Time options should include all integers between min and max inclusive.")
        XCTAssertEqual(timeOptions.first, minTime, "First time option should match the min value.")
        XCTAssertEqual(timeOptions.last, maxTime, "Last time option should match the max value.")
    }

    func test_numberOfRows_shouldMatchTimeOptionsCount() {
        // Arrange
        let pickerView = TimePickerView(frame: .zero, min: 0, max: 5)

        // Act
        let numberOfRows = pickerView.pickerView(pickerView, numberOfRowsInComponent: 0)

        // Assert
        XCTAssertEqual(numberOfRows, pickerView.timeOptions.count, "Number of rows should match the count of time options.")
    }

    func test_titleForRow_shouldReturnCorrectTitle() {
        // Arrange
        let pickerView = TimePickerView(frame: .zero, min: 0, max: 5)

        // Act
        let titleForRow = pickerView.pickerView(pickerView, titleForRow: 2, forComponent: 0)

        // Assert
        XCTAssertEqual(titleForRow, "2", "Title for row should return the correct string representation of the time option.")
    }

    func test_didSelectRow_shouldInvokeOnSelectClosure() {
        // Arrange
        let pickerView = TimePickerView(frame: .zero, min: 0, max: 5)
        let expectedSelection = 3
        let expectation = XCTestExpectation(description: "onSelect closure should be invoked with the correct time option")
        pickerView.onSelect = { selectedTime in
            XCTAssertEqual(selectedTime, expectedSelection, "onSelect should be invoked with the correct selected time.")
            expectation.fulfill()
        }

        // Act
        pickerView.pickerView(pickerView, didSelectRow: expectedSelection, inComponent: 0)

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func test_numberOfComponents_shouldAlwaysBeOne() {
        // Arrange
        let pickerView = TimePickerView(frame: .zero, min: 0, max: 5)

        // Act
        let numberOfComponents = pickerView.numberOfComponents(in: pickerView)

        // Assert
        XCTAssertEqual(numberOfComponents, 1, "Picker view should always have one component.")
    }
}
