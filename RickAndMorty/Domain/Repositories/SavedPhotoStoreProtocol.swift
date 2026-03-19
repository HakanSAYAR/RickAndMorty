//
//  SavedPhotoStoreProtocol.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026.
//

import Foundation

// MARK: - SavedPhotoStoreProtocol
//
// Persistence contract for characterId → PHAsset localIdentifier mappings.

protocol SavedPhotoStoreProtocol: Sendable {
    func localIdentifier(for characterId: Int) async -> String?
    func save(characterId: Int, localIdentifier: String) async
    func remove(characterId: Int) async
}
