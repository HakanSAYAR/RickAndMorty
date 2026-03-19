//
//  MockFetchGalleryItemsUseCase.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
@testable import RickAndMorty

// MARK: - MockFetchGalleryItemsUseCase
// Returns a fixed result for every execute() call.

final class MockFetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol {

    var result: Result<[GalleryPhoto], Error> = .success([])
    var executeCallCount = 0

    func execute() async throws -> [GalleryPhoto] {
        executeCallCount += 1
        return try result.get()
    }
}
