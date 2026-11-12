//
//  AlertOnboardingViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import Foundation

/// Second onboarding step: asks for the permission that lets a phase ending
/// alert the user when Catodoro isn't on screen. On iOS 26 and later that's an
/// AlarmKit alarm; earlier versions use a notification.
///
/// Either answer (or "Not Now") finishes onboarding. When permission is granted
/// the matching alert style is saved; otherwise the default Live Activity style stays.
@MainActor
final class AlertOnboardingViewModel {
    enum Kind: Equatable {
        case alarm
        case notification

        /// What this device can use.
        static var current: Kind {
            if #available(iOS 26, *) {
                return .alarm
            } else {
                return .notification
            }
        }

        var alertStyle: AlertStyle {
            switch self {
            case .alarm: .alarm
            case .notification: .notification
            }
        }
    }

    let kind: Kind
    private(set) var isBusy = false
    var onStateChanged: (() -> Void)?
    var onComplete: (() -> Void)?

    private let countdown: CountdownControlling
    private let preferences: CatodoroPreferencesProtocol

    init(countdown: CountdownControlling,
         preferences: CatodoroPreferencesProtocol,
         kind: Kind = .current) {
        self.countdown = countdown
        self.preferences = preferences
        self.kind = kind
    }

    /// Shows the system permission prompt, saves the style if granted, then finishes.
    func allow() async {
        guard !isBusy else { return }
        isBusy = true
        onStateChanged?()

        let style = kind.alertStyle
        let granted = await countdown.requestAuthorization(for: style.backend)
        if granted {
            preferences.setAlertStyle(style)
        }

        isBusy = false
        onStateChanged?()
        finish()
    }

    /// Finishes without asking. The timer can still ask later if the user picks this style in Settings.
    func skip() {
        guard !isBusy else { return }
        finish()
    }

    private func finish() {
        // The sync step already saved the sync choice; this marks the whole flow done.
        preferences.completeOnboarding(syncEnabled: preferences.syncEnabled)
        onComplete?()
    }
}
