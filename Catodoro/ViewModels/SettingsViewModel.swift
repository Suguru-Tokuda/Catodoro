//
//  SettingsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import Foundation

struct SettingModel {
    let iconName: String
    let title: String
}

enum SettingOptions: String, CaseIterable {
    case color = "Color"
    case sound = "Sound"

    var iconName: String {
        switch self {
            case .color: return "paintbrush.fill"
            case .sound: return "speaker"
        }
    }
}

class SettingsViewModel {
    var selectedColorOption: ColorOptionModel?
    let settingOptions: [SettingModel]

    init(selectedColorOption: ColorOptionModel? = nil) {
        self.selectedColorOption = selectedColorOption
        var settingOptions: [SettingModel] = []
        SettingOptions.allCases.forEach {
            settingOptions.append(.init(iconName: $0.iconName, title: $0.rawValue))
        }
        self.settingOptions = settingOptions
    }
}
