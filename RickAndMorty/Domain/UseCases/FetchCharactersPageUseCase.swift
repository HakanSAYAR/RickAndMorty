//
//  FetchCharactersPageUseCase.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import Foundation

// MARK: - FetchCharactersPageUseCaseProtocol

protocol FetchCharactersPageUseCaseProtocol {
    func execute(page: Int) async throws -> CharacterPage
}

// MARK: - FetchCharactersPageUseCase

final class FetchCharactersPageUseCase: FetchCharactersPageUseCaseProtocol {

    nonisolated(unsafe) private let repository: any CharacterRepository

    nonisolated init(repository: any CharacterRepository) {
        self.repository = repository
    }

    func execute(page: Int) async throws -> CharacterPage {
        try await repository.fetchPage(page)
    }
}

