//
//  PhotoLibrarySaver.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos
import UIKit

// MARK: - PhotoSavingError

enum PhotoSavingError: Error {
    case permissionDenied
    case invalidImageData
    case saveFailed(Error)
}

// MARK: - PhotoLibrarySaver
//
// Concrete PhotoLibrarySaverProtocol. Permission checked here at infra boundary.

final class PhotoLibrarySaver: PhotoLibrarySaverProtocol {

    func save(imageData: Data) async throws -> String {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoSavingError.permissionDenied
        }
        guard let image = UIImage(data: imageData) else {
            throw PhotoSavingError.invalidImageData
        }
        return try await performSave(image)
    }

    func assetExists(localIdentifier: String) -> Bool {
        PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).count > 0
    }

    // MARK: - Private

    private func performSave(_ image: UIImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            var localIdentifier: String?
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
            }) { success, error in
                if success, let id = localIdentifier {
                    continuation.resume(returning: id)
                } else if let error {
                    continuation.resume(throwing: PhotoSavingError.saveFailed(error))
                } else {
                    continuation.resume(throwing: PhotoSavingError.saveFailed(
                        NSError(domain: "PhotoLibrarySaver", code: -1)
                    ))
                }
            }
        }
    }
}
