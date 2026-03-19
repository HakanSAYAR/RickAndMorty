//
//  PHAssetCache.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - PHAssetCacheProtocol

protocol PHAssetCacheProtocol: AnyObject {
    /// Returns the cached PHAsset for the given localIdentifier, or nil if not populated.
    nonisolated func asset(for localIdentifier: String) -> PHAsset?

    /// Populates the cache from an already-fetched PHFetchResult — no extra I/O.
    nonisolated func populate(with fetchResult: PHFetchResult<PHAsset>)
}

// MARK: - PHAssetCache

/// Thread-safe, in-memory cache mapping `localIdentifier → PHAsset`.
/// Populated once per gallery load; reused for all cell configures and caching calls.
/// NSLock serialises populate (background) vs asset(for:) (main thread) access.
final class PHAssetCache: PHAssetCacheProtocol, @unchecked Sendable {

    nonisolated(unsafe) private var storage: [String: PHAsset] = [:]
    private let lock = NSLock()

    nonisolated init() {}

    nonisolated func asset(for localIdentifier: String) -> PHAsset? {
        lock.withLock { storage[localIdentifier] }
    }

    nonisolated func populate(with fetchResult: PHFetchResult<PHAsset>) {
        var result: [String: PHAsset] = [:]
        result.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in
            result[asset.localIdentifier] = asset
        }
        lock.withLock { storage = result }
        PerformanceSignpost.event(PerformanceSignpost.Name.assetCachePopulate, "cache_populated")
    }
}
