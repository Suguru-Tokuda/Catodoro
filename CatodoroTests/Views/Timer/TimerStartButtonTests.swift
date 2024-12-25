import XCTest
@testable import Catodoro

class TimerStartButtonTests: XCTestCase {

    var button: TimerStartButton!

    override func setUp() {
        super.setUp()
        button = TimerStartButton()
    }

    override func tearDown() {
        button = nil
        super.tearDown()
    }

    // MARK: - Test for Initial State
    
    func test_initialState_shouldBeDisabledAndHaveDefaultLabel() {
        // Assert
        XCTAssertFalse(button.isEnabled, "Button should be disabled by default")
        XCTAssertEqual(button.testHooks.buttonLabel.text, "Start", "Default label text should be 'Start'")
        XCTAssertEqual(button.backgroundColor, ColorOptions.neonBlue.color, "Default background color should be neon blue")
    }

    // MARK: - Test for Button Label and Color
    
    func test_applyModel_shouldSetButtonLabelAndColor() {
        // Arrange
        let model = TimerStartButton.Model(buttonLabelText: "Go", color: .green)

        // Act
        button.model = model

        // Assert
        XCTAssertEqual(button.testHooks.buttonLabel.text, "Go", "Button label should be 'Go'")
        XCTAssertEqual(button.backgroundColor, .green, "Background color should be green")
    }

    // MARK: - Test for Model Property Change
    
    func test_modelChange_shouldUpdateButtonLabelAndColor() {
        // Arrange
        let initialModel = TimerStartButton.Model(buttonLabelText: "Start", color: ColorOptions.neonBlue.color)
        let updatedModel = TimerStartButton.Model(buttonLabelText: "Pause", color: .orange)

        // Act
        button.model = initialModel
        button.model = updatedModel

        // Assert
        XCTAssertEqual(button.testHooks.buttonLabel.text, "Pause", "Button label should be 'Pause' after model change")
        XCTAssertEqual(button.backgroundColor, .orange, "Background color should be orange after model change")
    }

    // MARK: - Test for Button Disabled State
    
    func test_disabledState_shouldHaveCorrectBackgroundColor() {
        // Arrange
        button.isEnabled = false

        // Act
        button.layoutIfNeeded()  // Ensure UI updates

        // Assert
        let expectedColor = ColorOptions.neonBlue.color
        let actualColor = button.backgroundColor ?? .clear
        
        // Use a color comparison function to check if the colors are close enough
        XCTAssertEqual(expectedColor, actualColor, "Disabled button should have a light gray background")
    }
    
    // MARK: - Test for Image View Configuration
    
    func test_imageViews_shouldHaveCorrectTintColor() {
        // Assert
        XCTAssertEqual(button.leadingImageView.tintColor, .white, "Leading image view should have white tint color")
        XCTAssertEqual(button.trailingImageView.tintColor, .white, "Trailing image view should have white tint color")
    }

    // MARK: - Test Hooks (Private Component Access)
    
    func test_testHooks_shouldAllowAccessToButtonLabel() {
        // Act
        let label = button.testHooks.buttonLabel
        
        // Assert
        XCTAssertNotNil(label, "Test hooks should allow access to button label")
        XCTAssertEqual(label.font, .systemFont(ofSize: 28, weight: .bold), "Label font should be system font with size 28 and bold weight")
    }
}

extension TimerStartButtonTests {
    // Helper function to compare two colors with tolerance
    func colorsAreSimilar(_ color1: UIColor, _ color2: UIColor, tolerance: CGFloat = 0.1) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return abs(r1 - r2) < tolerance && abs(g1 - g2) < tolerance && abs(b1 - b2) < tolerance && abs(a1 - a2) < tolerance
    }
}
