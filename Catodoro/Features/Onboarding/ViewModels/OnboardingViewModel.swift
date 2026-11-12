//
//  OnboardingViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import CatodoroShared
import Foundation

/// First onboarding step: iCloud sync or this device only.
/// Saves the sync choice; `AlertOnboardingViewModel` marks onboarding complete
/// after the next step, so quitting in between shows the alert step again.
@MainActor
final class OnboardingViewModel {
    private let lifecycle: SyncLifecycleManaging
    private let preferences: CatodoroPreferencesProtocol
    private(set) var isBusy = false
    private(set) var errorMessage: String?
    var onStateChanged: (() -> Void)?
    var onComplete: (() -> Void)?

    init(
        lifecycle: SyncLifecycleManaging,
        preferences: CatodoroPreferencesProtocol
    ) {
        self.lifecycle = lifecycle
        self.preferences = preferences
    }

    func enableSync() async {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        onStateChanged?()
        defer {
            isBusy = false
            onStateChanged?()
        }

        do {
            try await lifecycle.setSyncEnabled(true)
            preferences.setSyncEnabled(true)
            onComplete?()
        } catch is CancellationError {
            // Superseded activation
        } catch {
            errorMessage = AppStrings.Onboarding.enableSyncError
        }
    }

    func continueLocally() async {
        guard !isBusy else { return }

        isBusy = true
        errorMessage = nil
        onStateChanged?()

        defer {
            isBusy = false
            onStateChanged?()
        }

        do {
            try await lifecycle.setSyncEnabled(false)
            preferences.setSyncEnabled(false)
            onComplete?()
        } catch is CancellationError {
            // Superseded request.
        } catch {
            errorMessage = AppStrings.Onboarding.updateSyncError
        }
    }
}
