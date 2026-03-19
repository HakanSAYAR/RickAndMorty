//
//  CharacterRepository.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import Foundation

// MARK: - CharacterRepository

protocol CharacterRepository {
    func fetchPage(_ page: Int) async throws -> CharacterPage
}
