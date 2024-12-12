//
//  OptionSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import Foundation

struct OptionModel {
    let id: String
    let title: String
    var selected: Bool
}

class OptionSelectionViewModel {
    var selectedId: String?
    var preferences: CatodoroPreferences?
    var options: [OptionModel]

    init(options: [OptionModel]) {
        self.options = options
    }

    func setColor(colorCode: String) {
        preferences?.color = colorCode
        options = options.map { option in
            var option = option
            option.selected = option.id == colorCode
            return option
        }
    }

    func setSound(soundId: String) {
        preferences?.sound = soundId
        options = options.map { option in
            var option = option
            option.selected = option.id == soundId
            return option
        }
    }
}
