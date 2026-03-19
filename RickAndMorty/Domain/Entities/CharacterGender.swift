//
//  CharacterGender.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterGender

enum CharacterGender: String, Sendable {
    case male       = "Male"
    case female     = "Female"
    case genderless = "Genderless"
    case unknown    = "unknown"

    nonisolated var displayText: String { rawValue }
}

nonisolated extension CharacterGender: Hashable {}
