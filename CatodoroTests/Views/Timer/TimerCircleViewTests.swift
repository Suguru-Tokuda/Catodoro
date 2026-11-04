//
//  TimerCircleViewTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
import UIKit
@testable import Catodoro

final class TimerCircleViewTests: XCTestCase {
    func test_nonanimatedConfigurationClampsProgressAndRemovesAnimation() {
        let ring = TimerCircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        ring.configure(progress: 0.4)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 0.4, accuracy: 0.001)
        XCTAssertNil(ring.testHooks.shapeLayer.animationKeys())
        ring.configure(progress: 2)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 1)
        ring.configure(progress: -1)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 0)
    }

    func test_ringHasFlatEnds() {
        let ring = TimerCircleView(frame: .zero)
        XCTAssertEqual(ring.testHooks.shapeLayer.lineCap, .butt)
    }

    @MainActor
    func test_animatedProgressUpdatesModelAndCanBeStoppedImmediately() throws {
        let ring = TimerCircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        ring.configure(progress: 1)
        ring.configure(progress: 0.8, animated: true)
        let layer = ring.testHooks.shapeLayer
        XCTAssertEqual(layer.strokeEnd, 0.8, accuracy: 0.001)

        if UIAccessibility.isReduceMotionEnabled {
            XCTAssertNil(layer.animation(forKey: "progress"))
        } else {
            let animation = try XCTUnwrap(layer.animation(forKey: "progress") as? CABasicAnimation)
            XCTAssertEqual(animation.keyPath, "strokeEnd")
            XCTAssertEqual(animation.duration, 0.2, accuracy: 0.001)
            XCTAssertEqual(animation.toValue as? CGFloat, 0.8)
        }

        ring.configure(progress: 0.6)
        XCTAssertEqual(layer.strokeEnd, 0.6, accuracy: 0.001)
        XCTAssertNil(layer.animationKeys())
    }

    func test_ringRebuildsPathWhenBoundsChangeAndResolvesDarkAccent() {
        let ring = TimerCircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        ring.layoutIfNeeded()
        let smallPath = ring.testHooks.shapeLayer.path!.boundingBox
        ring.frame.size = CGSize(width: 300, height: 300)
        ring.overrideUserInterfaceStyle = .dark
        ring.setNeedsLayout()
        ring.layoutIfNeeded()
        XCTAssertGreaterThan(ring.testHooks.shapeLayer.path!.boundingBox.width, smallPath.width)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeColor,
                       ColorOptions.neonBlue.color.resolvedColor(with: ring.traitCollection).cgColor)
    }
}
