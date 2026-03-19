//
//  MockSavedPhotoStore.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - MockSavedPhotoStore

actor MockSavedPhotoStore: SavedPhotoStoreProtocol {

    var mappings: [Int: String]

    init(mappings: [Int: String] = [:]) {
        self.mappings = mappings
    }

    func localIdentifier(for characterId: Int) -> String? {
        mappings[characterId]
    }

    func save(characterId: Int, localIdentifier: String) {
        mappings[characterId] = localIdentifier
    }

    func remove(characterId: Int) {
        mappings.removeValue(forKey: characterId)
    }

    func remove(localIdentifier: String) {
        if let key = mappings.first(where: { $0.value == localIdentifier })?.key {
            mappings.removeValue(forKey: key)
        }
    }

    func allMappings() -> [Int: String] {
        mappings
    }
}
