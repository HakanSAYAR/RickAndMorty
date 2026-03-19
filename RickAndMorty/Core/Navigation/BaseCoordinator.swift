//
//  BaseCoordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

// MARK: - BaseCoordinator

class BaseCoordinator: NSObject, Coordinator {

    // MARK: - Coordinator

    let navigationController: UINavigationController
    var children: [Coordinator] = []
    var onFinish: (() -> Void)?
    var rootViewController: UIViewController?

    // MARK: - Init

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    // MARK: - Start

    func start() {}
}
