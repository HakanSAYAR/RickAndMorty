//
//  GalleryRepositoryImplTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - GalleryRepositoryImplTests

struct GalleryRepositoryImplTests {

    // MARK: - Mock: GalleryPermissionService

    private final class MockGalleryPermissionService: GalleryPermissionServiceProtocol {
        var result: GalleryPermissionResult = .granted
        func requestAuthorization() async -> GalleryPermissionResult { result }
    }

    // MARK: - Mock: GalleryAssetService

    private final class MockGalleryAssetService: GalleryAssetServiceProtocol {
        var stubbedPhotos: [GalleryPhoto] = []
        private(set) var fetchCallCount = 0

        func fetchPhotos() -> [GalleryPhoto] {
            fetchCallCount += 1
            return stubbedPhotos
        }
    }

    // MARK: - Helper

    private func makeSUT(
        permission: GalleryPermissionResult = .granted,
        photos: [GalleryPhoto] = []
    ) -> (sut: GalleryRepositoryImpl, permission: MockGalleryPermissionService, assets: MockGalleryAssetService) {
        let permissionService = MockGalleryPermissionService()
        permissionService.result = permission
        let assetService = MockGalleryAssetService()
        assetService.stubbedPhotos = photos
        let sut = GalleryRepositoryImpl(permissionService: permissionService, assetService: assetService)
        return (sut, permissionService, assetService)
    }

    // MARK: - Happy Path

    @Test func fetchPhotos_granted_returnsPhotosFromAssetService() async throws {
        let expected: [GalleryPhoto] = [
            .stub(localIdentifier: "photo-1"),
            .stub(localIdentifier: "photo-2")
        ]
        let (sut, _, assets) = makeSUT(permission: .granted, photos: expected)

        let photos = try await sut.fetchPhotos()

        #expect(photos.count == 2)
        #expect(photos[0].localIdentifier == "photo-1")
        #expect(photos[1].localIdentifier == "photo-2")
        #expect(assets.fetchCallCount == 1)
    }

    @Test func fetchPhotos_granted_emptyLibrary_returnsEmptyArray() async throws {
        let (sut, _, assets) = makeSUT(permission: .granted, photos: [])

        let photos = try await sut.fetchPhotos()

        #expect(photos.isEmpty)
        #expect(assets.fetchCallCount == 1)
    }

    // MARK: - Permission Error Propagation

    @Test func fetchPhotos_denied_throwsAccessDenied_doesNotFetchAssets() async {
        let (sut, _, assets) = makeSUT(permission: .denied)

        do {
            _ = try await sut.fetchPhotos()
            Issue.record("Expected GalleryError.accessDenied")
        } catch let error as GalleryError {
            #expect(error == GalleryError.accessDenied)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(assets.fetchCallCount == 0)
    }

    @Test func fetchPhotos_restricted_throwsAccessRestricted_doesNotFetchAssets() async {
        let (sut, _, assets) = makeSUT(permission: .restricted)

        do {
            _ = try await sut.fetchPhotos()
            Issue.record("Expected GalleryError.accessRestricted")
        } catch let error as GalleryError {
            #expect(error == GalleryError.accessRestricted)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
        #expect(assets.fetchCallCount == 0)
    }
}
