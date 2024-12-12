//
//  OptionSelectionViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class OptionSelectionViewCell: UITableViewCell {
    static let reuseIdentifier = "OptionSelectionViewCell"

    private var optionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()
    private var checkIcon: UIImageView = {
        let icon = UIImageView(image: .init(systemName: "checkmark.circle"))
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
        contentView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([optionLabel, checkIcon])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            checkIcon.widthAnchor.constraint(equalToConstant: 24),
            checkIcon.heightAnchor.constraint(equalToConstant: 24),
        ])
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    func configure(optionLabelText: String, isSelected: Bool) {
        optionLabel.text = optionLabelText
        checkIcon.alpha = isSelected ? 1 : 0 
    }
}
