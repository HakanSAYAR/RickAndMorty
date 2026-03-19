//
//  CharacterRepositoryImpl.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import NetworkKit

// MARK: - CharacterRepositoryImpl

final class CharacterRepositoryImpl: CharacterRepository {

    nonisolated(unsafe) private let apiService: APIServiceProtocol

    nonisolated init(apiService: APIServiceProtocol) {
        self.apiService = apiService
    }

    func fetchPage(_ page: Int) async throws -> CharacterPage {
        let dto: CharacterPageDTO = try await apiService.fetch(
            endpoint: CharacterEndpoint.characters(page: page)
        )
        return CharacterDTOMapper.map(dto)
    }
}
