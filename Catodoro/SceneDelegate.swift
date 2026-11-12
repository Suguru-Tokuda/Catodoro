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
    private var mainCoordinator: Coordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.backgroundColor = CatTheme.background
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let dependencies = appDelegate.dependencies
        // Timer state isn't restored across launches, so any existing activity is orphaned.
        dependencies.liveActivityManager.endStaleActivities()

        let coordinator = MainCoordinator(dependencies: dependencies)
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
        (UIApplication.shared.delegate as? AppDelegate)?.dependencies.liveActivityManager.endLiveActivity()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        Task { await appDelegate.dependencies.countdown.reconcile() }
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
