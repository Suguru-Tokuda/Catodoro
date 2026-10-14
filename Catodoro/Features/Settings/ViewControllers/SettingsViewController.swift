//
//  SettingsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func onSettingMenuSelected(settingOption: SettingOptions)
}

final class SettingsViewController: UIViewController {
    weak var delegate: SettingsViewControllerDelegate?
    private let settingsView = SettingsView()
    private let viewModel: SettingsViewModel
    private var subscriptions = Set<AnyCancellable>()

    init(preferences: CatodoroPreferencesProtocol? = nil) {
        viewModel = SettingsViewModel(preferences: preferences)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = settingsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        settingsView.onColorSelected = { [weak self] color in
            self?.viewModel.selectColor(color)
        }
        settingsView.onSoundRequested = { [weak self] in
            self?.delegate?.onSettingMenuSelected(settingOption: .sound)
        }
        settingsView.onLiveActivityChanged = { [weak self] enabled in
            self?.viewModel.setLiveActivityEnabled(enabled)
        }
        settingsView.onSystemSettingsRequested = {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }

            UIApplication.shared.open(url)
        }
        viewModel.statePublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.settingsView.render(state)
            }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.viewModel.refresh()
            }
            .store(in: &subscriptions)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.refresh()
        navigationController?.navigationBar.tintColor = viewModel.state.color.color
    }
}
