//
//  SavedPhotoStore.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation

// MARK: - SavedPhotoStore

/// Actor-isolated, UserDefaults-backed store for characterId → localIdentifier mappings.
actor SavedPhotoStore: SavedPhotoStoreProtocol {

    // MARK: - Private

    // nonisolated(unsafe): let constant, set in init only.
    nonisolated(unsafe) private let defaults: UserDefaults
    private let storageKey = "saved_photo_store_mappings"

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - SavedPhotoStoreProtocol

    func localIdentifier(for characterId: Int) -> String? {
        load()[characterId]
    }

    func save(characterId: Int, localIdentifier: String) {
        var mappings = load()
        mappings[characterId] = localIdentifier
        persist(mappings)
    }

    func remove(characterId: Int) {
        var mappings = load()
        mappings.removeValue(forKey: characterId)
        persist(mappings)
    }

    func remove(localIdentifier: String) {
        var mappings = load()
        if let key = mappings.first(where: { $0.value == localIdentifier })?.key {
            mappings.removeValue(forKey: key)
            persist(mappings)
        }
    }

    func allMappings() -> [Int: String] {
        load()
    }

    // MARK: - Private

    private func load() -> [Int: String] {
        guard let data = defaults.data(forKey: storageKey) else { return [:] }
        guard let decoded = try? JSONDecoder().decode([Int: String].self, from: data) else {
            assertionFailure("SavedPhotoStore: decode failed for key '\(storageKey)'")
            defaults.removeObject(forKey: storageKey)
            return [:]
        }
        return decoded
    }

    private func persist(_ mappings: [Int: String]) {
        guard let data = try? JSONEncoder().encode(mappings) else {
            assertionFailure("SavedPhotoStore: encode failed for key '\(storageKey)'")
            return
        }
        defaults.set(data, forKey: storageKey)
    }
}
