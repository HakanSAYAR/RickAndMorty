//
//  PHImageRequestOptionsFactoryTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Photos
@testable import RickAndMorty

// MARK: - PHImageRequestOptionsFactoryTests

struct PHImageRequestOptionsFactoryTests {

    private let factory = PHImageRequestOptionsFactory()

    // MARK: - Visible Options

    @Test func makeVisibleOptions_deliveryMode_isOpportunistic() {
        #expect(factory.makeVisibleOptions().deliveryMode == .opportunistic)
    }

    @Test func makeVisibleOptions_resizeMode_isFast() {
        #expect(factory.makeVisibleOptions().resizeMode == .fast)
    }

    @Test func makeVisibleOptions_networkAccess_isTrue() {
        #expect(factory.makeVisibleOptions().isNetworkAccessAllowed == true)
    }

    // MARK: - Caching Options

    @Test func makeCachingOptions_deliveryMode_isFastFormat() {
        #expect(factory.makeCachingOptions().deliveryMode == .fastFormat)
    }

    @Test func makeCachingOptions_resizeMode_isFast() {
        #expect(factory.makeCachingOptions().resizeMode == .fast)
    }

    @Test func makeCachingOptions_networkAccess_isFalse() {
        #expect(factory.makeCachingOptions().isNetworkAccessAllowed == false)
    }

    // MARK: - Intent Separation

    /// Visible and caching options must have different delivery modes —
    /// this is the core contract that separates user-facing quality from background speed.
    @Test func visibleAndCaching_deliveryModes_areDifferent() {
        #expect(factory.makeVisibleOptions().deliveryMode != factory.makeCachingOptions().deliveryMode)
    }
}
