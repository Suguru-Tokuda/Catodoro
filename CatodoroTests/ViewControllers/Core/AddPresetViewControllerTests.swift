//
//  AddPresetViewControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class AddPresetViewControllerTests: XCTestCase {

    var viewController: AddPresetViewController!
    var mockPreferences: MockPreferences!
    var mockCoordinator: MockCoordinator!
    var mockViewModel: MockTimerConfigViewModel!
    
    override func setUp() {
        super.setUp()
        
        // Mock preferences and coordinator
        mockPreferences = MockPreferences()
        mockCoordinator = MockCoordinator()
        
        // Mock view model
        mockViewModel = MockTimerConfigViewModel()
        
        // Initialize the view controller with the mock objects
        viewController = AddPresetViewController(preferences: mockPreferences)
        
        // Swap out the view model with the mock
        viewController.testHooks.setViewModel(viewModel: mockViewModel)
        
        // Load the view hierarchy
        _ = viewController.view
    }

    override func tearDown() {
        viewController = nil
        mockPreferences = nil
        mockCoordinator = nil
        mockViewModel = nil
        super.tearDown()
    }

    func test_viewDidLoad_setsUpSubviews() {
        // When
        _ = viewController.view // Trigger viewDidLoad
        
        // Then
        XCTAssertNotNil(viewController.view.subviews.first(where: { $0 is TimerConfigView }), "TimerConfigView should be added as a subview.")
        XCTAssertEqual(viewController.navigationItem.title, "Add Preset", "The navigation title should be set correctly.")
    }

    func test_onStartButtonTap_callsAddPreset() {
        let expectation = expectation(description: "Add Preset")
        // Given
        var didCallAddPreset = false
        mockViewModel.addPresetClosure = {
            didCallAddPreset = true
        }
        
        // When
        viewController.testHooks.timerConfigView.onStartButtonTap?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard self != nil else {
                XCTFail("self is nil")
                return
            }
            expectation.fulfill()
            // Then
            XCTAssertTrue(didCallAddPreset, "The addPreset method should be called when the start button is tapped.")
        }

        waitForExpectations(timeout: 1.0)
    }
}
