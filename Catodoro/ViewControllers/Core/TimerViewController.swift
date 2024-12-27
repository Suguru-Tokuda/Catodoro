//
//  TimerViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

protocol TimerViewControllerDelegate: AnyObject {
    func timerViewControllerDidFinish(_ controller: TimerViewController)
}

class TimerViewController: UIViewController {
    weak var delegate: TimerViewControllerDelegate?
    private var cancellables: Set<AnyCancellable> = .init()
    private var viewModel: TimerViewModel
    private var timerView: TimerView

    init(preferences: CatodoroPreferencesProtocol?) {
        viewModel = .init(preferences: preferences)
        timerView = .init(frame: .zero, strokeColor: ColorOptions(preferences?.color ?? "").color)
        super.init(nibName: nil, bundle: nil)
        addSubscripitons()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSubviews()
        setupConstraints()
        setActionHandlers()
        navigationItem.setHidesBackButton(true, animated: false)
    }

    func addSubscripitons() {
        viewModel.timerSubject
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timerLabelValue in
                guard let self else { return }
                timerView.setTimerLabelText(labelText: timerLabelValue)
            }
            .store(in: &cancellables)

        viewModel.timerStatusSubject
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timerStatus in
                guard let self else { return }
                timerView.configurePlayPauseButton(timerStatus: timerStatus == .playing ? .playing : .paused)
            }
            .store(in: &cancellables)

        viewModel.timerActionSubject
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timerAction in
                guard let self else { return }
                switch timerAction {
                case .pause:
                    timerView.pauseTimer()
                case .stop:
                    timerView.stopTimer()
                case .start:
                    timerView.startTimer(duration: viewModel.duration)
                case .resume:
                    timerView.resumeTimer()
                case .finish:
                    viewModel.playFinishSound()
                }
            }
            .store(in: &cancellables)

        viewModel.timerLabelSubject
            .subscribe(on: DispatchQueue.global(qos: .userInteractive))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timerNameStr in
                guard let self else { return }
                timerView.setTimerNameLabelText(labelText: timerNameStr)
            }
            .store(in: &cancellables)
    }

    func configure(timerConfigViewModel: TimerConfigViewModel) {
        viewModel.configure(totalDuration: timerConfigViewModel.timerModel.mainTimer.duration,
                            intervalDuration: timerConfigViewModel.timerModel.interval.duration,
                            intervals: timerConfigViewModel.timerModel.intervals)
    }

    private func setupSubviews() {
        view.addAutolayoutSubview(timerView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timerView.topAnchor.constraint(equalTo: view.topAnchor),
            timerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            timerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

// MARK: Action handlers

extension TimerViewController {
    private func setActionHandlers() {
        handlePlayPauseButtonTapped()
        handleStopButton()
    }
    
    private func handlePlayPauseButtonTapped() {
        timerView.onPlayPauseButtonTap = { [weak self] in
            guard let self else { return }
            viewModel.handlePlayPauseButtonTap()
        }
    }
    
    private func handleStopButton() {
        timerView.onStopButtonTap = { [weak self] in
            guard let self else { return }
            viewModel.stopTimer()
            timerView.stopTimer()
            delegate?.timerViewControllerDidFinish(self)
        }
    }
}
