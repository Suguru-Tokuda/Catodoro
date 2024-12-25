//
//  TimePickerView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/7/24.
//

import UIKit

class TimerPickerView: UIView {
    var onSelect: ((Int, Int, Int) -> Void)?
    var hours: Int?
    var minutes: Int?
    var seconds: Int?

    private var hourLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Hours"
        return label
    }()
    private var minuteLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Minutes"
        return label
    }()
    private var secondLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Seconds"
        return label
    }()
    private var hourPicker: TimePickerView = {
        let hourPicker = TimePickerView(frame: .zero, max: 23)
        return hourPicker
    }()
    private var minutePicker: TimePickerView = {
        let minutePicker = TimePickerView(frame: .zero, max: 59)
        return minutePicker
    }()
    private var secondPicker: TimePickerView = {
        let secondPicker = TimePickerView(frame: .zero, max: 59)
        return secondPicker
    }()
    private var pickersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    private var labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    private var outerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
        setupEventHandlers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addAutolayoutSubview(outerStackView)

        outerStackView.addArrangedSubviews([
            labelStackView,
            pickersStackView
        ])

        labelStackView.addArrangedSubviews([
            hourLabel,
            minuteLabel,
            secondLabel
        ])

        pickersStackView.addArrangedSubviews([
            hourPicker,
            minutePicker,
            secondPicker
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            outerStackView.topAnchor.constraint(equalTo: topAnchor),
            outerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            labelStackView.heightAnchor.constraint(equalToConstant: .init(24)),
            pickersStackView.heightAnchor.constraint(equalToConstant: .init(120))
        ])
    }

    private func setupEventHandlers() {
        hourPicker.onSelect = { hours in
            self.hours = hours
            self.handleOnSelect()
        }

        minutePicker.onSelect = { minutes in
            self.minutes = minutes
            self.handleOnSelect()
        }
    
        secondPicker.onSelect = { seconds in
            self.seconds = seconds
            self.handleOnSelect()
        }
    }

    private func handleOnSelect() {
        onSelect?(hours ?? 0, minutes ?? 0, seconds ?? 0)
    }

    func configure(hour: Int, minute: Int, second: Int) {
        self.hours = hour
        self.minutes = minute
        self.seconds = second
        hourPicker.selectRow(hour, inComponent: 0, animated: false)
        minutePicker.selectRow(minute, inComponent: 0, animated: false)
        secondPicker.selectRow(second, inComponent: 0, animated: false)
    }
}

#if DEBUG
extension TimerPickerView {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: TimerPickerView

        var hourPicker: TimePickerView { target.hourPicker }
        var minutePicker: TimePickerView { target.minutePicker }
        var secondPicker: TimePickerView { target.secondPicker }
    }
}
#endif
