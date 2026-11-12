//
//  SettingOptionsViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/9/24.
//

import CatodoroShared
import UIKit

class SettingOptionsViewCell: BaseTableViewCell {
    static let reuseIdentifier: String = "SettingOptionsViewCell"
    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()
    private let settingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()

    override func constructSubviews() {
        super.constructSubviews()
        contentView.addAutolayoutSubviews([icon, settingLabel])
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        let bottomConstraint = settingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.space16)
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.space16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: Spacing.space24),
            icon.heightAnchor.constraint(equalToConstant: Spacing.space24),

            settingLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: Spacing.space16),
            settingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.space16),
            settingLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bottomConstraint
        ])
    }

    func configure(settingLabelText: String, iconName: String) {
        settingLabel.text = settingLabelText
        settingLabel.isAccessibilityElement = true
        settingLabel.accessibilityLabel = settingLabelText

        if let image = UIImage(systemName: iconName) {
            icon.image = image
            icon.isAccessibilityElement = true
            icon.accessibilityLabel = iconName
        } else {
            icon.image = nil
            icon.isAccessibilityElement = false
            icon.accessibilityLabel = nil
        }
    }
}

#if DEBUG
extension SettingOptionsViewCell {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: SettingOptionsViewCell

        var icon: UIImageView { target.icon }
        var settingLabel: UILabel { target.settingLabel }
    }
}
#endif
