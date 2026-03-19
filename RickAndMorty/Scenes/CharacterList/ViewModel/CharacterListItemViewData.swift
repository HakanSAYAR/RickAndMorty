//
//  GalleryCellViewData.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation

// MARK: - GalleryCellViewData

struct GalleryCellViewData: Sendable {
    nonisolated let localIdentifier: String

    nonisolated init(localIdentifier: String) {
        self.localIdentifier = localIdentifier
    }
}

// nonisolated Hashable so NSDiffableDataSourceSnapshot works in background contexts.
nonisolated extension GalleryCellViewData: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }
}

// MARK: - CharacterCellViewData

struct CharacterCellViewData: Sendable {
    nonisolated let id: Int
    nonisolated let title: String
    nonisolated let subtitle: String
    nonisolated let imageURL: URL?

    nonisolated init(id: Int, title: String, subtitle: String, imageURL: URL?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
    }
}

// nonisolated Hashable so NSDiffableDataSourceSnapshot works in background contexts.
// Identity is id-only.
nonisolated extension CharacterCellViewData: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
