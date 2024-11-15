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
        setupUI()
        setupEventHandlers()
        setUpBackButtonTitle()
    }

    private func setupUI() {
        view.addAutolayoutSubview(timerConfigView)

        NSLayoutConstraint.activate([
            timerConfigView.topAnchor.constraint(equalTo: view.topAnchor),
            timerConfigView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerConfigView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerConfigView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupEventHandlers() {
        timerConfigView.onMainTimerSelect = { (hours, minutes, seconds) in
            self.vm.timerModel.mainTimer = .init(hours: hours,
                                                 minutes: minutes,
                                                 seconds: seconds)
            self.timerConfigView.setStartButtonStatus(isEnabled: self.vm.isValidSelection)
        }

        timerConfigView.onBreakTimerSelect = { (hours, minutes, seconds) in
            self.vm.timerModel.interval = .init(hours: hours,
                                                minutes: minutes,
                                                seconds: seconds)
        }

        timerConfigView.onIntervalSelect = { intervals in
            self.vm.timerModel.numberOfIntervals = intervals
        }

        timerConfigView.onStartButtonTap = {
            if let coordinator = self.coordinator as? TimerCoordiantor {
                coordinator.navigateToTimerView(viewModel: self.vm)
            }
        }
    }

    private func setUpBackButtonTitle() {
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
