//
//  SettingsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class SettingsViewController: UIViewController {
    private weak var coordinator: Coordinator?
    private var vm: SettingsViewModel = .init()
    private var label: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        return label
    }()
    private var scrollView: UIScrollView = .init()
    private var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private var colorOptionSubTitle: SettingSubtitleLabel = .init(labelText: "Color")
    private var colorOptionsList: ColorOptionsList = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.className)
        view.addAutolayoutSubview(scrollView)
        scrollView.addAutolayoutSubview(stackView)
        stackView.addArrangedSubviews([
            colorOptionSubTitle,
            colorOptionsList
        ])
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(self.className)
    }

    func setCoordinator(coordinator: Coordinator) {
        self.coordinator = coordinator
    }
}
