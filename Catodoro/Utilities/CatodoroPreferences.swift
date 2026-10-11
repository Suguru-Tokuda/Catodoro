//
//  CatodoroPreferences.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import Combine
import UIKit

protocol CatodoroPreferencesProtocol: AnyObject {
    var liveActivityEnabled: Bool { get }
    var liveActivityPublisher: AnyPublisher<Bool, Never> { get }
    func setLiveActivityEnabled(_ enabled: Bool)

    var colorPublisher: AnyPublisher<String?, Never> { get }
    var soundPublisher: AnyPublisher<String?, Never> { get }
    var color: String? { get }
    var sound: String? { get }
    func setColor(_ newColor: ColorOptions)
    func setSound(_ newSound: SoundOptions)
}

class CatodoroPreferences: CatodoroPreferencesProtocol {
    @Published private(set) var liveActivityEnabled: Bool
    @Published private(set) var color: String?
    @Published private(set) var sound: String?

    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        liveActivityEnabled = userDefaults.object(forKey: Keys.liveActivityEnabled.rawValue) as? Bool ?? true
        self.color = userDefaults.string(forKey: Keys.color.rawValue)
        self.sound = userDefaults.string(forKey: Keys.sound.rawValue)

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
    }

    deinit {
        cancellables.removeAll()
    }

    private enum Keys: String {
        case liveActivityEnabled
        case color
        case sound
    }

    var liveActivityPublisher: AnyPublisher<Bool, Never> {
        $liveActivityEnabled.eraseToAnyPublisher()
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

    // Expose publishers for color and sound as required by the protocol
    var colorPublisher: AnyPublisher<String?, Never> {
        $color.eraseToAnyPublisher()
    }

    var soundPublisher: AnyPublisher<String?, Never> {
        $sound.eraseToAnyPublisher()
    }
}
