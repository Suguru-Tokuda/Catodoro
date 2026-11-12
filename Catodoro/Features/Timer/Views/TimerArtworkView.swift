//
//  TimerArtworkView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/31/26.
//

import CatodoroShared
import UIKit

final class TimerArtworkView: BaseView {
    let artworkMask = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.mask = artworkMask
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        artworkMask.frame = bounds
        let inset: CGFloat = Spacing.space26
        let innerBounds = bounds.insetBy(dx: inset, dy: inset)
        artworkMask.path = innerBounds.width > 0 && innerBounds.height > 0
            ? UIBezierPath(ovalIn: innerBounds).cgPath : nil
    }
}
