//
//  CharacterDetailRoute.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation

// MARK: - CharacterDetailRoute

enum CharacterDetailRoute {
    case showPhoto(imageURL: URL?, characterName: String, characterId: Int)
}
