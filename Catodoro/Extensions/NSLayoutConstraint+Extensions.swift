//
//  NSLayoutConstraint+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import UIKit

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
