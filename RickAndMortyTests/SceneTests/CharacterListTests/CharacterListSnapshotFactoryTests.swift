//
//  CharacterListSnapshotFactoryTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterListSnapshotFactoryTests

struct CharacterListSnapshotFactoryTests {

    // MARK: - Empty

    @Test func makeSnapshot_emptySections_producesEmptySnapshot() {
        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: [])
        #expect(snapshot.sectionIdentifiers.isEmpty)
        #expect(snapshot.numberOfItems == 0)
    }

    // MARK: - Single Section

    @Test func makeSnapshot_singleSection_containsSection() {
        let sections = [
            CharacterListSectionModel(
                section: .characters,
                items: [.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive", imageURL: nil))]
            )
        ]
        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        #expect(snapshot.sectionIdentifiers == [.characters])
    }

    @Test func makeSnapshot_singleSection_containsItems() {
        let item = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive", imageURL: nil))
        let sections = [CharacterListSectionModel(section: .characters, items: [item])]
        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        #expect(snapshot.itemIdentifiers(inSection: .characters) == [item])
    }

    // MARK: - Multiple Sections

    @Test func makeSnapshot_twoSections_preservesOrder() {
        let sections = [
            CharacterListSectionModel(section: .gallery, items: [.photo(GalleryCellViewData(localIdentifier: "id-1"))]),
            CharacterListSectionModel(section: .characters, items: [.character(CharacterCellViewData(id: 2, title: "Morty", subtitle: "Alive", imageURL: nil))])
        ]
        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        #expect(snapshot.sectionIdentifiers == [.gallery, .characters])
    }

    @Test func makeSnapshot_twoSections_correctItemCounts() {
        let photoItem = CharacterListSectionItem.photo(GalleryCellViewData(localIdentifier: "id-1"))
        let charItem = CharacterListSectionItem.character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "", imageURL: nil))
        let sections = [
            CharacterListSectionModel(section: .gallery, items: [photoItem]),
            CharacterListSectionModel(section: .characters, items: [charItem])
        ]
        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        #expect(snapshot.numberOfItems(inSection: .gallery) == 1)
        #expect(snapshot.numberOfItems(inSection: .characters) == 1)
    }

    // MARK: - Stateless (multiple calls)

    @Test func makeSnapshot_calledTwice_producesEqualResults() {
        let sections = [
            CharacterListSectionModel(section: .characters, items: [
                .character(CharacterCellViewData(id: 1, title: "Rick", subtitle: "Alive", imageURL: nil))
            ])
        ]
        let s1 = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        let s2 = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        #expect(s1.sectionIdentifiers == s2.sectionIdentifiers)
        #expect(s1.itemIdentifiers(inSection: .characters) == s2.itemIdentifiers(inSection: .characters))
    }
}
