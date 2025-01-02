//
//  OptionSelectionViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class OptionSelectionViewCell: BaseTableViewCell {
    static let reuseIdentifier = "OptionSelectionViewCell"

    private var optionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()
    private var selectedIcon: UIImageView = {
        let icon = UIImageView(image: .init(systemName: "pawprint.fill"))
        icon.tintColor = .label
        return icon
    }()
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()

    override func setupSubviews() {
        contentView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([optionLabel, selectedIcon])
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            selectedIcon.widthAnchor.constraint(equalToConstant: 24),
            selectedIcon.heightAnchor.constraint(equalToConstant: 24),
        ])
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    func configure(optionLabelText: String, isSelected: Bool, textColor: UIColor = .label) {
        optionLabel.text = optionLabelText
        optionLabel.isAccessibilityElement = true
        optionLabel.accessibilityLabel = optionLabelText

        selectedIcon.alpha = isSelected ? 1 : 0
        selectedIcon.isAccessibilityElement = true
        selectedIcon.accessibilityLabel = isSelected ? "Selected" : "Not Selected"
        
        optionLabel.textColor = textColor
        selectedIcon.tintColor = textColor
    }
}

#if DEBUG
extension OptionSelectionViewCell {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: OptionSelectionViewCell

        var stackView: UIStackView { target.stackView }
        var optionLabel: UILabel { target.optionLabel }
        var selectedIcon: UIImageView { target.selectedIcon }
    }
}
#endif
