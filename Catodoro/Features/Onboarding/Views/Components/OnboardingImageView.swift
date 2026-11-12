//
//  OnboardingImageView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Decorative cat illustration at the top of an onboarding step.
final class OnboardingImageView: UIImageView {
    init(imageName: String, height: CGFloat = Spacing.space190) {
        super.init(image: UIImage(named: imageName))
        contentMode = .scaleAspectFit
        isAccessibilityElement = false
        heightAnchor.constraint(equalToConstant: height).isActive = true
    }

    required init?(coder: NSCoder) {
        nil
    }
}
