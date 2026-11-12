//
//  SoundSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import CatodoroShared
import UIKit

protocol SoundSelectionViewControllerDelegate: AnyObject {
    /// Done was tapped; the screen can be dismissed.
    func soundSelectionViewControllerDidFinish(_ viewController: SoundSelectionViewController)
    /// The screen left the navigation stack (Back, swipe, Done or pop).
    func soundSelectionViewControllerDidClose(_ viewController: SoundSelectionViewController)
}

final class SoundSelectionViewController: BaseOptionSelectionViewController {
    weak var delegate: SoundSelectionViewControllerDelegate?
    private let viewModel: SoundSelectionViewModel

    init(viewModel: SoundSelectionViewModel, titleLabelText: String) {
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
        viewModel.onPreviewFailed = { [weak self] _ in
            self?.showPreviewFailedAlert()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            viewModel.stopPreview()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            delegate?.soundSelectionViewControllerDidClose(self)
        }
    }

    @objc private func doneTapped() {
        delegate?.soundSelectionViewControllerDidFinish(self)
    }

    private func showPreviewFailedAlert() {
        let alert = UIAlertController(title: AppStrings.Settings.couldntPreviewSound,
                                      message: AppStrings.Settings.pleaseTryAgain,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.Common.ok, style: .default))
        present(alert, animated: true)
    }
}

extension SoundSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectOption(at: indexPath.row)
        optionTableView.reloadData()
    }
}

extension SoundSelectionViewController: UITableViewDataSource {
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
