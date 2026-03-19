//
//  CharacterListPrefetchHandler.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Kingfisher

// MARK: - CharacterListPrefetchHandler

/// Handles UICollectionViewDataSourcePrefetching for .character items only.
///
/// Gallery preheat uses PHCachingImageManager via scroll-based rect diff
/// (CharacterListGalleryPipeline) — not UIKit's prefetch API.
final class CharacterListPrefetchHandler: NSObject, UICollectionViewDataSourcePrefetching {

    // MARK: - Injected

    /// Resolves a DataSource item for a given IndexPath.
    /// Set by the ViewController after DataSource is configured.
    var itemForIndexPath: ((IndexPath) -> CharacterListSectionItem?)?

    /// Returns the character cell target size for Kingfisher options.
    /// Closure injection avoids coupling to UICollectionView reference.
    var targetSize: (() -> CGSize)?

    // MARK: - Private

    private let imagePipeline: any CharacterListImagePipelineProtocol
    private var activePrefetcher: ImagePrefetcher?

    // MARK: - Init

    init(imagePipeline: any CharacterListImagePipelineProtocol) {
        self.imagePipeline = imagePipeline
    }

    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { indexPath -> URL? in
            guard case .character(let viewData) = itemForIndexPath?(indexPath) else { return nil }
            return viewData.imageURL
        }
        guard !urls.isEmpty else { return }

        // Off-screen prefetch uses formula fallback matching cell's cache key.
        let size = targetSize?() ?? .zero
        PerformanceSignpost.event(PerformanceSignpost.Name.prefetchStart, "character_prefetch")
        activePrefetcher = ImagePrefetcher(urls: urls, options: imagePipeline.options(targetSize: size))
        activePrefetcher?.start()
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        // ImagePrefetcher has no per-URL cancel. Full teardown in cancelAll().
        PerformanceSignpost.event(PerformanceSignpost.Name.prefetchCancel, "character_prefetch_cancel")
    }

    // MARK: - Lifecycle

    func cancelAll() {
        activePrefetcher?.stop()
        activePrefetcher = nil
    }
}
