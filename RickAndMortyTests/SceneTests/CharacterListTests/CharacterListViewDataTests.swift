//
//  CharacterListViewDataTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterListViewDataTests
// Verifies identity semantics of ViewData types used in DiffableDataSource.

struct CharacterListViewDataTests {

    // MARK: - GalleryCellViewData Hashable Identity

    @Test func galleryCellViewData_sameIdentifier_isEqual() {
        let lhs = GalleryCellViewData(localIdentifier: "photo-1")
        let rhs = GalleryCellViewData(localIdentifier: "photo-1")
        #expect(lhs == rhs)
    }

    @Test func galleryCellViewData_differentIdentifier_isNotEqual() {
        let lhs = GalleryCellViewData(localIdentifier: "photo-1")
        let rhs = GalleryCellViewData(localIdentifier: "photo-2")
        #expect(lhs != rhs)
    }

    @Test func galleryCellViewData_sameIdentifier_hasSameHashValue() {
        let lhs = GalleryCellViewData(localIdentifier: "photo-1")
        let rhs = GalleryCellViewData(localIdentifier: "photo-1")
        #expect(lhs.hashValue == rhs.hashValue)
    }

    // MARK: - CharacterCellViewData Hashable Identity
    // Equality is intentionally id-only — DiffableDataSource uses this for diffing.
    // Two items with the same id are considered the same cell regardless of content.

    @Test func characterCellViewData_sameId_isEqual_regardlessOfContent() {
        let lhs = CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive · Human", imageURL: nil)
        let rhs = CharacterCellViewData(id: 1, title: "Evil Rick", subtitle: "Dead · Human", imageURL: nil)
        #expect(lhs == rhs)
    }

    @Test func characterCellViewData_differentId_isNotEqual() {
        let lhs = CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive · Human", imageURL: nil)
        let rhs = CharacterCellViewData(id: 2, title: "Rick", subtitle: "Alive · Human", imageURL: nil)
        #expect(lhs != rhs)
    }

    @Test func characterCellViewData_sameId_hasSameHashValue() {
        let lhs = CharacterCellViewData(id: 42, title: "Rick", subtitle: "Alive · Human", imageURL: nil)
        let rhs = CharacterCellViewData(id: 42, title: "Morty", subtitle: "Dead · Human", imageURL: nil)
        #expect(lhs.hashValue == rhs.hashValue)
    }
}
