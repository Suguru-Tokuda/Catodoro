//
//  TimerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerView: UIView {
    var onPlayPauseButtonTap: (() -> Void)?
    var onStopButtonTap: (() -> Void)?

    // MARK: - Class properties
    private let timerCircleDiameter: CGFloat = 250
    private let buttonSize: CGFloat = 40

    // MARK: - UI Elements

    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 16
        return stackView
    }()

    private var timerNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40, weight: .regular)
        return label
    }()

    /// UI Elements
    private var timerLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00:00"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 48, weight: .thin)
        return label
    }()

    private var timerCircleView: TimerCircleView
    private lazy var playPauseButton: PlayPauseButton = .init()
    private lazy var stopButton: StopButton = .init()

    init(frame: CGRect, strokeColor: UIColor = ColorOptions.neonBlue.color) {
        timerCircleView = .init(frame: .init(x: 0, y: 0, width: timerCircleDiameter, height: timerCircleDiameter),
                                strokeColor: strokeColor)
        super.init(frame: frame)
        setupActionHandlers()
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    private func setupSubviews() {
        addAutolayoutSubviews([
            timerNameLabel,
            timerCircleView,
            stackView,
            playPauseButton,
            stopButton
        ])

        stackView.addArrangedSubviews([
            timerLabel
        ])

        timerCircleView.setupCircleLayers()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timerNameLabel.bottomAnchor.constraint(equalTo: timerCircleView.topAnchor, constant: -8),
            timerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timerNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            timerCircleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            timerCircleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            timerCircleView.widthAnchor.constraint(equalToConstant: timerCircleDiameter),
            timerCircleView.heightAnchor.constraint(equalToConstant: timerCircleDiameter),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            timerLabel.widthAnchor.constraint(equalToConstant: 200),

            playPauseButton.topAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            playPauseButton.leadingAnchor.constraint(equalTo: timerCircleView.leadingAnchor),
            playPauseButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playPauseButton.widthAnchor.constraint(equalToConstant: buttonSize),

            stopButton.topAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            stopButton.trailingAnchor.constraint(equalTo: timerCircleView.trailingAnchor),
            stopButton.heightAnchor.constraint(equalToConstant: buttonSize),
            stopButton.widthAnchor.constraint(equalToConstant: buttonSize),
        ])
    }

    private func setupActionHandlers() {
        playPauseButton.onButtonTap = {
            self.onPlayPauseButtonTap?()
        }

        stopButton.onButtonTap = {
            self.onStopButtonTap?()
        }
    }
}

extension TimerView {
    func setTimerLabelText(labelText: String) {
        timerLabel.text = labelText
    }

    func setTimerNameLabelText(labelText: String) {
        timerNameLabel.text = labelText
    }

    func configurePlayPauseButton(timerStatus: TimerButtonStatus) {
        playPauseButton.configure(timerStatus: timerStatus)
    }

    func pauseTimer() {
        timerCircleView.pauseTimer()
    }

    func stopTimer() {
        timerCircleView.resetTimer()
    }

    func startTimer(duration: TimeInterval) {
        timerCircleView.startTimer(duration: duration)
    }

    func resumeTimer() {
        timerCircleView.resumeTimer()
    }
}

#if DEBUG
extension TimerView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerView

        var timerNameLabel: UILabel { target.timerNameLabel }
        var timerLabel: UILabel { target.timerLabel }
        var stackView: UIStackView { target.stackView }
        var timerCircleView: TimerCircleView { target.timerCircleView }
        var playPauseButton: PlayPauseButton { target.playPauseButton }
        var stopButton: StopButton { target.stopButton }
    }
}
#endif
