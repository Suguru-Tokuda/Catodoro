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

final class SettingsViewModel {
    struct State {
        let color: ColorOptions
        let sound: SoundOptions
        let liveActivityEnabled: Bool
        let activitiesAuthorized: Bool
    }

    @Published private(set) var state: State
    private let preferences: CatodoroPreferencesProtocol?
    private let activitiesAuthorized: () -> Bool
    private var subscriptions = Set<AnyCancellable>()

    init(preferences: CatodoroPreferencesProtocol? = nil,
         activitiesAuthorized: @escaping () -> Bool = { ActivityAuthorizationInfo().areActivitiesEnabled }) {
        self.preferences = preferences
        self.activitiesAuthorized = activitiesAuthorized
        state = State(color: ColorOptions(preferences?.color ?? ""),
                      sound: SoundOptions(preferences?.sound ?? ""),
                      liveActivityEnabled: preferences?.liveActivityEnabled ?? true,
                      activitiesAuthorized: activitiesAuthorized())
        if let preferences {
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

    func selectColor(_ option: ColorOptions) {
        preferences?.setColor(option)
        refresh()
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        preferences?.setLiveActivityEnabled(enabled)
        refresh()
    }

    func refresh() {
        state = State(color: ColorOptions(preferences?.color ?? ""),
                      sound: SoundOptions(preferences?.sound ?? ""),
                      liveActivityEnabled: preferences?.liveActivityEnabled ?? true,
                      activitiesAuthorized: activitiesAuthorized())
    }
}
