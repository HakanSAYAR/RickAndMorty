//
//  CharacterListViewStateTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterListViewStateTests
@MainActor
struct CharacterListViewStateTests {

    // MARK: - Helpers

    private func makeGalleryViewData(localIdentifier: String = "id-1") -> GalleryCellViewData {
        GalleryCellViewData(localIdentifier: localIdentifier)
    }

    private func makeGallerySection(items: [CharacterListSectionItem]) -> CharacterListSectionModel {
        CharacterListSectionModel(section: .gallery, items: items)
    }

    private func makeData(
        sections: [CharacterListSectionModel] = [],
        isRefreshing: Bool = false
    ) -> CharacterListLoadedData {
        CharacterListLoadedData(
            sections: sections,
            pagination: .idle,
            gallerySortOrder: .newestFirst,
            isRefreshing: isRefreshing
        )
    }

    // MARK: - shouldShowSortButton

    @Test func shouldShowSortButton_withGalleryPhotos_returnsTrue() {
        let section = makeGallerySection(items: [.photo(makeGalleryViewData())])
        let data = makeData(sections: [section])
        #expect(data.shouldShowSortButton == true)
    }

    @Test func shouldShowSortButton_withNoSections_returnsFalse() {
        let data = makeData(sections: [])
        #expect(data.shouldShowSortButton == false)
    }

    @Test func shouldShowSortButton_withGallerySectionButNoItems_returnsFalse() {
        let section = makeGallerySection(items: [])
        let data = makeData(sections: [section])
        #expect(data.shouldShowSortButton == false)
    }

    @Test func shouldShowSortButton_withPermissionDeniedOnly_returnsFalse() {
        let section = makeGallerySection(items: [.permissionDenied])
        let data = makeData(sections: [section])
        #expect(data.shouldShowSortButton == false)
    }

    @Test func shouldShowSortButton_duringRefresh_returnsFalse() {
        let section = makeGallerySection(items: [.photo(makeGalleryViewData())])
        let data = makeData(sections: [section], isRefreshing: true)
        #expect(data.shouldShowSortButton == false)
    }
}
