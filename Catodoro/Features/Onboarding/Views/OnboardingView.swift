//
//  OnboardingView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/12/26.
//

import UIKit

final class OnboardingView: BaseView {
    var onEnableSync: (() -> Void)?
    var onContinueLocally: (() -> Void)?
    private let enableButton = UIButton(type: .system)
    private let localButton = UIButton(type: .system)
    private let errorLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override func constructView() {
        super.constructView()
        backgroundColor = CatTheme.background
    }

    override func constructSubviews() {
        super.constructSubviews()
        addAutolayoutSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 20
        scroll.addAutolayoutSubview(stack)

        stack.addArrangedSubview(label("CATODORO", style: .caption1, color: CatTheme.secondaryText))
        let image = UIImageView(image: UIImage(named: "CatCloud"))
        image.contentMode = .scaleAspectFit
        image.isAccessibilityElement = false
        image.heightAnchor.constraint(equalToConstant: 190).isActive = true
        stack.addArrangedSubview(image)
        stack.addArrangedSubview(label("Your routines,\nwherever you focus.", style: .title1, weight: .bold))
        stack.addArrangedSubview(label("Keep your presets together with iCloud, or start with everything on this device.", style: .body, color: CatTheme.secondaryText))

        let benefits = UIStackView()
        benefits.axis = .vertical
        benefits.spacing = 18
        benefits.backgroundColor = CatTheme.card
        benefits.layer.cornerRadius = CatTheme.cardRadius
        benefits.isLayoutMarginsRelativeArrangement = true
        benefits.layoutMargins = UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18)
        for (symbol, text) in [
            ("arrow.triangle.2.circlepath", "Keep presets in sync across your devices"),
            ("icloud.and.arrow.down", "Bring back presets already saved in iCloud"),
            ("wifi.slash", "Keep focusing and saving presets offline")
        ] {
            let icon = UIImageView(image: UIImage(systemName: symbol))
            icon.tintColor = CatTheme.accent(.neonBlue)
            icon.contentMode = .scaleAspectFit
            icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
            icon.setContentHuggingPriority(.required, for: .horizontal)
            let textLabel = label(text, style: .subheadline)
            textLabel.textAlignment = .left
            let row = UIStackView(arrangedSubviews: [icon, textLabel])
            row.spacing = 12
            row.alignment = .center
            benefits.addArrangedSubview(row)
        }
        stack.addArrangedSubview(benefits)
        configure(enableButton, title: "Enable iCloud Sync", primary: true)
        configure(localButton, title: "Continue on This Device", primary: false)
        enableButton.addAction(UIAction { [weak self] _ in self?.onEnableSync?() }, for: .touchUpInside)
        localButton.addAction(UIAction { [weak self] _ in self?.onContinueLocally?() }, for: .touchUpInside)
        stack.addArrangedSubview(enableButton)
        stack.addArrangedSubview(localButton)
        stack.addArrangedSubview(label("You can change this later in Settings.", style: .footnote, color: CatTheme.secondaryText))
        spinner.hidesWhenStopped = true
        stack.addArrangedSubview(spinner)
        errorLabel.numberOfLines = 0
        errorLabel.font = CatTheme.font(.footnote)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        stack.addArrangedSubview(errorLabel)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    func render(isBusy: Bool, error: String?) {
        enableButton.isEnabled = !isBusy
        localButton.isEnabled = !isBusy
        enableButton.setTitle(error == nil ? "Enable iCloud Sync" : "Retry iCloud Sync", for: .normal)
        errorLabel.text = error
        errorLabel.isHidden = error == nil
        if isBusy { spinner.startAnimating() } else { spinner.stopAnimating() }
    }

    private func label(_ text: String, style: UIFont.TextStyle, weight: UIFont.Weight = .regular, color: UIColor = CatTheme.text) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = CatTheme.font(style, weight: weight)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        return label
    }

    private func configure(_ button: UIButton, title: String, primary: Bool) {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.baseBackgroundColor = primary ? CatTheme.accent(.neonBlue) : CatTheme.selection
        configuration.baseForegroundColor = primary ? CatTheme.onAccent : CatTheme.accent(.neonBlue)
        configuration.background.cornerRadius = CatTheme.controlRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)
        button.configuration = configuration
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
    }
}
