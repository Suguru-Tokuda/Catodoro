//
//  CatSummaryRow.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit

final class CatSummaryRow: UIControl {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.body, weight: .semibold)
        label.textColor = CatTheme.text
        label.textAlignment = .right
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = ColorOptions.neonBlue.color
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private let chevron: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = CatTheme.secondaryText
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()

    private let iconBadge = UIView()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = CatTheme.Spacing.medium
        stack.isUserInteractionEnabled = false

        return stack
    }()

    init(title: String, value: String, symbol: String) {
        super.init(frame: .zero)

        titleLabel.text = title
        valueLabel.text = value
        iconView.image = symbol == "CatPaw"
            ? UIImage(named: "CatPaw")?.withRenderingMode(.alwaysTemplate)
            : UIImage(systemName: symbol)
        iconBadge.backgroundColor = symbol == "cup.and.saucer.fill"
            ? CatTheme.selection : CatTheme.color(0xFBE6D4, 0x574037)
        iconBadge.layer.cornerRadius = 18
        iconBadge.addAutolayoutSubview(iconView)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        stack.addArrangedSubviews([iconBadge, titleLabel, valueLabel, chevron])
        addAutolayoutSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: CatTheme.minimumTouchTarget),
            iconBadge.widthAnchor.constraint(equalToConstant: 36),
            iconBadge.heightAnchor.constraint(equalToConstant: 36),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12)
        ])

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = title
        accessibilityValue = value
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configureAccent(_ color: UIColor) {
        iconView.tintColor = color
        iconBadge.backgroundColor = color.withAlphaComponent(0.18)
    }

    func setValue(_ value: String) {
        valueLabel.text = value
        accessibilityValue = value
    }
}
