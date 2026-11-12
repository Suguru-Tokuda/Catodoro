//
//  PresetImagePickerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/30/26.
//

import CatodoroShared
import UIKit

final class PresetImagePickerView: BaseView {
    var onSelect: ((CatPose) -> Void)?
    private let scrollView = UIScrollView()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Spacing.space12
        return stack
    }()

    override func constructSubviews() {
        super.constructSubviews()
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stack)

        for pair in stride(from: 0, to: CatPose.allCases.count, by: 2) {
            let row = UIStackView()
            row.spacing = Spacing.space12
            row.distribution = .fillEqually

            for pose in CatPose.allCases[pair..<min(pair + 2, CatPose.allCases.count)] {
                let button = makePoseButton(pose)
                row.addArrangedSubview(button)
            }

            stack.addArrangedSubview(row)
        }
    }

    private func makePoseButton(_ pose: CatPose) -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.tinted()
        configuration.image = UIImage(named: pose.rawValue)?.withRenderingMode(.alwaysOriginal)
            .preparingThumbnail(of: CGSize(width: 264, height: 264))
            .flatMap { thumbnail in
                guard let cgImage = thumbnail.cgImage else { return nil }

                return UIImage(cgImage: cgImage, scale: 3, orientation: .up)
            }
        configuration.title = pose.displayName
        configuration.imagePlacement = .top
        configuration.imagePadding = Spacing.space8
        configuration.baseBackgroundColor = CatTheme.card
        configuration.baseForegroundColor = CatTheme.text
        configuration.cornerStyle = .large
        button.configuration = configuration
        button.accessibilityIdentifier = pose.rawValue
        button.addAction(UIAction { [weak self] _ in
            self?.onSelect?(pose)
        }, for: .touchUpInside)

        return button
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.space16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: Spacing.space16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -Spacing.space16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.space16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -Spacing.space16 * 2)
        ])
    }
}
