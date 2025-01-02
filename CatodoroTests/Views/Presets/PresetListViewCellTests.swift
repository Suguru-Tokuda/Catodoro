//
//  PlayPauseButtonView.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

class PresetListViewCellTests: XCTestCase {
    
    var cell: PresetListViewCell!
    var mockModel: PresetModel!
    
    override func setUp() {
        super.setUp()
        cell = PresetListViewCell(style: .default, reuseIdentifier: PresetListViewCell.reuseIdentifier)
        mockModel = PresetModel(id: UUID(), totalDuration: 1500, intervalDuration: 300, intervals: 5)
    }
    
    override func tearDown() {
        cell = nil
        mockModel = nil
        super.tearDown()
    }
    
    func test_initialization_expectSubviewsInitialized() {
        XCTAssertNotNil(cell.timerLabel, "Timer label should be initialized")
        XCTAssertNotNil(cell.intervalDurationLabel, "Interval duration label should be initialized")
        XCTAssertNotNil(cell.intervalLabel, "Interval label should be initialized")
        XCTAssertNotNil(cell.playButton, "Play button should be initialized")
        XCTAssertNotNil(cell.horizontalStackView, "Horizontal stack view should be initialized")
        XCTAssertNotNil(cell.verticalStackView, "Vertical stack view should be initialized")
    }
    
    func test_applyModel_expectLabelsUpdatedCorrectly() {
        cell.model = mockModel
        
        XCTAssertEqual(cell.timerLabel.text, "00:25:00", "Timer label should display formatted total duration")
        XCTAssertEqual(cell.intervalDurationLabel.text, "Interval: 00:05:00", "Interval duration label should display formatted interval duration")
        XCTAssertEqual(cell.intervalLabel.text, "Intervals: 5", "Interval label should display the correct number of intervals")
    }
    
    func test_playButtonTap_expectOnPlayButtonTappedCalled() {
        var actionTriggered = false
        cell.onPlayButtonTapped = {
            actionTriggered = true
        }
        
        cell.playButton.sendActions(for: .touchUpInside)
        
        XCTAssertTrue(actionTriggered, "Play button action should be triggered")
    }
    
    func test_defaultStates_expectInitialLabelValuesNil() {
        XCTAssertNil(cell.timerLabel.text, "Timer label should be nil by default")
        XCTAssertNil(cell.intervalDurationLabel.text, "Interval duration label should be nil by default")
        XCTAssertNil(cell.intervalLabel.text, "Interval label should be nil by default")
    }
    
    func test_reusability_expectLabelsResetWhenModelCleared() {
        cell.model = mockModel
        XCTAssertEqual(cell.timerLabel.text, "00:25:00", "Timer label should be set after model is applied")
        
        cell.model = nil
        XCTAssertNotNil(cell.timerLabel.text, "Timer label should reset after model is cleared")
    }
    
    func test_accessibility_expectLabelsAndPlayButtonAccessible() {
        XCTAssertNotNil(cell.timerLabel.accessibilityLabel, "Timer label should have an accessibility label")
        XCTAssertNotNil(cell.intervalDurationLabel.accessibilityLabel, "Interval duration label should have an accessibility label")
        XCTAssertNotNil(cell.intervalLabel.accessibilityLabel, "Interval label should have an accessibility label")
        XCTAssertTrue(cell.playButton.isAccessibilityElement, "Play button should be accessible")
    }
}
