//
//  OnboardingContentView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

/// Scrolling vertical column that holds an onboarding step's content,
/// inset 24pt on every side and as wide as the screen allows.
final class OnboardingContentView: BaseView {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    override func constructSubviews() {
        super.constructSubviews()
        stackView.axis = .vertical
        stackView.spacing = Spacing.space20
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.space24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.space24),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Spacing.space24),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Spacing.space24),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.space24 * 2)
        ])
    }

    func addArrangedSubview(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }

    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(stackView.addArrangedSubview)
    }

    var arrangedSubviews: [UIView] { stackView.arrangedSubviews }
}
