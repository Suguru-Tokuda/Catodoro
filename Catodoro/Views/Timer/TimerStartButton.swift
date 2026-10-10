//
//  TimerStartButton.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerStartButton: UIButton {
    struct Model {
        let buttonLabelText: String
        let color: UIColor

        init(buttonLabelText: String = "Start",
             color: UIColor = ColorOptions.neonBlue.color) {
            self.buttonLabelText = buttonLabelText
            self.color = color
        }
    }

    var model: Model? = .init() {
        didSet {
            applyModel()
        }
    }

    // MARK: - UI Components

    private let buttonLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.title2, weight: .bold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = CatTheme.onAccent
        return label
    }()

    // Stack view to hold images and label
    let stackView = UIStackView()
    let leadingImageView: UIImageView
    let trailingImageView: UIImageView

    override init(frame: CGRect) {
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        let image = UIImage(systemName: "pawprint.fill")?.withConfiguration(imageConfig)

        // Set up leading and trailing images
        leadingImageView = UIImageView(image: image)
        trailingImageView = UIImageView(image: image)

        super.init(frame: frame)
        setupUI()
        setupConstraints()
        applyModel()
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    private func setupUI() {
        leadingImageView.tintColor = CatTheme.onAccent
        trailingImageView.tintColor = CatTheme.onAccent

        stackView.addArrangedSubviews([
            leadingImageView,
            buttonLabel,
            trailingImageView,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        stackView.isUserInteractionEnabled = false

        // Add the stack view as the button's cutstom view
        configuration?.contentInsets = .zero
        addAutolayoutSubview(stackView)

        backgroundColor = ColorOptions.neonBlue.color
        setBackgroundColor(ColorOptions.neonBlue.color, for: .normal)
        setBackgroundColor(CatTheme.disabled, for: .disabled)
        clipsToBounds = true
        layer.cornerRadius = CatTheme.controlRadius
        isEnabled = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            leadingImageView.heightAnchor.constraint(equalToConstant: 28),
            leadingImageView.widthAnchor.constraint(equalToConstant: 30),
            trailingImageView.heightAnchor.constraint(equalToConstant: 28),
            trailingImageView.widthAnchor.constraint(equalToConstant: 30),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyModel()
        }
    }

    private func applyModel() {
        guard let model else { return }
        buttonLabel.text = model.buttonLabelText
        accessibilityLabel = model.buttonLabelText
        backgroundColor = model.color
        traitCollection.performAsCurrent {
            setBackgroundColor(model.color, for: .normal)
            setBackgroundColor(CatTheme.disabled, for: .disabled)
        }
    }
}

#if DEBUG
extension TimerStartButton {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerStartButton

        var buttonLabel: UILabel { target.buttonLabel }
    }
}
#endif
