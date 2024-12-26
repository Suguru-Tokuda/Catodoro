//
//  SettingsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func onSettingMenuSelected(settingOption: SettingOptions)
}

class SettingsViewController: UIViewController {
    weak var delegate: SettingsViewControllerDelegate?
    var preferences: CatodoroPreferencesProtocol?
    private var viewModel: SettingsViewModel = .init()
    private var label: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    private var colorOptionSubTitle: SettingSubtitleLabel = .init(labelText: "Color")
    private var optionTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SettingOptionsViewCell.self,
                           forCellReuseIdentifier: SettingOptionsViewCell.reuseIdentifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        optionTableView.delegate = self
        optionTableView.dataSource = self
        setupSubviewss()
        setupConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func setupSubviewss() {
        view.addAutolayoutSubviews([
            label,
            optionTableView
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            optionTableView.topAnchor.constraint(equalTo: label.bottomAnchor),
            optionTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            optionTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            optionTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = viewModel.settingOptions[indexPath.row]
        if let settingModel = SettingOptions.init(rawValue: selectedOption.title) {
            delegate?.onSettingMenuSelected(settingOption: settingModel)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.settingOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: SettingOptionsViewCell.reuseIdentifier,
                                                    for: indexPath) as? SettingOptionsViewCell {
            let optionLabelText = viewModel.settingOptions[indexPath.row].title
            let iconName = viewModel.settingOptions[indexPath.row].iconName
            cell.configure(settingLabelText: optionLabelText, iconName: iconName)
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
