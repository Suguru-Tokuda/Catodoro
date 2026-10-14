//
//  PreferencesMock.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/23/24.
//

import Combine
import Foundation
@testable import Catodoro

// Mock implementation of CatodoroPreferencesProtocol
final class MockPreferences: CatodoroPreferencesProtocol {
    var theme: ThemeOption = .system {
        didSet { themeSubject.send(theme) }
    }
    private let themeSubject = CurrentValueSubject<ThemeOption, Never>(.system)
    var themePublisher: AnyPublisher<ThemeOption, Never> { themeSubject.eraseToAnyPublisher() }
    func setTheme(_ theme: ThemeOption) { self.theme = theme }

    var hasCompletedOnboarding = false
    var syncEnabled = false

    func setSyncEnabled(_ enabled: Bool) { syncEnabled = enabled }

    func completeOnboarding(syncEnabled: Bool) {
        self.syncEnabled = syncEnabled
        hasCompletedOnboarding = true
    }

    var liveActivityEnabled = true {
        didSet {
            liveActivitySubject.send(liveActivityEnabled)
        }
    }

    private let liveActivitySubject = CurrentValueSubject<Bool, Never>(true)

    var liveActivityPublisher: AnyPublisher<Bool, Never> {
        liveActivitySubject.eraseToAnyPublisher()
    }

    func setLiveActivityEnabled(_ enabled: Bool) {
        liveActivityEnabled = enabled
    }

    var color: String? {
        didSet {
            colorSubject.send(color)
        }
    }
    
    var sound: String? {
        didSet {
            soundSubject.send(sound)
        }
    }

    private let colorSubject = CurrentValueSubject<String?, Never>(nil)
    private let soundSubject = CurrentValueSubject<String?, Never>(nil)

    var colorPublisher: AnyPublisher<String?, Never> {
        colorSubject.eraseToAnyPublisher()
    }
    
    var soundPublisher: AnyPublisher<String?, Never> {
        soundSubject.eraseToAnyPublisher()
    }

    func setColor(_ newColor: ColorOptions) {
        color = newColor.code
    }

    func setSound(_ newSound: SoundOptions) {
        sound = newSound.id
    }
}
