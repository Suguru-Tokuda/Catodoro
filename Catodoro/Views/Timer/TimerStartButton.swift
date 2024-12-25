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

    var model: Model? {
        didSet {
            applyModel()
        }
    }

    // MARK: - UI Components

    private let buttonLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
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
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    private func setupUI() {
        leadingImageView.tintColor = .white
        trailingImageView.tintColor = .white

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

        backgroundColor = .systemBlue
        setBackgroundColor(.systemBlue, for: .normal)
        setBackgroundColor(.systemGray, for: .disabled)
        clipsToBounds = true
        layer.cornerRadius = 16
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

    private func applyModel() {
        guard let model else { return }
        buttonLabel.text = model.buttonLabelText
        backgroundColor = model.color
        setBackgroundColor(model.color, for: .normal)
        setBackgroundColor(.lightGray, for: .disabled)
    }
}
