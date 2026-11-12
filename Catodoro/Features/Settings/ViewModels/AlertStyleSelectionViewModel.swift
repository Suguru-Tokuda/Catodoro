//
//  AlertStyleSelectionViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation

/// Lists the alert styles this device supports (AlarmKit alarm on iOS 26+, notification, Live Activity only).
/// A style that needs a system permission is saved only once it's granted.
final class AlertStyleSelectionViewModel {
    enum SelectionResult: Equatable {
        case saved(AlertStyle)
        /// Denied now or earlier. iOS won't ask again, so the view offers Settings.
        /// The previous choice stays selected.
        case permissionDenied(AlertStyle)
        case ignored
    }

    private(set) var options: [OptionModel]
    private let preferences: CatodoroPreferencesProtocol?
    private let countdown: CountdownControlling?

    /// - Parameter alarmKitAvailable: Whether to offer `.alarm`; false before iOS 26.
    init(preferences: CatodoroPreferencesProtocol?,
         countdown: CountdownControlling?,
         alarmKitAvailable: Bool = AlertStyle.isAlarmKitAvailable) {
        self.preferences = preferences
        self.countdown = countdown
        let selectedStyle = (preferences?.alertStyle ?? .liveActivity).resolved(alarmKitAvailable: alarmKitAvailable)
        options = AlertStyle.availableCases(alarmKitAvailable: alarmKitAvailable).map {
            OptionModel(id: $0.rawValue, title: $0.title, selected: $0 == selectedStyle)
        }
    }

    var selectedStyle: AlertStyle? {
        options.first(where: \.selected).flatMap { AlertStyle(rawValue: $0.id) }
    }

    /// Main actor so `options` is only ever changed on the main thread.
    @MainActor
    func selectOption(at index: Int) async -> SelectionResult {
        guard options.indices.contains(index),
              let style = AlertStyle(rawValue: options[index].id) else {
            return .ignored
        }

        if style.needsPermission, let countdown {
            let granted = await countdown.requestAuthorization(for: style.backend)
            guard granted else { return .permissionDenied(style) }
        }

        preferences?.setAlertStyle(style)
        options = options.selecting(id: style.rawValue)
        return .saved(style)
    }
}
