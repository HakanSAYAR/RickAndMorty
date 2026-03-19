//
//  PhotoDetailCoordinator.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit

// MARK: - PhotoDetailCoordinator

final class PhotoDetailCoordinator: BaseCoordinator {

    // MARK: - Properties

    private let imageSource: PhotoImageSource
    private let characterName: String
    private let characterId: Int?
    private let showDownloadButton: Bool
    private let savePhotoUseCase: SaveImageToGalleryUseCaseProtocol

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        imageSource: PhotoImageSource,
        characterName: String,
        characterId: Int?,
        showDownloadButton: Bool,
        savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    ) {
        self.imageSource = imageSource
        self.characterName = characterName
        self.characterId = characterId
        self.showDownloadButton = showDownloadButton
        self.savePhotoUseCase = savePhotoUseCase
        super.init(navigationController: navigationController)
    }

    // MARK: - Coordinator

    override func start() {
        let scene = PhotoDetailBuilder.make(
            imageSource: imageSource,
            characterName: characterName,
            characterId: characterId,
            showDownloadButton: showDownloadButton,
            savePhotoUseCase: savePhotoUseCase
        )
        rootViewController = scene.viewController
        navigationController.pushViewController(scene.viewController, animated: true)
    }
}
