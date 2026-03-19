//
//  CharacterListViewController.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Combine
import Photos

// MARK: - CharacterListViewController

final class CharacterListViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: any CharacterListViewModelProtocol
    private let assetCache: PHAssetCacheProtocol
    private let galleryPipeline: any CharacterListGalleryPipelineProtocol
    private let imagePipeline: any CharacterListImagePipelineProtocol
    private let optionsFactory: any PHImageRequestOptionsFactoryProtocol
    private var cancellables = Set<AnyCancellable>()

    private var listDataSource: CharacterListDataSource!
    private var prefetchHandler: CharacterListPrefetchHandler!
    private var currentLoadedData: CharacterListLoadedData?
    private var hasAppliedInitialSnapshot = false
    private var previousSortOrder: GallerySortOrder?
    private var pendingSnapshotWork: DispatchWorkItem?
    private var previousPreheatRect: CGRect = .zero

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: view.bounds, collectionViewLayout: makeLayout())
        cv.backgroundColor = .systemBackground
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
        return cv
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return rc
    }()

    private lazy var errorStateView: ErrorStateView = {
        let view = ErrorStateView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.accessibilityIdentifier = "character_list_load_error_retry_button"
        view.onRetry = { [weak self] in self?.viewModel.send(.retryLoad) }
        return view
    }()

    private lazy var sortBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: Images.sortNewest,
            style: .plain,
            target: self,
            action: #selector(handleSortTapped)
        )
        button.accessibilityIdentifier = "character_list_sort_button"
        return button
    }()

    // MARK: - Init

    init(
        viewModel: any CharacterListViewModelProtocol,
        assetCache: PHAssetCacheProtocol,
        galleryPipeline: any CharacterListGalleryPipelineProtocol,
        imagePipeline: any CharacterListImagePipelineProtocol,
        optionsFactory: any PHImageRequestOptionsFactoryProtocol = PHImageRequestOptionsFactory()
    ) {
        self.viewModel = viewModel
        self.assetCache = assetCache
        self.galleryPipeline = galleryPipeline
        self.imagePipeline = imagePipeline
        self.optionsFactory = optionsFactory
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        bindViewModel()
        viewModel.send(.viewDidLoad)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        galleryPipeline.invalidateCaching()
        prefetchHandler.cancelAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        galleryPipeline.invalidateCaching()
        prefetchHandler.cancelAll()
    }

    // MARK: - UI Setup

    private func setupUI() {
        setupView()
        setupNavigationBar()
        setupCollectionView()
        setupActivityIndicator()
        setupErrorStateView()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
    }
    
    private func setupNavigationBar() {
        title = L10n.CharacterList.title
    }
    
    private func setupCollectionView() {
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        collectionView.register(CharacterCell.self, forCellWithReuseIdentifier: CharacterCell.reuseIdentifier)
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseIdentifier)
        collectionView.register(PermissionDeniedCell.self, forCellWithReuseIdentifier: PermissionDeniedCell.reuseIdentifier)
        collectionView.register(
            CharacterListSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CharacterListSectionHeaderView.reuseIdentifier
        )
        collectionView.register(
            CharacterListLoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: CharacterListLoadingFooterView.reuseIdentifier
        )
        collectionView.refreshControl = refreshControl
    }

    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupErrorStateView() {
        view.addSubview(errorStateView)
        NSLayoutConstraint.activate([
            errorStateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Data Source

    private func configureDataSource() {
        listDataSource = CharacterListDataSource(
            collectionView: collectionView,
            imagePipeline: imagePipeline,
            cachingImageManager: galleryPipeline.cachingImageManager,
            assetCache: assetCache,
            optionsFactory: optionsFactory,
            targetSizeProvider: { [weak self] indexPath, kind in
                self?.targetSize(for: indexPath, kind: kind) ?? .zero
            }
        )
        listDataSource.onPaginationRetry = { [weak self] in
            self?.viewModel.send(.retryPagination)
        }

        prefetchHandler = CharacterListPrefetchHandler(imagePipeline: imagePipeline)
        prefetchHandler.itemForIndexPath = { [weak self] indexPath in
            self?.listDataSource.item(at: indexPath)
        }
        prefetchHandler.targetSize = { [weak self] in
            guard let self else { return .zero }
            return CharacterListLayoutMetrics.fallbackTargetSize(
                for: .character,
                containerWidth: collectionView.bounds.width
            )
        }
        collectionView.prefetchDataSource = prefetchHandler
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.state
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] event in
                switch event {
                case .showError(let message):
                    self?.showError(message: message)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Render

    private func render(_ state: CharacterListState) {
        switch state {
        case .loading:
            currentLoadedData = nil
            activityIndicator.startAnimating()
            errorStateView.isHidden = true
            applySnapshot(sections: [], animated: false)

        case .loaded(let data):
            currentLoadedData = data
            activityIndicator.stopAnimating()
            errorStateView.isHidden = true
            if !data.isRefreshing && refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
            let isSortChange = hasAppliedInitialSnapshot
                && previousSortOrder != nil
                && data.gallerySortOrder != previousSortOrder
            previousSortOrder = data.gallerySortOrder
            listDataSource.paginationState = data.pagination
            if isSortChange {
                let galleryItems = data.sections.first { $0.section == .gallery }?.items ?? []
                replaceGallerySectionItems(with: galleryItems)
            } else {
                scheduleSnapshot(sections: data.sections, animated: false)
            }
            listDataSource.reloadFooter(in: collectionView)
            renderSortButton(data: data)

        case .error(let message):
            currentLoadedData = nil
            activityIndicator.stopAnimating()
            if refreshControl.isRefreshing { refreshControl.endRefreshing() }
            errorStateView.configure(message: message, retryTitle: L10n.CharacterList.loadErrorRetryButton)
            errorStateView.isHidden = false
        }
    }

    private func renderSortButton(data: CharacterListLoadedData) {
        guard data.shouldShowSortButton else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        switch data.gallerySortOrder {
        case .newestFirst:
            sortBarButton.image = Images.sortNewest
            sortBarButton.accessibilityLabel = L10n.CharacterList.sortNewestFirst
        case .oldestFirst:
            sortBarButton.image = Images.sortOldest
            sortBarButton.accessibilityLabel = L10n.CharacterList.sortOldestFirst
        }

        navigationItem.rightBarButtonItem = sortBarButton
    }

    // MARK: - Snapshot

    /// Applies the first snapshot immediately (leading edge) to avoid delaying initial paint.
    /// Subsequent rapid updates are debounced so only the last snapshot within
    /// `SnapshotDebounce.thresholdMs` is applied — coalescing pagination + gallery updates.
    /// Immediate UI updates (indicators, footer, sort button) are NOT debounced.
    private func scheduleSnapshot(sections: [CharacterListSectionModel], animated: Bool) {
        guard hasAppliedInitialSnapshot else {
            applySnapshot(sections: sections, animated: false)
            return
        }
        pendingSnapshotWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applySnapshot(sections: sections, animated: animated)
        }
        pendingSnapshotWork = work
        DispatchQueue.main.asyncAfter(
            deadline: .now() + .milliseconds(SnapshotDebounce.thresholdMs),
            execute: work
        )
    }

    /// Replaces only the gallery section's items in the current snapshot.
    /// Used for sort changes — character section is never touched.
    /// No animation, no debounce: sort is a deliberate user action.
    private func replaceGallerySectionItems(with items: [CharacterListSectionItem]) {
        var snapshot = listDataSource.currentSnapshot()
        guard snapshot.sectionIdentifiers.contains(.gallery) else {
            assertionFailure("replaceGallerySectionItems called without .gallery section in snapshot")
            return
        }
        snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .gallery))
        snapshot.appendItems(items, toSection: .gallery)
        listDataSource.apply(snapshot, animated: false)
    }

    private func applySnapshot(sections: [CharacterListSectionModel], animated: Bool) {
        PerformanceSignpost.begin(PerformanceSignpost.Name.snapshotApply)
        defer { PerformanceSignpost.end(PerformanceSignpost.Name.snapshotApply) }

        let snapshot = CharacterListSnapshotFactory.makeSnapshot(from: sections)
        listDataSource.apply(snapshot, animated: animated)
        if !sections.isEmpty {
            hasAppliedInitialSnapshot = true
        }
    }

    // MARK: - Preheat

    private func updatePreheatIfNeeded() {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -visibleRect.height / 2)
        guard CharacterListGalleryPipeline.shouldUpdatePreheatRect(
            previous: previousPreheatRect,
            current: preheatRect
        ) else { return }
        previousPreheatRect = preheatRect

        let assets = listDataSource.photoAssets(
            in: preheatRect,
            collectionView: collectionView,
            assetProvider: assetCache.asset(for:)
        )
        let targetSize = CharacterListLayoutMetrics.galleryThumbnailTargetSize(
            for: collectionView.bounds.width,
            screenScale: UIScreen.main.scale
        )
        galleryPipeline.updateCaching(
            assets: assets,
            targetSize: targetSize,
            options: optionsFactory.makeCachingOptions()
        )
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.send(.refresh)
    }

    @objc private func handleSortTapped() {
        viewModel.send(.sort)
    }

    // MARK: - Helpers

    private func showError(message: String) {
        showAlert(
            title: L10n.CharacterList.errorAlertTitle,
            message: message,
            buttonTitle: L10n.CharacterList.errorAlertButton
        )
    }
}

// MARK: - UICollectionViewDelegate

extension CharacterListViewController: UICollectionViewDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        // Pagination trigger only — gallery caching is handled by scroll-based preheat.
        let snapshot = listDataSource.currentSnapshot()
        guard let section = snapshot.sectionIdentifiers[safe: indexPath.section] else { return }
        let isLastSection = section == snapshot.sectionIdentifiers.last
        let itemCount = snapshot.numberOfItems(inSection: section)
        let thresholdIndex = max(0, itemCount - Self.paginationThreshold)
        let isNearEnd = indexPath.item >= thresholdIndex
        guard isLastSection && isNearEnd else { return }
        viewModel.send(.loadNextPage)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let item = listDataSource.item(at: indexPath) else { return }
        switch item {
        case .character(let viewData):
            viewModel.send(.selectCharacter(id: viewData.id))
        case .photo(let galleryItem):
            viewModel.send(.selectGalleryPhoto(localIdentifier: galleryItem.localIdentifier))
        case .permissionDenied:
            break
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updatePreheatIfNeeded()
    }
}

// MARK: - Layout

private extension CharacterListViewController {

    enum SnapshotDebounce {
        /// Starting threshold for coalescing rapid consecutive state updates.
        /// Increase if UI feels unresponsive; decrease if churn persists.
        /// Validate with Instruments before changing.
        static let thresholdMs: Int = 50
    }

    static let paginationThreshold = 4

    func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self,
                  let section = listDataSource?.currentSnapshot().sectionIdentifiers[safe: sectionIndex]
            else {
                return CharacterListLayoutMetrics.makeCharactersSection(environment: environment)
            }
            switch section {
            case .gallery:    return CharacterListLayoutMetrics.makeGallerySection(environment: environment)
            case .characters: return CharacterListLayoutMetrics.makeCharactersSection(environment: environment)
            }
        }
    }

    /// Returns the display size for the cell at `indexPath`.
    ///
    /// Primary: `layoutAttributesForItem` returns the real frame after layout pass.
    /// Fallback: formula-based size from `CharacterListLayoutMetrics`.
    func targetSize(for indexPath: IndexPath, kind: CharacterListLayoutMetrics.CellSizeKind) -> CGSize {
        if let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame {
            let w = frame.width
            switch kind {
            case .character: return CGSize(width: w, height: w * CharacterListLayoutMetrics.characterAspectRatio)
            case .gallery:   return CGSize(width: w, height: w)
            }
        }
        return CharacterListLayoutMetrics.fallbackTargetSize(for: kind, containerWidth: collectionView.bounds.width)
    }
}
