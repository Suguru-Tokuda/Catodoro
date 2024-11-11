//
//  UIView+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/27/24.
//

import UIKit

extension UIView {
    func addAutolayoutSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
    }

    func addAutolayoutSubviews(_ subviews: [UIView]) {
        subviews.forEach { addAutolayoutSubview($0) }
    }
}
