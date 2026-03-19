//
//  CharacterListSection.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

// MARK: - CharacterListSection

nonisolated enum CharacterListSection: Int, CaseIterable, Sendable {
    case gallery    = 0
    case characters = 1

    var title: String {
        switch self {
        case .gallery:    return L10n.CharacterList.gallerySection
        case .characters: return L10n.CharacterList.charactersSection
        }
    }
}

// MARK: - CharacterListSectionModel

struct CharacterListSectionModel {
    nonisolated let section: CharacterListSection
    nonisolated let items: [CharacterListSectionItem]

    nonisolated init(section: CharacterListSection, items: [CharacterListSectionItem]) {
        self.section = section
        self.items = items
    }
}

nonisolated extension CharacterListSectionModel: Equatable {}

// MARK: - CharacterListSectionItem

nonisolated enum CharacterListSectionItem: Hashable, Sendable {
    case photo(GalleryCellViewData)
    case permissionDenied
    case character(CharacterCellViewData)
}
