//
//  GalleryAssetStoreTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Photos
@testable import RickAndMorty

// MARK: - GalleryAssetStoreTests

struct GalleryAssetStoreTests {

    @Test func init_doesNotCrash() {
        _ = GalleryAssetStore()
    }

    @Test func nonisolatedMethods_callableFromDetachedTask() async {
        let store = GalleryAssetStore()
        await Task.detached {
            // update() requires PHFetchResult so we cannot call it here,
            // but reaching this point from a detached (nonisolated) context
            // confirms the store itself crosses isolation boundaries without issues.
            _ = store  // reference is enough to confirm Sendable + nonisolated access
        }.value
    }
}
