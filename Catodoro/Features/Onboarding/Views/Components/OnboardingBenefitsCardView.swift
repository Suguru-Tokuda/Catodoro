//
//  OnboardingBenefitsCardView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Rounded card listing what an onboarding choice gives the user.
final class OnboardingBenefitsCardView: BaseView {
    struct Benefit: Equatable {
        let symbolName: String
        let text: String
    }

    private let stackView = UIStackView()

    init(benefits: [Benefit]) {
        super.init(frame: .zero)
        benefits.forEach {
            stackView.addArrangedSubview(OnboardingBenefitRowView(symbolName: $0.symbolName, text: $0.text))
        }
    }

    required init?(coder: NSCoder) {
        nil
    }

    var rows: [OnboardingBenefitRowView] {
        stackView.arrangedSubviews.compactMap { $0 as? OnboardingBenefitRowView }
    }

    override func constructView() {
        super.constructView()
        backgroundColor = CatTheme.card
        layer.cornerRadius = CatTheme.cardRadius
    }

    override func constructSubviews() {
        super.constructSubviews()
        stackView.axis = .vertical
        stackView.spacing = Spacing.space18
        addAutolayoutSubview(stackView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.space20),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.space20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.space18),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.space18)
        ])
    }
}
