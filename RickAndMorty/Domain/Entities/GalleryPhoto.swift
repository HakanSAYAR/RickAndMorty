//
//  AppConfiguration.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - GalleryPhoto

struct GalleryPhoto: Sendable {
    nonisolated let localIdentifier: String
    nonisolated let creationDate: Date?

    nonisolated init(localIdentifier: String, creationDate: Date?) {
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
    }
}

// nonisolated Hashable so NSDiffableDataSourceSnapshot works in background contexts.
nonisolated extension GalleryPhoto: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(localIdentifier)
    }

    static func == (lhs: GalleryPhoto, rhs: GalleryPhoto) -> Bool {
        lhs.localIdentifier == rhs.localIdentifier
    }
}
