//
//  CharacterRepositoryImplTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import NetworkKit
@testable import RickAndMorty

// MARK: - CharacterRepositoryImplTests

struct CharacterRepositoryImplTests {

    // MARK: - Helpers

    private func makeSUT() -> (sut: CharacterRepositoryImpl, api: MockAPIService) {
        let api = MockAPIService()
        return (CharacterRepositoryImpl(apiService: api), api)
    }

    // MARK: - Happy Path

    @Test func fetchPage_happyPath_returnsMappedDomainPage() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(
            CharacterPageDTO.stub(
                pages: 3,
                next: "https://api.example.com/character?page=2",
                characters: [.stub(id: 42, name: "Rick Sanchez", status: "Alive")]
            )
        )

        let page = try await sut.fetchPage(1)

        #expect(api.fetchCallCount == 1)
        #expect(page.info.totalPages == 3)
        #expect(page.info.hasNextPage == true)
        #expect(page.results.count == 1)
        #expect(page.results[0].id == 42)
        #expect(page.results[0].name == "Rick Sanchez")
        #expect(page.results[0].status == .alive)
    }

    @Test func fetchPage_lastPage_hasNextPageFalse() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(CharacterPageDTO.stub(pages: 1, next: nil))

        let page = try await sut.fetchPage(1)

        #expect(page.info.hasNextPage == false)
        #expect(page.info.totalPages == 1)
    }

    // MARK: - Mapper Integration

    @Test func fetchPage_unknownStatus_mapperFallsBackToUnknown() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(
            CharacterPageDTO.stub(characters: [.stub(status: "Cyborg")])
        )

        let page = try await sut.fetchPage(1)

        // Proves the mapper ran — raw DTO value was not exposed as-is
        #expect(page.results[0].status == .unknown)
    }

    @Test func fetchPage_unknownGender_mapperFallsBackToUnknown() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(
            CharacterPageDTO.stub(characters: [.stub(gender: "Agender")])
        )

        let page = try await sut.fetchPage(1)

        #expect(page.results[0].gender == .unknown)
    }

    @Test func fetchPage_nilOriginName_mapperProducesEmptyString() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(
            CharacterPageDTO.stub(characters: [.stub(originName: nil)])
        )

        let page = try await sut.fetchPage(1)

        #expect(page.results[0].origin.name == "")
    }

    // MARK: - Error Propagation

    @Test func fetchPage_networkFailure_propagatesError() async {
        let (sut, api) = makeSUT()
        api.defaultResult = .failure(MockError.generic)

        do {
            _ = try await sut.fetchPage(1)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is MockError)
        }
    }

    @Test func fetchPage_wrongDecodedType_propagatesError() async {
        let (sut, api) = makeSUT()
        // Returning a CharacterPage (domain type) instead of CharacterPageDTO triggers
        // the MockAPIService type-cast guard → throws MockError.unexpectedType
        api.defaultResult = .success(CharacterPage.stub())

        do {
            _ = try await sut.fetchPage(1)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is MockError)
        }
    }

    // MARK: - Empty Results

    @Test func fetchPage_emptyResults_returnsDomainPageWithNoCharacters() async throws {
        let (sut, api) = makeSUT()
        api.defaultResult = .success(CharacterPageDTO.stub(characters: []))

        let page = try await sut.fetchPage(1)

        #expect(page.results.isEmpty)
    }
}
