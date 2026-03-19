//
//  MockFetchCharactersUseCase.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - MockFetchCharactersUseCase
// Uses a result queue: each execute() call dequeues the first result.
// Falls back to defaultResult when the queue is empty.

final class MockFetchCharactersUseCase: FetchCharactersPageUseCaseProtocol {

    var resultsQueue: [Result<CharacterPage, Error>] = []
    var defaultResult: Result<CharacterPage, Error> = .success(CharacterPage.stub())
    var executeCallCount = 0

    func execute(page: Int) async throws -> CharacterPage {
        executeCallCount += 1
        let result = resultsQueue.isEmpty ? defaultResult : resultsQueue.removeFirst()
        return try result.get()
    }
}
