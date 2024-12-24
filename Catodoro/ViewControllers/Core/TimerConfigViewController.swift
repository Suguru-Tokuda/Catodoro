//
//  TimerConfigViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Combine
import UIKit

class TimerConfigViewController: UIViewController {
    private weak var coordinator: Coordinator?
    private var viewModel: TimerConfigViewModel = .init()
    private weak var preferences: CatodoroPreferencesProtocol?
    private var cancellables: Set<AnyCancellable> = .init()
    
    // MARK: UI Components
    private lazy var timerConfigView: TimerConfigView = .init()

    init(preferences: CatodoroPreferencesProtocol?) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        removeSubscriptions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
        setupEventHandlers()
        setupBackButtonTitle()
        addSubscriptions()
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
            self.viewModel.timerModel.mainTimer = .init(hours: hours,
                                                 minutes: minutes,
                                                 seconds: seconds)
            self.timerConfigView.setStartButtonStatus(isEnabled: self.viewModel.isValidSelection)
        }

        timerConfigView.onBreakTimerSelect = { [weak self] (hours, minutes, seconds) in
            guard let self else { return }
            self.viewModel.timerModel.interval = .init(hours: hours,
                                                minutes: minutes,
                                                seconds: seconds)
        }

        timerConfigView.onIntervalSelect = { [weak self] intervals in
            guard let self else { return }
            self.viewModel.timerModel.intervals = intervals
        }

        timerConfigView.onStartButtonTap = { [weak self] in
            guard let self else { return }
            if let coordinator = self.coordinator as? TimerCoordiantor {
                coordinator.navigateToTimerView(viewModel: self.viewModel)
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

    func addSubscriptions() {
        preferences?
            .colorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] colorStr in
                guard let self,
                      let colorStr else { return }
                let color = ColorOptions(colorStr).color
                timerConfigView.model = .init(color: color)
            }
            .store(in: &cancellables)
    }

    func removeSubscriptions() {
        cancellables.removeAll()
    }
}
