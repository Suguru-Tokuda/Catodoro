//
//  PresetsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

protocol PresetsViewControllerDelegate: AnyObject {
    func presetsViewControllerDidRequestEdit(_ viewController: PresetsViewController, preset: PresetModel)
    func presetsViewControllerDidSelectPreset(_ viewController: PresetsViewController, preset: PresetModel)
    func presetsViewControllerDidTapAddButton(_ viewController: PresetsViewController, onFinish: @escaping(() -> Void))
}

class PresetsViewController: BaseViewController {
    weak var delegate: PresetsViewControllerDelegate?
    private var viewModel: PresetsViewModelProtocol
    private var cancellables: Set<AnyCancellable> = .init()

    private let presetsView = PresetsView()
    private weak var preferences: CatodoroPreferencesProtocol?

    private var accent: UIColor {
        ColorOptions(preferences?.color ?? "").color
    }

    init(preferences: CatodoroPreferencesProtocol? = nil, viewModel: PresetsViewModelProtocol) {
        self.viewModel = viewModel
        self.preferences = preferences
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = presetsView
    }

    deinit {
        removeSubscriptions()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        presetsView.tableView.delegate = self
        presetsView.tableView.dataSource = self
        presetsView.onCreatePreset = { [weak self] in
            self?.handleAddButtonTap()
        }
        setupAddButton()
        addSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = accent
        presetsView.tintColor = accent
        presetsView.tableView.reloadData()
        reloadPresets()
    }

    private func reloadPresets() {
        Task { [weak self] in
            guard let self else { return }

            await viewModel.loadPresets()
            updateEmptyState()
            showPersistenceErrorIfNeeded()
        }
    }

    private func showPersistenceErrorIfNeeded() {
        guard let error = viewModel.coreDataError, presentedViewController == nil else { return }

        let alert = UIAlertController(title: "Couldn't update presets", message: "Please try again. Your saved presets have not been removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        if error == .get {
            alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                self?.reloadPresets()
            })
        }
        present(alert, animated: true)
    }

    private func setupAddButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddButtonTap))
        navigationItem.rightBarButtonItem = addButton
    }

    private func addSubscriptions() {
        preferences?.colorPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }

                presetsView.tintColor = accent
                navigationController?.navigationBar.tintColor = accent
                presetsView.tableView.reloadData()
            }
            .store(in: &cancellables)


        viewModel.presetsPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }

                presetsView.tableView.reloadData()
                updateEmptyState()
            }
            .store(in: &cancellables)

        viewModel.loadingStatePublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] loadingState in
                guard let self else { return }

                presetsView.render(
                    isEmpty: viewModel.presets.isEmpty,
                    showLoading: loadingState == .loading
                )
            }
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        presetsView.render(
            isEmpty: viewModel.presets.isEmpty,
            showLoading: viewModel.loadingState == .loading
        )
    }

    private func removeSubscriptions() {
        cancellables.removeAll()
    }
}

extension PresetsViewController {
    @objc private func handleAddButtonTap() {
        delegate?.presetsViewControllerDidTapAddButton(self, onFinish: {})
    }
}

extension PresetsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.presetsViewControllerDidRequestEdit(self, preset: viewModel.presets[indexPath.row])
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let preset = viewModel.presets[indexPath.row]
            Task(priority: .utility) {
                await viewModel.deletePreset(preset)
                showPersistenceErrorIfNeeded()
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
            cell.accent = accent
            cell.model = presetModel
            cell.onPlayButtonTapped = { [weak self] in
                guard let self else { return }

                self.delegate?.presetsViewControllerDidSelectPreset(self, preset: presetModel)
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

        var presetsTableView: UITableView { target.presetsView.tableView }
        func setViewModel(viewModel: PresetsViewModelProtocol) { target.viewModel = viewModel}
        func handleAddButtonTap() { target.handleAddButtonTap() }
    }
}
#endif
