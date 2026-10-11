//
//  TimerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerView: BaseView {
    var onPlayPauseButtonTap: (() -> Void)?
    var onStopButtonTap: (() -> Void)?
    var onDismissButtonTap: (() -> Void)?

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

    private let companion = CatIllustrationView(pose: .focus)
    private let artworkContainer = UIView()
    private let artworkMask = CAShapeLayer()
    private var timerCircleView: TimerCircleView
    private let playPauseButton: PlayPauseButton = .init()
    private let stopButton: StopButton = .init()
    private let dismissButton: DismissButton = {
        let button = DismissButton()
        button.isHidden = true
        return button
    }()

    init(frame: CGRect, strokeColor: UIColor = ColorOptions.neonBlue.color) {
        timerCircleView = .init(frame: .init(x: 0, y: 0, width: timerCircleDiameter, height: timerCircleDiameter),
                                strokeColor: strokeColor)
        super.init(frame: frame)
        setupActionHandlers()
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    override func setupSubviews() {
        addAutolayoutSubviews([
            timerNameLabel,
            artworkContainer,
            timerCircleView,
            stackView,
            playPauseButton,
            stopButton,
            dismissButton
        ])

        artworkContainer.isUserInteractionEnabled = false
        artworkContainer.layer.mask = artworkMask
        artworkContainer.addAutolayoutSubview(companion)

        stackView.addArrangedSubviews([
            timerLabel
        ])
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            timerNameLabel.bottomAnchor.constraint(equalTo: timerCircleView.topAnchor, constant: -8),
            timerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            timerNameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            timerCircleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            timerCircleView.centerYAnchor.constraint(equalTo: centerYAnchor),
            timerCircleView.widthAnchor.constraint(equalToConstant: timerCircleDiameter),
            timerCircleView.heightAnchor.constraint(equalToConstant: timerCircleDiameter),
            
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: timerCircleView.centerYAnchor, constant: -24),
            artworkContainer.leadingAnchor.constraint(equalTo: timerCircleView.leadingAnchor),
            artworkContainer.trailingAnchor.constraint(equalTo: timerCircleView.trailingAnchor),
            artworkContainer.topAnchor.constraint(equalTo: timerCircleView.topAnchor),
            artworkContainer.bottomAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            companion.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            companion.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor, constant: 30),
            companion.widthAnchor.constraint(equalTo: artworkContainer.widthAnchor, constant: 20),
            companion.heightAnchor.constraint(equalToConstant: 150),

            timerLabel.widthAnchor.constraint(equalToConstant: 200),

            playPauseButton.topAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            playPauseButton.leadingAnchor.constraint(equalTo: timerCircleView.leadingAnchor),
            playPauseButton.heightAnchor.constraint(equalToConstant: buttonSize),
            playPauseButton.widthAnchor.constraint(equalToConstant: buttonSize),

            stopButton.topAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            stopButton.trailingAnchor.constraint(equalTo: timerCircleView.trailingAnchor),
            stopButton.heightAnchor.constraint(equalToConstant: buttonSize),
            stopButton.widthAnchor.constraint(equalToConstant: buttonSize),

            dismissButton.topAnchor.constraint(equalTo: timerCircleView.bottomAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: timerCircleView.trailingAnchor),
            dismissButton.heightAnchor.constraint(equalToConstant: buttonSize),
            dismissButton.widthAnchor.constraint(equalToConstant: buttonSize),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Match the inner edge of the progress ring; only the illustration is clipped.
        let inset = 10 + timerCircleView.lineWidth / 2
        artworkMask.frame = artworkContainer.bounds
        artworkMask.path = UIBezierPath(ovalIn: artworkContainer.bounds.insetBy(dx: inset, dy: inset)).cgPath
    }

    private func setupActionHandlers() {
        playPauseButton.onButtonTap = { [weak self] in
            guard let self else { return }
            onPlayPauseButtonTap?()
        }

        stopButton.onButtonTap = { [weak self] in
            guard let self else { return }
            onStopButtonTap?()
        }

        dismissButton.onButtonTap = { [weak self] in
            guard let self else { return }
            onDismissButtonTap?()
        }
    }
}

extension TimerView {
    func setCompanion(isBreak: Bool) {
        companion.pose = isBreak ? .timerBreak : .focus
    }

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

    func setupStopDimissButtons(showStopButton: Bool) {
        stopButton.isHidden = !showStopButton
        dismissButton.isHidden = showStopButton
    }
}

#if DEBUG
extension TimerView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerView

        var artworkMask: CAShapeLayer { target.artworkMask }
        var companion: CatIllustrationView { target.companion }
        var artworkContainer: UIView { target.artworkContainer }
        var timerNameLabel: UILabel { target.timerNameLabel }
        var timerLabel: UILabel { target.timerLabel }
        var stackView: UIStackView { target.stackView }
        var timerCircleView: TimerCircleView { target.timerCircleView }
        var playPauseButton: PlayPauseButton { target.playPauseButton }
        var stopButton: StopButton { target.stopButton }
    }
}
#endif
