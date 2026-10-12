//
//  TimerConfigViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 9/30/24.
//

import Combine
import UIKit

protocol TimerConfigViewControllerDelegate: AnyObject {
    func didFinishConfiguring(viewModel: TimerConfigViewModel)
}

class TimerConfigViewController: BaseViewController {
    weak var delegate: TimerConfigViewControllerDelegate?
    private var viewModel = TimerConfigViewModel()
    private weak var preferences: CatodoroPreferencesProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: UI Components
    private let timerConfigView: TimerConfigView = TimerConfigView()

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
        setupEventHandlers()
        setupBackButtonTitle()
        addSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func constructSubviews() {
        super.constructSubviews()
        view.addAutolayoutSubview(timerConfigView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            timerConfigView.topAnchor.constraint(equalTo: view.topAnchor),
            timerConfigView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerConfigView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerConfigView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupEventHandlers() {
        timerConfigView.render(viewModel.timerModel)
        timerConfigView.onSelectionRequest = { [weak self] selection in
            guard let self else { return }

            presentRoutineSelection(selection, configuration: self.viewModel.timerModel,
                                         accent: ColorOptions(self.preferences?.color ?? "").color) { [weak self] updated in
                guard let self else { return }

                viewModel.timerModel = updated
                timerConfigView.render(updated)
            }
        }

        timerConfigView.onStartButtonTap = { [weak self] in
            guard let self else { return }
            delegate?.didFinishConfiguring(viewModel: viewModel)
        }
    }

    private func setupBackButtonTitle() {
        let backButton = UIBarButtonItem(title: "Timer Config",
                                         style: .plain,
                                         target: nil,
                                         action: nil)
        navigationItem.backBarButtonItem = backButton
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
