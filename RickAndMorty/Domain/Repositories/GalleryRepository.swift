//
//  GalleryRepository.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import Foundation

// MARK: - GalleryRepository

protocol GalleryRepository {
    /// Fetches all gallery photos from the photo library.
    /// Throws `GalleryError` if access is denied or restricted.
    func fetchPhotos() async throws -> [GalleryPhoto]
}

// MARK: - GalleryError

enum GalleryError: Error {
    case accessDenied
    case accessRestricted
}

nonisolated extension GalleryError: Equatable {}
