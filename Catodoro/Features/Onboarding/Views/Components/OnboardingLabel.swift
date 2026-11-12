//
//  OnboardingLabel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Centered, wrapping, Dynamic Type label used for onboarding copy.
final class OnboardingLabel: UILabel {
    init(text: String,
         style: UIFont.TextStyle,
         weight: UIFont.Weight = .regular,
         color: UIColor = CatTheme.text) {
        super.init(frame: .zero)
        self.text = text
        numberOfLines = 0
        textAlignment = .center
        font = CatTheme.font(style, weight: weight)
        adjustsFontForContentSizeCategory = true
        textColor = color
    }

    required init?(coder: NSCoder) {
        nil
    }
}
