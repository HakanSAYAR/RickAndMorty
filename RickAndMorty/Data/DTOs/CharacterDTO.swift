//
//  CharacterDTO.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterDTO

struct CharacterDTO: Decodable {
    let id: Int
    let name: String
    let status: String
    let species: String
    let gender: String
    let origin: CharacterLocationDTO
    let location: CharacterLocationDTO
    let image: String

    // nonisolated: test construction without Decodable conflict.
    nonisolated init(
        id: Int,
        name: String,
        status: String,
        species: String,
        gender: String,
        origin: CharacterLocationDTO,
        location: CharacterLocationDTO,
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

// MARK: - CharacterLocationDTO

struct CharacterLocationDTO: Decodable {
    let name: String?

    nonisolated init(name: String?) {
        self.name = name
    }
}
