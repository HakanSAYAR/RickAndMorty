//
//  Character.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - Character

struct Character: Sendable {
    nonisolated let id: Int
    nonisolated let name: String
    nonisolated let status: CharacterStatus
    nonisolated let species: String
    nonisolated let gender: CharacterGender
    nonisolated let origin: CharacterLocation
    nonisolated let location: CharacterLocation
    nonisolated let image: String

    nonisolated init(
        id: Int,
        name: String,
        status: CharacterStatus,
        species: String,
        gender: CharacterGender,
        origin: CharacterLocation,
        location: CharacterLocation,
        image: String
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.species = species
        self.gender = gender
        self.origin = origin
        self.location = location
        self.image = image
    }
}

// nonisolated extension: identity is id-only; other fields not part of Hashable.
nonisolated extension Character: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Character, rhs: Character) -> Bool {
        lhs.id == rhs.id
    }
}
