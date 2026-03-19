//
//  AppCoordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

// MARK: - AppCoordinator

final class AppCoordinator: BaseCoordinator {

    // MARK: - Private

    private let container: AppDIContainer

    // MARK: - Init

    init(navigationController: UINavigationController, container: AppDIContainer) {
        self.container = container
        super.init(navigationController: navigationController)
    }

    // MARK: - BaseCoordinator

    override func start() {
        let coordinator = CharacterListCoordinator(
            navigationController: navigationController,
            fetchCharactersUseCase: container.fetchCharactersUseCase,
            fetchGalleryItemsUseCase: container.fetchGalleryItemsUseCase,
            savePhotoUseCase: container.savePhotoUseCase,
            galleryChangeObserver: container.galleryChangeObserver,
            assetCache: container.assetCache,
            galleryPipeline: container.galleryPipeline,
            imagePipeline: container.imagePipeline,
            optionsFactory: container.optionsFactory
        )
        add(child: coordinator)
        coordinator.start()
    }
}
