//
//  AlertStyleAvailabilityTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 11/11/26.
//

import XCTest
@testable import Catodoro

final class AlertStyleAvailabilityTests: XCTestCase {
    func test_isAlarmKitAvailable_expectTrueOnIOS26AndLater() {
        if #available(iOS 26, *) {
            XCTAssertTrue(AlertStyle.isAlarmKitAvailable)
        } else {
            XCTAssertFalse(AlertStyle.isAlarmKitAvailable)
        }
    }

    func test_availableCases_expectAlarmOnlyWithAlarmKit() {
        XCTAssertEqual(AlertStyle.availableCases(alarmKitAvailable: true), [.alarm, .notification, .liveActivity])
        XCTAssertEqual(AlertStyle.availableCases(alarmKitAvailable: false), [.notification, .liveActivity])
    }

    func test_resolved_expectAlarmFallsBackToNotificationWithoutAlarmKit() {
        XCTAssertEqual(AlertStyle.alarm.resolved(alarmKitAvailable: false), .notification)
        XCTAssertEqual(AlertStyle.alarm.resolved(alarmKitAvailable: true), .alarm)
        XCTAssertEqual(AlertStyle.notification.resolved(alarmKitAvailable: false), .notification)
        XCTAssertEqual(AlertStyle.liveActivity.resolved(alarmKitAvailable: false), .liveActivity)
    }

    func test_resolvedBackend_neverAlarmKitWithoutIt() {
        for style in AlertStyle.allCases {
            XCTAssertNotEqual(style.resolved(alarmKitAvailable: false).backend, .alarmKit, "\(style)")
        }
    }
}
