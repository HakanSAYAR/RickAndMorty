//
//  CharacterListStateTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterListStateTests
@MainActor
struct CharacterListStateTests {

    // MARK: - State Cases

    @Test func loadingState_isDistinctFromLoaded() {
        let loading = CharacterListState.loading
        let loaded = CharacterListState.loaded(.initial)
        if case .loading = loading { } else {
            Issue.record("Expected .loading")
        }
        if case .loaded = loaded { } else {
            Issue.record("Expected .loaded")
        }
    }

    @Test func errorState_carriesMessage() {
        let state = CharacterListState.error(message: "Network error")
        guard case .error(let message) = state else {
            Issue.record("Expected .error")
            return
        }
        #expect(message == "Network error")
    }

    // MARK: - CharacterListLoadedData — initial

    @Test func initial_hasEmptySections() {
        #expect(CharacterListLoadedData.initial.sections.isEmpty)
    }

    @Test func initial_isNotRefreshing() {
        #expect(!CharacterListLoadedData.initial.isRefreshing)
    }

    @Test func initial_paginationIsIdle() {
        #expect(CharacterListLoadedData.initial.pagination == .idle)
    }

    @Test func initial_sortOrderIsNewestFirst() {
        #expect(CharacterListLoadedData.initial.gallerySortOrder == .newestFirst)
    }

    // MARK: - shouldShowSortButton

    @Test func shouldShowSortButton_withPhotoItems_returnsTrue() {
        let data = CharacterListLoadedData(
            sections: [CharacterListSectionModel(
                section: .gallery,
                items: [.photo(GalleryCellViewData(localIdentifier: "id-1"))]
            )],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        )
        #expect(data.shouldShowSortButton == true)
    }

    @Test func shouldShowSortButton_duringRefresh_returnsFalse() {
        let data = CharacterListLoadedData(
            sections: [CharacterListSectionModel(
                section: .gallery,
                items: [.photo(GalleryCellViewData(localIdentifier: "id-1"))]
            )],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: true
        )
        #expect(data.shouldShowSortButton == false)
    }

    @Test func shouldShowSortButton_withPermissionDenied_returnsFalse() {
        let data = CharacterListLoadedData(
            sections: [CharacterListSectionModel(section: .gallery, items: [.permissionDenied])],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        )
        #expect(data.shouldShowSortButton == false)
    }

    @Test func shouldShowSortButton_withNoGallerySection_returnsFalse() {
        let data = CharacterListLoadedData(
            sections: [CharacterListSectionModel(
                section: .characters,
                items: [.character(CharacterCellViewData.stub())]
            )],
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: false
        )
        #expect(data.shouldShowSortButton == false)
    }

    // MARK: - Equatable

    @Test func loadedData_equatable_sameValues_areEqual() {
        let a = CharacterListLoadedData.initial
        let b = CharacterListLoadedData.initial
        #expect(a == b)
    }

    @Test func loadedData_equatable_differentPagination_areNotEqual() {
        let a = CharacterListLoadedData(sections: [], pagination: .idle, gallerySortOrder: .newestFirst, isRefreshing: false)
        let b = CharacterListLoadedData(sections: [], pagination: .loading, gallerySortOrder: .newestFirst, isRefreshing: false)
        #expect(a != b)
    }
}
