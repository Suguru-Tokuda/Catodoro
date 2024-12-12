//
//  ColorSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class ColorSelectionViewController: BaseOptionSelectionViewController {
    var vm: OptionSelectionViewModel

    init(vm: OptionSelectionViewModel, titleLabelText: String) {
        self.vm = vm
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
        let selectedId = vm.options[indexPath.row].id
        vm.selectedId = selectedId
        tableView.deselectRow(at: indexPath, animated: true)
        vm.setColor(colorCode: selectedId)
        optionTableView.reloadData()
    }
}

extension ColorSelectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vm.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: OptionSelectionViewCell.reuseIdentifier, for: indexPath) as? OptionSelectionViewCell {
            let option = vm.options[indexPath.row]
            cell.configure(optionLabelText: option.title, isSelected: option.selected)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
