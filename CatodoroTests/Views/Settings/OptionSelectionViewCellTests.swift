//
//  OptionSelectionViewCellTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class OptionSelectionViewCellTests: XCTestCase {
    
    var cell: OptionSelectionViewCell!

    override func setUp() {
        super.setUp()
        cell = OptionSelectionViewCell(style: .default, reuseIdentifier: OptionSelectionViewCell.reuseIdentifier)
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func test_initialConfiguration_expectSubviewsToBeAdded() {
        XCTAssertNotNil(cell.contentView.subviews.contains(cell.testHooks.stackView), "StackView should be added to the contentView")
        XCTAssertTrue(cell.testHooks.stackView.arrangedSubviews.contains(cell.testHooks.optionLabel), "OptionLabel should be added to the stackView")
        XCTAssertTrue(cell.testHooks.stackView.arrangedSubviews.contains(cell.testHooks.selectedIcon), "CheckIcon should be added to the stackView")
    }

    func test_configure_whenSelected_expectCheckIconVisible() {
        // When
        cell.configure(optionLabelText: "Option 1", isSelected: true)
        
        // Then
        XCTAssertEqual(cell.testHooks.optionLabel.text, "Option 1", "OptionLabel text should be set correctly")
        XCTAssertEqual(cell.testHooks.selectedIcon.alpha, 1, "CheckIcon should be visible when selected")
    }

    func test_configure_whenNotSelected_expectCheckIconHidden() {
        // When
        cell.configure(optionLabelText: "Option 2", isSelected: false)
        
        // Then
        XCTAssertEqual(cell.testHooks.optionLabel.text, "Option 2", "OptionLabel text should be set correctly")
        XCTAssertEqual(cell.testHooks.selectedIcon.alpha, 0, "CheckIcon should be hidden when not selected")
    }

    func test_configure_withCustomTextColor_expectLabelAndIconToMatchColor() {
        // Given
        let customColor = UIColor.red
        
        // When
        cell.configure(optionLabelText: "Option 3", isSelected: true, textColor: customColor)
        
        // Then
        XCTAssertEqual(cell.testHooks.optionLabel.textColor, customColor, "OptionLabel text color should match the provided custom color")
        XCTAssertEqual(cell.testHooks.selectedIcon.tintColor, customColor, "CheckIcon tint color should match the provided custom color")
    }

    func test_dynamicResizing_expectCellHeightToAdjustForLongText() {
        // Given
        let tableView = UITableView()
        tableView.register(OptionSelectionViewCell.self, forCellReuseIdentifier: OptionSelectionViewCell.reuseIdentifier)
        
        // Configure cell
        let longText = String(repeating: "Long Text ", count: 20)
        cell.configure(optionLabelText: longText, isSelected: false)
        
        // Measure height
        let targetSize = CGSize(width: tableView.frame.width, height: UIView.layoutFittingCompressedSize.height)
        let height = cell.contentView.systemLayoutSizeFitting(targetSize).height
        
        // Assert
        XCTAssertGreaterThan(height, 44, "Cell height should increase to accommodate long text")
    }

    func test_accessibility_expectElementsAccessible() {
        // Given
        cell.configure(optionLabelText: "Option 4", isSelected: true)
        
        // Then
        XCTAssertTrue(cell.testHooks.optionLabel.isAccessibilityElement, "OptionLabel should be accessible")
        XCTAssertTrue(cell.testHooks.selectedIcon.isAccessibilityElement, "CheckIcon should be accessible")
        XCTAssertEqual(cell.testHooks.optionLabel.accessibilityLabel, "Option 4", "OptionLabel should have the correct accessibility label")
        XCTAssertEqual(cell.testHooks.selectedIcon.accessibilityLabel, "Selected", "CheckIcon should have the correct accessibility label when selected")
    }

    func test_accessibility_whenNotSelected_expectCheckIconToHaveCorrectAccessibilityLabel() {
        // Given
        cell.configure(optionLabelText: "Option 5", isSelected: false)
        
        // Then
        XCTAssertEqual(cell.testHooks.selectedIcon.accessibilityLabel, "Not Selected", "CheckIcon should have the correct accessibility label when not selected")
    }
}
