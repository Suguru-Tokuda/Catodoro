//
//  SettingOptionsViewCellTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class SettingOptionsViewCellTests: XCTestCase {

    var cell: SettingOptionsViewCell!

    override func setUp() {
        super.setUp()
        cell = SettingOptionsViewCell(style: .default, reuseIdentifier: SettingOptionsViewCell.reuseIdentifier)
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func test_initialConfiguration_expectSubviewsToBeAdded() {
        XCTAssertTrue(cell.contentView.subviews.contains(cell.testHooks.icon), "Icon should be added to the contentView")
        XCTAssertTrue(cell.contentView.subviews.contains(cell.testHooks.settingLabel), "SettingLabel should be added to the contentView")
    }

    func test_configure_expectSettingLabelTextAndIconImageSetCorrectly() {
        // Given
        let settingText = "Test Setting"
        let iconName = "gearshape.fill"
        
        // When
        cell.configure(settingLabelText: settingText, iconName: iconName)
        
        // Then
        XCTAssertEqual(cell.testHooks.settingLabel.text, settingText, "SettingLabel text should match the configured text")
        XCTAssertEqual(cell.testHooks.icon.image, UIImage(systemName: iconName), "Icon image should match the configured system image name")
    }

    func test_dynamicResizing_expectCellHeightToAdjustForLongText() {
        // Given
        let tableView = UITableView()
        tableView.register(SettingOptionsViewCell.self, forCellReuseIdentifier: SettingOptionsViewCell.reuseIdentifier)
        
        // Configure cell
        let longText = String(repeating: "Long Setting Text ", count: 10)
        cell.configure(settingLabelText: longText, iconName: "gearshape.fill")
        
        // Measure height
        let targetSize = CGSize(width: tableView.frame.width, height: UIView.layoutFittingCompressedSize.height)
        let height = cell.contentView.systemLayoutSizeFitting(targetSize).height
        
        // Assert
        XCTAssertGreaterThan(height, 44, "Cell height should increase to accommodate long text in the setting label")
    }

    func test_accessibility_expectElementsToBeAccessible() {
        // Given
        let settingText = "Accessibility Setting"
        let iconName = "gearshape.fill"
        
        // When
        cell.configure(settingLabelText: settingText, iconName: iconName)
        
        // Then
        XCTAssertTrue(cell.testHooks.settingLabel.isAccessibilityElement, "SettingLabel should be accessible")
        XCTAssertEqual(cell.testHooks.settingLabel.accessibilityLabel, settingText, "SettingLabel accessibility label should match the text")
        
        XCTAssertTrue(cell.testHooks.icon.isAccessibilityElement, "Icon should be accessible")
        XCTAssertEqual(cell.testHooks.icon.accessibilityLabel, "gearshape.fill", "Icon accessibility label should match the system image name")
    }

    func test_accessibility_whenIconNameIsEmpty_expectIconToBeHiddenFromAccessibility() {
        // Given
        let settingText = "Hidden Icon Test"
        let iconName = ""
        
        // When
        cell.configure(settingLabelText: settingText, iconName: iconName)
        
        // Then
        XCTAssertFalse(cell.testHooks.icon.isAccessibilityElement, "Icon should still not be an accessibility element")
        XCTAssertNil(cell.testHooks.icon.image, "Icon should not have an image when iconName is empty")
        XCTAssertNil(cell.testHooks.icon.accessibilityLabel, "Icon accessibility label should be nil when no icon is provided")
    }
}
