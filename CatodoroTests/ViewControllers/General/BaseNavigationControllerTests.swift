//
//  BaseNavigationControllerTests.swift
//  CatodoroTests
//
//  Created by Suguru Tokuda on 12/25/24.
//

import XCTest
@testable import Catodoro

final class BaseNavigationControllerTests: XCTestCase {

    var navigationController: BaseNavigationController!

    override func setUp() {
        super.setUp()
        // Create an instance of CustomNavigationController
        navigationController = BaseNavigationController()
        
        // Load the view hierarchy
        _ = navigationController.view
    }

    override func tearDown() {
        navigationController = nil
        super.tearDown()
    }

    func test_viewDidLoad_setsDelegate() {
        // When
        _ = navigationController.view // Trigger viewDidLoad
        
        // Then
        XCTAssertEqual(navigationController.delegate as? BaseNavigationController, navigationController, "The navigation controller's delegate should be set to itself.")
    }

    func test_contains_withValidViewController_returnsTrue() {
        // Given
        let viewController = UIViewController()
        
        // Push the view controller to the navigation stack
        navigationController.pushViewController(viewController, animated: false)
        
        // When
        let contains = navigationController.contains(viewController: viewController)
        
        // Then
        XCTAssertTrue(contains, "The navigation controller should contain the pushed view controller.")
    }

    func test_contains_withInvalidViewController_returnsFalse() {
        // Given
        let viewController = UIViewController()
        
        // When
        let contains = navigationController.contains(viewController: viewController)
        
        // Then
        XCTAssertFalse(contains, "The navigation controller should not contain a view controller that wasn't pushed.")
    }

    func test_pushViewController_whenDuplicateViewController_expectViewControllerNotPushedAgain() {
        // Given
        let viewController = UIViewController()
        
        // Push the view controller initially
        navigationController.pushViewController(viewController, animated: false)
        
        // When
        navigationController.pushViewController(viewController, animated: false)
        
        // Then
        XCTAssertEqual(navigationController.viewControllers.count, 1, "The navigation controller should not push the same view controller multiple times.")
    }

    func test_pushViewController_whenNewViewController_expectViewControllerPushed() {
        // Given
        let firstViewController = UIViewController()
        let secondViewController = UIViewController()
        
        // Push the first view controller
        navigationController.pushViewController(firstViewController, animated: false)
        
        // When
        navigationController.pushViewController(secondViewController, animated: false)
        
        // Then
        XCTAssertEqual(navigationController.viewControllers.count, 1, "The navigation controller should push a new view controller when a different one is added.")
    }

    func test_navigationController_didShow_updatesIsNewViewControllerBeingAddedFlag() {
        // Given
        let viewController = UIViewController()
        
        // Push a view controller
        navigationController.pushViewController(viewController, animated: false)
        
        // When
        navigationController.delegate?.navigationController?(navigationController, didShow: viewController, animated: false)
        
        // Then
        XCTAssertFalse(navigationController.isNewViewControllerBeingAdded, "The flag should be reset to false after a view controller is shown.")
    }
}
