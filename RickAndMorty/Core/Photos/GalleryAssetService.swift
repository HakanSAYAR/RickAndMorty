//
//  GalleryAssetService.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - GalleryAssetServiceProtocol

protocol GalleryAssetServiceProtocol {
    /// Synchronously fetches images and warms cache. Must run on a background context.
    nonisolated func fetchPhotos() -> [GalleryPhoto]
}

// MARK: - GalleryAssetService
// Fetches photos, updates asset cache, maps to domain types.

final class GalleryAssetService: GalleryAssetServiceProtocol {

    private let store: GalleryAssetStore
    nonisolated(unsafe) private let assetCache: PHAssetCacheProtocol

    init(store: GalleryAssetStore, assetCache: PHAssetCacheProtocol) {
        self.store = store
        self.assetCache = assetCache
    }

    nonisolated func fetchPhotos() -> [GalleryPhoto] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.includeAssetSourceTypes = [.typeUserLibrary]

        let result = PHAsset.fetchAssets(with: .image, options: options)

        store.update(fetchResult: result)
        assetCache.populate(with: result)

        var photos: [GalleryPhoto] = []
        photos.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            photos.append(GalleryPhoto(
                localIdentifier: asset.localIdentifier,
                creationDate: asset.creationDate
            ))
        }
        return photos
    }
}
