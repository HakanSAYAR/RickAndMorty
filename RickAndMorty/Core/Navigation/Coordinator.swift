//
//  Coordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

// MARK: - Coordinator

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var children: [Coordinator] { get set }
    var onFinish: (() -> Void)? { get set }
    var rootViewController: UIViewController? { get }
    func start()
}

// MARK: - Default Implementation

extension Coordinator {

    var rootViewController: UIViewController? { nil }

    func add(child: Coordinator) {
        children.append(child)
    }

    func remove(child: Coordinator) {
        children = children.filter { $0 !== child }
    }

    /// Walks the coordinator tree and finishes the owner of `viewController`. onFinish fires at most once.
    func didPop(viewController: UIViewController) {
        for child in children where child.rootViewController === viewController {
            let finish = child.onFinish
            child.onFinish = nil
            finish?()
            return
        }
        children.forEach { $0.didPop(viewController: viewController) }
    }
}
