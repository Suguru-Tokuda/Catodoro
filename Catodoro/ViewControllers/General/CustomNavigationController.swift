//
//  CustomNavigationController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class CustomNavigationController: UINavigationController {
    var isNewViewControllerBeingAdded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }

    func contains(viewController: UIViewController) -> Bool {
        return self.viewControllers.map { $0.className }.contains(viewController.className)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if (!self.isNewViewControllerBeingAdded && !self.contains(viewController: viewController)) {
            self.isNewViewControllerBeingAdded = true
            super.pushViewController(viewController, animated: true)
        }
    }
}

extension CustomNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.isNewViewControllerBeingAdded = false
    }
}
