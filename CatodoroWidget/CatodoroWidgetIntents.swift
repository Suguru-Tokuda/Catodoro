//
//  CatodoroWidgetIntents.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import AppIntents
import CatodoroShared

struct CatodoroWidgetIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [CatodoroSharedIntents.self] }
}
