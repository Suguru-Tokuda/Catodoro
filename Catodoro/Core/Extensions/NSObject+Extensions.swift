//
//  NSObject+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Foundation

extension NSObject {
    var className: String {
        get {
            return NSStringFromClass(type(of: self))
        }
    }
}
