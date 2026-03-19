//
//  CharacterStatus.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - CharacterStatus

enum CharacterStatus: String, Sendable {
    case alive   = "Alive"
    case dead    = "Dead"
    case unknown = "unknown"

    nonisolated var displayText: String { rawValue }
}

nonisolated extension CharacterStatus: Hashable {}
