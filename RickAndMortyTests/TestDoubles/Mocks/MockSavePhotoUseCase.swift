//
//  MockSavePhotoUseCase.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - MockSavePhotoUseCase
// Records all execute() calls, optionally throws a configured error, and returns a configured result.

final class MockSavePhotoUseCase: SaveImageToGalleryUseCaseProtocol {

    var executeCallCount = 0
    var lastCharacterId: Int?
    var lastSavedData: Data?
    var result: SaveImageResult = .saved
    var saveError: Error?

    func execute(characterId: Int, imageData: Data) async throws -> SaveImageResult {
        executeCallCount += 1
        lastCharacterId = characterId
        lastSavedData = imageData
        if let error = saveError { throw error }
        return result
    }
}
