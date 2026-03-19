//
//  CharacterListGalleryPipelineTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Photos
import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterListGalleryPipelineTests

struct CharacterListGalleryPipelineTests {

    // MARK: - shouldUpdatePreheatRect (threshold logic)

    @Test func shouldUpdate_emptyPrevious_nonEmptyCurrent_returnsTrue() {
        #expect(CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: .zero, current: CGRect(x: 0, y: 0, width: 100, height: 200)))
    }

    @Test func shouldUpdate_emptyPrevious_emptyCurrent_returnsFalse() {
        #expect(!CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: .zero, current: .zero))
    }

    @Test func shouldUpdate_smallShift_belowThreshold_returnsFalse() {
        let previous = CGRect(x: 0, y: 0, width: 375, height: 800)
        // Shift = 10 < 800/4 = 200 → false
        let current = CGRect(x: 0, y: 10, width: 375, height: 800)
        #expect(!CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: previous, current: current))
    }

    @Test func shouldUpdate_largeShift_aboveThreshold_returnsTrue() {
        let previous = CGRect(x: 0, y: 0, width: 375, height: 800)
        // Shift = 250 > 800/4 = 200 → true
        let current = CGRect(x: 0, y: 250, width: 375, height: 800)
        #expect(CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: previous, current: current))
    }

    @Test func shouldUpdate_exactlyAtThreshold_returnsFalse() {
        let previous = CGRect(x: 0, y: 0, width: 375, height: 800)
        // Shift = 200 == 800/4 = 200 → NOT > threshold, returns false
        let current = CGRect(x: 0, y: 200, width: 375, height: 800)
        #expect(!CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: previous, current: current))
    }

    @Test func shouldUpdate_scrollingUp_usesAbsoluteDelta() {
        let previous = CGRect(x: 0, y: 500, width: 375, height: 800)
        // Shift = |-300| = 300 > 800/4 = 200 → true
        let current = CGRect(x: 0, y: 200, width: 375, height: 800)
        #expect(CharacterListGalleryPipeline.shouldUpdatePreheatRect(previous: previous, current: current))
    }

    // MARK: - invalidateCaching

    @Test func invalidateCaching_doesNotCrash() {
        let pipeline = CharacterListGalleryPipeline()
        pipeline.invalidateCaching()
        // No crash, manager is reset
    }

    @Test func invalidateCaching_calledTwice_doesNotCrash() {
        let pipeline = CharacterListGalleryPipeline()
        pipeline.invalidateCaching()
        pipeline.invalidateCaching()
    }

    // MARK: - cachingImageManager exposure

    @Test func cachingImageManager_isAccessible() {
        let pipeline = CharacterListGalleryPipeline()
        // Protocol { get } surface — verifies the property is readable.
        // PHCachingImageManager is a reference type; we confirm the same instance is returned twice.
        #expect(pipeline.cachingImageManager === pipeline.cachingImageManager)
    }

    // MARK: - updateCaching diff contract

    @Test func updateCaching_firstCall_startsAllAssets() {
        let spy = PHCachingImageManagerSpy()
        let pipeline = CharacterListGalleryPipeline(cachingImageManager: spy)
        let assets = [StubPHAsset(id: "A"), StubPHAsset(id: "B")]

        pipeline.updateCaching(assets: assets, targetSize: CGSize(width: 100, height: 100), options: nil)

        #expect(spy.startCalls.count == 1)
        #expect(spy.startCalls[0].assets.map { $0.localIdentifier } == ["A", "B"])
        #expect(spy.stopCalls.isEmpty)
    }

    @Test func updateCaching_partialOverlap_startsAndStopsOnlyDiff() {
        let spy = PHCachingImageManagerSpy()
        let pipeline = CharacterListGalleryPipeline(cachingImageManager: spy)
        let size = CGSize(width: 100, height: 100)

        // First call: [A, B, C]
        pipeline.updateCaching(
            assets: [StubPHAsset(id: "A"), StubPHAsset(id: "B"), StubPHAsset(id: "C")],
            targetSize: size,
            options: nil
        )

        // Second call: [B, C, D] — A removed, D added
        pipeline.updateCaching(
            assets: [StubPHAsset(id: "B"), StubPHAsset(id: "C"), StubPHAsset(id: "D")],
            targetSize: size,
            options: nil
        )

        #expect(spy.stopCalls.count == 1)
        #expect(spy.stopCalls[0].assets.map { $0.localIdentifier } == ["A"])
        #expect(spy.startCalls.count == 2)
        #expect(spy.startCalls[1].assets.map { $0.localIdentifier } == ["D"])
    }

    @Test func updateCaching_forwardsTargetSizeContentModeAndOptions() {
        let spy = PHCachingImageManagerSpy()
        let pipeline = CharacterListGalleryPipeline(cachingImageManager: spy)
        let targetSize = CGSize(width: 200, height: 200)
        let options = PHImageRequestOptions()

        pipeline.updateCaching(assets: [StubPHAsset(id: "A")], targetSize: targetSize, options: options)

        let call = try! #require(spy.startCalls.first)
        #expect(call.targetSize == targetSize)
        #expect(call.contentMode == .aspectFill)
        #expect(call.options === options)
    }

    @Test func updateCaching_sameAssets_doesNotStartOrStop() {
        let spy = PHCachingImageManagerSpy()
        let pipeline = CharacterListGalleryPipeline(cachingImageManager: spy)
        let assets = [StubPHAsset(id: "A"), StubPHAsset(id: "B")]
        let size = CGSize(width: 100, height: 100)

        pipeline.updateCaching(assets: assets, targetSize: size, options: nil)
        spy.startCalls.removeAll()
        spy.stopCalls.removeAll()

        pipeline.updateCaching(assets: assets, targetSize: size, options: nil)

        #expect(spy.startCalls.isEmpty)
        #expect(spy.stopCalls.isEmpty)
    }
}

// MARK: - Test Doubles

private final class PHCachingImageManagerSpy: PHCachingImageManager, @unchecked Sendable {

    struct CachingCall {
        let assets: [PHAsset]
        let targetSize: CGSize
        let contentMode: PHImageContentMode
        let options: PHImageRequestOptions?
    }

    var startCalls: [CachingCall] = []
    var stopCalls: [CachingCall] = []

    override func startCachingImages(
        for assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) {
        startCalls.append(CachingCall(assets: assets, targetSize: targetSize, contentMode: contentMode, options: options))
    }

    override func stopCachingImages(
        for assets: [PHAsset],
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?
    ) {
        stopCalls.append(CachingCall(assets: assets, targetSize: targetSize, contentMode: contentMode, options: options))
    }
}

private final class StubPHAsset: PHAsset, @unchecked Sendable {
    private let _id: String
    init(id: String) { self._id = id }
    override var localIdentifier: String { _id }
}
