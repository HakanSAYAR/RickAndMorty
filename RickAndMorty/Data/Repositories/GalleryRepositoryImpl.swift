//
//  GalleryRepositoryImpl.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026.
//

import Foundation

// MARK: - GalleryRepositoryImpl

final class GalleryRepositoryImpl: GalleryRepository {

    nonisolated(unsafe) private let permissionService: GalleryPermissionServiceProtocol
    nonisolated(unsafe) private let assetService: GalleryAssetServiceProtocol

    nonisolated init(
        permissionService: GalleryPermissionServiceProtocol,
        assetService: GalleryAssetServiceProtocol
    ) {
        self.permissionService = permissionService
        self.assetService = assetService
    }

    func fetchPhotos() async throws -> [GalleryPhoto] {
        let permission = await permissionService.requestAuthorization()
        switch permission {
        case .granted:
            return await Task.detached(priority: .userInitiated) { [assetService] in
                assetService.fetchPhotos()
            }.value
        case .denied:     throw GalleryError.accessDenied
        case .restricted: throw GalleryError.accessRestricted
        }
    }
}
