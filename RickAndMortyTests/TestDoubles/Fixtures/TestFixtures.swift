//
//  TestFixtures.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - Character

extension Character {
    static func stub(
        id: Int = 1,
        name: String = "Rick Sanchez",
        status: CharacterStatus = .alive,
        species: String = "Human",
        gender: CharacterGender = .male,
        originName: String = "Earth (C-137)",
        locationName: String = "Citadel of Ricks",
        image: String = "https://example.com/rick.jpg"
    ) -> Character {
        Character(
            id: id,
            name: name,
            status: status,
            species: species,
            gender: gender,
            origin: CharacterLocation(name: originName),
            location: CharacterLocation(name: locationName),
            image: image
        )
    }
}

// MARK: - CharacterPage

extension CharacterPage {
    static func stub(
        pages: Int = 1,
        characters: [Character] = [.stub()]
    ) -> CharacterPage {
        CharacterPage(
            info: PaginationInfo(totalPages: pages, hasNextPage: pages > 1),
            results: characters
        )
    }
}

// MARK: - GalleryPhoto

extension GalleryPhoto {
    static func stub(localIdentifier: String = "test-local-id", creationDate: Date? = nil) -> GalleryPhoto {
        GalleryPhoto(localIdentifier: localIdentifier, creationDate: creationDate)
    }
}

// MARK: - CharacterDTO

extension CharacterDTO {
    static func stub(
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
}

// MARK: - CharacterPageDTO

extension CharacterPageDTO {
    static func stub(
        pages: Int = 1,
        next: String? = nil,
        characters: [CharacterDTO] = [.stub()]
    ) -> CharacterPageDTO {
        CharacterPageDTO(
            info: PageInfoDTO(count: characters.count, pages: pages, next: next, prev: nil),
            results: characters
        )
    }
}

// MARK: - CharacterCellViewData

extension CharacterCellViewData {
    static func stub(
        id: Int = 1,
        title: String = "Rick Sanchez",
        subtitle: String = "Alive · Human",
        imageURL: URL? = nil
    ) -> CharacterCellViewData {
        CharacterCellViewData(id: id, title: title, subtitle: subtitle, imageURL: imageURL)
    }
}

// MARK: - GalleryCellViewData

extension GalleryCellViewData {
    static func stub(localIdentifier: String = "test-local-id") -> GalleryCellViewData {
        GalleryCellViewData(localIdentifier: localIdentifier)
    }
}
