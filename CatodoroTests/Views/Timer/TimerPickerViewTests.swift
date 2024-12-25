import XCTest
@testable import Catodoro

class TimerPickerViewTests: XCTestCase {
    
    var view: TimerPickerView!
    
    override func setUp() {
        super.setUp()
        view = TimerPickerView()
    }
    
    override func tearDown() {
        view = nil
        super.tearDown()
    }

    // MARK: - Test for Configuration

    func test_configure_shouldSelectCorrectRows() {
        // Arrange
        let expectedHour = 2
        let expectedMinute = 30
        let expectedSecond = 45
        
        // Act
        view.configure(hour: expectedHour, minute: expectedMinute, second: expectedSecond)
        
        // Assert
        XCTAssertEqual(view.hours, expectedHour, "Hour should be selected correctly")
        XCTAssertEqual(view.minutes, expectedMinute, "Minute should be selected correctly")
        XCTAssertEqual(view.seconds, expectedSecond, "Second should be selected correctly")
    }
    
    // MARK: - Test for Event Handling
    
    func test_eventHandlers_shouldTriggerOnSelect() {
        // Arrange
        let totalDurationExpectation = XCTestExpectation(description: "Total duration picker onSelect should trigger.")
        
        // Set up closures to fulfill expectations
        view.onSelect = { hours, minutes, seconds in
            if hours == 2 && minutes == 30 && seconds == 45 {
                totalDurationExpectation.fulfill()
            }
        }
        
        // Act
        view.testHooks.hourPicker.onSelect?(2) // Simulate hour selection
        view.testHooks.minutePicker.onSelect?(30) // Simulate minute selection
        view.testHooks.secondPicker.onSelect?(45) // Simulate second selection
        
        // Assert
        wait(for: [totalDurationExpectation], timeout: 1.0)
    }

    // MARK: - Test for `handleOnSelect` (Internal method)

    func test_handleOnSelect_shouldCallOnSelect() {
        // Arrange
        let totalDurationExpectation = XCTestExpectation(description: "Total duration picker onSelect should trigger.")
        
        view.onSelect = { hours, minutes, seconds in
            if hours == 2 && minutes == 30 && seconds == 45 {
                totalDurationExpectation.fulfill()
            }
        }
        
        // Act
        view.testHooks.hourPicker.onSelect?(2)
        view.testHooks.minutePicker.onSelect?(30)
        view.testHooks.secondPicker.onSelect?(45)
        
        // Assert
        wait(for: [totalDurationExpectation], timeout: 1.0)
    }
    
    // MARK: - Test for `onSelect` being nil
    
    func test_handleOnSelect_shouldNotCrashWhenOnSelectIsNil() {
        // Arrange
        view.onSelect = nil
        
        // Act
        view.testHooks.hourPicker.onSelect?(2)
        view.testHooks.minutePicker.onSelect?(30)
        view.testHooks.secondPicker.onSelect?(45)
        
        // Assert
        // No assertion needed, we just want to ensure no crash occurs.
        XCTAssertTrue(true, "No crash should occur when onSelect is nil.")
    }
}
