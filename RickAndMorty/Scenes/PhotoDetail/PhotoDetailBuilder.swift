//
//  PhotoDetailBuilder.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - PhotoDetailScene

struct PhotoDetailScene {
    let viewController: PhotoDetailViewController
    let viewModel: any PhotoDetailViewModelProtocol
}

// MARK: - PhotoDetailBuilder

enum PhotoDetailBuilder {
    static func make(
        imageSource: PhotoImageSource,
        characterName: String? = nil,
        characterId: Int?,
        showDownloadButton: Bool,
        savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    ) -> PhotoDetailScene {
        let viewModel = PhotoDetailViewModel(
            imageSource: imageSource,
            characterName: characterName,
            characterId: characterId,
            showDownloadButton: showDownloadButton,
            savePhotoUseCase: savePhotoUseCase
        )
        let viewController = PhotoDetailViewController(viewModel: viewModel)
        return PhotoDetailScene(viewController: viewController, viewModel: viewModel)
    }
}
