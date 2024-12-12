//
//  SoundOptions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import Foundation

enum SoundOptions: String, CaseIterable {
    case angry = "Angry"
    case meowLoud = "Meow (Loud)"
    case meowRegular = "Meow (Regular)"
    case hungry = "Hugnry"
    case kitty = "Kitty"

    var id: String {
        switch self {
        case .angry:
            "angry"
        case .meowLoud:
            "meowLoud"
        case .meowRegular:
            "meowRegular"
        case .hungry:
            "hungry"
        case .kitty:
            "kitty"
        }
    }

    var fileName: String {
        switch self {
        case .angry:
            "angry_cat"
        case .meowLoud:
            "cat_meow_loud"
        case .meowRegular:
            "cat_meow_regular"
        case .hungry:
            "hungry_cat"
        case .kitty:
            "kitty_meow"
        }
    }
}
