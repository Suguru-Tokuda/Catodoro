//
//  BaseOptionSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class BaseOptionSelectionViewController: BaseViewController {
    // MARK: UI Components
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = CatTheme.font(.title2, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    let optionTableView: UITableView = {
       let tableView = UITableView()
        tableView.backgroundColor = CatTheme.background
        tableView.separatorColor = CatTheme.separator
        tableView.register(OptionSelectionViewCell.self,
                           forCellReuseIdentifier: OptionSelectionViewCell.reuseIdentifier)
        return tableView
    }()

    init(titleLabelText: String) {
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = titleLabelText
        titleLabel.isHidden = true
        title = titleLabelText
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func constructSubviews() {
        view.addAutolayoutSubviews([
            titleLabel,
            optionTableView
        ])
    }

    override func constructSubviewLayoutConstraints() {
        NSLayoutConstraint.activate([
            optionTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            optionTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            optionTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            optionTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
