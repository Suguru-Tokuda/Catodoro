//
//  CatodoroPreferences.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class CatodoroPreferences {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    private enum Keys: String {
        case color
        case sound
    }

    var color: String? {
        get {
            userDefaults.string(forKey: Keys.color.rawValue)
        }
        set {
            userDefaults.setValue(newValue, forKey: Keys.color.rawValue)
        }
    }

    var sound: String? {
        get {
            userDefaults.string(forKey: Keys.sound.rawValue)
        }
        set {
            userDefaults.setValue(newValue, forKey: Keys.sound.rawValue)
        }
    }
}
