//
//  CoordinatorMock.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

@testable import Catodoro
import UIKit

class MockCoordinator: Coordinator, Equatable {
    static func == (lhs: MockCoordinator, rhs: MockCoordinator) -> Bool {
        lhs.type == rhs.type
    }
    
    var finishDelegate: (any Catodoro.CoordinatorFinishDelegate)?
    
    var childCoordinators: [any Catodoro.Coordinator]
    
    var navigationController: UINavigationController
    
    var type: Catodoro.CoordinatorType

    init(finishDelegate: (any Catodoro.CoordinatorFinishDelegate)? = nil, childCoordinators: [any Catodoro.Coordinator] = [], navigationController: UINavigationController = .init(), type: Catodoro.CoordinatorType = .app) {
        self.finishDelegate = finishDelegate
        self.childCoordinators = childCoordinators
        self.navigationController = navigationController
        self.type = type
    }
    
    func start() {
    }
}
