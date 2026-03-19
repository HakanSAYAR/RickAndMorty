//
//  CharacterListBuilder.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

// MARK: - CharacterListScene

struct CharacterListScene {
    let viewController: CharacterListViewController
    let viewModel: any CharacterListViewModelProtocol
}

// MARK: - CharacterListBuilder

enum CharacterListBuilder {
    static func make(
        fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol,
        fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol,
        galleryChangeObserver: any GalleryChangePublishing,
        assetCache: PHAssetCacheProtocol,
        galleryPipeline: any CharacterListGalleryPipelineProtocol,
        imagePipeline: any CharacterListImagePipelineProtocol,
        optionsFactory: any PHImageRequestOptionsFactoryProtocol
    ) -> CharacterListScene {
        let viewModel = CharacterListViewModel(
            fetchCharactersUseCase: fetchCharactersUseCase,
            fetchGalleryItemsUseCase: fetchGalleryItemsUseCase,
            galleryChangeObserver: galleryChangeObserver
        )
        let viewController = CharacterListViewController(
            viewModel: viewModel,
            assetCache: assetCache,
            galleryPipeline: galleryPipeline,
            imagePipeline: imagePipeline,
            optionsFactory: optionsFactory
        )
        return CharacterListScene(viewController: viewController, viewModel: viewModel)
    }
}
