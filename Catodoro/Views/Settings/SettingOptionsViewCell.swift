//
//  SettingOptionsViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/9/24.
//

import UIKit

class SettingOptionsViewCell: UITableViewCell {
    static let reuseIdentifier: String = "SettingOptionsViewCell"
    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()
    private lazy var settingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        contentView.addAutolayoutSubviews([icon, settingLabel])
    }

    private func setupConstraints() {
        let bottomConstraint = settingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        bottomConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            settingLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 16),
            settingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
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
