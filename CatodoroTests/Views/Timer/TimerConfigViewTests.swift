import XCTest
@testable import Catodoro

final class TimerConfigViewTests: XCTestCase {
    
    func test_initialSubviewsAreAddedAndConstrained() {
        // Arrange
        let view = TimerConfigView()
        
        // Act
        view.layoutIfNeeded()
        
        // Assert
        XCTAssertTrue(view.subviews.contains(view.testHooks.scrollView), "scrollView should be a subview.")
        XCTAssertTrue(view.testHooks.scrollView.subviews.contains(view.testHooks.stackView), "stackView should be a subview of scrollView.")
        XCTAssertTrue(view.testHooks.stackView.arrangedSubviews.contains(view.testHooks.totalDurationLabel), "totalDurationLabel should be arranged in stackView.")
        XCTAssertTrue(view.testHooks.stackView.arrangedSubviews.contains(view.testHooks.startButton), "startButton should be arranged in stackView.")
    }
    
    func test_defaultModel_shouldApplyToStartButton() {
        // Arrange
        let view = TimerConfigView()
        let defaultModel = TimerConfigView.Model()
        
        // Act
        view.model = defaultModel
        
        // Assert
        XCTAssertEqual(view.testHooks.startButton.model?.buttonLabelText, "Start", "Start button text should match the default model's startLabelText.")
        XCTAssertEqual(view.testHooks.startButton.model?.color, ColorOptions.neonBlue.color, "Start button color should match the default model's color.")
    }
    
    func test_settingModel_shouldUpdateStartButton() {
        // Arrange
        let view = TimerConfigView()
        let updatedModel = TimerConfigView.Model(startLabelText: "Go", color: .red)
        
        // Act
        view.model = updatedModel
        
        // Assert
        XCTAssertEqual(view.testHooks.startButton.model?.buttonLabelText, "Go", "Start button text should update to the new model's startLabelText.")
        XCTAssertEqual(view.testHooks.startButton.model?.color, .red, "Start button color should update to the new model's color.")
    }
    
    func test_startButtonTap_shouldTriggerClosure() {
        // Arrange
        let view = TimerConfigView()
        let expectation = XCTestExpectation(description: "Start button tap should trigger closure.")
        view.onStartButtonTap = { expectation.fulfill() }
        
        // Act
        view.testHooks.startButton.sendActions(for: .touchUpInside)
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_setStartButtonStatus_shouldUpdateIsEnabled() {
        // Arrange
        let view = TimerConfigView()
        
        // Act
        view.setStartButtonStatus(isEnabled: false)
        
        // Assert
        XCTAssertFalse(view.testHooks.startButton.isEnabled, "Start button should be disabled.")
        
        // Act
        view.setStartButtonStatus(isEnabled: true)
        
        // Assert
        XCTAssertTrue(view.testHooks.startButton.isEnabled, "Start button should be enabled.")
    }
    
    func test_eventHandlers_shouldPropagatePickerSelections() {
        // Arrange
        let view = TimerConfigView()
        
        let totalDurationExpectation = XCTestExpectation(description: "Total duration picker onSelect should trigger.")
        let intervalDurationExpectation = XCTestExpectation(description: "Interval duration picker onSelect should trigger.")
        let intervalExpectation = XCTestExpectation(description: "Interval picker onSelect should trigger.")

        view.onTotalDurationSelect = { _, _, _ in totalDurationExpectation.fulfill() }
        view.onIntervalDurationSelect = { _, _, _ in intervalDurationExpectation.fulfill() }
        view.onIntervalSelect = { _ in intervalExpectation.fulfill() }

        view.testHooks.setupEventHandlers() // Explicitly set up event handlers
        // Act
        view.testHooks.totalDurationPicker.onSelect?(1, 2, 3)
        view.testHooks.intervalDurationPicker.onSelect?(4, 5, 6)
        view.testHooks.intervalPicker.onSelect?(7)
        
        // Assert
        wait(for: [totalDurationExpectation, intervalDurationExpectation, intervalExpectation], timeout: 1.0)
    }
}
