//
//  OnboardingBenefitRowView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// One SF Symbol + text line inside `OnboardingBenefitsCardView`.
final class OnboardingBenefitRowView: BaseView {
    private let iconView = UIImageView()
    private let textLabel = OnboardingLabel(text: "", style: .subheadline)
    private let stackView = UIStackView()

    init(symbolName: String, text: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: symbolName)
        textLabel.text = text
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func constructSubviews() {
        super.constructSubviews()
        iconView.tintColor = CatTheme.accent(.neonBlue)
        iconView.contentMode = .scaleAspectFit
        iconView.isAccessibilityElement = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        textLabel.textAlignment = .left

        stackView.spacing = Spacing.space12
        stackView.alignment = .center
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(textLabel)
        addAutolayoutSubview(stackView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: Spacing.space22),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

#if DEBUG
extension OnboardingBenefitRowView {
    var testHooks: TestHooks { .init(target: self) }

    struct TestHooks {
        let target: OnboardingBenefitRowView

        var iconView: UIImageView { target.iconView }
        var textLabel: UILabel { target.textLabel }
    }
}
#endif
