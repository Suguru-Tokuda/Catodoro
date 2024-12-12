//
//  PresetsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class PresetsViewController: UIViewController {
    var onPresetSelected: ((PresetModel) -> Void)?
    private weak var coordinator: Coordinator?
    private var viewModel: PresetsViewModel = .init()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "Presets"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    private lazy var presetsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PresetListViewCell.self,
                           forCellReuseIdentifier: PresetListViewCell.reuseIdentifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
    }

    func setCoordinator(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    private func setupSubviews() {
        presetsTableView.dataSource = self
        presetsTableView.allowsSelection = false
        view.addAutolayoutSubviews([
            label,
            presetsTableView
        ])
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presetsTableView.topAnchor.constraint(equalTo: label.bottomAnchor),
            presetsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            presetsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            presetsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension PresetsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.presets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: PresetListViewCell.reuseIdentifier,
                                                    for: indexPath) as? PresetListViewCell {
            let presetModel = viewModel.presets[indexPath.row]
            cell.model = presetModel
            cell.onPlayButtonTapped = { [weak self] in
                guard let self else { return }
                onPresetSelected?(presetModel)
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
}
