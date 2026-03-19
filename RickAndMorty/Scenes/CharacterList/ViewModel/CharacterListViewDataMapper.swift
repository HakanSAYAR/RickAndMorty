//
//  CharacterListViewDataMapper.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation

// MARK: - CharacterListViewDataMapper

nonisolated enum CharacterListViewDataMapper {

    static func map(_ character: Character) -> CharacterCellViewData {
        CharacterCellViewData(
            id: character.id,
            title: character.name,
            subtitle: "\(character.status.displayText) · \(character.species)",
            imageURL: URL(string: character.image)
        )
    }

    static func map(_ photo: GalleryPhoto) -> GalleryCellViewData {
        GalleryCellViewData(localIdentifier: photo.localIdentifier)
    }
}
