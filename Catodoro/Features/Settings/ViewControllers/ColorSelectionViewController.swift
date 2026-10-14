//
//  ColorSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

protocol ColorSelectionViewControllerDelegate: AnyObject {
    func onColorSelected()
}

class ColorSelectionViewController: BaseOptionSelectionViewController {
    weak var delegate: ColorSelectionViewControllerDelegate?
    var viewModel: OptionSelectionViewModel

    init(viewModel: OptionSelectionViewModel, titleLabelText: String) {
        self.viewModel = viewModel
        super.init(titleLabelText: titleLabelText)
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        optionTableView.delegate = self
        optionTableView.dataSource = self
    }
}

extension ColorSelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedId = viewModel.options[indexPath.row].id
        viewModel.selectedId = selectedId
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.setColor(colorCode: selectedId)
        optionTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            delegate?.onColorSelected()
        }
    }
}

extension ColorSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: OptionSelectionViewCell.reuseIdentifier, for: indexPath) as? OptionSelectionViewCell {
            let option = viewModel.options[indexPath.row]
            cell.configure(optionLabelText: option.title, isSelected: option.selected, textColor: option.color)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
