//
//  SettingsViewModel.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import ActivityKit
import Combine
import Foundation

struct SettingModel {
    let iconName: String
    let title: String
}

enum SettingOptions: String, CaseIterable {
    case color = "Color"
    case sound = "Sound"

    var iconName: String {
        switch self {
            case .color: return "paintbrush.fill"
            case .sound: return "speaker"
        }
    }
}

@MainActor
final class SettingsViewModel {
    struct State {
        var theme: ThemeOption = .system
        let color: ColorOptions
        let sound: SoundOptions
        let liveActivityEnabled: Bool
        let activitiesAuthorized: Bool
        var syncEnabled = false
        var syncAvailable = false
        var syncBusy = false
        var syncToggleEnabled = false
        var syncMessage = ""
    }

    @Published private(set) var state: State
    private let preferences: CatodoroPreferencesProtocol?
    private let activitiesAuthorized: () -> Bool
    private let syncLifecycleManager: SyncLifecycleManaging?
    private var syncBusy = false
    private var subscriptions = Set<AnyCancellable>()

    init(preferences: CatodoroPreferencesProtocol? = nil,
         activitiesAuthorized: @escaping () -> Bool = { ActivityAuthorizationInfo().areActivitiesEnabled },
         syncLifecycleManager: SyncLifecycleManaging? = nil) {
        self.syncLifecycleManager = syncLifecycleManager
        self.preferences = preferences
        self.activitiesAuthorized = activitiesAuthorized
        state = State(color: ColorOptions(preferences?.color ?? ""),
                      sound: SoundOptions(preferences?.sound ?? ""),
                      liveActivityEnabled: preferences?.liveActivityEnabled ?? true,
                      activitiesAuthorized: activitiesAuthorized())
        if let syncLifecycleManager {
            syncLifecycleManager.syncStatusPublisher.receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.refresh() }
                .store(in: &subscriptions)
        }
        refresh()
        if let preferences {
            preferences.themePublisher.receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.refresh() }
                .store(in: &subscriptions)
            preferences.colorPublisher.combineLatest(preferences.soundPublisher, preferences.liveActivityPublisher)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.refresh()
                }
                .store(in: &subscriptions)
        }
    }

    var statePublisher: AnyPublisher<State, Never> {
        $state.eraseToAnyPublisher()
    }

    func selectTheme(_ theme: ThemeOption) {
        preferences?.setTheme(theme)
        refresh()
    }

    func selectColor(_ option: ColorOptions) {
        preferences?.setColor(option)
        refresh()
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        preferences?.setLiveActivityEnabled(enabled)
        refresh()
    }

    func setSyncEnabled(_ enabled: Bool) async {
        guard !syncBusy, let syncLifecycleManager else { return }
        syncBusy = true
        refresh()
        defer { syncBusy = false; refresh() }
        do { try await syncLifecycleManager.setSyncEnabled(enabled) }
        catch { /* The lifecycle manager publishes the error. */ }
    }

    func refresh() {
        var next = State(color: ColorOptions(preferences?.color ?? ""),
                      sound: SoundOptions(preferences?.sound ?? ""),
                      liveActivityEnabled: preferences?.liveActivityEnabled ?? true,
                      activitiesAuthorized: activitiesAuthorized())
        next.syncAvailable = syncLifecycleManager != nil
        next.syncBusy = syncBusy
        let status = syncLifecycleManager?.syncStatus
        next.syncEnabled = status?.isAvailable == true && status?.isEnabled == true
        next.syncToggleEnabled = status?.isAvailable == true
            && status?.isCheckingAvailability == false && !syncBusy
        if status?.isCheckingAvailability == true {
            next.syncMessage = "Checking iCloud availability…"
        } else if let error = status?.errorMessage {
            next.syncMessage = error
        } else if status?.isAvailable != true {
            next.syncMessage = "Enable iCloud for Catodoro in iOS iCloud Settings to sync your presets."
        } else if status?.isSyncing == true {
            next.syncMessage = "Syncing presets with iCloud…"
        } else {
            next.syncMessage = next.syncEnabled
                ? "Presets sync automatically when iCloud is available."
                : "Presets stay on this device. Turn on iCloud to merge them with your other devices."
        }
        next.theme = preferences?.theme ?? .system
        state = next
    }
}
