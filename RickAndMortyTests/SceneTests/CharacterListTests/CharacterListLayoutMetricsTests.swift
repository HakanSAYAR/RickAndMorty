//
//  CharacterListLayoutMetricsTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterListLayoutMetricsTests

struct CharacterListLayoutMetricsTests {

    // MARK: - columnCount

    @Test func columnCount_narrowWidth_returns2() {
        #expect(CharacterListLayoutMetrics.columnCount(for: 375) == CharacterListLayoutMetrics.narrowColumnCount)
    }

    @Test func columnCount_mediumWidth_returns3() {
        #expect(CharacterListLayoutMetrics.columnCount(for: 500) == CharacterListLayoutMetrics.mediumColumnCount)
    }

    @Test func columnCount_wideWidth_returns4() {
        #expect(CharacterListLayoutMetrics.columnCount(for: 768) == CharacterListLayoutMetrics.wideColumnCount)
    }

    @Test func columnCount_atBreakpointMedium_returnsMediumColumnCount() {
        #expect(CharacterListLayoutMetrics.columnCount(for: CharacterListLayoutMetrics.breakpointMedium) == CharacterListLayoutMetrics.mediumColumnCount)
    }

    @Test func columnCount_atBreakpointWide_returnsWideColumnCount() {
        #expect(CharacterListLayoutMetrics.columnCount(for: CharacterListLayoutMetrics.breakpointWide) == CharacterListLayoutMetrics.wideColumnCount)
    }

    @Test func columnCount_justBelowBreakpointMedium_returnsNarrowColumnCount() {
        #expect(CharacterListLayoutMetrics.columnCount(for: CharacterListLayoutMetrics.breakpointMedium - 1) == CharacterListLayoutMetrics.narrowColumnCount)
    }

    @Test func columnCount_justBelowBreakpointWide_returnsMediumColumnCount() {
        #expect(CharacterListLayoutMetrics.columnCount(for: CharacterListLayoutMetrics.breakpointWide - 1) == CharacterListLayoutMetrics.mediumColumnCount)
    }

    // MARK: - itemWidth

    @Test func itemWidth_greaterThanZero_forNarrowWidth() {
        #expect(CharacterListLayoutMetrics.itemWidth(for: 375) > 0)
    }

    @Test func itemWidth_narrowerContainer_producesLargerItems() {
        // Fewer columns → wider items per column (compare same-era widths)
        let narrow = CharacterListLayoutMetrics.itemWidth(for: 375) // 2 cols → 163.5
        let medium = CharacterListLayoutMetrics.itemWidth(for: 450) // 3 cols → ~128.7
        #expect(narrow > medium)
    }

    // MARK: - galleryThumbnailTargetSize

    @Test func galleryThumbnailTargetSize_isSquare() {
        let size = CharacterListLayoutMetrics.galleryThumbnailTargetSize(for: 375, screenScale: 2)
        #expect(size.width == size.height)
    }

    @Test func galleryThumbnailTargetSize_scaledByScreenScale() {
        let size1x = CharacterListLayoutMetrics.galleryThumbnailTargetSize(for: 375, screenScale: 1)
        let size2x = CharacterListLayoutMetrics.galleryThumbnailTargetSize(for: 375, screenScale: 2)
        #expect(size2x.width == size1x.width * 2)
    }

    @Test func galleryThumbnailTargetSize_greaterThanZero() {
        let size = CharacterListLayoutMetrics.galleryThumbnailTargetSize(for: 375, screenScale: 2)
        #expect(size.width > 0)
        #expect(size.height > 0)
    }

    // MARK: - characterTargetSize

    @Test func characterTargetSize_heightIsWidthTimesAspectRatio() {
        let size = CharacterListLayoutMetrics.characterTargetSize(for: 375)
        let expected = size.width * CharacterListLayoutMetrics.characterAspectRatio
        #expect(abs(size.height - expected) < 0.001)
    }

    // MARK: - fallbackTargetSize

    @Test func fallbackTargetSize_character_matchesCharacterTargetSize() {
        let fallback = CharacterListLayoutMetrics.fallbackTargetSize(for: .character, containerWidth: 375)
        let direct = CharacterListLayoutMetrics.characterTargetSize(for: 375)
        #expect(fallback == direct)
    }

    @Test func fallbackTargetSize_gallery_isSquare() {
        let fallback = CharacterListLayoutMetrics.fallbackTargetSize(for: .gallery, containerWidth: 375)
        #expect(fallback.width == fallback.height)
    }

    // MARK: - Constants

    @Test func constants_arePositive() {
        #expect(CharacterListLayoutMetrics.sectionSpacing > 0)
        #expect(CharacterListLayoutMetrics.sectionHorizontalInset > 0)
        #expect(CharacterListLayoutMetrics.itemInset > 0)
        #expect(CharacterListLayoutMetrics.characterAspectRatio > 0)
        #expect(CharacterListLayoutMetrics.headerHeight > 0)
        #expect(CharacterListLayoutMetrics.footerHeight > 0)
        #expect(CharacterListLayoutMetrics.breakpointMedium > 0)
        #expect(CharacterListLayoutMetrics.breakpointWide > CharacterListLayoutMetrics.breakpointMedium)
    }
}
