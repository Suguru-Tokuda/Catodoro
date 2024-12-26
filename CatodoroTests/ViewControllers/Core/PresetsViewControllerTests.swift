//
//  PresetsViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
import Combine
@testable import Catodoro

class PresetsViewControllerTests: XCTestCase {
    var sut: PresetsViewController!
    var mockDelegate: MockPresetsViewControllerDelegate!
    var mockViewModel: MockPresetsViewModel!

    override func setUp() {
        super.setUp()
        // Initialize the view controller
        sut = PresetsViewController()
        
        // Create a mock delegate and set it
        mockDelegate = MockPresetsViewControllerDelegate()
        sut.delegate = mockDelegate
        
        // Create a mock view model and set it
        mockViewModel = MockPresetsViewModel()
        sut.testHooks.setViewModel(viewModel: mockViewModel)
        
        // Load the view
        _ = sut.view
    }

    override func tearDown() {
        sut = nil
        mockDelegate = nil
        mockViewModel = nil
        super.tearDown()
    }

    func testViewDidLoad() {
        // Verify if presets are loaded when the view is loaded
        XCTAssertNotNil(sut.testHooks.presetsTableView)
    }

    func test_didTapAddButton_expectDelegateMethodToBeCalled() {
        // Given an expectation that the add button tap will trigger the delegate method
        let expectation = self.expectation(description: "Add button tapped")
        
        mockDelegate.addButtonTappedExpectation = expectation
        
        // When the add button is tapped
        sut.testHooks.handleAddButtonTap()
        
        // Then the delegate method should be called
        waitForExpectations(timeout: 1, handler: nil)
    }
}

// MARK: - Mock Classes

class MockPresetsViewControllerDelegate: PresetsViewControllerDelegate {
    var selectedPreset: PresetModel?
    var addButtonTappedExpectation: XCTestExpectation?
    
    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel) {
        selectedPreset = preset
    }
    
    func presetsViewControllerDidTapAddButton(_ viewController: PresetsViewController, onFinish: @escaping (() -> Void)) {
        onFinish()
        addButtonTappedExpectation?.fulfill()
    }
}
