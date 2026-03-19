//
//  SaveImageToGalleryUseCaseTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - SaveImageToGalleryUseCaseTests

struct SaveImageToGalleryUseCaseTests {

    // MARK: - Mock: SavedPhotoStore

    private actor MockSavedPhotoStoreLocal: SavedPhotoStoreProtocol {
        var mappings: [Int: String] = [:]

        func localIdentifier(for characterId: Int) -> String? {
            mappings[characterId]
        }

        func save(characterId: Int, localIdentifier: String) {
            mappings[characterId] = localIdentifier
        }

        func remove(characterId: Int) {
            mappings.removeValue(forKey: characterId)
        }
    }

    // MARK: - Mock: PhotoLibrarySaver

    private final class MockPhotoLibrarySaver: PhotoLibrarySaverProtocol {
        var stubbedLocalIdentifier: String = "new-local-id"
        var saveError: Error?
        var existingIdentifiers: Set<String> = []
        private(set) var saveCallCount = 0
        private(set) var assetExistsCallCount = 0

        /// Returns the `localIdentifier` of the newly saved PHAsset.
        func save(imageData: Data) async throws -> String {
            saveCallCount += 1
            if let error = saveError { throw error }
            return stubbedLocalIdentifier
        }

        func assetExists(localIdentifier: String) -> Bool {
            assetExistsCallCount += 1
            return existingIdentifiers.contains(localIdentifier)
        }
    }

    // MARK: - Helper

    private func makeSUT(
        existingMappings: [Int: String] = [:],
        existingAssets: Set<String> = [],
        stubbedLocalIdentifier: String = "new-local-id",
        saveError: Error? = nil
    ) async -> (
        sut: SaveImageToGalleryUseCase,
        store: MockSavedPhotoStoreLocal,
        saver: MockPhotoLibrarySaver
    ) {
        let store = MockSavedPhotoStoreLocal()
        for (id, lid) in existingMappings { await store.save(characterId: id, localIdentifier: lid) }
        let saver = MockPhotoLibrarySaver()
        saver.existingIdentifiers = existingAssets
        saver.stubbedLocalIdentifier = stubbedLocalIdentifier
        saver.saveError = saveError
        let sut = SaveImageToGalleryUseCase(savedPhotoStore: store, photoLibrarySaver: saver)
        return (sut, store, saver)
    }

    // MARK: - Scenario 1: No existing mapping → save → .saved

    @Test func execute_noExistingMapping_savesAndReturnsSaved() async throws {
        let (sut, store, saver) = await makeSUT(stubbedLocalIdentifier: "fresh-id")

        let result = try await sut.execute(characterId: 1, imageData: Data([0xFF, 0xD8]))

        #expect(result == .saved)
        #expect(saver.saveCallCount == 1)
        let stored = await store.localIdentifier(for: 1)
        #expect(stored == "fresh-id")
    }

    // MARK: - Scenario 2: Record exists + asset still valid → .alreadyExists

    @Test func execute_existingValidMapping_returnsAlreadyExists() async throws {
        let existingId = "existing-asset-id"
        let (sut, _, saver) = await makeSUT(
            existingMappings: [1: existingId],
            existingAssets: [existingId]
        )

        let result = try await sut.execute(characterId: 1, imageData: Data([0x01]))

        #expect(result == .alreadyExists)
        #expect(saver.saveCallCount == 0)
        #expect(saver.assetExistsCallCount == 1)
    }

    // MARK: - Scenario 3: Record exists + asset deleted → remove stale → save → .saved

    @Test func execute_staleMapping_assetDeleted_removesAndResaves() async throws {
        let staleId = "stale-asset-id"
        let (sut, store, saver) = await makeSUT(
            existingMappings: [1: staleId],
            existingAssets: [],          // asset no longer exists
            stubbedLocalIdentifier: "new-after-stale"
        )

        let result = try await sut.execute(characterId: 1, imageData: Data([0x01]))

        #expect(result == .saved)
        #expect(saver.saveCallCount == 1)
        let stored = await store.localIdentifier(for: 1)
        #expect(stored == "new-after-stale")
        // Stale entry was replaced
        #expect(stored != staleId)
    }

    // MARK: - Scenario 4: Saver throws → error propagates

    @Test func execute_saverThrows_propagatesError() async {
        let (sut, _, _) = await makeSUT(saveError: MockError.generic)

        do {
            _ = try await sut.execute(characterId: 1, imageData: Data([0x01]))
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is MockError)
        }
    }

    @Test func execute_saverThrows_doesNotRecordMapping() async {
        let (sut, store, _) = await makeSUT(saveError: MockError.generic)

        _ = try? await sut.execute(characterId: 1, imageData: Data([0x01]))

        let stored = await store.localIdentifier(for: 1)
        #expect(stored == nil)
    }
}
