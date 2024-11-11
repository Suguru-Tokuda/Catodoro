//
//  ColorPickOptionViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class ColorPickOptionViewCell: UITableViewCell {
    static let reuseIdentifier: String = "ColorPickOptionViewCell"

    let colorLabel: UILabel = {
       let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()

    let pawImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "paw")
        return imageView
    }()

    func configure(colorName: String, color: UIColor) {
        colorLabel.textColor = color
        pawImageView.tintColor = color
        colorLabel.text = colorName
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.addAutolayoutSubviews([colorLabel, pawImageView])

        NSLayoutConstraint.activate([
            colorLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pawImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pawImageView.leadingAnchor.constraint(equalTo: colorLabel.trailingAnchor, constant: 8),
            pawImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        colorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        colorLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pawImageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        pawImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
