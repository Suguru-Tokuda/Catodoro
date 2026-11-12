//
//  TimerConfigView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import CatodoroShared
import UIKit

class TimerConfigView: BaseView {
    struct Model {
        enum Mode { case focus, createRoutine }
        let mode: Mode
        let startLabelText: String
        let color: UIColor

        init(startLabelText: String = AppStrings.Timer.startFocusing,
             color: UIColor = ColorOptions.neonBlue.color,
             mode: Mode = .focus) {
            self.mode = mode
            self.startLabelText = startLabelText
            self.color = color
        }
    }

    var model: Model? = .init() {
        didSet {
            applyModel()
        }
    }

    var onStartButtonTap: (() -> Void)?
    var onSelectionRequest: ((RoutineSelection) -> Void)?

    private let focusRow = CatSummaryRow(title: AppStrings.Common.focusTime, value: "", symbol: "clock")
    private let breakRow = CatSummaryRow(title: AppStrings.Common.catnapBreak, value: "", symbol: "cup.and.saucer.fill")
    private let sessionsRow = CatSummaryRow(title: AppStrings.Common.sessions, value: "", symbol: "CatPaw")

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.footnote)
        label.textColor = CatTheme.secondaryText
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space16
        return stack
    }()

    private let startButton = TimerStartButton()

    private let scrollView = UIScrollView()
    private let companion = CatIllustrationView(pose: .sitting)
    private let heroView = CatGardenView()
    private let routineCard = CatCardView()

    private let heading: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Common.catodoro
        label.font = CatTheme.font(.largeTitle, weight: .heavy)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let tagline: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Timer.onePawAtATime
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let routineTitle: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Timer.yourFocusRoutine
        label.font = CatTheme.font(.headline, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let routineStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical

        return stack
    }()

    private func separator() -> UIView {
        let view = UIView()
        view.backgroundColor = CatTheme.separator
        view.heightAnchor.constraint(equalToConstant: Spacing.hairline).isActive = true

        return view
    }

    override func constructSubviews() {
        super.constructSubviews()
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([heading, tagline, heroView, routineCard, startButton])
        stackView.setCustomSpacing(Spacing.space4, after: heading)
        stackView.setCustomSpacing(0, after: tagline)
        heroView.addAutolayoutSubview(companion)
        routineCard.addAutolayoutSubview(routineStack)
        routineStack.addArrangedSubviews([
            routineTitle, focusRow, separator(), breakRow, separator(), sessionsRow,
            separator(), summaryLabel
        ])
        routineStack.setCustomSpacing(Spacing.space8, after: routineTitle)
        routineStack.setCustomSpacing(Spacing.space12, after: routineStack.arrangedSubviews[6])
        configureSelectionActions()
        applyModel()
    }

    private func configureSelectionActions() {
        focusRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.focus)
        }, for: .touchUpInside)
        breakRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.catnap)
        }, for: .touchUpInside)
        sessionsRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.sessions)
        }, for: .touchUpInside)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            heroView.heightAnchor.constraint(equalToConstant: Spacing.space200),
            companion.heightAnchor.constraint(equalTo: heroView.heightAnchor),
            companion.widthAnchor.constraint(equalTo: heroView.widthAnchor, multiplier: 0.7),
            companion.centerXAnchor.constraint(equalTo: heroView.centerXAnchor, constant: -Spacing.space20),
            companion.bottomAnchor.constraint(equalTo: heroView.bottomAnchor),
            routineStack.leadingAnchor.constraint(equalTo: routineCard.leadingAnchor, constant: Spacing.space16),
            routineStack.trailingAnchor.constraint(equalTo: routineCard.trailingAnchor, constant: -Spacing.space16),
            routineStack.topAnchor.constraint(equalTo: routineCard.topAnchor, constant: Spacing.space16),
            routineStack.bottomAnchor.constraint(equalTo: routineCard.bottomAnchor, constant: -Spacing.space16),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: Spacing.space16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.space16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.space16),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.space24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            startButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Spacing.space56)
        ])
    }

    func render(_ configuration: TimerConfigModel) {
        focusRow.setValue(TimerConfigModel.durationSummary(configuration.mainTimer.duration))
        breakRow.setValue(configuration.interval.duration == 0
            ? AppStrings.Common.noBreak : TimerConfigModel.durationSummary(configuration.interval.duration))
        sessionsRow.setValue("\(configuration.intervals)")
        let total = TimerConfigModel.durationSummary(configuration.totalDuration)
        summaryLabel.text = configuration.interval.duration > 0 && configuration.intervals > 1
            ? AppStrings.Timer.aboutIncludingBreaks(total) : AppStrings.Timer.aboutFocusTime(total)
        setStartButtonStatus(isEnabled: configuration.isValid)
    }

    private func applyModel() {
        guard let model else { return }

        heading.text = model.mode == .createRoutine ? AppStrings.Timer.createARoutine : AppStrings.Common.catodoro
        startButton.model = .init(buttonLabelText: model.startLabelText, color: model.color)
        [focusRow, breakRow, sessionsRow].forEach { $0.configureAccent(model.color) }
    }

    private func setStartButtonStatus(isEnabled: Bool) {
        startButton.isEnabled = isEnabled
    }

    @objc private func startButtonTapped() {
        onStartButtonTap?()
    }
}

#if DEBUG
extension TimerConfigView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerConfigView

        var heading: UILabel { target.heading }
        var scrollView: UIScrollView { target.scrollView }
        var stackView: UIStackView { target.stackView }
        var focusRow: CatSummaryRow { target.focusRow }
        var breakRow: CatSummaryRow { target.breakRow }
        var sessionsRow: CatSummaryRow { target.sessionsRow }
        var summaryLabel: UILabel { target.summaryLabel }
        var startButton: TimerStartButton { target.startButton }

        func setStartButtonStatus(isEnabled: Bool) { target.setStartButtonStatus(isEnabled: isEnabled) }
    }
}
#endif
