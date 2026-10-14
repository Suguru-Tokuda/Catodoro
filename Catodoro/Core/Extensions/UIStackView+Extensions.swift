//
//  UIStackView+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/2/24.
//

import UIKit

extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
}
