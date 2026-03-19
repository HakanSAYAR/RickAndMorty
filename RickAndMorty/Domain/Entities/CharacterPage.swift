//
//  CharacterPage.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterPage

struct CharacterPage {
    nonisolated let info: PaginationInfo
    nonisolated let results: [Character]

    nonisolated init(info: PaginationInfo, results: [Character]) {
        self.info = info
        self.results = results
    }
}
