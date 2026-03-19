//
//  CharacterListCoordinatorTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterListCoordinatorTests

@MainActor
struct CharacterListCoordinatorTests {

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: CharacterListCoordinator,
        nav: UINavigationController
    ) {
        let nav = UINavigationController()
        let sut = CharacterListCoordinator(
            navigationController: nav,
            fetchCharactersUseCase: MockFetchCharactersUseCase(),
            fetchGalleryItemsUseCase: MockFetchGalleryItemsUseCase(),
            savePhotoUseCase: MockSavePhotoUseCase(),
            galleryChangeObserver: StubGalleryChangePublisher(),
            assetCache: MockPHAssetCache(),
            galleryPipeline: MockCharacterListGalleryPipeline(),
            imagePipeline: MockCharacterListImagePipeline(),
            optionsFactory: MockPHImageRequestOptionsFactory()
        )
        return (sut, nav)
    }

    private func makePhotoDetailCoordinator(
        nav: UINavigationController,
        imageSource: PhotoImageSource = .local("id-1"),
        characterId: Int? = nil,
        showDownloadButton: Bool = false
    ) -> PhotoDetailCoordinator {
        PhotoDetailCoordinator(
            navigationController: nav,
            imageSource: imageSource,
            characterName: "",
            characterId: characterId,
            showDownloadButton: showDownloadButton,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
    }

    // MARK: - Delegate Ownership

    @Test func start_setsItselfAsNavigationDelegate() {
        let (sut, nav) = makeSUT()
        sut.start()
        #expect(nav.delegate === sut)
    }

    // MARK: - Initial State

    @Test func start_initialChildrenIsEmpty() {
        let (sut, _) = makeSUT()
        sut.start()
        #expect(sut.children.isEmpty)
    }

    // MARK: - Pop Cleanup (direct child)

    @Test func didPop_removesDirectChildCoordinator() {
        let (sut, nav) = makeSUT()
        sut.start()

        let child = makePhotoDetailCoordinator(nav: nav)
        child.start()

        child.onFinish = { [weak sut, weak child] in
            guard let child else { return }
            sut?.remove(child: child)
        }
        sut.add(child: child)

        #expect(sut.children.count == 1)

        sut.didPop(viewController: child.rootViewController!)

        #expect(sut.children.isEmpty)
    }

    // MARK: - Pop Cleanup (nested child)

    @Test func didPop_removesNestedChildCoordinator() {
        let (sut, nav) = makeSUT()
        sut.start()

        // Simulate: CharacterDetailCoordinator is a direct child of sut
        let detailCoordinator = CharacterDetailCoordinator(
            navigationController: nav,
            character: .stub(),
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        detailCoordinator.start()
        detailCoordinator.onFinish = { [weak sut, weak detailCoordinator] in
            guard let detailCoordinator else { return }
            sut?.remove(child: detailCoordinator)
        }
        sut.add(child: detailCoordinator)

        // Simulate: PhotoDetailCoordinator is a nested child of detailCoordinator
        let photoCoordinator = PhotoDetailCoordinator(
            navigationController: nav,
            imageSource: .remote(nil),
            characterName: "Rick",
            characterId: 42,
            showDownloadButton: true,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        photoCoordinator.start()
        photoCoordinator.onFinish = { [weak detailCoordinator, weak photoCoordinator] in
            guard let photoCoordinator else { return }
            detailCoordinator?.remove(child: photoCoordinator)
        }
        detailCoordinator.add(child: photoCoordinator)

        #expect(sut.children.count == 1)
        #expect(detailCoordinator.children.count == 1)

        // Pop the nested photo detail VC — recursive didPop should clean it up
        sut.didPop(viewController: photoCoordinator.rootViewController!)

        #expect(detailCoordinator.children.isEmpty)
        #expect(sut.children.count == 1) // detailCoordinator itself stays
    }

    // MARK: - Re-entry Prevention

    @Test func didPop_onFinishFiresAtMostOnce() {
        let (sut, nav) = makeSUT()
        sut.start()

        let child = makePhotoDetailCoordinator(nav: nav, imageSource: .local("id-2"))
        child.start()

        var finishCallCount = 0
        child.onFinish = { [weak sut, weak child] in
            finishCallCount += 1
            guard let child else { return }
            sut?.remove(child: child)
        }
        sut.add(child: child)

        sut.didPop(viewController: child.rootViewController!)
        sut.didPop(viewController: child.rootViewController!)

        #expect(finishCallCount == 1)
    }
}
