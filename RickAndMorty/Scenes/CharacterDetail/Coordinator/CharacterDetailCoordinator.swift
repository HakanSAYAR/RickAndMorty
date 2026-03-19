//
//  CharacterDetailCoordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit
import Combine

// MARK: - CharacterDetailCoordinator

final class CharacterDetailCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let character: Character
    private let savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        character: Character,
        savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    ) {
        self.character = character
        self.savePhotoUseCase = savePhotoUseCase
        super.init(navigationController: navigationController)
    }

    // MARK: - Coordinator

    override func start() {
        let scene = CharacterDetailBuilder.make(character: character)
        rootViewController = scene.viewController

        scene.viewModel.route
            .sink { [weak self] route in
                self?.handle(route)
            }
            .store(in: &cancellables)

        navigationController.pushViewController(scene.viewController, animated: true)
    }

    // MARK: - Navigation

    private func handle(_ route: CharacterDetailRoute) {
        switch route {
        case .showPhoto(let imageURL, let characterName, let characterId):
            let coordinator = PhotoDetailCoordinator(
                navigationController: navigationController,
                imageSource: .remote(imageURL),
                characterName: characterName,
                characterId: characterId,
                showDownloadButton: true,
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
