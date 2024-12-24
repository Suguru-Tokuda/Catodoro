//
//  ColorOptions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

enum ColorOptions: String, CaseIterable {
    case neonBlue = "Blue"
    case neonGreen = "Green"
    case neonOrange = "Orange"
    case neonPink = "Pink"
    case neonPurple = "Purple"
    case neonYellow = "Yellow"

    init(_ code: String) {
        switch code {
        case "nBlue":
            self = .neonBlue
        case "nGreen":
            self = .neonGreen
        case "nOrange":
            self = .neonOrange
        case "nPink":
            self = .neonPink
        case "nPurple":
            self = .neonPurple
        case "nYellow":
            self = .neonYellow
        default:
            self = .neonBlue
        }
    }

    var code: String {
        switch self {
        case .neonBlue:
            "nBlue"
        case .neonGreen:
            "nGreen"
        case .neonOrange:
            "nOrange"
        case .neonPink:
            "nPink"
        case .neonPurple:
            "nPurple"
        case .neonYellow:
            "nYellow"
        }
    }

    var color: UIColor {
        switch self {
        case .neonBlue:
            .neonBlue
        case .neonGreen:
            .neonGreen
        case .neonOrange:
            .neonOrange
        case .neonPink:
            .neonPink
        case .neonPurple:
            .neonPurple
        case .neonYellow:
            .neonYellow
        }
    }
}
