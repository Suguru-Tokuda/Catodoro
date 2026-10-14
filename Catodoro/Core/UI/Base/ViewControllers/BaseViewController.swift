//
//  BaseViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 1/1/25.
//

import UIKit

class BaseViewController: UIViewController, Constructable {
    var onFinish: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        construct()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            onFinish?()
        }
    }

    private func construct() {
        constructView()
        constructSubviews()
        constructSubviewLayoutConstraints()
    }

    func constructView() {
        view.backgroundColor = CatTheme.background
    }

    func constructSubviews() {}

    func constructSubviewLayoutConstraints() {}
}
