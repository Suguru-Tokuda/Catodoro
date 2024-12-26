//
//  BaseOptionSelectionViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class BaseOptionSelectionViewControllerTests: XCTestCase {

    var viewController: BaseOptionSelectionViewController!

    override func setUp() {
        super.setUp()
        // Create a new instance of the view controller with a title
        viewController = BaseOptionSelectionViewController(titleLabelText: "Test Title")
        
        // Load the view hierarchy
        _ = viewController.view
    }

    override func tearDown() {
        viewController = nil
        super.tearDown()
    }

    func test_initialization_withTitleText_expectTitleLabelTextToMatch() {
        // Given
        let expectedTitle = "Test Title"
        
        // When
        let titleLabelText = viewController.titleLabel.text
        
        // Then
        XCTAssertEqual(titleLabelText, expectedTitle, "Title label text should match the provided title")
    }

    func test_viewDidLoad_setsBackgroundColor_expectBackgroundColorToBeSystemBackground() {
        // When
        _ = viewController.view // Trigger viewDidLoad
        
        // Then
        XCTAssertEqual(viewController.view.backgroundColor, .systemBackground, "View background color should be system background")
    }

    func test_setupSubviews_expectSubviewsAddedToView() {
        // When
        _ = viewController.view // Trigger viewDidLoad
        
        // Then
        XCTAssertTrue(viewController.view.subviews.contains(viewController.titleLabel), "Title label should be added as a subview")
        XCTAssertTrue(viewController.view.subviews.contains(viewController.optionTableView), "Option table view should be added as a subview")
    }
}
