//
//  DeepLinkTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/12/26.
//

import CatodoroShared
import XCTest

final class DeepLinkTests: XCTestCase {
    func test_timerURL_expectCatodoroTimer() {
        XCTAssertEqual(DeepLink.timer.absoluteString, "catodoro://timer")
        XCTAssertTrue(DeepLink.isTimer(DeepLink.timer))
    }

    func test_isTimer_rejectsOtherHostsAndSchemes() throws {
        for string in ["catodoro://presets", "catodoro://", "https://timer", "other://timer"] {
            let url = try XCTUnwrap(URL(string: string))
            XCTAssertFalse(DeepLink.isTimer(url), string)
        }
    }

    func test_appRegistersTheScheme() throws {
        let types = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        XCTAssertTrue(schemes.contains(DeepLink.scheme))
    }
}
