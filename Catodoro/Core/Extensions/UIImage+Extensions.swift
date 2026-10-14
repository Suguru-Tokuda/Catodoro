//
//  UIImage+Extensions.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/2/24.
//

import UIKit

extension UIImage {
    func resizedTo(_ newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }
}
