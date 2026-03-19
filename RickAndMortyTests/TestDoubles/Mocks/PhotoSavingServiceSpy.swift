//
//  PhotoSavingServiceSpy.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - PhotoSavingServiceSpy
// Records all save() calls and optionally throws a configured error.

final class PhotoSavingServiceSpy: PhotoLibrarySaverProtocol {

    var saveCallCount = 0
    var lastSavedData: Data?
    var saveError: Error?
    var stubbedLocalIdentifier: String = "stub-local-id"

    func save(imageData: Data) async throws -> String {
        saveCallCount += 1
        lastSavedData = imageData
        if let error = saveError { throw error }
        return stubbedLocalIdentifier
    }

    func assetExists(localIdentifier: String) -> Bool { false }
}
