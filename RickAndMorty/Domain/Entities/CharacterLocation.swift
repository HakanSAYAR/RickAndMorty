//
//  CharacterLocation.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterLocation

struct CharacterLocation: Sendable {
    nonisolated let name: String

    nonisolated init(name: String) {
        self.name = name
    }
}

nonisolated extension CharacterLocation: Hashable {}
