//
//  OptionSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

struct OptionModel {
    let id: String
    let title: String
    var selected: Bool
    let color: UIColor

    init(id: String, title: String, selected: Bool, color: UIColor = .label) {
        self.id = id
        self.title = title
        self.selected = selected
        self.color = color
    }
}

class OptionSelectionViewModel {
    var selectedId: String?
    var preferences: CatodoroPreferencesProtocol?
    var options: [OptionModel]

    init(options: [OptionModel]) {
        self.options = options
    }

    func setColor(colorCode: String) {
        preferences?.setColor(ColorOptions(colorCode))
        options = options.map { option in
            var option = option
            option.selected = option.id == colorCode
            return option
        }
    }

    func setSound(soundId: String) {
        preferences?.setSound(SoundOptions(soundId))
        options = options.map { option in
            var option = option
            option.selected = option.id == soundId
            return option
        }
    }
}
