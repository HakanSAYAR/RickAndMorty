//
//  SaveImageToGalleryUseCase.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026.
//

import Foundation

// MARK: - SaveImageResult

enum SaveImageResult {
    case saved
    case alreadyExists
}

nonisolated extension SaveImageResult: Equatable {}

// MARK: - SaveImageToGalleryUseCaseProtocol

protocol SaveImageToGalleryUseCaseProtocol {
    func execute(characterId: Int, imageData: Data) async throws -> SaveImageResult
}

// MARK: - SaveImageToGalleryUseCase

/// Idempotently saves a character image, detecting externally-deleted assets.
final class SaveImageToGalleryUseCase: SaveImageToGalleryUseCaseProtocol {

    private let savedPhotoStore: any SavedPhotoStoreProtocol
    nonisolated(unsafe) private let photoLibrarySaver: any PhotoLibrarySaverProtocol

    nonisolated init(
        savedPhotoStore: any SavedPhotoStoreProtocol,
        photoLibrarySaver: any PhotoLibrarySaverProtocol
    ) {
        self.savedPhotoStore = savedPhotoStore
        self.photoLibrarySaver = photoLibrarySaver
    }

    func execute(characterId: Int, imageData: Data) async throws -> SaveImageResult {
        if let existingIdentifier = await savedPhotoStore.localIdentifier(for: characterId) {
            if photoLibrarySaver.assetExists(localIdentifier: existingIdentifier) {
                return .alreadyExists
            }
            await savedPhotoStore.remove(characterId: characterId)
        }
        let localIdentifier = try await photoLibrarySaver.save(imageData: imageData)
        await savedPhotoStore.save(characterId: characterId, localIdentifier: localIdentifier)
        return .saved
    }
}

