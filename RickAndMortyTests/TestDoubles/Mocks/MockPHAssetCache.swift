//
//  MockPHAssetCache.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Photos
@testable import RickAndMorty

// MARK: - MockPHAssetCache

final class MockPHAssetCache: PHAssetCacheProtocol {
    private var storage: [String: PHAsset] = [:]
    private(set) var populateCalled = false

    func asset(for localIdentifier: String) -> PHAsset? {
        storage[localIdentifier]
    }

    func populate(with fetchResult: PHFetchResult<PHAsset>) {
        populateCalled = true
    }
}
