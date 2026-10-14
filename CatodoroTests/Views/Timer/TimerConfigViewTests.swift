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
        XCTAssertTrue(view.testHooks.focusRow.isDescendant(of: view.testHooks.stackView), "totalDurationLabel should be arranged in stackView.")
        XCTAssertTrue(view.testHooks.stackView.arrangedSubviews.contains(view.testHooks.startButton), "startButton should be arranged in stackView.")
    }
    
    func test_defaultModel_shouldApplyToStartButton() {
        // Arrange
        let view = TimerConfigView()
        let defaultModel = TimerConfigView.Model()
        
        // Act
        view.model = defaultModel
        
        // Assert
        XCTAssertEqual(view.testHooks.startButton.model?.buttonLabelText, "Start focusing", "Start button text should match the default model's startLabelText.")
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
    
    func test_rowsRequestSelectionWithoutLayoutPass() {
        let view = TimerConfigView()
        var selections: [RoutineSelection] = []
        view.onSelectionRequest = { selections.append($0) }

        view.testHooks.focusRow.sendActions(for: .touchUpInside)
        view.testHooks.breakRow.sendActions(for: .touchUpInside)
        view.testHooks.sessionsRow.sendActions(for: .touchUpInside)

        XCTAssertEqual(selections, [.focus, .catnap, .sessions])
    }

    func test_renderUsesConfirmedRoutine() {
        let view = TimerConfigView()
        var routine = TimerConfigModel.standard
        view.render(routine)

        XCTAssertEqual(view.testHooks.focusRow.accessibilityValue, "25 min")
        XCTAssertEqual(view.testHooks.summaryLabel.text, "About 1 hr 55 min, including breaks.")
        XCTAssertTrue(view.testHooks.startButton.isEnabled)

        routine.interval = .init(hours: 0, minutes: 0, seconds: 0)
        view.render(routine)
        XCTAssertEqual(view.testHooks.breakRow.accessibilityValue, "No break")
        XCTAssertEqual(view.testHooks.summaryLabel.text, "About 1 hr 40 min of focus time.")
    }
}
