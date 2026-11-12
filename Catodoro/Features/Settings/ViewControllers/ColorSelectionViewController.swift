//
//  ColorSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

protocol ColorSelectionViewControllerDelegate: AnyObject {
    /// A color was picked; the screen can be dismissed.
    func colorSelectionViewControllerDidFinish(_ viewController: ColorSelectionViewController)
    /// The screen left the navigation stack (Back, swipe or pop).
    func colorSelectionViewControllerDidClose(_ viewController: ColorSelectionViewController)
}

final class ColorSelectionViewController: BaseOptionSelectionViewController {
    weak var delegate: ColorSelectionViewControllerDelegate?
    private let viewModel: ColorSelectionViewModel

    init(viewModel: ColorSelectionViewModel, titleLabelText: String) {
        self.viewModel = viewModel
        super.init(titleLabelText: titleLabelText)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func constructSubviews() {
        super.constructSubviews()
        optionTableView.delegate = self
        optionTableView.dataSource = self
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            delegate?.colorSelectionViewControllerDidClose(self)
        }
    }
}

extension ColorSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectOption(at: indexPath.row)
        optionTableView.reloadData()

        // Short pause so the paw moves before the screen pops.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            delegate?.colorSelectionViewControllerDidFinish(self)
        }
    }
}

extension ColorSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OptionSelectionViewCell.reuseIdentifier,
                                                       for: indexPath) as? OptionSelectionViewCell else {
            return UITableViewCell()
        }
        let option = viewModel.options[indexPath.row]
        cell.configure(optionLabelText: option.title, isSelected: option.selected, textColor: option.color)
        return cell
    }
}
