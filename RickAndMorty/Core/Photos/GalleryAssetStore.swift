//
//  GalleryAssetStore.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - GalleryAssetStore
// Holds the current PHFetchResult snapshot. NSLock serialises all access.

final class GalleryAssetStore: @unchecked Sendable {

    // MARK: - State

    // nonisolated(unsafe): guarded by lock in all read/write paths.
    nonisolated(unsafe) private var currentFetchResult: PHFetchResult<PHAsset>?
    private let lock = NSLock()

    nonisolated init() {}

    // MARK: - Snapshot Update

    nonisolated func update(fetchResult: PHFetchResult<PHAsset>) {
        lock.withLock { currentFetchResult = fetchResult }
    }

}
