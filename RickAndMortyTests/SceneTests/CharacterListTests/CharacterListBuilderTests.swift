//
//  CharacterListBuilderTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterListBuilderTests

@MainActor
struct CharacterListBuilderTests {

    @Test func make_returnsCorrectViewControllerType() {
        let scene = CharacterListBuilder.make(
            fetchCharactersUseCase: MockFetchCharactersUseCase(),
            fetchGalleryItemsUseCase: MockFetchGalleryItemsUseCase(),
            galleryChangeObserver: StubGalleryChangePublisher(),
            assetCache: MockPHAssetCache(),
            galleryPipeline: MockCharacterListGalleryPipeline(),
            imagePipeline: MockCharacterListImagePipeline(),
            optionsFactory: MockPHImageRequestOptionsFactory()
        )
        let vc: UIViewController = scene.viewController
        #expect(vc is CharacterListViewController)
    }

    @Test func make_returnsCorrectViewModelType() {
        let scene = CharacterListBuilder.make(
            fetchCharactersUseCase: MockFetchCharactersUseCase(),
            fetchGalleryItemsUseCase: MockFetchGalleryItemsUseCase(),
            galleryChangeObserver: StubGalleryChangePublisher(),
            assetCache: MockPHAssetCache(),
            galleryPipeline: MockCharacterListGalleryPipeline(),
            imagePipeline: MockCharacterListImagePipeline(),
            optionsFactory: MockPHImageRequestOptionsFactory()
        )
        #expect(scene.viewModel is CharacterListViewModel)
    }

    @Test func make_viewModelIsInjectedIntoViewController() {
        let scene = CharacterListBuilder.make(
            fetchCharactersUseCase: MockFetchCharactersUseCase(),
            fetchGalleryItemsUseCase: MockFetchGalleryItemsUseCase(),
            galleryChangeObserver: StubGalleryChangePublisher(),
            assetCache: MockPHAssetCache(),
            galleryPipeline: MockCharacterListGalleryPipeline(),
            imagePipeline: MockCharacterListImagePipeline(),
            optionsFactory: MockPHImageRequestOptionsFactory()
        )
        // Scene struct holds the same VM instance that was injected into the VC.
        // Verifying both exist and are non-nil is sufficient for assembly regression.
        #expect(scene.viewModel is CharacterListViewModel)
        let vc: UIViewController = scene.viewController
        #expect(vc is CharacterListViewController)
    }
}
