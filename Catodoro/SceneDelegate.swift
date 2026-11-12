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
    private var mainCoordinator: MainCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.backgroundColor = CatTheme.background
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let dependencies = appDelegate.dependencies
        // The previous process's activity can't be updated any more; `reconcile()` starts a
        // fresh one if the cycle is still running.
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
        // Nothing to end here. iOS doesn't call this when a suspended app is killed, and when
        // it does (the scene was only discarded) the cycle is still running and keeps its activity.
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

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        mainCoordinator?.handle(url)
    }
}

extension SceneDelegate {
    private func setupAppearance() {
        let barButtonItemAppearance = UIBarButtonItem.appearance()
        barButtonItemAppearance.setBackButtonTitlePositionAdjustment(UIOffset(horizontal: -1000, vertical: 0), for: .default)
    }
}
