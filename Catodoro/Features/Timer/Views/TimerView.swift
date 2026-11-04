//
//  TimerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import CatodoroShared
import UIKit

final class TimerView: BaseView {
    var onPlayPauseButtonTap: (() -> Void)?
    var onSkipBreakTap: (() -> Void)?
    var onStopButtonTap: (() -> Void)?
    var onDismissButtonTap: (() -> Void)?
    private var isComplete = false
    private let accent: UIColor
    private let timerCircleView: TimerCircleView
    private let companion = CatIllustrationView(pose: .focus)
    private let artworkContainer = TimerArtworkView()
    private let ringContainer = UIView()
    private var previousTimerState: TimerPresentationState?

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false

        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16

        return stack
    }()

    private let timerNameLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline, weight: .semibold)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let sessionLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.title3, weight: .semibold)
        label.textColor = CatTheme.text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let timerLabel: UILabel = {
        let label = UILabel()
        let font = UIFont.monospacedDigitSystemFont(ofSize: 56, weight: .bold)
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
        label.textColor = CatTheme.text
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.4
        label.accessibilityIdentifier = AccessibilityID.timerCountdown

        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let pawsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.isAccessibilityElement = true

        return stack
    }()

    private let pawIndicators: [UIImageView] = {
        (0..<6).map { _ in
            let image = UIImageView(image: UIImage(named: "CatPaw"))
            image.contentMode = .scaleAspectFit
            image.isAccessibilityElement = false
            image.widthAnchor.constraint(equalToConstant: 28).isActive = true
            image.heightAnchor.constraint(equalToConstant: 28).isActive = true

            return image
        }
    }()

    private let primaryButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        configuration.imagePadding = 10
        configuration.contentInsets = .init(top: 16, leading: 20, bottom: 16, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = CatTheme.font(.headline, weight: .semibold)

            return updated
        }
        button.configuration = configuration

        return button
    }()

    private let skipBreakButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(AppStrings.Common.skipBreak, for: .normal)
        button.titleLabel?.font = CatTheme.font(.body, weight: .semibold)
        button.isHidden = true
        button.accessibilityIdentifier = AccessibilityID.skipBreak
        return button
    }()

    private let secondaryButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.bordered()
        configuration.baseForegroundColor = CatTheme.secondaryText
        configuration.baseBackgroundColor = .clear
        configuration.background.strokeColor = CatTheme.separator
        configuration.background.strokeWidth = 1
        configuration.cornerStyle = .capsule
        configuration.imagePadding = 10
        configuration.contentInsets = .init(top: 16, leading: 20, bottom: 16, trailing: 20)
        button.configuration = configuration

        return button
    }()

    init(frame: CGRect, strokeColor: UIColor = ColorOptions.neonBlue.color) {
        self.accent = strokeColor
        self.timerCircleView = TimerCircleView(strokeColor: strokeColor)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func constructSubviews() {
        super.constructSubviews()
        backgroundColor = CatTheme.background
        constructScrollContent()
        constructRingContent()
        constructControls()
        addActions()
    }

    private func constructScrollContent() {
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([
            timerNameLabel, sessionLabel, ringContainer, pawsStack, messageLabel,
            primaryButton, skipBreakButton, secondaryButton
        ])
        stackView.setCustomSpacing(4, after: timerNameLabel)
        stackView.setCustomSpacing(28, after: messageLabel)
    }

    private func constructRingContent() {
        ringContainer.addAutolayoutSubviews([artworkContainer, timerCircleView, timerLabel, statusLabel])
        artworkContainer.isUserInteractionEnabled = false
        artworkContainer.addAutolayoutSubview(companion)
    }

    private func constructControls() {
        pawsStack.addArrangedSubviews(pawIndicators)
        primaryButton.configuration?.baseBackgroundColor = accent

        skipBreakButton.tintColor = accent
        skipBreakButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    private func addActions() {
        primaryButton.addAction(UIAction { [weak self] _ in
            self?.onPlayPauseButtonTap?()
        }, for: .touchUpInside)

        skipBreakButton.addAction(UIAction { [weak self] _ in
            self?.onSkipBreakTap?()
        }, for: .touchUpInside)

        secondaryButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }

            if isComplete {
                onDismissButtonTap?()
            } else {
                onStopButtonTap?()
            }
        }, for: .touchUpInside)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()

        constructScrollViewConstraints()
        constructStackViewConstraints()
        constructRingContainerConstraints()
        constructArtworkConstraints()
        constructLabelsConstraints()
        constructButtonsConstraints()
    }

    private func constructScrollViewConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func constructStackViewConstraints() {
        let contentWidth = stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        contentWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 28),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentWidth,
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 420)
        ])
    }

    private func constructRingContainerConstraints() {
        let ringWidth = ringContainer.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ringWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            ringWidth,
            ringContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
            ringContainer.heightAnchor.constraint(equalTo: ringContainer.widthAnchor),
            timerCircleView.leadingAnchor.constraint(equalTo: ringContainer.leadingAnchor),
            timerCircleView.trailingAnchor.constraint(equalTo: ringContainer.trailingAnchor),
            timerCircleView.topAnchor.constraint(equalTo: ringContainer.topAnchor),
            timerCircleView.bottomAnchor.constraint(equalTo: ringContainer.bottomAnchor)
        ])
    }

    private func constructArtworkConstraints() {
        NSLayoutConstraint.activate([
            artworkContainer.leadingAnchor.constraint(equalTo: ringContainer.leadingAnchor),
            artworkContainer.trailingAnchor.constraint(equalTo: ringContainer.trailingAnchor),
            artworkContainer.topAnchor.constraint(equalTo: ringContainer.topAnchor),
            artworkContainer.bottomAnchor.constraint(equalTo: ringContainer.bottomAnchor),
            companion.centerXAnchor.constraint(equalTo: artworkContainer.centerXAnchor),
            companion.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor, constant: 32),
            companion.widthAnchor.constraint(equalTo: artworkContainer.widthAnchor, multiplier: 0.95),
            companion.heightAnchor.constraint(equalTo: artworkContainer.heightAnchor, multiplier: 0.63)
        ])
    }

    private func constructLabelsConstraints() {
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: ringContainer.topAnchor, constant: 65),
            timerLabel.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor),
            timerLabel.widthAnchor.constraint(equalTo: ringContainer.widthAnchor, multiplier: 0.8),
            statusLabel.topAnchor.constraint(equalTo: timerLabel.bottomAnchor, constant: 4),
            statusLabel.centerXAnchor.constraint(equalTo: ringContainer.centerXAnchor),
            statusLabel.widthAnchor.constraint(equalTo: ringContainer.widthAnchor, multiplier: 0.75),
            timerNameLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            sessionLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            messageLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }

    private func constructButtonsConstraints() {
        NSLayoutConstraint.activate([
            primaryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            secondaryButton.widthAnchor.constraint(equalTo: stackView.widthAnchor),
            primaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            secondaryButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52)
        ])
    }

    func configure(_ state: TimerPresentationState) {
        isComplete = state.status == .finished
        configureCompanionPose(state)
        configureLabels(state)
        configureButtons(state: state)
        configureCircleView(state: state)
        configurePawIndicators(state: state)

        previousTimerState = state
    }

    private func configureCompanionPose(_ state: TimerPresentationState) {
        companion.pose = isComplete ? .playful : (state.isBreak ? .timerBreak : .focus)
    }

    private func configureLabels(_ state: TimerPresentationState) {
        configureSessionLabels(state)
        configureCountdownLabel(state)
        configureStatusLabels(state)
    }

    private func configureSessionLabels(_ state: TimerPresentationState) {
        timerNameLabel.text = state.phaseTitle.uppercased()
        sessionLabel.text = state.sessionSummary
    }

    private func configureCountdownLabel(_ state: TimerPresentationState) {
        timerLabel.text = state.countdown
        timerLabel.accessibilityLabel = AppStrings.Common.timeRemaining
        timerLabel.accessibilityValue = TimerConfigModel.durationSummary(ceil(state.remainingDuration))
    }

    private func configureStatusLabels(_ state: TimerPresentationState) {
        statusLabel.text = isComplete ? AppStrings.Timer.wellDone : (state.status == .paused ? AppStrings.Common.paused : (state.isBreak ? AppStrings.Common.restYourPaws : AppStrings.Common.timeToFocus))
        messageLabel.text = isComplete ? AppStrings.Timer.onePawAtATimeYouDidIt
            : (state.status == .paused ? AppStrings.Timer.yourRoutineWillBeHereWhenYoureReady : AppStrings.Timer.yourCatIsKeepingYouCompany)
    }

    private func configureCircleView(
        state: TimerPresentationState
    ) {
        let previous = previousTimerState
        let shouldAnimate =
            state.status == .playing &&
            previous?.status == .playing &&
            previous?.isBreak == state.isBreak &&
            previous?.sessionIndex == state.sessionIndex &&
            previous?.phaseDuration == state.phaseDuration &&
            abs((previous?.remainingDuration ?? state.remainingDuration) - state.remainingDuration) < 0.5

        timerCircleView.configure(progress: isComplete ? 1 : 1 - state.progress, animated: shouldAnimate)
    }

    private func configureButtons(state: TimerPresentationState) {
        configurePrimaryButton(state: state)
        configureSecondaryButton()
        skipBreakButton.isHidden = !state.isBreak || isComplete
    }

    private func configurePrimaryButton(state: TimerPresentationState) {
        primaryButton.configuration?.title = isComplete ?
            AppStrings.Common.focusAgain : (state.status == .playing ? AppStrings.Common.pause : AppStrings.Common.resume)
        primaryButton.configuration?.image = UIImage(systemName: isComplete ? "arrow.clockwise" : (state.status == .playing ? "pause.fill" : "play.fill"))
    }

    private func configureSecondaryButton() {
        secondaryButton.configuration?.title = isComplete ? AppStrings.Timer.backToRoutine : AppStrings.Timer.endSession
        secondaryButton.configuration?.image = UIImage(systemName: isComplete ? "arrow.left" : "stop.fill")
    }

    private func configurePawIndicators(state: TimerPresentationState) {
        pawsStack.accessibilityLabel = state.sessionSummary

        for (index, paw) in pawIndicators.enumerated() {
            paw.isHidden = index >= min(6, state.sessionCount)
            paw.tintColor = isComplete || index < state.sessionIndex ? accent : CatTheme.disabled
        }
    }
}

#if DEBUG
extension TimerView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerView

        var artworkMask: CAShapeLayer {
            target.artworkContainer.artworkMask
        }

        var companion: CatIllustrationView {
            target.companion
        }

        var artworkContainer: UIView {
            target.artworkContainer
        }

        var timerNameLabel: UILabel {
            target.timerNameLabel
        }

        var timerLabel: UILabel {
            target.timerLabel
        }

        var timerCircleView: TimerCircleView {
            target.timerCircleView
        }

        var primaryButton: UIButton {
            target.primaryButton
        }

        var skipBreakButton: UIButton {
            target.skipBreakButton
        }

        var secondaryButton: UIButton {
            target.secondaryButton
        }

        var statusLabel: UILabel {
            target.statusLabel
        }
    }
}
#endif
