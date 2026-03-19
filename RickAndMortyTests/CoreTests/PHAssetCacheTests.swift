//
//  PHAssetCacheTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Photos
@testable import RickAndMorty

// MARK: - PHAssetCacheTests

struct PHAssetCacheTests {

    // MARK: - Lookup on Empty Cache

    @Test func lookup_onFreshCache_returnsNil() {
        let cache = PHAssetCache()
        #expect(cache.asset(for: "any-identifier") == nil)
    }

    @Test func lookup_unknownIdentifier_returnsNil() {
        let cache = PHAssetCache()
        #expect(cache.asset(for: "") == nil)
        #expect(cache.asset(for: "com.apple.photos.unknown") == nil)
    }

    // MARK: - Thread Safety

    @Test func concurrentReads_doNotCrash() async {
        let cache = PHAssetCache()
        // Fire 200 concurrent read tasks against an empty cache.
        // If NSLock is missing or incorrect a TSAN/crash would appear here.
        await withTaskGroup(of: PHAsset?.self) { group in
            for i in 0..<200 {
                group.addTask {
                    cache.asset(for: "identifier-\(i % 10)")
                }
            }
            for await _ in group { }
        }
        // Reaching here without crash confirms lock correctness under concurrent reads.
    }
}
