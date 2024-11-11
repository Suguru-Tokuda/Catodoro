//
//  SettingsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import Foundation

class SettingsViewModel {
    var selectedColorOption: ColorOptionModel?
    let colorOptions: [ColorOptionModel]

    init(selectedColorOption: ColorOptionModel? = nil,
         colorOptions: [ColorOptionModel] = [
            .init(color: .neonBlue, colorName: "Blue"),
            .init(color: .neonGreen, colorName: "Green"),
            .init(color: .neonOrange, colorName: "Orange"),
            .init(color: .neonPink, colorName: "Pink"),
            .init(color: .neonPurple, colorName: "Purple"),
            .init(color: .yellow, colorName: "Yellow")
         ]) {
            self.selectedColorOption = selectedColorOption
            self.colorOptions = colorOptions

             if self.selectedColorOption == nil {
                 self.selectedColorOption = colorOptions.first
             }
    }
}
