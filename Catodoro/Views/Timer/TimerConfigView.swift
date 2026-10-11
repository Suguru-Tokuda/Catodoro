//
//  TimerConfigView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerConfigView: BaseView {
    struct Model {
        let startLabelText: String
        let color: UIColor

        init(startLabelText: String = "Start focusing",
             color: UIColor = ColorOptions.neonBlue.color) {
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

    private let focusRow = CatSummaryRow(title: "Focus time", value: "", symbol: "clock")
    private let breakRow = CatSummaryRow(title: "Catnap break", value: "", symbol: "cup.and.saucer.fill")
    private let sessionsRow = CatSummaryRow(title: "Sessions", value: "", symbol: "CatPaw")

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
        stack.spacing = CatTheme.Spacing.medium
        return stack
    }()

    private let startButton = TimerStartButton()

    private let scrollView = UIScrollView()
    private let companion = CatIllustrationView(pose: .sitting)
    private let heroView = CatGardenView()
    private let routineCard = CatCardView()

    private let heading: UILabel = {
        let label = UILabel()
        label.text = "Catodoro"
        label.font = CatTheme.font(.largeTitle, weight: .heavy)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let tagline: UILabel = {
        let label = UILabel()
        label.text = "One paw at a time."
        label.font = CatTheme.font(.body)
        label.textColor = CatTheme.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let routineTitle: UILabel = {
        let label = UILabel()
        label.text = "Your focus routine"
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
        view.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

        return view
    }

    override func setupSubviews() {
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([heading, tagline, heroView, routineCard, startButton])
        stackView.setCustomSpacing(4, after: heading)
        stackView.setCustomSpacing(0, after: tagline)
        heroView.addAutolayoutSubview(companion)
        routineCard.addAutolayoutSubview(routineStack)
        routineStack.addArrangedSubviews([
            routineTitle, focusRow, separator(), breakRow, separator(), sessionsRow,
            separator(), summaryLabel
        ])
        routineStack.setCustomSpacing(8, after: routineTitle)
        routineStack.setCustomSpacing(12, after: routineStack.arrangedSubviews[6])
        focusRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.focus)
        }, for: .touchUpInside)
        breakRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.catnap)
        }, for: .touchUpInside)
        sessionsRow.addAction(UIAction { [weak self] _ in
            self?.onSelectionRequest?(.sessions)
        }, for: .touchUpInside)
        applyModel()
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            heroView.heightAnchor.constraint(equalToConstant: 200),
            companion.heightAnchor.constraint(equalTo: heroView.heightAnchor),
            companion.widthAnchor.constraint(equalTo: heroView.widthAnchor, multiplier: 0.7),
            companion.centerXAnchor.constraint(equalTo: heroView.centerXAnchor, constant: -20),
            companion.bottomAnchor.constraint(equalTo: heroView.bottomAnchor),
            routineStack.leadingAnchor.constraint(equalTo: routineCard.leadingAnchor, constant: 16),
            routineStack.trailingAnchor.constraint(equalTo: routineCard.trailingAnchor, constant: -16),
            routineStack.topAnchor.constraint(equalTo: routineCard.topAnchor, constant: 16),
            routineStack.bottomAnchor.constraint(equalTo: routineCard.bottomAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            startButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
    }

    func render(_ configuration: TimerConfigModel) {
        focusRow.setValue(TimerConfigModel.durationSummary(configuration.mainTimer.duration))
        breakRow.setValue(configuration.interval.duration == 0
            ? "No break" : TimerConfigModel.durationSummary(configuration.interval.duration))
        sessionsRow.setValue("\(configuration.intervals)")
        let total = TimerConfigModel.durationSummary(configuration.totalDuration)
        summaryLabel.text = configuration.interval.duration > 0 && configuration.intervals > 1
            ? "About \(total), including breaks." : "About \(total) of focus time."
        setStartButtonStatus(isEnabled: configuration.isValid)
    }

    private func applyModel() {
        guard let model else { return }

        heading.text = model.startLabelText == "Save" ? "Create a routine" : "Catodoro"
        startButton.model = .init(buttonLabelText: model.startLabelText, color: model.color)
    }

    func setStartButtonStatus(isEnabled: Bool) {
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

        var scrollView: UIScrollView { target.scrollView }
        var stackView: UIStackView { target.stackView }
        var focusRow: CatSummaryRow { target.focusRow }
        var breakRow: CatSummaryRow { target.breakRow }
        var sessionsRow: CatSummaryRow { target.sessionsRow }
        var summaryLabel: UILabel { target.summaryLabel }
        var startButton: TimerStartButton { target.startButton }
    }
}
#endif

/// Decorative garden shapes frame the original cat artwork without announcing it to VoiceOver.
private final class CatGardenView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(_ rect: CGRect) {
        CatTheme.color(0xF1E4CF, 0x39313A).setFill()
        UIBezierPath(ovalIn: CGRect(x: 8, y: rect.height - 22, width: rect.width - 16, height: 20)).fill()

        let plantX = rect.width * 0.84
        CatTheme.color(0x8A9F7C, 0x71856D).setStroke()
        let stem = UIBezierPath()
        stem.move(to: CGPoint(x: plantX, y: rect.height - 32))
        stem.addQuadCurve(to: CGPoint(x: plantX - 8, y: 38), controlPoint: CGPoint(x: plantX - 16, y: 100))
        stem.lineWidth = 3
        stem.stroke()

        for index in 0..<5 {
            let left = index % 2 == 0
            let leaf = UIBezierPath()
            let y = CGFloat(45 + index * 22)
            let x = plantX - 8
            leaf.move(to: CGPoint(x: x, y: y + 25))
            leaf.addQuadCurve(to: CGPoint(x: x + (left ? -35 : 35), y: y - 8),
                              controlPoint: CGPoint(x: x + (left ? -48 : 48), y: y + 20))
            leaf.addQuadCurve(to: CGPoint(x: x, y: y + 25),
                              controlPoint: CGPoint(x: x + (left ? -5 : 5), y: y - 20))
            CatTheme.color(index % 2 == 0 ? 0x9BAF8C : 0x7E9973, 0x63795E).setFill()
            leaf.fill()
        }

        CatTheme.color(0xE3D4BC, 0x776858).setFill()
        let pot = UIBezierPath(roundedRect: CGRect(x: plantX - 25, y: rect.height - 48, width: 50, height: 38), cornerRadius: 12)
        pot.fill()
    }
}
