//
//  CharacterListLayoutMetrics.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit

// MARK: - CharacterListLayoutMetrics

nonisolated enum CharacterListLayoutMetrics {

    // MARK: - Constants

    static let sectionSpacing: CGFloat = 8
    static let sectionHorizontalInset: CGFloat = 12
    static let itemInset: CGFloat = 4
    static let characterAspectRatio: CGFloat = 1.4
    static let headerHeight: CGFloat = 44
    static let footerHeight: CGFloat = 48
    static let characterSectionBottomInset: CGFloat = 16
    static let gallerySectionBottomInset: CGFloat = 16

    // MARK: - Column Breakpoints

    static let breakpointMedium: CGFloat = 400
    static let breakpointWide: CGFloat = 600

    static let narrowColumnCount: Int = 2
    static let mediumColumnCount: Int = 3
    static let wideColumnCount: Int = 4

    // MARK: - Cell Size Kind

    enum CellSizeKind {
        case character
        case gallery
    }

    // MARK: - Dynamic Sizing

    static func columnCount(for width: CGFloat) -> Int {
        switch width {
        case ..<breakpointMedium:                   return narrowColumnCount
        case breakpointMedium..<breakpointWide:     return mediumColumnCount
        default:                                    return wideColumnCount
        }
    }

    static func itemWidth(for containerWidth: CGFloat) -> CGFloat {
        let columns = CGFloat(columnCount(for: containerWidth))
        let totalInsets = sectionHorizontalInset * 2
            + itemInset * 2 * columns
            + sectionSpacing * (columns - 1)
        return max((containerWidth - totalInsets) / columns, 1)
    }

    /// Pixel-accurate thumbnail size for PHCachingImageManager and GalleryCell.
    /// Must be called with consistent `containerWidth` and `screenScale` across
    /// all caching call sites to guarantee matching cache keys.
    static func galleryThumbnailTargetSize(for containerWidth: CGFloat, screenScale: CGFloat) -> CGSize {
        let w = itemWidth(for: containerWidth) * screenScale
        return CGSize(width: max(w, 1), height: max(w, 1))
    }

    /// Point-based target size for character cells and Kingfisher downsampling.
    static func characterTargetSize(for containerWidth: CGFloat) -> CGSize {
        let w = itemWidth(for: containerWidth)
        return CGSize(width: w, height: w * characterAspectRatio)
    }

    /// Formula-based fallback when layout attributes are unavailable (off-screen prefetch).
    static func fallbackTargetSize(for kind: CellSizeKind, containerWidth: CGFloat) -> CGSize {
        let w = itemWidth(for: containerWidth)
        switch kind {
        case .character: return CGSize(width: w, height: w * characterAspectRatio)
        case .gallery:   return CGSize(width: w, height: w)
        }
    }

    // MARK: - Section Builders

    @MainActor
    static func makeGallerySection(environment: NSCollectionLayoutEnvironment?) -> NSCollectionLayoutSection {
        let availableWidth = environment?.container.effectiveContentSize.width ?? UIScreen.main.bounds.width
        let count = columnCount(for: availableWidth)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / CGFloat(count))
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: itemInset, leading: itemInset, bottom: 0, trailing: itemInset)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: count
        )
        group.interItemSpacing = .fixed(sectionSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = sectionSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: sectionSpacing, leading: sectionHorizontalInset, bottom: gallerySectionBottomInset, trailing: sectionHorizontalInset
        )
        section.boundarySupplementaryItems = [makeHeader()]
        return section
    }

    @MainActor
    static func makeCharactersSection(environment: NSCollectionLayoutEnvironment?) -> NSCollectionLayoutSection {
        let availableWidth = environment?.container.effectiveContentSize.width ?? UIScreen.main.bounds.width
        let count = columnCount(for: availableWidth)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1.0 / CGFloat(count) * characterAspectRatio)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: itemInset, leading: itemInset, bottom: itemInset, trailing: itemInset)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: count
        )
        group.interItemSpacing = .fixed(sectionSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = sectionSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: sectionSpacing, leading: sectionHorizontalInset,
            bottom: characterSectionBottomInset, trailing: sectionHorizontalInset
        )
        section.boundarySupplementaryItems = [makeHeader(), makeFooter()]
        return section
    }

    // MARK: - Supplementary Items

    @MainActor
    private static func makeHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(headerHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    @MainActor
    private static func makeFooter() -> NSCollectionLayoutBoundarySupplementaryItem {
        let size = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(footerHeight)
        )
        return NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
    }
}
