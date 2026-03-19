//
//  CharacterListDataSource.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Photos

// MARK: - CharacterListDataSource

/// Wraps UICollectionViewDiffableDataSource and owns all cell/supplementary configure logic.
/// `paginationState` is presentation config only — ViewModel drives truth.
final class CharacterListDataSource {

    // MARK: - Presentation Config

    /// Footer rendering state. Set by ViewController from ViewModel state.
    /// Must not duplicate or drive ViewModel logic.
    var paginationState: PaginationState = .idle

    /// Called when the user taps the pagination retry button in the footer.
    var onPaginationRetry: (() -> Void)?

    // MARK: - Private

    private let diffableDataSource: UICollectionViewDiffableDataSource<CharacterListSection, CharacterListSectionItem>

    // MARK: - Init

    init(
        collectionView: UICollectionView,
        imagePipeline: any CharacterListImagePipelineProtocol,
        cachingImageManager: PHCachingImageManager,
        assetCache: PHAssetCacheProtocol,
        optionsFactory: any PHImageRequestOptionsFactoryProtocol,
        targetSizeProvider: @escaping (IndexPath, CharacterListLayoutMetrics.CellSizeKind) -> CGSize
    ) {
        diffableDataSource = UICollectionViewDiffableDataSource(
            collectionView: collectionView
        ) { [imagePipeline, cachingImageManager, assetCache, optionsFactory, targetSizeProvider]
            collectionView, indexPath, item in
            switch item {
            case .character(let viewData):
                let cell: CharacterCell = collectionView.dequeueCell(for: indexPath)
                cell.configure(
                    with: viewData,
                    targetSize: targetSizeProvider(indexPath, .character),
                    pipeline: imagePipeline
                )
                return cell

            case .photo(let galleryItem):
                let cell: GalleryCell = collectionView.dequeueCell(for: indexPath)
                let asset = assetCache.asset(for: galleryItem.localIdentifier)
                cell.configure(
                    with: galleryItem,
                    asset: asset,
                    targetSize: targetSizeProvider(indexPath, .gallery),
                    imageManager: cachingImageManager,
                    optionsFactory: optionsFactory
                )
                return cell

            case .permissionDenied:
                return collectionView.dequeueCell(PermissionDeniedCell.self, for: indexPath)
            }
        }

        diffableDataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            switch kind {
            case UICollectionView.elementKindSectionHeader:
                let header: CharacterListSectionHeaderView = collectionView.dequeueSupplementary(
                    ofKind: UICollectionView.elementKindSectionHeader,
                    for: indexPath
                )
                let section = self?.diffableDataSource.snapshot().sectionIdentifiers[safe: indexPath.section]
                header.configure(title: section?.title ?? "")
                return header

            case UICollectionView.elementKindSectionFooter:
                let footer: CharacterListLoadingFooterView = collectionView.dequeueSupplementary(
                    ofKind: UICollectionView.elementKindSectionFooter,
                    for: indexPath
                )
                footer.configure(state: self?.paginationState ?? .idle)
                footer.onRetry = self?.onPaginationRetry
                return footer

            default:
                return nil
            }
        }
    }

    // MARK: - Public API

    func apply(
        _ snapshot: NSDiffableDataSourceSnapshot<CharacterListSection, CharacterListSectionItem>,
        animated: Bool
    ) {
        diffableDataSource.apply(snapshot, animatingDifferences: animated)
    }

    func item(at indexPath: IndexPath) -> CharacterListSectionItem? {
        diffableDataSource.itemIdentifier(for: indexPath)
    }

    func currentSnapshot() -> NSDiffableDataSourceSnapshot<CharacterListSection, CharacterListSectionItem> {
        diffableDataSource.snapshot()
    }

    /// Reconfigures the footer without a full snapshot apply.
    func reloadFooter(in collectionView: UICollectionView) {
        let sections = diffableDataSource.snapshot().sectionIdentifiers
        guard let lastSection = sections.last,
              let sectionIndex = sections.firstIndex(of: lastSection) else { return }
        let indexPath = IndexPath(item: 0, section: sectionIndex)
        guard let footer = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: indexPath
        ) as? CharacterListLoadingFooterView else { return }
        footer.configure(state: paginationState)
    }

    /// Returns PHAssets for all `.photo` items whose layout frame intersects `rect`.
    func photoAssets(
        in rect: CGRect,
        collectionView: UICollectionView,
        assetProvider: (String) -> PHAsset?
    ) -> [PHAsset] {
        guard let attributes = collectionView.collectionViewLayout.layoutAttributesForElements(in: rect) else {
            return []
        }
        return attributes.compactMap { attr -> PHAsset? in
            guard case .photo(let viewData) = diffableDataSource.itemIdentifier(for: attr.indexPath) else {
                return nil
            }
            return assetProvider(viewData.localIdentifier)
        }
    }
}
