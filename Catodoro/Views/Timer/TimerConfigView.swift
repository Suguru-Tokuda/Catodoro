//
//  TimerConfigView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 11/10/24.
//

import UIKit

class TimerConfigView: UIView {
    struct Model {
        let color: UIColor

        init(color: UIColor = ColorOptions.neonBlue.color) {
            self.color = color
        }
    }

    var model: Model? {
        didSet {
            applyModel()
        }
    }

    // MARK: Closures
    var onStartButtonTap: (() -> Void)?
    var onMainTimerSelect: ((Int, Int, Int) -> Void)?
    var onBreakTimerSelect: ((Int, Int, Int) -> Void)?
    var onIntervalSelect: ((Int) -> Void)?
    // MARK: UI Components
    
    private lazy var mainTimerLabel: TimerConfigSubTitle = .init(text: "Main Timer")
    private lazy var breakTimerLabel: TimerConfigSubTitle = .init(text: "Break")
    private lazy var intervalsLabel: TimerConfigSubTitle = .init(text: "Intervals")
    private lazy var mainTimerPicker: TimerPickerView = .init()
    private lazy var breakTimerPicker: TimerPickerView = .init()
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
            mainTimerLabel,
            mainTimerPicker,
            breakTimerLabel,
            breakTimerPicker,
            intervalsLabel,
            intervalStackView,
            startButton
        ])
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
        mainTimerPicker.onSelect = onMainTimerSelect
        breakTimerPicker.onSelect = onBreakTimerSelect
        onIntervalSelect = intervalPicker.onSelect
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupEventHandlers()
    }

    private func applyModel() {
        guard let model else { return }
        
        startButton.model = .init(color: model.color)
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
