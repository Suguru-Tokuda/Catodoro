//
//  SessionSelectionView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

import CatodoroShared
import UIKit

final class SessionSelectionView: RoutineSelectionView {
    var onCountChange: ((Int) -> Void)?

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: CatTheme.font(.largeTitle, weight: .heavy).withSize(56))
        label.textColor = CatTheme.text
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true

        return label
    }()

    private let minusButton = SessionSelectionView.stepButton(symbol: "minus", label: AppStrings.Timer.fewerSessions)
    private let plusButton = SessionSelectionView.stepButton(symbol: "plus", label: AppStrings.Timer.moreSessions)

    private let stepperStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space16

        return stack
    }()

    private let indicatorsLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = ColorOptions.neonBlue.color
        label.font = CatTheme.font(.body)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false

        return label
    }()

    private let pawIndicators: [UIImageView] = {
        (0..<6).map { _ in
            let indicator = UIImageView(image: UIImage(named: "CatPaw"))
            indicator.contentMode = .scaleAspectFit
            indicator.tintColor = ColorOptions.neonBlue.color
            indicator.isAccessibilityElement = false

            return indicator
        }
    }()

    private let pawsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Spacing.space12
        stack.isAccessibilityElement = false

        return stack
    }()

    private let indicatorsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center

        return stack
    }()

    private let stepperCard: UIView = {
        let card = UIView()
        card.backgroundColor = CatTheme.selection
        card.layer.cornerRadius = CatTheme.cardRadius
        card.layer.cornerCurve = .continuous

        return card
    }()

    private let stepperContent: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space8

        return stack
    }()

    private let limitsLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Timer.sessionRange
        label.font = CatTheme.font(.caption1)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let breakdownCard = CatCardView()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = CatTheme.separator

        return view
    }()

    private let breakdownStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space12

        return stack
    }()

    private let focusValue = SessionSelectionView.valueLabel()
    private let breakValue = SessionSelectionView.valueLabel()
    private let totalValue: UILabel = {
        let label = SessionSelectionView.valueLabel()
        label.font = CatTheme.font(.headline, weight: .bold)

        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.text = AppStrings.Timer.breaksHappenBetweenSessions
        label.font = CatTheme.font(.caption1)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    override func applyAccent(_ color: UIColor) {
        super.applyAccent(color)
        stepperCard.backgroundColor = color.withAlphaComponent(0.18)
        minusButton.configuration?.baseBackgroundColor = color
        plusButton.configuration?.baseBackgroundColor = color
        indicatorsLabel.textColor = color
        pawIndicators.forEach { $0.tintColor = color }
        breakdownStack.arrangedSubviews.compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? UIImageView }
            .forEach { $0.tintColor = color }
    }

    override func constructView() {
        super.constructView()
        configureHeader(title: AppStrings.Timer.focusSessions, subtitle: AppStrings.Timer.sessionPrompt, pose: .playful)
        confirmButton.setTitle(AppStrings.Timer.setSessions, for: .normal)
    }

    override func constructSubviews() {
        super.constructSubviews()
        stepperStack.addArrangedSubviews([minusButton, countLabel, plusButton])
        pawsStack.addArrangedSubviews(pawIndicators)
        indicatorsStack.addArrangedSubviews([pawsStack, indicatorsLabel])
        stepperContent.addArrangedSubviews([stepperStack, indicatorsStack])
        stepperCard.addAutolayoutSubview(stepperContent)
        breakdownCard.addAutolayoutSubview(breakdownStack)
        breakdownStack.addArrangedSubviews([
            summaryRow(title: AppStrings.Common.focus, symbol: "clock", value: focusValue),
            summaryRow(title: AppStrings.Timer.breaks, symbol: "cup.and.saucer.fill", value: breakValue),
            separator,
            summaryRow(title: AppStrings.Common.totalTime, symbol: nil, value: totalValue)
        ])
        contentStack.addArrangedSubviews([stepperCard, limitsLabel, breakdownCard, footerLabel])
        setupCountActions()
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            separator.heightAnchor.constraint(equalToConstant: Spacing.space1),
            minusButton.widthAnchor.constraint(equalToConstant: Spacing.space52),
            minusButton.heightAnchor.constraint(equalToConstant: Spacing.space52),
            plusButton.widthAnchor.constraint(equalToConstant: Spacing.space52),
            plusButton.heightAnchor.constraint(equalToConstant: Spacing.space52),
            stepperContent.leadingAnchor.constraint(equalTo: stepperCard.leadingAnchor, constant: Spacing.space16),
            stepperContent.trailingAnchor.constraint(equalTo: stepperCard.trailingAnchor, constant: -Spacing.space16),
            stepperContent.topAnchor.constraint(equalTo: stepperCard.topAnchor, constant: Spacing.space16),
            stepperContent.bottomAnchor.constraint(equalTo: stepperCard.bottomAnchor, constant: -Spacing.space16),
            breakdownStack.leadingAnchor.constraint(equalTo: breakdownCard.leadingAnchor, constant: Spacing.space16),
            breakdownStack.trailingAnchor.constraint(equalTo: breakdownCard.trailingAnchor, constant: -Spacing.space16),
            breakdownStack.topAnchor.constraint(equalTo: breakdownCard.topAnchor, constant: Spacing.space16),
            breakdownStack.bottomAnchor.constraint(equalTo: breakdownCard.bottomAnchor, constant: -Spacing.space16)
        ])

        NSLayoutConstraint.activate(pawIndicators.flatMap { indicator in
            [indicator.widthAnchor.constraint(equalToConstant: Spacing.space28),
             indicator.heightAnchor.constraint(equalToConstant: Spacing.space28)]
        })
    }

    private func setupCountActions() {
        minusButton.addAction(UIAction { [weak self] _ in
            self?.onCountChange?(-1)
        }, for: .touchUpInside)
        plusButton.addAction(UIAction { [weak self] _ in
            self?.onCountChange?(1)
        }, for: .touchUpInside)
    }

    private static func stepButton(symbol: String, label: String) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: symbol)
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.baseBackgroundColor = ColorOptions.neonBlue.color
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.accessibilityLabel = label

        return button
    }

    private static func valueLabel() -> UILabel {
        let label = UILabel()
        label.font = CatTheme.font(.subheadline, weight: .semibold)
        label.textColor = CatTheme.text
        label.textAlignment = .right
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true

        return label
    }

    private func summaryRow(title: String, symbol: String?, value: UILabel) -> UIView {
        let label = Self.valueLabel()
        label.text = title
        label.textAlignment = .left

        if symbol == nil {
            label.font = CatTheme.font(.headline, weight: .bold)
        }

        let row = UIStackView(arrangedSubviews: [label, value])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Spacing.space12

        if let symbol {
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = ColorOptions.neonBlue.color
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: Spacing.space24).isActive = true
            icon.heightAnchor.constraint(equalToConstant: Spacing.space24).isActive = true
            icon.isAccessibilityElement = false
            row.insertArrangedSubview(icon, at: 0)
        }

        return row
    }

    func render(count: Int, focusSummary: String, breakSummary: String, totalSummary: String) {
        countLabel.text = "\(count)"
        countLabel.accessibilityLabel = AppStrings.Timer.focusSessionCount(count)
        minusButton.isEnabled = count > 1
        plusButton.isEnabled = count < 20
        focusValue.text = focusSummary
        breakValue.text = breakSummary
        totalValue.text = totalSummary
        renderIndicators(count: count)
    }

    func announceCount(_ count: Int) {
        UIAccessibility.post(notification: .announcement, argument: AppStrings.Timer.focusSessionCount(count))
    }

    private func renderIndicators(count draftCount: Int) {
        let showsPaws = draftCount <= 6
        pawsStack.isHidden = !showsPaws
        indicatorsLabel.isHidden = showsPaws
        indicatorsLabel.text = showsPaws ? nil : AppStrings.Timer.focusSessionCount(draftCount)

        for (index, indicator) in pawIndicators.enumerated() {
            indicator.isHidden = index >= draftCount
        }
    }

}

#if DEBUG
extension SessionSelectionView {
    var focusSummary: String? {
        focusValue.text
    }

    var breakSummary: String? {
        breakValue.text
    }

    var totalSummary: String? {
        totalValue.text
    }

    var canDecrease: Bool {
        minusButton.isEnabled
    }

    var canIncrease: Bool {
        plusButton.isEnabled
    }
}
#endif
