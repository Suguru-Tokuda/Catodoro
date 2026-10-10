//
//  CatIllustrationView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

enum CatPose: String, CaseIterable {
    case sitting = "CatSitting"
    case sleeping = "CatSleeping"
    case stretching = "CatStretching"
    case playful = "CatPlayful"
    case focus = "CatFocus"
    case timerBreak = "CatBreak"
}

/// Decorative artwork uses original colors in both appearances and never intercepts touches.
final class CatIllustrationView: UIImageView {
    var pose: CatPose {
        didSet {
            image = UIImage(named: pose.rawValue)
        }
    }

    init(pose: CatPose = .sitting) {
        self.pose = pose
        super.init(image: UIImage(named: pose.rawValue))

        contentMode = .scaleAspectFit
        isAccessibilityElement = false
        isUserInteractionEnabled = false
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) {
        nil
    }
}
