//
//  AlertStyleSelectionViewController.swift
//  Catodoro
//  Created by Suguru Tokuda on 11/11/26.
//

import CatodoroShared
import UIKit

protocol AlertStyleSelectionViewControllerDelegate: AnyObject {
    /// Done was tapped; the screen can be dismissed.
    func alertStyleSelectionViewControllerDidFinish(_ viewController: AlertStyleSelectionViewController)
    /// The screen left the navigation stack (Back, swipe, Done or pop).
    func alertStyleSelectionViewControllerDidClose(_ viewController: AlertStyleSelectionViewController)
}

/// Lets the user choose how a phase ending is announced: AlarmKit alarm,
/// notification, or Live Activity only. The view model asks for any permission
/// the choice needs; this screen only shows the result.
final class AlertStyleSelectionViewController: BaseOptionSelectionViewController {
    weak var delegate: AlertStyleSelectionViewControllerDelegate?
    private let viewModel: AlertStyleSelectionViewModel
    private var selectionTask: Task<Void, Never>?

    init(viewModel: AlertStyleSelectionViewModel, titleLabelText: String) {
        self.viewModel = viewModel
        super.init(titleLabelText: titleLabelText)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        optionTableView.delegate = self
        optionTableView.dataSource = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            delegate?.alertStyleSelectionViewControllerDidClose(self)
        }
    }

    @objc private func doneTapped() {
        delegate?.alertStyleSelectionViewControllerDidFinish(self)
    }

    private func select(at index: Int) {
        // Ignore taps while a permission prompt is still being answered.
        guard selectionTask == nil else { return }

        selectionTask = Task { @MainActor [weak self] in
            guard let viewModel = self?.viewModel else { return }
            let result = await viewModel.selectOption(at: index)
            guard let self else { return }
            selectionTask = nil

            switch result {
            case .saved:
                optionTableView.reloadData()
            case .permissionDenied(let style):
                showPermissionDeniedAlert(for: style)
            case .ignored:
                break
            }
        }
    }

    private func showPermissionDeniedAlert(for style: AlertStyle) {
        let isAlarm = style == .alarm
        let alert = UIAlertController(
            title: isAlarm ? AppStrings.AlertStyles.alarmsTurnedOff : AppStrings.AlertStyles.notificationsTurnedOff,
            message: isAlarm ? AppStrings.AlertStyles.allowAlarmsInSettings : AppStrings.AlertStyles.allowNotificationsInSettings,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: AppStrings.AlertStyles.openSettings, style: .default) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        alert.addAction(UIAlertAction(title: AppStrings.Common.ok, style: .cancel))
        present(alert, animated: true)
    }
}

extension AlertStyleSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        select(at: indexPath.row)
    }
}

extension AlertStyleSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OptionSelectionViewCell.reuseIdentifier,
                                                       for: indexPath) as? OptionSelectionViewCell else {
            return UITableViewCell()
        }
        let option = viewModel.options[indexPath.row]
        cell.configure(optionLabelText: option.title, isSelected: option.selected)
        return cell
    }
}
