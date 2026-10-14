//
//  PresetsView.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 10/11/26.
//

import UIKit

final class PresetsView: BaseView {
    var onCreatePreset: (() -> Void)?

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Presets"
        label.font = CatTheme.font(.title2, weight: .bold)
        label.textColor = CatTheme.text
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        return label
    }()

    let tableView: UITableView = {
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

    private let spinner = UIActivityIndicatorView(style: .large)
    private let loadingBackgroundView = UIView()

    override func constructView() {
        backgroundColor = CatTheme.background
    }

    override func constructSubviews() {
        addAutolayoutSubviews([label, tableView])
        loadingBackgroundView.addAutolayoutSubview(spinner)
        spinner.color = CatTheme.secondaryText
    }

    override func constructSubviewLayoutConstraints() {
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingBackgroundView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: loadingBackgroundView.centerYAnchor),
            label.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            tableView.topAnchor.constraint(equalTo: label.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func showLoading() {
        spinner.startAnimating()
        tableView.backgroundView = loadingBackgroundView
    }

    func hideLoading() {
        spinner.stopAnimating()
        if tableView.backgroundView === loadingBackgroundView {
            tableView.backgroundView = nil
        }
    }

    func render(isEmpty: Bool, showLoading: Bool) {
        if showLoading {
            self.showLoading()
            return
        }
        hideLoading()

        guard isEmpty else {
            tableView.backgroundView = nil
            return
        }

        var configuration = UIContentUnavailableConfiguration.empty()
        configuration.image = UIImage(named: "CatPaw")?.preparingThumbnail(of: CGSize(width: 48, height: 48))
        configuration.text = "Your routines belong here"
        configuration.secondaryText = "Save a favorite rhythm and choose a cat to keep you company."
        configuration.button.title = "Create preset"
        configuration.buttonProperties.primaryAction = UIAction { [weak self] _ in
            self?.onCreatePreset?()
        }
        tableView.backgroundView = UIContentUnavailableView(configuration: configuration)
    }
}
