//
//  CharacterListCoordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Combine

// MARK: - CharacterListCoordinator

final class CharacterListCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol
    private let fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol
    private let savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    private let galleryChangeObserver: any GalleryChangePublishing
    private let assetCache: PHAssetCacheProtocol
    private let galleryPipeline: any CharacterListGalleryPipelineProtocol
    private let imagePipeline: any CharacterListImagePipelineProtocol
    private let optionsFactory: any PHImageRequestOptionsFactoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol,
        fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol,
        savePhotoUseCase: SaveImageToGalleryUseCaseProtocol,
        galleryChangeObserver: any GalleryChangePublishing,
        assetCache: PHAssetCacheProtocol,
        galleryPipeline: any CharacterListGalleryPipelineProtocol,
        imagePipeline: any CharacterListImagePipelineProtocol,
        optionsFactory: any PHImageRequestOptionsFactoryProtocol = PHImageRequestOptionsFactory()
    ) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.fetchGalleryItemsUseCase = fetchGalleryItemsUseCase
        self.savePhotoUseCase = savePhotoUseCase
        self.galleryChangeObserver = galleryChangeObserver
        self.assetCache = assetCache
        self.galleryPipeline = galleryPipeline
        self.imagePipeline = imagePipeline
        self.optionsFactory = optionsFactory
        super.init(navigationController: navigationController)
    }

    // MARK: - Coordinator

    override func start() {
        // Pop events cleaned up via UINavigationControllerDelegate.didShow.
        navigationController.delegate = self

        let scene = CharacterListBuilder.make(
            fetchCharactersUseCase: fetchCharactersUseCase,
            fetchGalleryItemsUseCase: fetchGalleryItemsUseCase,
            galleryChangeObserver: galleryChangeObserver,
            assetCache: assetCache,
            galleryPipeline: galleryPipeline,
            imagePipeline: imagePipeline,
            optionsFactory: optionsFactory
        )
        scene.viewModel.route
            .sink { [weak self] route in
                self?.handle(route)
            }
            .store(in: &cancellables)

        navigationController.setViewControllers([scene.viewController], animated: false)
    }

    // MARK: - Navigation

    private func handle(_ route: CharacterListRoute) {
        switch route {
        case .showCharacterDetail(let character):
            let coordinator = CharacterDetailCoordinator(
                navigationController: navigationController,
                character: character,
                savePhotoUseCase: savePhotoUseCase
            )
            coordinator.onFinish = { [weak self, weak coordinator] in
                guard let coordinator else { return }
                self?.remove(child: coordinator)
            }
            add(child: coordinator)
            coordinator.start()

        case .showPhotoDetail(let localIdentifier):
            let coordinator = PhotoDetailCoordinator(
                navigationController: navigationController,
                imageSource: .local(localIdentifier),
                characterName: "",
                characterId: nil,
                showDownloadButton: false,
                savePhotoUseCase: savePhotoUseCase
            )
            coordinator.onFinish = { [weak self, weak coordinator] in
                guard let coordinator else { return }
                self?.remove(child: coordinator)
            }
            add(child: coordinator)
            coordinator.start()
        }
    }
}

// MARK: - UINavigationControllerDelegate

extension CharacterListCoordinator: UINavigationControllerDelegate {

    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // transitionCoordinator is nil for setViewControllers; guard prevents false positives.
        guard
            let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
            !navigationController.viewControllers.contains(fromVC)
        else { return }

        didPop(viewController: fromVC)
    }
}
