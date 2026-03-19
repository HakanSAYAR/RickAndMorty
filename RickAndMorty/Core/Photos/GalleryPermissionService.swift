//
//  GalleryPermissionService.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - GalleryPermissionResult
// Domain-friendly result — PHAuthorizationStatus does not cross this boundary.

enum GalleryPermissionResult {
    case granted
    case denied
    case restricted
}

// MARK: - GalleryPermissionServiceProtocol

protocol GalleryPermissionServiceProtocol {
    func requestAuthorization() async -> GalleryPermissionResult
}

// MARK: - GalleryPermissionService

final class GalleryPermissionService: GalleryPermissionServiceProtocol {

    func requestAuthorization() async -> GalleryPermissionResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited: return .granted
        case .restricted:           return .restricted
        default:                    return .denied
        }
    }
}
