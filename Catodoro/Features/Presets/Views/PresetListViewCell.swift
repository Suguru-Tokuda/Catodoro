//
//  PresetListViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import CatodoroShared
import UIKit

final class PresetListViewCell: BaseTableViewCell {
    static let reuseIdentifier = "PresetListViewCell"
    var onPlayButtonTapped: (() -> Void)?

    var accent: UIColor = ColorOptions.neonBlue.color {
        didSet {
            playButton.configuration?.baseBackgroundColor = accent
        }
    }

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
        label.accessibilityLabel = AppStrings.Common.presetName
        return label
    }()

    private let intervalDurationLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = AppStrings.Common.routine
        return label
    }()

    private let intervalLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.footnote)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityLabel = AppStrings.Common.totalTime
        return label
    }()

    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "play.fill")
        configuration.baseBackgroundColor = ColorOptions.neonBlue.color
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.isAccessibilityElement = true
        button.accessibilityLabel = AppStrings.Presets.startPreset
        return button
    }()

    private let horizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space12
        return stack
    }()

    private let verticalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space8
        return stack
    }()

    override func constructSubviews() {
        super.constructSubviews()
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

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.space16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.space16),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.space8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.space8),
            horizontalStackView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Spacing.space16),
            horizontalStackView.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -Spacing.space16),
            horizontalStackView.topAnchor.constraint(equalTo: card.topAnchor, constant: Spacing.space20),
            horizontalStackView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Spacing.space20),
            artwork.widthAnchor.constraint(equalToConstant: Spacing.space64),
            artwork.heightAnchor.constraint(equalToConstant: Spacing.space90),
            playButton.widthAnchor.constraint(equalToConstant: Spacing.space44),
            playButton.heightAnchor.constraint(equalToConstant: Spacing.space44)
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
            AppStrings.Presets.routineSummary(TimerConfigModel.durationSummary($0.totalDuration), TimerConfigModel.durationSummary($0.intervalDuration), $0.intervals)
        }
        intervalLabel.text = model.map {
            AppStrings.Presets.totalDuration(TimerConfigModel.durationSummary($0.configuration.totalDuration))
        }
        timerLabel.accessibilityLabel = timerLabel.text
        intervalDurationLabel.accessibilityLabel = intervalDurationLabel.text
        intervalLabel.accessibilityLabel = intervalLabel.text
        artwork.pose = model?.catPose ?? .sitting
        playButton.accessibilityLabel = model.map { AppStrings.Presets.startNamedPreset($0.displayName) } ?? AppStrings.Presets.startPreset
        playButton.isEnabled = model?.configuration.isValid == true
    }
}

#if DEBUG
extension PresetListViewCell {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: PresetListViewCell

        var intervalDurationLabel: UILabel { target.intervalDurationLabel }
        var intervalLabel: UILabel { target.intervalLabel }
        var playButton: UIButton { target.playButton }
        var horizontalStackView: UIStackView { target.horizontalStackView }
        var verticalStackView: UIStackView { target.verticalStackView }
    }
}
#endif
