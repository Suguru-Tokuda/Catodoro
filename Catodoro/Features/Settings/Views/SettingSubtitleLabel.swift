//
//  SettingSubtitleLabel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class SettingSubtitleLabel: UILabel {
    init(labelText: String = "") {
        super.init(frame: .zero)
        text = labelText
        font = .systemFont(ofSize: 14, weight: .regular)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(labelText: String) {
        text = labelText
    }
}
