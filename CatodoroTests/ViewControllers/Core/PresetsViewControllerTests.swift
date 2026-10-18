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
    @MainActor
    func test_publishedPresetsReloadTableUsingIncomingSnapshot() throws {
        let model = MockPresetsViewModel()
        let controller = PresetsViewController(viewModel: model)
        controller.loadViewIfNeeded()
        let table = controller.testHooks.presetsTableView
        XCTAssertEqual(table.numberOfRows(inSection: 0), 0)

        let preset = PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300,
                                 intervals: 4, name: "Saved routine")
        model.presets = [preset]
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
        let cell = try XCTUnwrap(controller.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
            as? PresetListViewCell)
        XCTAssertEqual(cell.timerLabel.text, "Saved routine")

        model.presets = []
        XCTAssertEqual(table.numberOfRows(inSection: 0), 0)
        XCTAssertTrue(table.backgroundView is UIContentUnavailableView)
    }

    @MainActor
    func test_loadingSpinnerIsCenteredAndTerminalStatesRestoreTableBackground() throws {
        let view = PresetsView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        view.render(isEmpty: true, showLoading: true)
        view.layoutIfNeeded()
        let background = try XCTUnwrap(view.tableView.backgroundView)
        background.layoutIfNeeded()
        let spinner = try XCTUnwrap(background.subviews.compactMap { $0 as? UIActivityIndicatorView }.first)
        XCTAssertTrue(spinner.isAnimating)
        XCTAssertGreaterThan(spinner.bounds.width, 0)
        XCTAssertGreaterThan(spinner.bounds.height, 0)
        XCTAssertEqual(spinner.center.x, background.bounds.midX, accuracy: 0.5)
        XCTAssertEqual(spinner.center.y, background.bounds.midY, accuracy: 0.5)
        XCTAssertFalse(spinner.hasAmbiguousLayout)

        view.render(isEmpty: true, showLoading: false)
        XCTAssertFalse(spinner.isAnimating)
        XCTAssertTrue(view.tableView.backgroundView is UIContentUnavailableView)
        // A repeated stop must not erase the rendered empty state.
        view.hideLoading()
        XCTAssertTrue(view.tableView.backgroundView is UIContentUnavailableView)
        view.render(isEmpty: false, showLoading: false)
        XCTAssertNil(view.tableView.backgroundView)
    }

    @MainActor
    func test_presetsViewUsesSavedAccentAndRefreshesAfterPreferenceChanges() async throws {
        let preferences = MockPreferences()
        preferences.setColor(.neonPink)
        let controller = PresetsViewController(preferences: preferences, viewModel: MockPresetsViewModel())
        let model = MockPresetsViewModel()
        model.presets = [PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 4)]
        controller.testHooks.setViewModel(viewModel: model)
        controller.loadViewIfNeeded()
        XCTAssertTrue(controller.view is PresetsView)
        let table = controller.testHooks.presetsTableView
        let path = IndexPath(row: 0, section: 0)
        let initial = try XCTUnwrap(controller.tableView(table, cellForRowAt: path) as? PresetListViewCell)
        XCTAssertEqual(initial.playButton.configuration?.baseBackgroundColor, ColorOptions.neonPink.color)

        preferences.setColor(.neonPurple)
        let refreshed = expectation(description: "Accent publisher reaches the Presets screen")
        DispatchQueue.main.async { refreshed.fulfill() }
        await fulfillment(of: [refreshed], timeout: 1)
        let updated = try XCTUnwrap(controller.tableView(table, cellForRowAt: path) as? PresetListViewCell)
        XCTAssertEqual(updated.playButton.configuration?.baseBackgroundColor, ColorOptions.neonPurple.color)
        XCTAssertEqual(controller.view.tintColor, ColorOptions.neonPurple.color)
    }

    var sut: PresetsViewController!
    var mockDelegate: MockPresetsViewControllerDelegate!
    var mockViewModel: MockPresetsViewModel!

    override func setUp() {
        super.setUp()
        // Initialize the view controller
        sut = PresetsViewController(viewModel: MockPresetsViewModel())
        
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
        let tabs = TabCoordinator(preferences: nil, liveActivityManager: nil, coreDataManager: InMemoryPresetStore())
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
