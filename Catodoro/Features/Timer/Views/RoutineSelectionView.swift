//
//  RoutineSelectionView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import CatodoroShared
import UIKit

class RoutineSelectionView: BaseView {
    var onClose: (() -> Void)?
    var onConfirm: (() -> Void)?

    let scrollView = UIScrollView()

    let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space16

        return stack
    }()

    let explanationLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = ColorOptions.neonBlue.color
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = CatTheme.font(.headline, weight: .semibold)

            return updated
        }
        configuration.contentInsets = .init(top: Spacing.space16, leading: Spacing.space20, bottom: Spacing.space16, trailing: Spacing.space20)
        button.configuration = configuration
        button.titleLabel?.font = CatTheme.font(.headline)

        return button
    }()

    private let headerTitle: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.title3, weight: .bold)
        label.textColor = CatTheme.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityTraits = .header

        return label
    }()

    private let headerImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.isAccessibilityElement = false
        image.tintColor = CatTheme.color(0xD77840, 0xF0B182)

        return image
    }()

    private let imagePlate: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 36

        return view
    }()

    private let headerLabels: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space4
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = .init(top: 0, left: 0, bottom: 0, right: Spacing.space36)

        return stack
    }()

    private let headerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space12

        return stack
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.image = UIImage(systemName: "xmark")
        configuration.baseForegroundColor = CatTheme.text
        configuration.baseBackgroundColor = CatTheme.color(0xEFE5D8, 0x48414B)
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.accessibilityLabel = AppStrings.Common.close
        return button
    }()

    func configureHeader(title: String, subtitle: String, pose: CatPose? = nil) {
        headerTitle.text = title
        explanationLabel.text = subtitle
        headerImage.image = UIImage(named: pose?.rawValue ?? "CatPaw")
        imagePlate.backgroundColor = pose == nil ? CatTheme.color(0xFBE7D5, 0x4B352E) : .clear
    }

    func applyAccent(_ color: UIColor) {
        tintColor = color
        confirmButton.configuration?.baseBackgroundColor = color
    }

    override func constructView() {
        super.constructView()
        backgroundColor = CatTheme.background
    }

    override func constructSubviews() {
        super.constructSubviews()
        headerLabels.addArrangedSubviews([headerTitle, explanationLabel])
        headerStack.addArrangedSubviews([imagePlate, headerLabels])
        addAutolayoutSubviews([scrollView, confirmButton, closeButton])
        imagePlate.addAutolayoutSubview(headerImage)
        contentStack.addArrangedSubview(headerStack)
        scrollView.addAutolayoutSubview(contentStack)
        setupActions()
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Spacing.space20),
            closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Spacing.space12),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.space12),
            closeButton.widthAnchor.constraint(equalToConstant: Spacing.space44),
            closeButton.heightAnchor.constraint(equalToConstant: Spacing.space44),
            imagePlate.widthAnchor.constraint(equalToConstant: Spacing.space72),
            imagePlate.heightAnchor.constraint(equalToConstant: Spacing.space72),
            headerImage.centerXAnchor.constraint(equalTo: imagePlate.centerXAnchor),
            headerImage.centerYAnchor.constraint(equalTo: imagePlate.centerYAnchor),
            headerImage.widthAnchor.constraint(equalTo: imagePlate.widthAnchor, multiplier: 0.85),
            headerImage.heightAnchor.constraint(equalTo: imagePlate.heightAnchor, multiplier: 0.85),
            scrollView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -Spacing.space16),
            confirmButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.space16),
            confirmButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.space16),
            confirmButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.space16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.space16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.space24),
            contentStack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.space16 * 2),
            confirmButton.heightAnchor.constraint(greaterThanOrEqualToConstant: CatTheme.minimumTouchTarget)
        ])
    }

    private func setupActions() {
        closeButton.addAction(UIAction { [weak self] _ in
            self?.onClose?()
        }, for: .touchUpInside)

        confirmButton.addAction(UIAction { [weak self] _ in
            self?.onConfirm?()
        }, for: .touchUpInside)
    }
}
