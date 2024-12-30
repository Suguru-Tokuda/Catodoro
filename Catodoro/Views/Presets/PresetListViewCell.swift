//
//  PresetListViewCell.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/12/24.
//

import UIKit

class PresetListViewCell: UITableViewCell {
    static let reuseIdentifier = "PresetListViewCell"
    var onPlayButtonTapped: (() -> Void)?
    var model: PresetModel? {
        didSet {
            applyModel()
        }
    }

    // MARK: UI Components

    let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40, weight: .regular)
        label.isAccessibilityElement = true
        label.accessibilityLabel = "Timer"
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    let intervalDurationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .light)
        label.isAccessibilityElement = true
        label.accessibilityLabel = "Interval duration"
        return label
    }()

    let intervalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .light)
        label.isAccessibilityElement = true
        label.accessibilityLabel = "Intervals"
        return label
    }()

    let playButton: PlayPauseButton = {
        let button = PlayPauseButton(buttonHeight: 36,
                                     buttonWidth: 36,
                                     buttonStatus: .paused)
        button.isAccessibilityElement = true
        button.accessibilityLabel = "Play or Pause"
        return button
    }()
    let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        return stackView
    }()

    let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 4
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
        contentView.addAutolayoutSubview(horizontalStackView)
        horizontalStackView.addArrangedSubviews([
            verticalStackView,
            playButton
        ])
        verticalStackView.addArrangedSubviews([
            timerLabel,
            intervalDurationLabel,
            intervalLabel
        ])

        playButton.addTarget(self, action: #selector(handlePlayButtonTap), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            horizontalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            horizontalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            horizontalStackView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                     constant: 8).withPriority(.defaultHigh),
            horizontalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                        constant: -8).withPriority(.defaultLow),

            playButton.heightAnchor.constraint(equalToConstant: 32),
            playButton.widthAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func applyModel() {
        guard let model else { return }

        timerLabel.text = model.totalDuration.getTimerLabelValue()
        intervalDurationLabel.text = "Interval: \(model.intervalDuration.getTimerLabelValue())"
        intervalLabel.text = "Intervals: \(model.intervals)"
    }
}

extension PresetListViewCell {
    @objc private func handlePlayButtonTap() {
        onPlayButtonTapped?()
    }
}
