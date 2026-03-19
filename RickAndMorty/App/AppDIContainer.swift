//
//  AppDIContainer.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import NetworkKit

// MARK: - AppDIContainer

final class AppDIContainer {

    // MARK: - Properties

    private let configuration: ConfigurationProvider
    let fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol
    let fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol
    let savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    let galleryChangeObserver: any GalleryChangePublishing
    let assetCache: PHAssetCacheProtocol
    let galleryPipeline: any CharacterListGalleryPipelineProtocol
    let imagePipeline: any CharacterListImagePipelineProtocol
    let optionsFactory: any PHImageRequestOptionsFactoryProtocol

    // MARK: - Init

    init(configuration: ConfigurationProvider = AppConfiguration.current) {
        self.configuration = configuration

        let networkConfiguration = NetworkConfiguration(baseURL: configuration.baseURL)
        let apiService = NetworkFactory.make(
            configuration: networkConfiguration,
            logLevel: configuration.logLevel
        ).apiService
        self.fetchCharactersUseCase = FetchCharactersPageUseCase(
            repository: CharacterRepositoryImpl(apiService: apiService)
        )

        let cache = PHAssetCache()
        self.assetCache = cache
        let assetStore = GalleryAssetStore()
        let assetService = GalleryAssetService(store: assetStore, assetCache: cache)
        self.fetchGalleryItemsUseCase = FetchGalleryPhotosUseCase(
            repository: GalleryRepositoryImpl(
                permissionService: GalleryPermissionService(),
                assetService: assetService
            )
        )

        self.savePhotoUseCase = SaveImageToGalleryUseCase(
            savedPhotoStore: SavedPhotoStore(),
            photoLibrarySaver: PhotoLibrarySaver()
        )

        self.galleryChangeObserver = GalleryChangeObserverProxy()
        self.galleryPipeline = CharacterListGalleryPipeline()
        self.imagePipeline = CharacterListImagePipeline()
        self.optionsFactory = PHImageRequestOptionsFactory()
    }
}
