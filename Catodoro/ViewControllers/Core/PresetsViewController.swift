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
    private var viewModel: PresetsViewModelProtocol = PresetsViewModel()
    private var cancellables: Set<AnyCancellable> = .init()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Presets"
        label.font = CatTheme.font(.title2, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()
    private let presetsTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = CatTheme.background
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 180
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
        setupAddButton()
        addSubscriptions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.tintColor = ColorOptions.neonBlue.color
        reloadPresets()
    }

    override func setupSubviews() {
        super.setupSubviews()
        presetsTableView.delegate = self
        presetsTableView.dataSource = self
        presetsTableView.allowsSelection = true
        view.backgroundColor = CatTheme.background
        view.addAutolayoutSubviews([
            label,
            presetsTableView
        ])
    }

    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            presetsTableView.topAnchor.constraint(equalTo: label.bottomAnchor),
            presetsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            presetsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            presetsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func reloadPresets() {
        Task { [weak self] in
            guard let self else { return }

            let spinner = UIActivityIndicatorView(style: .medium)
            if self.viewModel.presets.isEmpty {
                spinner.startAnimating()
                self.presetsTableView.backgroundView = spinner
            }

            await self.viewModel.loadPresets()
            self.updateEmptyState()
            self.showPersistenceErrorIfNeeded()
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
        viewModel.presetsPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.presetsTableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
    }

    private func updateEmptyState() {
        guard viewModel.presets.isEmpty else {
            presetsTableView.backgroundView = nil
            return
        }

        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(named: "CatPaw")?.preparingThumbnail(of: CGSize(width: 48, height: 48))
        configuration.text = "Your routines belong here"
        configuration.secondaryText = "Save a favorite rhythm and choose a cat to keep you company."
        configuration.button.title = "Create preset"
        configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
            self?.handleAddButtonTap()
        }
        presetsTableView.backgroundView = UIContentUnavailableView(configuration: configuration)
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

        var presetsTableView: UITableView { target.presetsTableView }
        func setViewModel(viewModel: PresetsViewModelProtocol) { target.viewModel = viewModel}
        func handleAddButtonTap() { target.handleAddButtonTap() }
    }
}
#endif
