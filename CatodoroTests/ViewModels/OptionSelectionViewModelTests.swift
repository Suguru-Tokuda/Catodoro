//
//  OptionSelectionViewModelTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/24/24.
//

import XCTest
@testable import Catodoro
import UIKit

class OptionSelectionViewModelTests: XCTestCase {
    var viewModel: OptionSelectionViewModel!
    var mockPreferences: CatodoroPreferencesProtocol!
    var colorOptions: [OptionModel]!
    var soundOptions: [OptionModel]!
    
    override func setUp() {
        super.setUp()
        
        // Create mock preferences
        mockPreferences = PreferencesMock()
        
        // Create options for testing
        colorOptions = [
            OptionModel(id: ColorOptions.neonBlue.code, title: "Blue", selected: false),
            OptionModel(id: ColorOptions.neonGreen.code, title: "Green", selected: false),
            OptionModel(id: ColorOptions.neonOrange.code, title: "Orange", selected: false),
            OptionModel(id: ColorOptions.neonPink.code, title: "Pink", selected: false)
        ]
        
        soundOptions = [
            OptionModel(id: SoundOptions.angry.id, title: "Angry", selected: false),
            OptionModel(id: SoundOptions.meowLoud.id, title: "Meow (Loud)", selected: false),
            OptionModel(id: SoundOptions.meowRegular.id, title: "Meow (Regular)", selected: false),
            OptionModel(id: SoundOptions.hungry.id, title: "Hungry", selected: false)
        ]
        
        // Initialize the view model with options
        viewModel = OptionSelectionViewModel(options: colorOptions)
        viewModel.preferences = mockPreferences
    }
    
    override func tearDown() {
        viewModel = nil
        mockPreferences = nil
        colorOptions = nil
        soundOptions = nil
        super.tearDown()
    }
    
    func test_setColor_expectSelectionAndPreferencesUpdated() {
        viewModel.setColor(colorCode: "nGreen")
        
        // Test if the selected option is correctly updated
        XCTAssertTrue(viewModel.options.first(where: { $0.id == ColorOptions.neonGreen.code })?.selected ?? false)
        XCTAssertFalse(viewModel.options.first(where: { $0.id == ColorOptions.neonBlue.code })?.selected ?? true)
        
        // Test if preferences are updated
        XCTAssertEqual(mockPreferences.color, ColorOptions.neonGreen.rawValue)
    }
    
    func test_setSound_expectSelectionAndPreferencesUpdated() {
        viewModel.setSound(soundId: "meowLoud")
        
        // Test if preferences are updated
        XCTAssertEqual(mockPreferences.sound, SoundOptions.meowLoud.rawValue)
    }
    
    func test_initializeSoundOptionsWithUnknownId_expectDefaultSoundOption() {
        let sound = SoundOptions("unknown")
        
        XCTAssertEqual(sound, SoundOptions.meowRegular)  // Default value for unknown IDs
        XCTAssertEqual(sound.id, "meowRegular")
    }
    
    func test_initializeColorOptionsWithUnknownCode_expectDefaultColorOption() {
        let color = ColorOptions("unknown")
        
        XCTAssertEqual(color, ColorOptions.neonBlue)  // Default value for unknown codes
        XCTAssertEqual(color.code, "nBlue")
    }
}
