//
//  PresetListViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import UIKit

final class PresetListViewCell: BaseTableViewCell {
    static let reuseIdentifier = "PresetListViewCell"
    var onPlayButtonTapped: (() -> Void)?

    var model: PresetModel? {
        didSet {
            applyModel()
        }
    }

    private let card = CatCardView()
    private let artwork = CatIllustrationView()

    let timerLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Preset name"
        return label
    }()

    let intervalDurationLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Routine"
        return label
    }()

    let intervalLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.footnote)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = "Total time"
        return label
    }()

    let playButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "play.fill")
        configuration.baseBackgroundColor = ColorOptions.neonBlue.color
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.isAccessibilityElement = true
        button.accessibilityLabel = "Start preset"
        return button
    }()

    let horizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        return stack
    }()

    let verticalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    override func setupSubviews() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addAutolayoutSubview(card)
        card.addAutolayoutSubview(horizontalStackView)
        horizontalStackView.addArrangedSubviews([artwork, verticalStackView, playButton])
        verticalStackView.addArrangedSubviews([timerLabel, intervalDurationLabel, intervalLabel])
        playButton.addAction(UIAction { [weak self] _ in
            self?.onPlayButtonTapped?()
        }, for: .touchUpInside)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            horizontalStackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            horizontalStackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            horizontalStackView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            horizontalStackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            artwork.widthAnchor.constraint(equalToConstant: 64),
            artwork.heightAnchor.constraint(equalToConstant: 90),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPlayButtonTapped = nil
        model = nil
    }

    private func applyModel() {
        timerLabel.text = model?.displayName
        intervalDurationLabel.text = model.map {
            "\(TimerConfigModel.durationSummary($0.totalDuration)) focus · \(TimerConfigModel.durationSummary($0.intervalDuration)) break · \($0.intervals) sessions"
        }
        intervalLabel.text = model.map {
            "Total: \(TimerConfigModel.durationSummary($0.configuration.totalDuration))"
        }
        timerLabel.accessibilityLabel = timerLabel.text
        intervalDurationLabel.accessibilityLabel = intervalDurationLabel.text
        intervalLabel.accessibilityLabel = intervalLabel.text
        artwork.pose = model?.catPose ?? .sitting
        playButton.accessibilityLabel = model.map { "Start \($0.displayName)" } ?? "Start preset"
        playButton.isEnabled = model?.configuration.isValid == true
    }
}
