//
//  OnboardingViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import Foundation

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
            preferences.completeOnboarding(syncEnabled: true)
            onComplete?()
        } catch is CancellationError {
            // Superseded activation
        } catch {
            errorMessage = "Couldn’t enable iCloud Sync. Please try again, or continue on this device."
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
            preferences.completeOnboarding(syncEnabled: false)
            onComplete?()
        } catch is CancellationError {
            // Superseded request.
        } catch {
            errorMessage = "Couldn't update sync settings. Please try again."
        }
    }
}
