//
//  OptionModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

/// One row on an option selection screen (color, sound, alert style).
struct OptionModel: Equatable {
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

extension Array where Element == OptionModel {
    /// The same options with only `id` marked as selected.
    func selecting(id: String) -> [OptionModel] {
        map { option in
            var option = option
            option.selected = option.id == id
            return option
        }
    }
}
