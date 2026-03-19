//
//  CharacterListState.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation

// MARK: - CharacterListState

enum CharacterListState {
    case loading
    case loaded(CharacterListLoadedData)
    case error(message: String)
}

// MARK: - CharacterListLoadedData

struct CharacterListLoadedData: Equatable {
    var sections: [CharacterListSectionModel]
    var pagination: PaginationState
    var gallerySortOrder: GallerySortOrder
    var isRefreshing: Bool

    // nonisolated init for test helpers; var properties remain @MainActor.
    nonisolated init(
        sections: [CharacterListSectionModel],
        pagination: PaginationState,
        gallerySortOrder: GallerySortOrder,
        isRefreshing: Bool
    ) {
        self.sections = sections
        self.pagination = pagination
        self.gallerySortOrder = gallerySortOrder
        self.isRefreshing = isRefreshing
    }

    /// True only when gallery has actual photo items and no refresh is in progress.
    /// Permission-denied and empty gallery sections do not qualify.
    var shouldShowSortButton: Bool {
        guard !isRefreshing else { return false }
        return sections.contains { section in
            section.section == .gallery && section.items.contains {
                if case .photo = $0 { return true }
                return false
            }
        }
    }

    nonisolated static let initial = CharacterListLoadedData(
        sections: [],
        pagination: .idle,
        gallerySortOrder: .newestFirst,
        isRefreshing: false
    )
}

// MARK: - GallerySortOrder

enum GallerySortOrder: Sendable {
    case newestFirst
    case oldestFirst
}

nonisolated extension GallerySortOrder: Equatable {}

// MARK: - PaginationState

enum PaginationState {
    case idle
    case loading
    case error
}

nonisolated extension PaginationState: Equatable {}

// MARK: - CharacterListEvent

enum CharacterListEvent {
    case showError(String)
}
