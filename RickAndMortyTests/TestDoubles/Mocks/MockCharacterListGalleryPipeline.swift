//
//  MockCharacterListGalleryPipeline.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Photos
@testable import RickAndMorty

// MARK: - MockCharacterListGalleryPipeline

final class MockCharacterListGalleryPipeline: CharacterListGalleryPipelineProtocol {

    let cachingImageManager = PHCachingImageManager()

    private(set) var updateCachingCallCount = 0
    private(set) var lastAssets: [PHAsset] = []
    private(set) var invalidateCachingCallCount = 0

    func updateCaching(assets: [PHAsset], targetSize: CGSize, options: PHImageRequestOptions?) {
        updateCachingCallCount += 1
        lastAssets = assets
    }

    func invalidateCaching() {
        invalidateCachingCallCount += 1
    }
}
