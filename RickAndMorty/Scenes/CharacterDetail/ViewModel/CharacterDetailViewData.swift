//
//  CharacterDetailViewData.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation

// MARK: - DetailRowViewData

struct DetailRowViewData: Sendable {
    nonisolated let title: String
    nonisolated let value: String

    nonisolated init(title: String, value: String) {
        self.title = title
        self.value = value
    }
}

nonisolated extension DetailRowViewData: Equatable {}

// MARK: - CharacterDetailViewData

struct CharacterDetailViewData: Sendable {
    nonisolated let imageURL: URL?
    nonisolated let name: String
    nonisolated let rows: [DetailRowViewData]

    nonisolated init(imageURL: URL?, name: String, rows: [DetailRowViewData]) {
        self.imageURL = imageURL
        self.name = name
        self.rows = rows
    }
}

nonisolated extension CharacterDetailViewData: Equatable {}
