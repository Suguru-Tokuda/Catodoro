//
//  CatTheme.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import UIKit

/// Semantic colors resolve for the current system appearance; persisted accent codes stay unchanged.
enum CatTheme {
    static func color(_ light: UInt32, _ dark: UInt32) -> UIColor {
        UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light

            return UIColor(red: CGFloat((value >> 16) & 255) / 255,
                           green: CGFloat((value >> 8) & 255) / 255,
                           blue: CGFloat(value & 255) / 255, alpha: 1)
        }
    }

    static let background = color(0xFAF6EE, 0x201D24)
    static let card = color(0xFFFCF7, 0x302B33)
    static let text = color(0x35251F, 0xFFF3DF)
    static let secondaryText = color(0x756255, 0xC9BBAE)
    static let separator = color(0xE4D8CA, 0x514751)
    static let selection = color(0xE1EBE5, 0x344942)
    static let disabled = color(0xDDD5C9, 0x48414B)
    static let onAccent = color(0xFFFFFF, 0x152B27)

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    static let cardRadius: CGFloat = 24
    static let controlRadius: CGFloat = 18
    static let minimumTouchTarget: CGFloat = 44

    static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: style).pointSize, weight: weight)

        return UIFont(descriptor: base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor, size: base.pointSize)
    }

    private static let accents = [
        color(0x23676A, 0x80D7C4), color(0x456C47, 0xABD29C),
        color(0x9F4E27, 0xF0B182), color(0xA14364, 0xEDACBF),
        color(0x70538F, 0xC6B3EA), color(0x80601C, 0xE5CA83)
    ]

    static func accent(_ option: ColorOptions) -> UIColor {
        switch option {
        case .neonBlue: return accents[0]
        case .neonGreen: return accents[1]
        case .neonOrange: return accents[2]
        case .neonPink: return accents[3]
        case .neonPurple: return accents[4]
        case .neonYellow: return accents[5]
        }
    }
}
