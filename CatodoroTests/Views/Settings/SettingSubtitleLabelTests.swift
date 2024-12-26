//
//  SettingSubtitleLabelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class SettingSubtitleLabelTests: XCTestCase {

    func test_initialization_withDefaultText_expectEmptyText() {
        // Given
        let label = SettingSubtitleLabel()
        
        // Then
        XCTAssertEqual(label.text, "", "Default text should be an empty string")
        XCTAssertEqual(label.font, .systemFont(ofSize: 14, weight: .regular), "Font should match the default configuration")
    }

    func test_initialization_withProvidedText_expectTextToMatch() {
        // Given
        let expectedText = "Initial Text"
        
        // When
        let label = SettingSubtitleLabel(labelText: expectedText)
        
        // Then
        XCTAssertEqual(label.text, expectedText, "Label text should match the provided text")
        XCTAssertEqual(label.font, .systemFont(ofSize: 14, weight: .regular), "Font should match the default configuration")
    }

    func test_configure_withNewLabelText_expectTextToUpdate() {
        // Given
        let label = SettingSubtitleLabel()
        let newText = "Updated Text"
        
        // When
        label.configure(labelText: newText)
        
        // Then
        XCTAssertEqual(label.text, newText, "Label text should update to the configured text")
    }

    func test_requiredInitializer_expectNil() {
        // When
        let label = SettingSubtitleLabel(coder: NSCoder())
        
        // Then
        XCTAssertNil(label, "Initialization with NSCoder should return nil")
    }
}
