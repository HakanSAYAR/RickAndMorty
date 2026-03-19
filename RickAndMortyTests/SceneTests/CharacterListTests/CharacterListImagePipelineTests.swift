//
//  CharacterListImagePipelineTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
import Kingfisher
@testable import RickAndMorty

// MARK: - CharacterListImagePipelineTests

struct CharacterListImagePipelineTests {

    private let pipeline = CharacterListImagePipeline()

    // MARK: - Processor

    @Test func options_containsDownsamplingProcessor() {
        let targetSize = CGSize(width: 100, height: 140)
        let options = pipeline.options(targetSize: targetSize)
        let hasDownsampling = options.contains {
            if case .processor(let p) = $0 {
                return p is DownsamplingImageProcessor
            }
            return false
        }
        #expect(hasDownsampling)
    }

    // MARK: - Cache Key Consistency

    @Test func options_sameSize_producesSameCacheKey() {
        let size = CGSize(width: 120, height: 168)
        let options1 = pipeline.options(targetSize: size)
        let options2 = pipeline.options(targetSize: size)

        let key1 = options1.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        let key2 = options2.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        #expect(key1 != nil)
        #expect(key1 == key2)
    }

    @Test func options_differentSize_producesDifferentCacheKey() {
        let options1 = pipeline.options(targetSize: CGSize(width: 100, height: 140))
        let options2 = pipeline.options(targetSize: CGSize(width: 200, height: 280))

        let key1 = options1.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        let key2 = options2.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        #expect(key1 != key2)
    }

    // MARK: - Scale Factor

    @Test func options_containsScaleFactor() {
        let options = pipeline.options(targetSize: CGSize(width: 100, height: 140))
        let hasScale = options.contains {
            if case .scaleFactor = $0 { return true }
            return false
        }
        #expect(hasScale)
    }

    // MARK: - Cell and Prefetch Alignment

    /// Scope: confirms that CharacterImagePipeline produces consistent identifiers
    /// for equal sizes. It does NOT guarantee a Kingfisher cache hit at runtime —
    /// actual hits depend on cache capacity and memory pressure.
    @Test func cellAndPrefetch_sameTargetSize_producesMatchingCacheKey() {
        let sharedSize = CGSize(width: 150, height: 210)
        let cellOptions = pipeline.options(targetSize: sharedSize)
        let prefetchOptions = pipeline.options(targetSize: sharedSize)

        let cellKey = cellOptions.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        let prefetchKey = prefetchOptions.compactMap { item -> String? in
            if case .processor(let p) = item { return p.identifier }
            return nil
        }.first

        #expect(cellKey != nil)
        #expect(cellKey == prefetchKey)
    }
}
