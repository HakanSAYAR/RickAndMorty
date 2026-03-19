//
//  CharacterDTOMapperTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - CharacterDTOMapperTests

struct CharacterDTOMapperTests {

    // MARK: - Helpers

    private func makeCharacterDTO(
        id: Int = 1,
        name: String = "Rick Sanchez",
        status: String = "Alive",
        species: String = "Human",
        gender: String = "Male",
        originName: String? = "Earth (C-137)",
        locationName: String? = "Citadel of Ricks",
        image: String = "https://example.com/rick.jpg"
    ) -> CharacterDTO {
        CharacterDTO(
            id: id,
            name: name,
            status: status,
            species: species,
            gender: gender,
            origin: CharacterLocationDTO(name: originName),
            location: CharacterLocationDTO(name: locationName),
            image: image
        )
    }

    private func makePageDTO(
        pages: Int = 1,
        next: String? = nil,
        characters: [CharacterDTO] = []
    ) -> CharacterPageDTO {
        CharacterPageDTO(
            info: PageInfoDTO(count: characters.count, pages: pages, next: next, prev: nil),
            results: characters
        )
    }

    // MARK: - Happy Path

    @Test func map_fullHappyPath_producesCorrectDomainAggregate() {
        let dto = makePageDTO(
            pages: 5,
            next: "https://api.example.com/character?page=2",
            characters: [makeCharacterDTO(id: 42, name: "Rick Sanchez")]
        )

        let page = CharacterDTOMapper.map(dto)

        #expect(page.info.totalPages == 5)
        #expect(page.info.hasNextPage == true)
        #expect(page.results.count == 1)
        #expect(page.results[0].id == 42)
        #expect(page.results[0].name == "Rick Sanchez")
        #expect(page.results[0].status == .alive)
        #expect(page.results[0].gender == .male)
        #expect(page.results[0].origin.name == "Earth (C-137)")
        #expect(page.results[0].location.name == "Citadel of Ricks")
        #expect(page.results[0].image == "https://example.com/rick.jpg")
    }

    // MARK: - Status Fallback

    @Test func map_unknownStatus_fallsBackToUnknown() {
        let dto = makePageDTO(characters: [makeCharacterDTO(status: "InvalidStatus")])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].status == .unknown)
    }

    @Test func map_emptyStatus_fallsBackToUnknown() {
        let dto = makePageDTO(characters: [makeCharacterDTO(status: "")])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].status == .unknown)
    }

    @Test func map_aliveStatus_mapsCorrectly() {
        let dto = makePageDTO(characters: [makeCharacterDTO(status: "Alive")])
        #expect(CharacterDTOMapper.map(dto).results[0].status == .alive)
    }

    @Test func map_deadStatus_mapsCorrectly() {
        let dto = makePageDTO(characters: [makeCharacterDTO(status: "Dead")])
        #expect(CharacterDTOMapper.map(dto).results[0].status == .dead)
    }

    // MARK: - Gender Fallback

    @Test func map_unknownGender_fallsBackToUnknown() {
        let dto = makePageDTO(characters: [makeCharacterDTO(gender: "InvalidGender")])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].gender == .unknown)
    }

    @Test func map_emptyGender_fallsBackToUnknown() {
        let dto = makePageDTO(characters: [makeCharacterDTO(gender: "")])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].gender == .unknown)
    }

    @Test func map_femaleGender_mapsCorrectly() {
        let dto = makePageDTO(characters: [makeCharacterDTO(gender: "Female")])
        #expect(CharacterDTOMapper.map(dto).results[0].gender == .female)
    }

    @Test func map_genderlessGender_mapsCorrectly() {
        let dto = makePageDTO(characters: [makeCharacterDTO(gender: "Genderless")])
        #expect(CharacterDTOMapper.map(dto).results[0].gender == .genderless)
    }

    // MARK: - PaginationInfo

    @Test func map_nextNil_hasNextPageFalse() {
        let dto = makePageDTO(pages: 1, next: nil)
        let page = CharacterDTOMapper.map(dto)
        #expect(page.info.hasNextPage == false)
    }

    @Test func map_nextPresent_hasNextPageTrue() {
        let dto = makePageDTO(pages: 3, next: "https://api.example.com/character?page=2")
        let page = CharacterDTOMapper.map(dto)
        #expect(page.info.hasNextPage == true)
        #expect(page.info.totalPages == 3)
    }

    // MARK: - Nested Location Edge Cases

    @Test func map_nilOriginName_producesEmptyString() {
        let dto = makePageDTO(characters: [makeCharacterDTO(originName: nil)])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].origin.name == "")
    }

    @Test func map_nilLocationName_producesEmptyString() {
        let dto = makePageDTO(characters: [makeCharacterDTO(locationName: nil)])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].location.name == "")
    }

    @Test func map_emptyOriginName_preservesEmptyString() {
        let dto = makePageDTO(characters: [makeCharacterDTO(originName: "")])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results[0].origin.name == "")
    }

    // MARK: - Multiple Characters

    @Test func map_multipleCharacters_allMapped() {
        let dto = makePageDTO(characters: [
            makeCharacterDTO(id: 1, name: "Rick"),
            makeCharacterDTO(id: 2, name: "Morty"),
            makeCharacterDTO(id: 3, name: "Summer")
        ])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results.count == 3)
        #expect(page.results[0].id == 1)
        #expect(page.results[1].id == 2)
        #expect(page.results[2].id == 3)
    }

    @Test func map_emptyResults_producesEmptyDomainList() {
        let dto = makePageDTO(characters: [])
        let page = CharacterDTOMapper.map(dto)
        #expect(page.results.isEmpty)
    }
}
