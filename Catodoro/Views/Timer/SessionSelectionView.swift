//
//  SessionSelectionView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/10/26.
//

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

    private let minusButton = SessionSelectionView.stepButton(symbol: "minus", label: "Fewer sessions")
    private let plusButton = SessionSelectionView.stepButton(symbol: "plus", label: "More sessions")

    private let stepperStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = CatTheme.Spacing.medium

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
            NSLayoutConstraint.activate([
                indicator.widthAnchor.constraint(equalToConstant: 28),
                indicator.heightAnchor.constraint(equalToConstant: 28)
            ])

            return indicator
        }
    }()

    private let pawsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
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
        stack.spacing = 8

        return stack
    }()

    private let limitsLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose 1–20 sessions"
        label.font = CatTheme.font(.caption1)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    private let breakdownCard = CatCardView()

    private let breakdownStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12

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
        label.text = "Breaks happen between sessions."
        label.font = CatTheme.font(.caption1)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0

        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHeader(title: "Focus sessions", subtitle: "How many focus sessions would you like?", pose: .playful)
        confirmButton.setTitle("Set sessions", for: .normal)
        stepperStack.addArrangedSubviews([minusButton, countLabel, plusButton])
        pawsStack.addArrangedSubviews(pawIndicators)
        indicatorsStack.addArrangedSubviews([pawsStack, indicatorsLabel])
        stepperContent.addArrangedSubviews([stepperStack, indicatorsStack])
        stepperCard.addAutolayoutSubview(stepperContent)
        breakdownCard.addAutolayoutSubview(breakdownStack)
        let separator = UIView()
        separator.backgroundColor = CatTheme.separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        breakdownStack.addArrangedSubviews([
            summaryRow(title: "Focus", symbol: "clock", value: focusValue),
            summaryRow(title: "Breaks", symbol: "cup.and.saucer.fill", value: breakValue),
            separator,
            summaryRow(title: "Total time", symbol: nil, value: totalValue)
        ])
        contentStack.addArrangedSubviews([stepperCard, limitsLabel, breakdownCard, footerLabel])
        NSLayoutConstraint.activate([
            stepperContent.leadingAnchor.constraint(equalTo: stepperCard.leadingAnchor, constant: 16),
            stepperContent.trailingAnchor.constraint(equalTo: stepperCard.trailingAnchor, constant: -16),
            stepperContent.topAnchor.constraint(equalTo: stepperCard.topAnchor, constant: 16),
            stepperContent.bottomAnchor.constraint(equalTo: stepperCard.bottomAnchor, constant: -16),
            breakdownStack.leadingAnchor.constraint(equalTo: breakdownCard.leadingAnchor, constant: 16),
            breakdownStack.trailingAnchor.constraint(equalTo: breakdownCard.trailingAnchor, constant: -16),
            breakdownStack.topAnchor.constraint(equalTo: breakdownCard.topAnchor, constant: 16),
            breakdownStack.bottomAnchor.constraint(equalTo: breakdownCard.bottomAnchor, constant: -16)
        ])
        minusButton.addAction(UIAction { [weak self] _ in
            self?.onCountChange?(-1)
        }, for: .touchUpInside)
        plusButton.addAction(UIAction { [weak self] _ in
            self?.onCountChange?(1)
        }, for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        nil
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
        button.widthAnchor.constraint(equalToConstant: 52).isActive = true
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true

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
        row.spacing = 12

        if let symbol {
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = ColorOptions.neonBlue.color
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 24).isActive = true
            icon.isAccessibilityElement = false
            row.insertArrangedSubview(icon, at: 0)
        }

        return row
    }

    func render(count: Int, focusSummary: String, breakSummary: String, totalSummary: String) {
        countLabel.text = "\(count)"
        countLabel.accessibilityLabel = "\(count) focus sessions"
        minusButton.isEnabled = count > 1
        plusButton.isEnabled = count < 20
        focusValue.text = focusSummary
        breakValue.text = breakSummary
        totalValue.text = totalSummary
        renderIndicators(count: count)
    }

    func announceCount(_ count: Int) {
        UIAccessibility.post(notification: .announcement, argument: "\(count) focus sessions")
    }

    private func renderIndicators(count draftCount: Int) {
        let showsPaws = draftCount <= 6
        pawsStack.isHidden = !showsPaws
        indicatorsLabel.isHidden = showsPaws
        indicatorsLabel.text = showsPaws ? nil : "\(draftCount) focus sessions"

        for (index, indicator) in pawIndicators.enumerated() {
            indicator.isHidden = index >= draftCount
        }
    }

    #if DEBUG
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
    #endif
}
