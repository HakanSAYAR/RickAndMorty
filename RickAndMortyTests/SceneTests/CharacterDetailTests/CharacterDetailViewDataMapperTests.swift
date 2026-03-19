//
//  CharacterDetailViewDataMapperTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - CharacterDetailViewDataMapperTests

struct CharacterDetailViewDataMapperTests {

    private let character = Character.stub(
        id: 1,
        name: "Rick Sanchez",
        status: .alive,
        species: "Human",
        gender: .male,
        originName: "Earth (C-137)",
        locationName: "Citadel of Ricks",
        image: "https://example.com/rick.jpg"
    )

    // MARK: - imageURL

    @Test func map_imageURL_parsesCorrectly() {
        let result = CharacterDetailViewDataMapper.map(character)
        #expect(result.imageURL?.absoluteString == "https://example.com/rick.jpg")
    }

    @Test func map_imageURL_isNil_whenEmptyString() {
        let result = CharacterDetailViewDataMapper.map(Character.stub(image: ""))
        #expect(result.imageURL == nil)
    }

    // MARK: - name

    @Test func map_name_equalsCharacterName() {
        let result = CharacterDetailViewDataMapper.map(character)
        #expect(result.name == "Rick Sanchez")
    }

    // MARK: - rows

    @Test func map_rowCount_isFive() {
        let result = CharacterDetailViewDataMapper.map(character)
        #expect(result.rows.count == 5)
    }

    @Test func map_statusRow_hasCorrectValue() {
        let result = CharacterDetailViewDataMapper.map(character)
        let row = result.rows.first { $0.title == L10n.CharacterDetail.rowStatus }
        #expect(row?.value == CharacterStatus.alive.displayText)
    }

    @Test func map_speciesRow_hasCorrectValue() {
        let result = CharacterDetailViewDataMapper.map(character)
        let row = result.rows.first { $0.title == L10n.CharacterDetail.rowSpecies }
        #expect(row?.value == "Human")
    }

    @Test func map_genderRow_hasCorrectValue() {
        let result = CharacterDetailViewDataMapper.map(character)
        let row = result.rows.first { $0.title == L10n.CharacterDetail.rowGender }
        #expect(row?.value == CharacterGender.male.displayText)
    }

    @Test func map_originRow_hasCorrectValue() {
        let result = CharacterDetailViewDataMapper.map(character)
        let row = result.rows.first { $0.title == L10n.CharacterDetail.rowOrigin }
        #expect(row?.value == "Earth (C-137)")
    }

    @Test func map_locationRow_hasCorrectValue() {
        let result = CharacterDetailViewDataMapper.map(character)
        let row = result.rows.first { $0.title == L10n.CharacterDetail.rowLocation }
        #expect(row?.value == "Citadel of Ricks")
    }

    // MARK: - Stateless

    @Test func map_calledTwice_producesEqualResults() {
        let r1 = CharacterDetailViewDataMapper.map(character)
        let r2 = CharacterDetailViewDataMapper.map(character)
        #expect(r1 == r2)
    }
}
