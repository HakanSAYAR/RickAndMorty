//
//  CharacterListViewDataMapperTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - CharacterListViewDataMapperTests

struct CharacterListViewDataMapperTests {

    // MARK: - Character → CharacterCellViewData

    @Test func mapCharacter_idPassedThrough() {
        let result = CharacterListViewDataMapper.map(Character.stub(id: 99))
        #expect(result.id == 99)
    }

    @Test func mapCharacter_nameBecomesTitle() {
        let result = CharacterListViewDataMapper.map(Character.stub(name: "Morty Smith"))
        #expect(result.title == "Morty Smith")
    }

    @Test func mapCharacter_subtitleCombinesStatusAndSpecies() {
        let result = CharacterListViewDataMapper.map(Character.stub(status: .alive, species: "Human"))
        #expect(result.subtitle == "Alive · Human")
    }

    @Test func mapCharacter_validImageURL_parsed() {
        let result = CharacterListViewDataMapper.map(Character.stub(image: "https://example.com/img.jpg"))
        #expect(result.imageURL == URL(string: "https://example.com/img.jpg"))
    }

    @Test func mapCharacter_invalidImageURL_isNil() {
        let result = CharacterListViewDataMapper.map(Character.stub(image: "not valid ://"))
        #expect(result.imageURL == nil)
    }

    // MARK: - GalleryPhoto → GalleryCellViewData

    @Test func mapGalleryPhoto_localIdentifierPassedThrough() {
        let photo = GalleryPhoto.stub(localIdentifier: "abc-123")
        let result = CharacterListViewDataMapper.map(photo)
        #expect(result.localIdentifier == "abc-123")
    }

    @Test func mapGalleryPhoto_differentIdentifiers_produceDifferentViewData() {
        let a = CharacterListViewDataMapper.map(GalleryPhoto.stub(localIdentifier: "id-1"))
        let b = CharacterListViewDataMapper.map(GalleryPhoto.stub(localIdentifier: "id-2"))
        #expect(a != b)
    }
}
