//
//  SceneDelegate.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var mainCoordinator: Coordinator?
    var liveActivityManager: LiveActivityManaging = LiveActivityManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.backgroundColor = CatTheme.background
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let dependencies = appDelegate.dependencies
        let coordinator = MainCoordinator(preferences: dependencies.preferences, liveActivityManager: liveActivityManager,
                                          coreDataManager: dependencies.coreDataManager,
                                          syncCoordinator: dependencies.syncCoordinator,
                                          syncLifecycleManager: dependencies.syncLifecycleManager
        )
        mainCoordinator = coordinator
        coordinator.start()
        window?.rootViewController = coordinator.navigationController
        window?.windowScene = windowScene
        window?.makeKeyAndVisible()

        window?.overrideUserInterfaceStyle = .unspecified

        UINavigationBar.appearance().tintColor = .white

        setupAppearance()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        liveActivityManager.endLiveActivity()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

extension SceneDelegate {
    private func setupAppearance() {
        let barButtonItemAppearance = UIBarButtonItem.appearance()
        barButtonItemAppearance.setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)
    }
}
