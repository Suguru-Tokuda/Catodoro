//
//  BaseNavigationController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class BaseNavigationController: UINavigationController {
    var isNewViewControllerBeingAdded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        view.backgroundColor = CatTheme.background
        let appearance = UINavigationBarAppearance()
        // Opaque + clear has neither fill nor blur; the default background uses the system material.
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: CatTheme.text, .font: CatTheme.font(.headline, weight: .bold)]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = ColorOptions.neonBlue.color
    }

    func contains(viewController: UIViewController) -> Bool {
        return viewControllers.map { $0.className }.contains(viewController.className)
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if (!isNewViewControllerBeingAdded && !contains(viewController: viewController)) {
            isNewViewControllerBeingAdded = true
            super.pushViewController(viewController, animated: animated)
        }
    }
}

extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        isNewViewControllerBeingAdded = false
    }
}
