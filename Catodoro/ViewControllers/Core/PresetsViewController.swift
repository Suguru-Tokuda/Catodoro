//
//  PresetsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

protocol PresetsViewControllerDelegate: AnyObject {
    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel)
    func presetsViewControllerDidTapAddButton(_ viewController: PresetsViewController, onFinish: @escaping(() -> Void))
}

class PresetsViewController: BaseViewController {
    weak var delegate: PresetsViewControllerDelegate?
    private var viewModel: PresetsViewModelProtocol = PresetsViewModel()
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
        tableView.separatorInset = .init(top: 0, left: 0, bottom: 0, right: 0)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task(priority: .utility) {
            await viewModel.loadPresets()
        }
    }

    override func setupSubviews() {
        super.setupSubviews()
        presetsTableView.delegate = self
        presetsTableView.dataSource = self
        presetsTableView.allowsSelection = false
        view.addAutolayoutSubviews([
            label,
            presetsTableView
        ])
    }

    override func setupConstraints() {
        super.setupSubviews()
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
        viewModel.presetsPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.presetsTableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
    }
}

extension PresetsViewController {
    @objc private func handleAddButtonTap() {
        delegate?.presetsViewControllerDidTapAddButton(self) { [weak self] in
            guard let self else { return }
            Task(priority: .utility) { [weak self] in
                guard let self else { return }
                await viewModel.loadPresets()
            }
        }
    }
}

extension PresetsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let preset = viewModel.presets[indexPath.row]
            Task(priority: .utility) {
                await viewModel.deletePreset(preset)
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
                self?.delegate?.presetsViewControllerDidSelectPreset(self!, preset: presetModel)
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
}


#if DEBUG
extension PresetsViewController {
    var testHooks: TestHooks {
        .init(target: self)
    }

    struct TestHooks {
        let target: PresetsViewController

        var presetsTableView: UITableView { target.presetsTableView }
        func setViewModel(viewModel: PresetsViewModelProtocol) { target.viewModel = viewModel}
        func handleAddButtonTap() { target.handleAddButtonTap() }
    }
}
#endif
