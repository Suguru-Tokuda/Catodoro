//
//  MainCoordinator.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

enum TabBarPage {
    case timer
    case presets
    case settings

    init?(index: Int) {
        switch index {
        case 0:
            self = .timer
        case 1:
            self = .presets
        case 2:
            self = .settings
        default:
            return nil
        }
    }
    
    var tabTitle: String {
        switch self {
        case .timer:
            return "Timer"
        case .presets:
            return "Presets"
        case .settings:
            return "Settings"
        }
    }

    var tabOrderNumber: Int {
        switch self {
        case .timer:
            return 0
        case .presets:
            return 1
        case .settings:
            return 2
        }
    }

    var tabImage: UIImage? {
        switch self {
        case .timer:
            return UIImage(systemName: "timer")
        case .presets:
            return UIImage(systemName: "list.bullet")
        case .settings:
            return UIImage(systemName: "gear")
        }
    }
}

protocol MainCoordinatorProtocol: Coordinator {
    func showMainFlow()
}

class MainCoordinator: MainCoordinatorProtocol {
    weak var finishDelegate: CoordinatorFinishDelegate? = nil
    var navigationController: UINavigationController
    var childCoordinators = [Coordinator]()
    var type: CoordinatorType { .app }

    required init(_ navigationController: UINavigationController = CustomNavigationController()) {
        self.navigationController = navigationController
        navigationController.setNavigationBarHidden(true, animated: false)
    }

    func start() {
        showMainFlow()
    }

    func showMainFlow() {
        let tabCoordinator = TabCoordinator.init(navigationController)
        tabCoordinator.finishDelegate = self
        tabCoordinator.start()
        childCoordinators.append(tabCoordinator)
    }
}

extension MainCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: any Coordinator) {
        childCoordinators = childCoordinators.filter({ $0.type != childCoordinator.type })
    }
}
