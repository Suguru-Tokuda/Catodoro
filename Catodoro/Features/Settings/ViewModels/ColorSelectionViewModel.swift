//
//  ColorSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation

/// Lists the accent colors and saves the one the user picks.
final class ColorSelectionViewModel {
    private(set) var options: [OptionModel]
    private let preferences: CatodoroPreferencesProtocol?

    init(preferences: CatodoroPreferencesProtocol?) {
        self.preferences = preferences
        let selectedCode = ColorOptions(preferences?.color ?? "").code
        options = ColorOptions.allCases.map {
            OptionModel(id: $0.code, title: $0.title, selected: $0.code == selectedCode, color: $0.color)
        }
    }

    var selectedColor: ColorOptions? {
        options.first(where: \.selected).map { ColorOptions($0.id) }
    }

    func selectOption(at index: Int) {
        guard options.indices.contains(index) else { return }
        let color = ColorOptions(options[index].id)
        preferences?.setColor(color)
        options = options.selecting(id: color.code)
    }
}
