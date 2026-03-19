//
//  PhotoLibrarySaverProtocol.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026.
//

import Foundation

// MARK: - PhotoLibrarySaverProtocol
//
// Domain boundary for photo library write access and asset existence queries.
// Concrete implementation: Core/Photos/PhotoLibrarySaver.swift

protocol PhotoLibrarySaverProtocol {
    /// Saves image data to the photo library.
    /// - Returns: The `localIdentifier` of the newly saved PHAsset.
    func save(imageData: Data) async throws -> String

    /// Returns `true` if the asset identified by `localIdentifier` still exists
    /// in the photo library. Used by `SaveImageToGalleryUseCase` to detect stale mappings.
    func assetExists(localIdentifier: String) -> Bool
}
