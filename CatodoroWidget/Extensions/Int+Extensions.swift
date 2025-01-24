//
//  Int+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/22/25.
//

import Foundation

extension Int {
    func getTimeStr() -> String {
        self < 10 ? "0\(self)" : String(self)
    }
}
