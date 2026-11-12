//
//  CatodoroPreferences.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import CatodoroShared
import Combine
import UIKit

enum ThemeOption: String, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return AppStrings.Settings.systemTheme
        case .light: return AppStrings.Settings.lightTheme
        case .dark: return AppStrings.Settings.darkTheme
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

protocol CatodoroPreferencesProtocol: AnyObject {
    var theme: ThemeOption { get }
    var themePublisher: AnyPublisher<ThemeOption, Never> { get }
    func setTheme(_ theme: ThemeOption)

    var hasCompletedOnboarding: Bool { get }
    var syncEnabled: Bool { get }
    func setSyncEnabled(_ enabled: Bool)
    func completeOnboarding(syncEnabled: Bool)

    var liveActivityEnabled: Bool { get }
    var liveActivityPublisher: AnyPublisher<Bool, Never> { get }
    func setLiveActivityEnabled(_ enabled: Bool)

    var colorPublisher: AnyPublisher<String?, Never> { get }
    var soundPublisher: AnyPublisher<String?, Never> { get }
    var color: String? { get }
    var sound: String? { get }
    
    func setColor(_ newColor: ColorOptions)
    func setSound(_ newSound: SoundOptions)

    var alertStyle: AlertStyle { get }
    var alertStylePublisher: AnyPublisher<AlertStyle, Never> { get }
    func setAlertStyle(_ style: AlertStyle)
}

class CatodoroPreferences: CatodoroPreferencesProtocol {
    private enum Keys: String {
        case alertStyle
        case hasCompletedOnboarding
        case presetSyncEnabled
        case liveActivityEnabled
        case theme
        case color
        case sound
    }

    @Published private(set) var theme: ThemeOption
    @Published private(set) var liveActivityEnabled: Bool
    @Published private(set) var color: String?
    @Published private(set) var sound: String?
    @Published private(set) var alertStyle: AlertStyle
    
    var liveActivityPublisher: AnyPublisher<Bool, Never> {
        $liveActivityEnabled.eraseToAnyPublisher()
    }

    var alertStylePublisher: AnyPublisher<AlertStyle, Never> {
        $alertStyle.eraseToAnyPublisher()
    }

    var themePublisher: AnyPublisher<ThemeOption, Never> {
        $theme.eraseToAnyPublisher()
    }

    var colorPublisher: AnyPublisher<String?, Never> {
        $color.eraseToAnyPublisher()
    }

    var soundPublisher: AnyPublisher<String?, Never> {
        $sound.eraseToAnyPublisher()
    }

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        theme = ThemeOption(rawValue: userDefaults.string(forKey: Keys.theme.rawValue) ?? "") ?? .system
        liveActivityEnabled = userDefaults.object(forKey: Keys.liveActivityEnabled.rawValue) as? Bool ?? true
        self.color = userDefaults.string(forKey: Keys.color.rawValue)
        self.sound = userDefaults.string(forKey: Keys.sound.rawValue)
        alertStyle = AlertStyle(rawValue: userDefaults.string(forKey: Keys.alertStyle.rawValue) ?? "") ?? .liveActivity

        $theme
            .sink { [weak self] theme in
                self?.userDefaults.set(theme.rawValue, forKey: Keys.theme.rawValue)
            }
            .store(in: &cancellables)

        $liveActivityEnabled
            .sink { [weak self] enabled in
                self?.userDefaults.set(enabled, forKey: Keys.liveActivityEnabled.rawValue)
            }
            .store(in: &cancellables)

        // Sync changes back to UserDefaults when properties are updated.
        $color
            .sink { [weak self] newValue in
                self?.userDefaults.setValue(newValue, forKey: Keys.color.rawValue)
            }
            .store(in: &cancellables)

        $sound
            .sink { [weak self] newValue in
                self?.userDefaults.setValue(newValue, forKey: Keys.sound.rawValue)
            }
            .store(in: &cancellables)

        $alertStyle
            .sink { [weak self] newValue in
                self?.userDefaults.setValue(newValue.rawValue, forKey: Keys.alertStyle.rawValue)
            }
            .store(in: &cancellables)
    }

    deinit {
        cancellables.removeAll()
    }

    var hasCompletedOnboarding: Bool {
        userDefaults.bool(forKey: Keys.hasCompletedOnboarding.rawValue)
    }

    var syncEnabled: Bool {
        userDefaults.bool(forKey: Keys.presetSyncEnabled.rawValue)
    }

    func setSyncEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.presetSyncEnabled.rawValue)
    }

    func completeOnboarding(syncEnabled: Bool) {
        setSyncEnabled(syncEnabled)
        userDefaults.set(true, forKey: Keys.hasCompletedOnboarding.rawValue)
    }



    func setLiveActivityEnabled(_ enabled: Bool) {
        liveActivityEnabled = enabled
    }

    func setColor(_ newColor: ColorOptions) {
        color = newColor.code
    }

    func setSound(_ newSound: SoundOptions) {
        sound = newSound.id
    }

    func setTheme(_ theme: ThemeOption) {
        self.theme = theme
    }

    func setAlertStyle(_ style: AlertStyle) {
        self.alertStyle = style
    }
}
