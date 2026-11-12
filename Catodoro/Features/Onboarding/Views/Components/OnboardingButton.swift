//
//  OnboardingButton.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Full-width onboarding action. The primary one is filled with the accent color;
/// the secondary one uses the selection color with accent text.
final class OnboardingButton: UIButton {
    enum Kind {
        case primary
        case secondary
    }

    let kind: Kind

    init(title: String, kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = kind == .primary ? CatTheme.accent(.neonBlue) : CatTheme.selection
        configuration.baseForegroundColor = kind == .primary ? CatTheme.onAccent : CatTheme.accent(.neonBlue)
        configuration.background.cornerRadius = CatTheme.controlRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: Spacing.space16, leading: Spacing.space12, bottom: Spacing.space16, trailing: Spacing.space12)
        self.configuration = configuration
        heightAnchor.constraint(greaterThanOrEqualToConstant: Spacing.space52).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }

    var titleText: String? {
        get { configuration?.title }
        set { configuration?.title = newValue }
    }

    /// Adds a tap handler.
    func onTap(_ handler: @escaping () -> Void) {
        addAction(UIAction { _ in handler() }, for: .touchUpInside)
    }
}
