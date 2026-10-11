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

    @MainActor
    func test_presetTimerUsesPresetsNavigationStackWithoutSwitchingTabs() throws {
        let tabs = TabCoordinator(preferences: nil, liveActivityManager: nil)
        tabs.start()
        tabs.selectPage(.presets)
        let presets = try XCTUnwrap(tabs.presetsCoordiantor)
        let list = try XCTUnwrap(presets.navigationController.topViewController as? PresetsViewController)
        // The off-screen navigation controller does not receive its initial didShow callback.
        let navigation = try XCTUnwrap(presets.navigationController as? BaseNavigationController)
        navigation.isNewViewControllerBeingAdded = false
        let focusStackCount = tabs.timerCoordinator?.navigationController.viewControllers.count
        let preset = PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 4)

        presets.presetsViewControllerDidSelectPreset(list, preset: preset)

        XCTAssertEqual(tabs.currentPage(), .presets)
        XCTAssertTrue(presets.navigationController.topViewController is TimerViewController)
        XCTAssertEqual(tabs.timerCoordinator?.navigationController.viewControllers.count, focusStackCount)
        XCTAssertTrue(presets.navigationController.topViewController?.hidesBottomBarWhenPushed == true)
        XCTAssertEqual(presets.childCoordinators.count, 1)
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
    func presetsViewControllerDidRequestEdit(_ viewController: PresetsViewController, preset: PresetModel) {
        selectedPreset = preset
    }

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
