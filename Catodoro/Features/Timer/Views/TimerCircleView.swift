//
//  TimerCircleView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/27/24.
//

import UIKit

/// The model supplies progress; the ring never runs its own countdown animation.
final class TimerCircleView: BaseView {
    private let shapeLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    let lineWidth: CGFloat = 16
    private let strokeColor: UIColor

    init(frame: CGRect = .zero, strokeColor: UIColor = ColorOptions.neonBlue.color) {
        self.strokeColor = strokeColor
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func constructSubviews() {
        isUserInteractionEnabled = false
        isAccessibilityElement = false

        for circle in [trackLayer, shapeLayer] {
            circle.fillColor = UIColor.clear.cgColor
            circle.lineWidth = lineWidth
            circle.lineCap = .round
            layer.addSublayer(circle)
        }

        shapeLayer.strokeEnd = 0
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: TimerCircleView, _: UITraitCollection) in
            view.setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = max(0, min(bounds.width, bounds.height) / 2 - 10 - lineWidth / 2)
        let path = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), radius: radius,
                                startAngle: -.pi / 2, endAngle: .pi * 1.5, clockwise: true)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.path = path.cgPath
        shapeLayer.path = path.cgPath
        trackLayer.strokeColor = CatTheme.selection.resolvedColor(with: traitCollection).cgColor
        shapeLayer.strokeColor = strokeColor.resolvedColor(with: traitCollection).cgColor
        CATransaction.commit()
    }

    func render(progress: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.strokeEnd = min(1, max(0, progress))
        CATransaction.commit()
    }
}

#if DEBUG
extension TimerCircleView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerCircleView

        var shapeLayer: CAShapeLayer {
            target.shapeLayer
        }
    }
}
#endif
