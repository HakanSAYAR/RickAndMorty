//
//  CharacterDetailViewDataMapper.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation

// MARK: - CharacterDetailViewDataMapper

nonisolated enum CharacterDetailViewDataMapper {
    static func map(_ character: Character) -> CharacterDetailViewData {
        CharacterDetailViewData(
            imageURL: URL(string: character.image),
            name: character.name,
            rows: [
                DetailRowViewData(title: L10n.CharacterDetail.rowName,     value: character.name),
                DetailRowViewData(title: L10n.CharacterDetail.rowStatus,   value: character.status.displayText),
                DetailRowViewData(title: L10n.CharacterDetail.rowSpecies,  value: character.species),
                DetailRowViewData(title: L10n.CharacterDetail.rowGender,   value: character.gender.displayText),
                DetailRowViewData(title: L10n.CharacterDetail.rowOrigin,   value: character.origin.name),
                DetailRowViewData(title: L10n.CharacterDetail.rowLocation, value: character.location.name)
            ]
        )
    }
}
