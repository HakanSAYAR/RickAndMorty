//
//  FetchCharactersPageUseCaseTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - FetchCharactersPageUseCaseTests

struct FetchCharactersPageUseCaseTests {

    // MARK: - Mock

    private final class MockCharacterRepository: CharacterRepository {
        var result: Result<CharacterPage, Error> = .success(.stub())
        private(set) var fetchPageCallCount = 0
        private(set) var lastPage: Int?

        func fetchPage(_ page: Int) async throws -> CharacterPage {
            fetchPageCallCount += 1
            lastPage = page
            return try result.get()
        }
    }

    // MARK: - Delegation

    @Test func execute_delegatesToRepository() async throws {
        let repo = MockCharacterRepository()
        repo.result = .success(.stub(pages: 3, characters: [.stub(id: 42)]))
        let sut = FetchCharactersPageUseCase(repository: repo)

        let result = try await sut.execute(page: 2)

        #expect(repo.fetchPageCallCount == 1)
        #expect(repo.lastPage == 2)
        #expect(result.results.first?.id == 42)
        #expect(result.info.totalPages == 3)
    }

    @Test func execute_passesCorrectPage() async throws {
        let repo = MockCharacterRepository()
        let sut = FetchCharactersPageUseCase(repository: repo)

        _ = try await sut.execute(page: 7)

        #expect(repo.lastPage == 7)
    }

    // MARK: - Error Propagation

    @Test func execute_propagatesError() async {
        let repo = MockCharacterRepository()
        repo.result = .failure(MockError.generic)
        let sut = FetchCharactersPageUseCase(repository: repo)

        do {
            _ = try await sut.execute(page: 1)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is MockError)
        }
    }
}
