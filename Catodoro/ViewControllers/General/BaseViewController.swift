//
//  BaseViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/1/25.
//

import UIKit

class BaseViewController: UIViewController {
    var onFinish: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupSubviews()
        setupConstraints()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onFinish?()
    }

    func setupSubviews() {}

    func setupConstraints() {}
}
