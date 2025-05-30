//
//  AddPresetViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/24/24.
//

import Combine
import UIKit

protocol AddPresetViewControllerDelegate: AnyObject {
    func onFinish()
}

class AddPresetViewController: BaseViewController {
    weak var delegate: AddPresetViewControllerDelegate?
    private var viewModel: TimerConfigViewModelProtocol = TimerConfigViewModel()
    private weak var preferences: CatodoroPreferencesProtocol?
    private var cancellables: Set<AnyCancellable> = .init()

    // MARK: - UI Components

    private let timerConfigView: TimerConfigView = .init()

    init(preferences: CatodoroPreferencesProtocol? = CatodoroPreferences()) {
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEventHandlers()
    }

    override func setupSubviews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Add Preset"
        timerConfigView.model = .init(startLabelText: "Save",
                                      color: ColorOptions(preferences?.color ?? ColorOptions.neonBlue.code).color)
        view.addAutolayoutSubview(timerConfigView)
    }

    override func setupConstraints() {
        NSLayoutConstraint.activate([
            timerConfigView.topAnchor.constraint(equalTo: view.topAnchor),
            timerConfigView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerConfigView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerConfigView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupEventHandlers() {
        timerConfigView.onTotalDurationSelect = { [weak self] (hours, minutes, seconds) in
            guard let self else { return }
            self.viewModel.timerModel.mainTimer = .init(hours: hours,
                                                 minutes: minutes,
                                                 seconds: seconds)
            self.timerConfigView.setStartButtonStatus(isEnabled: self.viewModel.isValidSelection)
        }

        timerConfigView.onIntervalDurationSelect = { [weak self] (hours, minutes, seconds) in
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
            Task(priority: .utility) { [weak self] in
                guard let self else { return }
                do {
                    try await viewModel.addPreset()
                    delegate?.onFinish()
                } catch {
                }
            }
        }
    }
}

#if DEBUG
extension AddPresetViewController {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: AddPresetViewController

        var timerConfigView: TimerConfigView { target.timerConfigView }
        
        func setViewModel(viewModel: TimerConfigViewModelProtocol) {
            target.viewModel = viewModel
        }
    }
}
#endif
