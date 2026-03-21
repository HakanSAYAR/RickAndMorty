//
//  SceneDelegate.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let navigationController = UINavigationController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        let container = AppDIContainer()
        let coordinator = AppCoordinator(navigationController: navigationController, container: container)
        appCoordinator = coordinator
        coordinator.start()
    }
}
