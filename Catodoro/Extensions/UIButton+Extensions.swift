//
//  UIButton+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/22/24.
//

import UIKit

extension UIButton {
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        let image = imageWithColor(color: color)
        self.setBackgroundImage(image, for: state)
    }

    private func imageWithColor(color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: .init(width: 1, height: 1))
        return renderer.image { context in
            color.setFill()
            context.fill(.init(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
