//
//  TimerConfigViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import UIKit

class TimerConfigViewController: UIViewController {
    private weak var coordinator: Coordinator?
    private var vm = TimerConfigViewModel()
    
    // MARK: UI Components
    private lazy var timerConfigView: TimerConfigView = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
        setupEventHandlers()
        setupBackButtonTitle()
    }

    private func setupSubviews() {
        view.addAutolayoutSubview(timerConfigView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timerConfigView.topAnchor.constraint(equalTo: view.topAnchor),
            timerConfigView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerConfigView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerConfigView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupEventHandlers() {
        timerConfigView.onMainTimerSelect = { [weak self] (hours, minutes, seconds) in
            guard let self else { return }
            self.vm.timerModel.mainTimer = .init(hours: hours,
                                                 minutes: minutes,
                                                 seconds: seconds)
            self.timerConfigView.setStartButtonStatus(isEnabled: self.vm.isValidSelection)
        }

        timerConfigView.onBreakTimerSelect = { [weak self] (hours, minutes, seconds) in
            guard let self else { return }
            self.vm.timerModel.interval = .init(hours: hours,
                                                minutes: minutes,
                                                seconds: seconds)
        }

        timerConfigView.onIntervalSelect = { [weak self] intervals in
            guard let self else { return }
            self.vm.timerModel.intervals = intervals
        }

        timerConfigView.onStartButtonTap = { [weak self] in
            guard let self else { return }
            if let coordinator = self.coordinator as? TimerCoordiantor {
                coordinator.navigateToTimerView(viewModel: self.vm)
            }
        }
    }

    private func setupBackButtonTitle() {
        let backButton = UIBarButtonItem(title: "Timer Config",
                                         style: .plain,
                                         target: nil,
                                         action: nil)
        navigationItem.backBarButtonItem = backButton
    }

    func setCoordinator(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
