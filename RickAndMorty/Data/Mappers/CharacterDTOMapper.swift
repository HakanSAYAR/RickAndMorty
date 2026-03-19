//
//  CharacterDTOMapper.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterDTOMapper

enum CharacterDTOMapper {

    // MARK: - Public

    // nonisolated: pure DTO → domain transformation, no shared state or UI dependency.
    nonisolated static func map(_ dto: CharacterPageDTO) -> CharacterPage {
        CharacterPage(
            info: mapPaginationInfo(dto.info),
            results: dto.results.map(mapCharacter)
        )
    }

    // MARK: - Private

    private nonisolated static func mapPaginationInfo(_ dto: PageInfoDTO) -> PaginationInfo {
        PaginationInfo(
            totalPages: dto.pages,
            hasNextPage: dto.next != nil
        )
    }

    private nonisolated static func mapCharacter(_ dto: CharacterDTO) -> Character {
        Character(
            id: dto.id,
            name: dto.name,
            status: CharacterStatus(rawValue: dto.status) ?? .unknown,
            species: dto.species,
            gender: CharacterGender(rawValue: dto.gender) ?? .unknown,
            origin: CharacterLocation(name: dto.origin.name ?? ""),
            location: CharacterLocation(name: dto.location.name ?? ""),
            image: dto.image
        )
    }
}
