//
//  TimerCircleView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/27/24.
//

import UIKit

class TimerCircleView: BaseView {
    private let shapeLayer = CAShapeLayer()
    private let trackLayer = CAShapeLayer()
    
    let lineWidth: CGFloat = 5
    var paursedTime: CFTimeInterval = 0
    let timerAnimationKey = "timerAnimation"
    var animation: CABasicAnimation?
    let strokeColor: UIColor

    init(frame: CGRect = .zero, strokeColor: UIColor = ColorOptions.neonBlue.color) {
        self.strokeColor = strokeColor
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func setupSubviews() {
        super.setupSubviews()
        let center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        let radius = min(frame.size.width, frame.size.height) / 2 - 10
        let startAngle: CGFloat = -.pi / 2
        let endAngle = 2 * CGFloat.pi + startAngle

        // Track Layer (Background circle)
        let trackPath = UIBezierPath(arcCenter: center,
                                     radius: radius,
                                     startAngle: startAngle,
                                     endAngle: endAngle,
                                     clockwise: true)
        trackLayer.path = trackPath.cgPath
        trackLayer.strokeColor = UIColor.lightGray.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .square
        layer.addSublayer(trackLayer)

        // Shape Layer (Animated circle)
        let shapePath = UIBezierPath(arcCenter: center,
                                     radius: radius,
                                     startAngle: startAngle,
                                     endAngle: endAngle,
                                     clockwise: true)
        shapeLayer.path = shapePath.cgPath
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineCap = .square
        shapeLayer.strokeEnd = 0 // Initially zero, to be animated
        layer.addSublayer(shapeLayer)
    }

    func startTimer(duration: TimeInterval) {
        animation = CABasicAnimation(keyPath: "strokeEnd")
        if let animation {
            animation.toValue = 1
            animation.duration = duration
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            animation.delegate = self
            shapeLayer.speed = 1.0
            shapeLayer.add(animation, forKey: timerAnimationKey)
        }
    }

    func restartTimer(duration: TimeInterval) {
        resetTimer()
        startTimer(duration: duration)
    }

    func pauseTimer() {
        let pausedTime = shapeLayer.convertTime(CACurrentMediaTime(), from: nil)
        shapeLayer.speed = 0.0
        shapeLayer.timeOffset = pausedTime
    }

    func resumeTimer() {
        let pausedTime = shapeLayer.timeOffset
        shapeLayer.speed = 1.0
        shapeLayer.timeOffset = 0.0
        shapeLayer.beginTime = 0.0
        let timeSincePause = shapeLayer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        shapeLayer.beginTime = timeSincePause
    }

    func resetTimer() {
        // remove existing animation if any
        shapeLayer.removeAnimation(forKey: timerAnimationKey)
        // reset strokeEnd to 0 (no progress)
        shapeLayer.strokeEnd = 0
        shapeLayer.speed = 0.0
    }
}

extension TimerCircleView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag, anim == shapeLayer.animation(forKey: timerAnimationKey) {
            // Ensure strokeEnd is set to 1 when the animation completes
            shapeLayer.strokeEnd = 1.0
        }
    }
}

#if DEBUG
extension TimerCircleView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerCircleView

        var shapeLayer: CAShapeLayer { target.shapeLayer }
    }
}
#endif
