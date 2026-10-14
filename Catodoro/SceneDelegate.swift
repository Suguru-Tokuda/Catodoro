//
//  SceneDelegate.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 8/21/24.
//

import Combine
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var themeSubscription: AnyCancellable?
    var window: UIWindow?
    var mainCoordinator: Coordinator?
    var liveActivityManager: LiveActivityManaging = LiveActivityManager()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.backgroundColor = CatTheme.background
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        // Timer state isn't restored across launches, so any existing activity is orphaned.
        liveActivityManager.endStaleActivities()
        let dependencies = appDelegate.dependencies
        let coordinator = MainCoordinator(preferences: dependencies.preferences, liveActivityManager: liveActivityManager,
                                          coreDataManager: dependencies.coreDataManager,
                                          syncLifecycleManager: dependencies.syncLifecycleManager
        )
        mainCoordinator = coordinator
        coordinator.start()
        window?.rootViewController = coordinator.navigationController
        window?.windowScene = windowScene
        window?.overrideUserInterfaceStyle = dependencies.preferences.theme.interfaceStyle
        themeSubscription = dependencies.preferences.themePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.window?.overrideUserInterfaceStyle = theme.interfaceStyle
            }

        window?.makeKeyAndVisible()

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
