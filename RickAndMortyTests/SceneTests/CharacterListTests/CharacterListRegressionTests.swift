//
//  CharacterListRegressionTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
import Combine
@testable import RickAndMorty

// MARK: - CharacterListRegressionTests

@MainActor
struct CharacterListRegressionTests {

    // MARK: - Helpers

    private func makeSUT(
        initialState: CharacterListState = .loaded(CharacterListLoadedData(
            sections: [],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
    ) -> (sut: CharacterListViewController, viewModel: SpyCharacterListViewModel) {
        let viewModel = SpyCharacterListViewModel(initialState: initialState)
        let sut = CharacterListViewController(
            viewModel: viewModel,
            assetCache: MockPHAssetCache(),
            galleryPipeline: MockCharacterListGalleryPipeline(),
            imagePipeline: MockCharacterListImagePipeline(),
            optionsFactory: MockPHImageRequestOptionsFactory()
        )
        sut.loadViewIfNeeded()
        return (sut, viewModel)
    }

    private func drain() async {
        for _ in 0..<3 { await Task.yield() }
    }

    private func loadedStateWithCharacters(count: Int = 1) -> CharacterListState {
        let items = (0..<count).map { _ in CharacterListSectionItem.character(.stub()) }
        return .loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .characters, items: items)],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
    }

    // MARK: - Memory Leak Guard

    @Test func viewController_deallocatesAfterRelease() {
        weak var weakSUT: CharacterListViewController?
        autoreleasepool {
            let (sut, _) = makeSUT()
            weakSUT = sut
            _ = sut
        }
        #expect(weakSUT == nil)
    }

    // MARK: - Lifecycle Safety

    @Test func viewDidDisappear_doesNotCrash() {
        let (sut, _) = makeSUT()
        sut.viewDidDisappear(false)
    }

    @Test func didReceiveMemoryWarning_doesNotCrash() {
        let (sut, _) = makeSUT()
        sut.didReceiveMemoryWarning()
    }

    @Test func viewDidDisappear_calledTwice_doesNotCrash() {
        let (sut, _) = makeSUT()
        sut.viewDidDisappear(false)
        sut.viewDidDisappear(false)
    }

    // MARK: - Snapshot Debounce: Leading Edge

    @Test func firstSnapshot_isApplied_withoutDebounceDelay() async {
        let (sut, viewModel) = makeSUT()
        viewModel.emit(loadedStateWithCharacters())

        await drain()

        let galleryState = CharacterListState.loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.photo(.stub())])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
        viewModel.emit(galleryState)
        await drain()
        #expect(sut.navigationItem.rightBarButtonItem != nil)
    }

    // MARK: - Snapshot Debounce: Coalescing

    @Test func rapidStateUpdates_afterFirstSnapshot_doNotCrash() async throws {
        let (_, viewModel) = makeSUT()

        viewModel.emit(loadedStateWithCharacters())
        await drain()

        for i in 1...10 {
            let items = (0..<i).map { _ in CharacterListSectionItem.character(.stub()) }
            viewModel.emit(.loaded(CharacterListLoadedData(
                sections: [CharacterListSectionModel(section: .characters, items: items)],
                pagination: .idle,
                gallerySortOrder: .newestFirst,
                isRefreshing: false
            )))
        }

        try await Task.sleep(nanoseconds: 150_000_000)
        // No crash = pass.
    }

    // MARK: - makeCachingOptions Integration Note

    @Test func galleryCellConfigure_withNilAsset_doesNotCrash() async {
        let (_, viewModel) = makeSUT()
        let state = CharacterListState.loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.photo(.stub())])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
        viewModel.emit(state)
        await drain()
        // No crash with nil asset → GalleryCell.configure guard path works correctly.
    }
}
