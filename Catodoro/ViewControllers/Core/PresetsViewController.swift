//
//  PresetsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

class PresetsViewController: UIViewController {
    var onPresetSelected: ((PresetModel) -> Void)?
    private weak var coordinator: Coordinator?
    private var viewModel: PresetsViewModel = .init()
    private var cancellables: Set<AnyCancellable> = .init()

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

    deinit {
        removeSubscriptions()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        setupConstraints()
        setupAddButton()
        addSubscriptions()
        Task(priority: .utility) {
            await viewModel.loadPresets()
        }
    }

    func setCoordinator(coordinator: Coordinator) {
        self.coordinator = coordinator
    }

    private func setupSubviews() {
        presetsTableView.delegate = self
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

    private func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddButtonTap))
        navigationItem.rightBarButtonItem = addButton
    }

    private func addSubscriptions() {
        viewModel.$presets.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                presetsTableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
    }
}

extension PresetsViewController {
    @objc private func handleAddButtonTap() {
        if let coordinator = coordinator as? PresetsCoordinator {
            coordinator.navigateToAddPreset { [weak self] in
                Task(priority: .utility) {
                    await self?.viewModel.loadPresets()
                }
            }
        }
    }
}

extension PresetsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Task(priority: .utility) {
                let preset = viewModel.presets[indexPath.row]
                await viewModel.deletePrset(preset)
            }
        }
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
