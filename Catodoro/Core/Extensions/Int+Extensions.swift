//
//  Int+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/27/24.
//

import Foundation

extension Int {
    func getTimeStr() -> String {
        self < 10 ? "0\(self)" : String(self)
    }
}
