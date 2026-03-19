//
//  CharacterPageDTO.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterPageDTO

struct CharacterPageDTO: Decodable {
    let info: PageInfoDTO
    let results: [CharacterDTO]

    nonisolated init(info: PageInfoDTO, results: [CharacterDTO]) {
        self.info = info
        self.results = results
    }
}

// MARK: - PageInfoDTO

struct PageInfoDTO: Decodable {
    let count: Int
    let pages: Int
    let next: String?
    let prev: String?

    nonisolated init(count: Int, pages: Int, next: String?, prev: String?) {
        self.count = count
        self.pages = pages
        self.next = next
        self.prev = prev
    }
}
