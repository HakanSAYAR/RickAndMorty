//
//  CharacterListViewControllerTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
import Combine
@testable import RickAndMorty

// MARK: - CharacterListViewControllerTests

@MainActor
struct CharacterListViewControllerTests {

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

    /// Yields to allow the @MainActor sink dispatch cycle to complete.
    private func drain() async {
        for _ in 0..<3 { await Task.yield() }
    }

    // MARK: - Lifecycle

    @Test func viewDidLoad_callsViewModelViewDidLoad() {
        let (_, viewModel) = makeSUT()
        #expect(viewModel.viewDidLoadCalled)
    }

    // MARK: - Sort Button Visibility

    @Test func render_withGalleryItems_showsSortButton() async {
        let (sut, viewModel) = makeSUT()
        let state = CharacterListState.loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.photo(.stub())])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
        viewModel.emit(state)
        await drain()
        #expect(sut.navigationItem.rightBarButtonItem != nil)
    }

    @Test func render_galleryItemsRemoved_hidesSortButton() async {
        let withGallery = CharacterListState.loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.photo(.stub())])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
        let (sut, viewModel) = makeSUT(initialState: withGallery)
        await drain()

        viewModel.emit(.loaded(.initial))
        await drain()
        #expect(sut.navigationItem.rightBarButtonItem == nil)
    }

    @Test func render_withPermissionDenied_hidesSortButton() async {
        let (sut, viewModel) = makeSUT()
        let state = CharacterListState.loaded(CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.permissionDenied])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        ))
        viewModel.emit(state)
        await drain()
        #expect(sut.navigationItem.rightBarButtonItem == nil)
    }
}
