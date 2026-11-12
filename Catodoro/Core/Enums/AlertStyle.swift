//
//  AlertStyle.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import Foundation

enum AlertStyle: String, CaseIterable {
    case alarm
    case notification
    case liveActivity

    var title: String {
        switch self {
        case .alarm:
            return AppStrings.AlertStyles.alarmTitle
        case .notification:
            return AppStrings.AlertStyles.notificationTitle
        case .liveActivity:
            return AppStrings.AlertStyles.liveActivityTitle
        }
    }

    /// Shown in Settings under the alarm card title.
    var detail: String {
        switch self {
        case .alarm:
            return AppStrings.AlertStyles.alarmDetail
        case .notification:
            return AppStrings.AlertStyles.notificationDetail
        case .liveActivity:
            return AppStrings.AlertStyles.liveActivityDetail
        }
    }

    var backend: CycleSession.Backend {
        switch self {
        case .alarm:
            return .alarmKit
        case .notification:
            return .notification
        case .liveActivity:
            return .liveActivity
        }
    }

    var needsPermission: Bool { self != .liveActivity }

    // MARK: - Availability

    /// AlarmKit alarms need iOS 26 or later.
    static var isAlarmKitAvailable: Bool {
        if #available(iOS 26, *) {
            return true
        } else {
            return false
        }
    }

    func isAvailable(alarmKitAvailable: Bool = isAlarmKitAvailable) -> Bool {
        self == .alarm ? alarmKitAvailable : true
    }

    /// The styles this device can use, in display order. Hides `.alarm` before iOS 26.
    static func availableCases(alarmKitAvailable: Bool = isAlarmKitAvailable) -> [AlertStyle] {
        allCases.filter { $0.isAvailable(alarmKitAvailable: alarmKitAvailable) }
    }

    /// The style that actually runs here: a saved `.alarm` (e.g. restored from a
    /// newer device's backup) falls back to `.notification` before iOS 26.
    func resolved(alarmKitAvailable: Bool = isAlarmKitAvailable) -> AlertStyle {
        isAvailable(alarmKitAvailable: alarmKitAvailable) ? self : .notification
    }
}
