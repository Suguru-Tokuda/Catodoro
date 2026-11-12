//
//  SpacingTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import XCTest

final class SpacingTests: XCTestCase {
    func test_eachTokenMatchesItsName() {
        let tokens: [(CGFloat, CGFloat)] = [
            (Spacing.hairline, 0.5),
            (Spacing.space1, 1),
            (Spacing.space4, 4),
            (Spacing.space5, 5),
            (Spacing.space8, 8),
            (Spacing.space10, 10),
            (Spacing.space12, 12),
            (Spacing.space16, 16),
            (Spacing.space18, 18),
            (Spacing.space20, 20),
            (Spacing.space22, 22),
            (Spacing.space24, 24),
            (Spacing.space26, 26),
            (Spacing.space28, 28),
            (Spacing.space30, 30),
            (Spacing.space32, 32),
            (Spacing.space36, 36),
            (Spacing.space44, 44),
            (Spacing.space48, 48),
            (Spacing.space52, 52),
            (Spacing.space56, 56),
            (Spacing.space60, 60),
            (Spacing.space64, 64),
            (Spacing.space65, 65),
            (Spacing.space66, 66),
            (Spacing.space72, 72),
            (Spacing.space76, 76),
            (Spacing.space80, 80),
            (Spacing.space90, 90),
            (Spacing.space96, 96),
            (Spacing.space140, 140),
            (Spacing.space150, 150),
            (Spacing.space180, 180),
            (Spacing.space190, 190),
            (Spacing.space200, 200),
            (Spacing.space340, 340),
            (Spacing.space420, 420),
            (Spacing.space500, 500),
            (Spacing.space520, 520),
        ]
        for (token, value) in tokens {
            XCTAssertEqual(token, value)
        }
    }
}
