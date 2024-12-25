//
//  TimerConfigView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerConfigView: UIView {
    struct Model {
        let startLabelText: String
        let color: UIColor

        init(startLabelText: String = "Start",
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

    // MARK: Closures
    var onStartButtonTap: (() -> Void)?
    var onTotalDurationSelect: ((Int, Int, Int) -> Void)?
    var onIntervalDurationSelect: ((Int, Int, Int) -> Void)?
    var onIntervalSelect: ((Int) -> Void)?
    // MARK: UI Components
    
    private lazy var totalDurationLabel: TimerConfigSubTitle = .init(text: "Main Timer")
    private lazy var intervalDurationLabel: TimerConfigSubTitle = .init(text: "Interval")
    private lazy var intervalsLabel: TimerConfigSubTitle = .init(text: "Intervals")
    private lazy var totalDurationPicker: TimerPickerView = .init()
    private lazy var intervalDurationPicker: TimerPickerView = .init()
    private lazy var intervalPicker: TimePickerView = .init(frame: .zero, min: 1, max: 20)
    private lazy var intervalStackView: UIStackView = {
       let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .leading
        return stackView
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()
    private lazy var startButton: TimerStartButton = {
        let button = TimerStartButton()
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        return button
    }()
    private lazy var scrollView: UIScrollView = .init()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        nil
    }

    private func setupSubviews() {
        addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubviews([stackView])
        intervalStackView.addArrangedSubviews([intervalPicker, UIView(), UIView()])
        stackView.addArrangedSubviews([
            totalDurationLabel,
            totalDurationPicker,
            intervalDurationLabel,
            intervalDurationPicker,
            intervalsLabel,
            intervalStackView,
            startButton
        ])
        applyModel()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // scrollView constraints
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: .init(16)),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .init(16)),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .init(-16)),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            // stackView constraints
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // setStackView constraint
            intervalStackView.heightAnchor.constraint(equalToConstant: .init(120)),
            // startButton constraint
            startButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            startButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupEventHandlers() {
        totalDurationPicker.onSelect = onTotalDurationSelect
        intervalDurationPicker.onSelect = onIntervalDurationSelect
        intervalPicker.onSelect = onIntervalSelect
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupEventHandlers()
    }

    private func applyModel() {
        guard let model else { return }
        
        startButton.model = .init(buttonLabelText: model.startLabelText,
                                  color: model.color)
    }
}

extension TimerConfigView {
    func setStartButtonStatus(isEnabled: Bool) {
        startButton.isEnabled = isEnabled
    }
}

extension TimerConfigView {
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
        var totalDurationLabel: TimerConfigSubTitle { target.totalDurationLabel }
        var startButton: TimerStartButton { target.startButton }
        var intervalDurationPicker: TimerPickerView { target.intervalDurationPicker }
        var totalDurationPicker: TimerPickerView { target.totalDurationPicker }
        var intervalPicker: TimePickerView { target.intervalPicker }

        func setupEventHandlers() { target.setupEventHandlers() }
    }
}
#endif
