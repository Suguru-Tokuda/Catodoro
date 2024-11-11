//
//  PresetsViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class PresetsViewController: UIViewController {
    private weak var coordinator: Coordinator?
    private var label: UILabel = {
        let label = UILabel()
        label.text = "Presets"
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print(self.className)
        view.addAutolayoutSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
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
