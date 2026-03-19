//
//  FetchGalleryPhotosUseCaseTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - FetchGalleryPhotosUseCaseTests

struct FetchGalleryPhotosUseCaseTests {

    // MARK: - Mock

    private final class MockGalleryRepository: GalleryRepository {
        var result: Result<[GalleryPhoto], Error> = .success([])
        private(set) var fetchPhotosCallCount = 0

        func fetchPhotos() async throws -> [GalleryPhoto] {
            fetchPhotosCallCount += 1
            return try result.get()
        }
    }

    // MARK: - Delegation

    @Test func execute_delegatesToRepository() async throws {
        let repo = MockGalleryRepository()
        repo.result = .success([
            GalleryPhoto(localIdentifier: "id-1", creationDate: nil),
            GalleryPhoto(localIdentifier: "id-2", creationDate: nil)
        ])
        let sut = FetchGalleryPhotosUseCase(repository: repo)

        let photos = try await sut.execute()

        #expect(repo.fetchPhotosCallCount == 1)
        #expect(photos.count == 2)
        #expect(photos.first?.localIdentifier == "id-1")
    }

    @Test func execute_returnsEmptyWhenRepositoryReturnsEmpty() async throws {
        let repo = MockGalleryRepository()
        repo.result = .success([])
        let sut = FetchGalleryPhotosUseCase(repository: repo)

        let photos = try await sut.execute()

        #expect(photos.isEmpty)
    }

    // MARK: - Error Propagation

    @Test func execute_propagatesAccessDenied() async {
        let repo = MockGalleryRepository()
        repo.result = .failure(GalleryError.accessDenied)
        let sut = FetchGalleryPhotosUseCase(repository: repo)

        do {
            _ = try await sut.execute()
            Issue.record("Expected GalleryError to be thrown")
        } catch let error as GalleryError {
            #expect(error == .accessDenied)
        } catch {
            Issue.record("Expected GalleryError, got \(error)")
        }
    }

    @Test func execute_propagatesAccessRestricted() async {
        let repo = MockGalleryRepository()
        repo.result = .failure(GalleryError.accessRestricted)
        let sut = FetchGalleryPhotosUseCase(repository: repo)

        do {
            _ = try await sut.execute()
            Issue.record("Expected GalleryError to be thrown")
        } catch let error as GalleryError {
            #expect(error == .accessRestricted)
        } catch {
            Issue.record("Expected GalleryError, got \(error)")
        }
    }
}
