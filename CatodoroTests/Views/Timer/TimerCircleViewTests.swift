//
//  TimerCircleViewTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class TimerCircleViewTests: XCTestCase {
    func test_ringUsesSuppliedProgressWithoutIndependentAnimation() {
        let ring = TimerCircleView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        ring.render(progress: 0.4)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 0.4, accuracy: 0.001)
        XCTAssertNil(ring.testHooks.shapeLayer.animationKeys())
        ring.render(progress: 2)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 1)
        ring.render(progress: -1)
        XCTAssertEqual(ring.testHooks.shapeLayer.strokeEnd, 0)
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
