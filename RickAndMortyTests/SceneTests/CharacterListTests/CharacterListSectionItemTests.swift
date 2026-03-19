//
//  CharacterListSectionItemTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterListSectionItemTests

struct CharacterListSectionItemTests {

    // MARK: - .photo identity (localIdentifier-based)

    @Test func photoItem_sameIdentifier_isEqual() {
        let a = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-1"))
        let b = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-1"))
        #expect(a == b)
    }

    @Test func photoItem_differentIdentifier_isNotEqual() {
        let a = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-1"))
        let b = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-2"))
        #expect(a != b)
    }

    @Test func photoItem_sameIdentifier_hasSameHashValue() {
        let a = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-1"))
        let b = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "photo-1"))
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - .character identity (id-based, content-agnostic)

    @Test func characterItem_sameId_isEqual_regardlessOfContent() {
        let a = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive · Human", imageURL: nil))
        let b = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Evil Rick", subtitle: "Dead · Human", imageURL: nil))
        #expect(a == b)
    }

    @Test func characterItem_differentId_isNotEqual() {
        let a = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive · Human", imageURL: nil))
        let b = CharacterListSectionItem.character(CharacterCellViewData(id: 2, title: "Rick", subtitle: "Alive · Human", imageURL: nil))
        #expect(a != b)
    }

    @Test func characterItem_sameId_hasSameHashValue() {
        let a = CharacterListSectionItem.character(CharacterCellViewData(id: 42, title: "Rick", subtitle: "Alive", imageURL: nil))
        let b = CharacterListSectionItem.character(CharacterCellViewData(id: 42, title: "Morty", subtitle: "Dead", imageURL: nil))
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - .permissionDenied

    @Test func permissionDeniedItem_equalsItself() {
        let a = CharacterListSectionItem.permissionDenied
        let b = CharacterListSectionItem.permissionDenied
        #expect(a == b)
    }

    @Test func permissionDeniedItem_hasSameHashValue() {
        let a = CharacterListSectionItem.permissionDenied
        let b = CharacterListSectionItem.permissionDenied
        #expect(a.hashValue == b.hashValue)
    }

    // MARK: - Cross-case inequality

    @Test func differentCases_areNotEqual() {
        let photo = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "id"))
        let permission = CharacterListSectionItem.permissionDenied
        let character = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "", imageURL: nil))
        #expect(photo != permission)
        #expect(photo != character)
        #expect(permission != character)
    }
}
