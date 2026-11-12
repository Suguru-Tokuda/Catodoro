//
//  ColorSelectionViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/24/24.
//

import XCTest
@testable import Catodoro

final class ColorSelectionViewModelTests: XCTestCase {
    private var preferences: MockPreferences!
    private var viewModel: ColorSelectionViewModel!

    override func setUp() {
        super.setUp()
        preferences = MockPreferences()
        preferences.color = ColorOptions.neonPink.code
        viewModel = ColorSelectionViewModel(preferences: preferences)
    }

    override func tearDown() {
        viewModel = nil
        preferences = nil
        super.tearDown()
    }

    func test_init_expectAllColorsWithSavedOneSelected() {
        XCTAssertEqual(viewModel.options.map(\.id), ColorOptions.allCases.map(\.code))
        XCTAssertEqual(viewModel.options.filter(\.selected).map(\.id), [ColorOptions.neonPink.code])
        XCTAssertEqual(viewModel.selectedColor, .neonPink)
    }

    func test_init_withNoSavedColor_expectDefaultSelected() {
        viewModel = ColorSelectionViewModel(preferences: MockPreferences())
        XCTAssertEqual(viewModel.selectedColor, .neonBlue)
    }

    func test_selectOption_expectSelectionAndPreferencesUpdated() throws {
        let index = try XCTUnwrap(viewModel.options.firstIndex { $0.id == ColorOptions.neonGreen.code })

        viewModel.selectOption(at: index)

        XCTAssertEqual(viewModel.options.filter(\.selected).map(\.id), [ColorOptions.neonGreen.code])
        XCTAssertEqual(preferences.color, ColorOptions.neonGreen.code)
    }

    func test_selectOption_outOfRange_expectNoChange() {
        viewModel.selectOption(at: viewModel.options.count)

        XCTAssertEqual(viewModel.selectedColor, .neonPink)
        XCTAssertEqual(preferences.color, ColorOptions.neonPink.code)
    }

    func test_initializeColorOptionsWithUnknownCode_expectDefaultColorOption() {
        let color = ColorOptions("unknown")

        XCTAssertEqual(color, ColorOptions.neonBlue)
        XCTAssertEqual(color.code, "nBlue")
    }
}
