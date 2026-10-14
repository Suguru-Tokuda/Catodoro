//
//  PresetEditorView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit

final class PresetEditorView: BaseView {
    var onNameChanged: ((String) -> Void)?
    var onImageRequested: (() -> Void)?
    var onSelectionRequested: ((RoutineSelection) -> Void)?
    var onSave: (() -> Void)?

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.keyboardDismissMode = .interactive
        return view
    }()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()

    private let artwork = CatIllustrationView()

    private let imageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose your cat", for: .normal)
        button.titleLabel?.font = CatTheme.font(.body, weight: .semibold)
        button.tintColor = ColorOptions.neonBlue.color
        button.accessibilityIdentifier = "presetImage"
        return button
    }()

    private let nameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Preset name"
        field.accessibilityLabel = "Preset name"
        field.accessibilityIdentifier = "presetName"
        field.font = CatTheme.font(.body)
        field.adjustsFontForContentSizeCategory = true
        field.textColor = CatTheme.text
        field.backgroundColor = CatTheme.card
        field.layer.cornerRadius = 16
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        field.rightViewMode = .always
        field.autocapitalizationType = .sentences
        field.returnKeyType = .done
        return field
    }()

    private let card = CatCardView()

    private let routineStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private let focusRow = CatSummaryRow(title: "Focus time", value: "", symbol: "clock")
    private let breakRow = CatSummaryRow(title: "Catnap break", value: "", symbol: "cup.and.saucer.fill")
    private let sessionsRow = CatSummaryRow(title: "Sessions", value: "", symbol: "CatPaw")

    private let summary: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.footnote)
        label.textColor = CatTheme.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.title = "Save preset"
        configuration.baseBackgroundColor = ColorOptions.neonBlue.color
        configuration.baseForegroundColor = CatTheme.onAccent
        configuration.cornerStyle = .capsule
        button.configuration = configuration
        button.titleLabel?.font = CatTheme.font(.headline, weight: .bold)
        button.accessibilityIdentifier = "savePreset"
        return button
    }()

    override func constructSubviews() {
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stack)
        stack.addArrangedSubviews([artwork, imageButton, nameField, card, summary, saveButton])
        card.addAutolayoutSubview(routineStack)
        routineStack.addArrangedSubviews([focusRow, breakRow, sessionsRow])
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        nameField.addAction(UIAction { [weak self] _ in
            self?.nameField.resignFirstResponder()
        }, for: .editingDidEndOnExit)
        imageButton.addAction(UIAction { [weak self] _ in
            self?.endEditing(true)
            self?.onImageRequested?()
        }, for: .touchUpInside)
        saveButton.addAction(UIAction { [weak self] _ in
            self?.endEditing(true)
            self?.onSave?()
        }, for: .touchUpInside)

        for (row, selection) in [(focusRow, RoutineSelection.focus), (breakRow, .catnap), (sessionsRow, .sessions)] {
            row.addAction(UIAction { [weak self] _ in
                self?.endEditing(true)
                self?.onSelectionRequested?(selection)
            }, for: .touchUpInside)
        }
    }

    override func constructSubviewLayoutConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            artwork.heightAnchor.constraint(equalToConstant: 150),
            imageButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            nameField.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),
            routineStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            routineStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -8),
            routineStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            routineStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }

    func configureAccent(_ color: UIColor) {
        [focusRow, breakRow, sessionsRow].forEach { $0.configureAccent(color) }
        imageButton.tintColor = color
        saveButton.configuration?.baseBackgroundColor = color
    }

    func render(name: String, pose: CatPose, configuration: TimerConfigModel, canSave: Bool, isSaving: Bool) {
        if nameField.text != name {
            nameField.text = name
        }

        artwork.pose = pose
        imageButton.accessibilityValue = pose.displayName
        focusRow.setValue(TimerConfigModel.durationSummary(configuration.mainTimer.duration))
        breakRow.setValue(configuration.interval.duration == 0 ? "No break" : TimerConfigModel.durationSummary(configuration.interval.duration))
        sessionsRow.setValue("\(configuration.intervals)")
        let total = TimerConfigModel.durationSummary(configuration.totalDuration)
        summary.text = configuration.breakSubtotal > 0
            ? "About \(total), including breaks." : "About \(total) of focus time."
        saveButton.isEnabled = canSave
        saveButton.configuration?.showsActivityIndicator = isSaving
        isUserInteractionEnabled = !isSaving
    }

    @objc private func nameChanged() {
        onNameChanged?(nameField.text ?? "")
    }
}

extension CatPose {
    var displayName: String {
        switch self {
        case .sitting: return "Sitting cat"
        case .sleeping: return "Sleeping cat"
        case .stretching: return "Stretching cat"
        case .playful: return "Playful cat"
        case .focus: return "Focus cat"
        case .timerBreak: return "Catnap cat"
        }
    }
}

final class PresetImagePickerView: BaseView {
    var onSelect: ((CatPose) -> Void)?
    private let scrollView = UIScrollView()

    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    override func constructSubviews() {
        backgroundColor = CatTheme.background
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stack)

        for pair in stride(from: 0, to: CatPose.allCases.count, by: 2) {
            let row = UIStackView()
            row.spacing = 12
            row.distribution = .fillEqually

            for pose in CatPose.allCases[pair..<min(pair + 2, CatPose.allCases.count)] {
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
                configuration.imagePadding = 8
                configuration.baseBackgroundColor = CatTheme.card
                configuration.baseForegroundColor = CatTheme.text
                configuration.cornerStyle = .large
                button.configuration = configuration
                button.accessibilityIdentifier = pose.rawValue
                button.addAction(UIAction { [weak self] _ in
                    self?.onSelect?(pose)
                }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }

            stack.addArrangedSubview(row)
        }
    }

    override func constructSubviewLayoutConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }
}
