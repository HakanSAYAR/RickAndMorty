//
//  CharacterListGalleryPipeline.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - CharacterListGalleryPipelineProtocol

protocol CharacterListGalleryPipelineProtocol: AnyObject {
    /// Read-only access to the caching manager for GalleryCell configure.
    /// Lifecycle (start/stop caching) is owned entirely by the pipeline.
    var cachingImageManager: PHCachingImageManager { get }

    /// Updates the preheat window with a diff-based start/stop caching call.
    ///
    /// - Parameters:
    ///   - assets:     All PHAssets that should be in the active preheat window.
    ///                 Computed by the caller from layout + snapshot.
    ///   - targetSize: Pixel-accurate size; must match the size used in GalleryCell.configure
    ///                 to guarantee cache key alignment.
    ///   - options:    PHImageRequestOptions from PHImageRequestOptionsFactory.
    func updateCaching(assets: [PHAsset], targetSize: CGSize, options: PHImageRequestOptions?)

    /// Stops all in-flight caching and resets internal state.
    /// Call from viewDidDisappear and didReceiveMemoryWarning.
    func invalidateCaching()
}

// MARK: - CharacterListGalleryPipeline

final class CharacterListGalleryPipeline: CharacterListGalleryPipelineProtocol {

    // MARK: - Properties

    let cachingImageManager: PHCachingImageManager

    // MARK: - Init

    nonisolated init(cachingImageManager: PHCachingImageManager = PHCachingImageManager()) {
        cachingImageManager.allowsCachingHighQualityImages = false
        self.cachingImageManager = cachingImageManager
    }

    /// Assets currently registered with the caching manager.
    /// Retained so we can compute stop-caching diffs without re-resolving identifiers.
    private var cachedAssets: [PHAsset] = []

    // MARK: - Update Caching

    func updateCaching(assets: [PHAsset], targetSize: CGSize, options: PHImageRequestOptions?) {
        let newIDs = Set(assets.map { $0.localIdentifier })
        let oldIDs = Set(cachedAssets.map { $0.localIdentifier })

        let toStop = cachedAssets.filter { !newIDs.contains($0.localIdentifier) }
        let toStart = assets.filter { !oldIDs.contains($0.localIdentifier) }
        cachedAssets = assets

        if !toStop.isEmpty {
            cachingImageManager.stopCachingImages(
                for: toStop,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            )
        }
        if !toStart.isEmpty {
            cachingImageManager.startCachingImages(
                for: toStart,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            )
        }
    }

    // MARK: - Invalidate

    func invalidateCaching() {
        cachingImageManager.stopCachingImagesForAllAssets()
        cachedAssets = []
    }

    // MARK: - Static Threshold Logic (testable)

    /// Returns true if preheat rect shifted > 25% of previous height.
    nonisolated static func shouldUpdatePreheatRect(previous: CGRect, current: CGRect) -> Bool {
        guard !previous.isEmpty else { return !current.isEmpty }
        let delta = abs(current.midY - previous.midY)
        return delta > previous.height / 4
    }
}
