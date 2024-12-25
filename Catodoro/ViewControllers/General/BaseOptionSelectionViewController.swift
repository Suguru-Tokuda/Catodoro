//
//  BaseOptionSelectionViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 12/10/24.
//

import UIKit

class BaseOptionSelectionViewController: UIViewController {
    weak var coordinator: Coordinator?

    // MARK: UI Components
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    lazy var optionTableView: UITableView = {
       let tableView = UITableView()
        tableView.register(OptionSelectionViewCell.self,
                           forCellReuseIdentifier: OptionSelectionViewCell.reuseIdentifier)
        return tableView
    }()

    init(titleLabelText: String) {
        super.init(nibName: nil, bundle: nil)
        titleLabel.text = titleLabelText
    }

    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSubviewss()
        setupConstraints()
    }

    private func setupSubviewss() {
        view.addAutolayoutSubviews([
            titleLabel,
            optionTableView
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            optionTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            optionTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            optionTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            optionTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func setCoordinator(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
