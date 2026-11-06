//
//  NSLayoutConstraint+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import UIKit

extension NSLayoutConstraint {
    private func withPriority(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}
