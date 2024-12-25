import XCTest
@testable import Catodoro

final class TimerConfigSubTitleTests: XCTestCase {

    func test_initWithText_shouldSetTextAndFont() {
        // Arrange
        let expectedText = "Test Subtitle"
        let expectedFont = UIFont.systemFont(ofSize: 26, weight: .bold)
        
        // Act
        let subtitle = TimerConfigSubTitle(text: expectedText)
        
        // Assert
        XCTAssertEqual(subtitle.text, expectedText, "The label text should match the provided text.")
        XCTAssertEqual(subtitle.font, expectedFont, "The label font should be set to the expected bold system font.")
    }
    
    func test_initWithFrame_shouldSetDefaultFont() {
        // Arrange
        let expectedFont = UIFont.systemFont(ofSize: 26, weight: .bold)
        
        // Act
        let subtitle = TimerConfigSubTitle(frame: .zero)
        
        // Assert
        XCTAssertEqual(subtitle.font, expectedFont, "The label font should be set to the expected bold system font by default.")
    }
    
    func test_initWithCoder_shouldReturnNil() {
        // Act
        let subtitle = TimerConfigSubTitle(coder: NSCoder())
        
        // Assert
        XCTAssertNil(subtitle, "init(coder:) should return nil as it is not implemented.")
    }
}
