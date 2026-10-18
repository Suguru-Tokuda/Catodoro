//
//  TimerViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import CatodoroShared
import Combine
import UIKit

protocol TimerViewControllerDelegate: AnyObject {
    func timerViewControllerDidFinish(_ controller: TimerViewController)
}

final class TimerViewController: BaseViewController {
    weak var delegate: TimerViewControllerDelegate?
    private var cancellables: Set<AnyCancellable> = []
    private var hasExited = false
    private let viewModel: TimerViewModel
    private let timerView: TimerView

    init(preferences: CatodoroPreferencesProtocol?,
         liveActivityManager: LiveActivityManaging?,
         shouldHidesBottomBarWhen: Bool = true
    ) {
        viewModel = TimerViewModel(preferences: preferences, liveActivityManager: liveActivityManager)
        timerView = TimerView(frame: .zero, strokeColor: ColorOptions(preferences?.color ?? "").color)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = shouldHidesBottomBarWhen
        addSubscriptions()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.setHidesBackButton(true, animated: false)
        timerView.onPlayPauseButtonTap = { [weak self] in
            self?.viewModel.handlePlayPauseButtonTap()
        }
        timerView.onSkipBreakTap = { [weak self] in
            self?.viewModel.skipBreak()
        }
        timerView.onStopButtonTap = { [weak self] in
            self?.viewModel.stopTimer()
        }
        timerView.onDismissButtonTap = { [weak self] in
            self?.viewModel.stopTimer()
        }
        timerView.render(viewModel.presentationSubject.value)
    }

    private func addSubscriptions() {
        viewModel.presentationSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.timerView.render(state)
            }
            .store(in: &cancellables)

        viewModel.timerActionSubject
            .dropFirst()
            .filter { $0 == .stop }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, !hasExited else {
                    return
                }

                hasExited = true
                delegate?.timerViewControllerDidFinish(self)
            }
            .store(in: &cancellables)
    }

    func configure(timerConfigViewModel: TimerConfigViewModel) {
        let routine = timerConfigViewModel.timerModel
        TimerController.shared.activeTimer = viewModel
        viewModel.configure(totalDuration: routine.mainTimer.duration,
                            intervalDuration: routine.interval.duration,
                            intervals: routine.intervals)
    }

    override func constructSubviews() {
        super.constructSubviews()
        view.addAutolayoutSubview(timerView)
    }

    override func constructSubviewLayoutConstraints() {
        super.constructSubviewLayoutConstraints()
        NSLayoutConstraint.activate([
            timerView.topAnchor.constraint(equalTo: view.topAnchor),
            timerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}
