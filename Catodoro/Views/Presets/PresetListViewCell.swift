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

    let timerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .regular)
        return label
    }()
    let intervalDurationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .light)
        return label
    }()
    let intervalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .light)
        return label
    }()
    let playButton: PlayPauseButton = .init(buttonHeight: 36,
                                            buttonWidth: 36,
                                            buttonStatus: .paused)
    let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
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
