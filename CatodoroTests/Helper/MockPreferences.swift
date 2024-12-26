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
        color = newColor.rawValue
    }

    func setSound(_ newSound: SoundOptions) {
        sound = newSound.rawValue
    }
}
