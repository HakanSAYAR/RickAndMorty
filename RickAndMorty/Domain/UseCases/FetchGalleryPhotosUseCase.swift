//
//  FetchGalleryPhotosUseCase.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import Foundation

// MARK: - FetchGalleryPhotosUseCaseProtocol

protocol FetchGalleryPhotosUseCaseProtocol {
    func execute() async throws -> [GalleryPhoto]
}

// MARK: - FetchGalleryPhotosUseCase

final class FetchGalleryPhotosUseCase: FetchGalleryPhotosUseCaseProtocol {

    nonisolated(unsafe) private let repository: any GalleryRepository

    nonisolated init(repository: any GalleryRepository) {
        self.repository = repository
    }

    func execute() async throws -> [GalleryPhoto] {
        try await repository.fetchPhotos()
    }
}
