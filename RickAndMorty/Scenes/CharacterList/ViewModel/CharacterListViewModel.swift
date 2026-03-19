//
//  CharacterListViewModel.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation
import Combine

// MARK: - CharacterListViewModelProtocol

@MainActor
protocol CharacterListViewModelProtocol: AnyObject {
    var state: AnyPublisher<CharacterListState, Never> { get }
    var events: AnyPublisher<CharacterListEvent, Never> { get }
    var route: AnyPublisher<CharacterListRoute, Never> { get }

    func send(_ action: CharacterListAction)
}

// MARK: - CharacterListViewModel

@MainActor
final class CharacterListViewModel: CharacterListViewModelProtocol {

    // MARK: - CharacterListViewModelProtocol

    var state: AnyPublisher<CharacterListState, Never> { $_state.eraseToAnyPublisher() }
    var events: AnyPublisher<CharacterListEvent, Never> { _events.eraseToAnyPublisher() }
    var route: AnyPublisher<CharacterListRoute, Never> { _route.eraseToAnyPublisher() }

    // MARK: - Private Output

    @Published private var _state: CharacterListState = .loaded(.initial)
    private let _events = PassthroughSubject<CharacterListEvent, Never>()
    private let _route = PassthroughSubject<CharacterListRoute, Never>()

    // MARK: - Private Domain State

    private let fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol
    private let fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol
    private let galleryChangeObserver: any GalleryChangePublishing

    private var characters: [Character] = []
    private var internalGalleryState: InternalGalleryState = .hidden
    private var gallerySortOrder: GallerySortOrder = .newestFirst
    private var sortedGalleryItems: [GalleryPhoto] = []
    private var currentPage = 1
    private var totalPages = 1

    /// Tracks the initial-load and refresh task.
    private var loadTask: Task<Void, Never>?
    /// Tracks the in-flight pagination task.
    private var fetchTask: Task<Void, Never>?
    /// Blocks automatic retries after a pagination error until explicitly retried.
    private var paginationFailed = false

    private var galleryLoadTask: Task<Void, Never>?
    private var sortTask: Task<Void, Never>?
    private var galleryObserverCancellable: AnyCancellable?

    // MARK: - Init

    init(
        fetchCharactersUseCase: FetchCharactersPageUseCaseProtocol,
        fetchGalleryItemsUseCase: FetchGalleryPhotosUseCaseProtocol,
        galleryChangeObserver: any GalleryChangePublishing
    ) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.fetchGalleryItemsUseCase = fetchGalleryItemsUseCase
        self.galleryChangeObserver = galleryChangeObserver
        bindGalleryObserver()
    }

    // MARK: - Lifecycle

    deinit {
        loadTask?.cancel()
        fetchTask?.cancel()
        galleryLoadTask?.cancel()
        sortTask?.cancel()
        galleryObserverCancellable?.cancel()
    }

    // MARK: - Public Interface

    func send(_ action: CharacterListAction) {
        switch action {
        case .viewDidLoad:                              handleViewDidLoad()
        case .refresh:                                  handleRefresh()
        case .loadNextPage:                             handleLoadNextPage()
        case .retryLoad:                                handleRetryLoad()
        case .retryPagination:                          handleRetryPagination()
        case .reloadGallery:                            handleReloadGallery()
        case .sort:                                     handleSort()
        case .selectCharacter(let id):                  handleSelectCharacter(id: id)
        case .selectGalleryPhoto(let localIdentifier):  handleSelectGalleryPhoto(localIdentifier: localIdentifier)
        }
    }

    // MARK: - Private Handlers

    private func handleViewDidLoad() {
        loadTask?.cancel()
        _state = .loading
        loadTask = makeInitialLoadTask()
    }

    /// Called when the user taps "Try Again" on the full-screen error view.
    private func handleRetryLoad() {
        guard loadTask == nil else { return }
        fetchTask?.cancel()
        fetchTask = nil
        galleryLoadTask?.cancel()
        galleryLoadTask = nil
        paginationFailed = false
        characters = []
        internalGalleryState = .hidden
        currentPage = 1
        totalPages = 1
        _state = .loading
        loadTask = makeInitialLoadTask()
    }

    /// Pull-to-refresh: resets character state and re-fetches from page 1.
    /// Gallery is intentionally NOT reset — it stays current via the change observer.
    private func handleRefresh() {
        guard !isRefreshing else { return }
        loadTask?.cancel()
        loadTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        galleryLoadTask?.cancel()
        galleryLoadTask = nil
        paginationFailed = false
        characters = []
        currentPage = 1
        totalPages = 1
        _state = .loaded(CharacterListLoadedData(
            sections: buildSections(),
            pagination: .idle,
            gallerySortOrder: gallerySortOrder,
            isRefreshing: true
        ))
        loadTask = Task {
            await fetchCharacters(page: 1)
            guard !Task.isCancelled else { return }
            updateLoaded { $0.isRefreshing = false }
            loadTask = nil
        }
    }

    /// Called when the user scrolls near the end of the list.
    private func handleLoadNextPage() {
        guard loadTask == nil,
              fetchTask == nil,
              currentPage < totalPages,
              !paginationFailed else { return }
        updateLoaded { $0.pagination = .loading }
        fetchTask = Task {
            await fetchCharacters(page: currentPage + 1)
        }
    }

    /// Called when the user taps retry in the pagination footer.
    private func handleRetryPagination() {
        guard paginationFailed else { return }
        paginationFailed = false
        updateLoaded { $0.pagination = .idle }
        handleLoadNextPage()
    }

    /// Reloads only the gallery section. Skipped while initial load is in progress.
    private func handleReloadGallery() {
        guard loadTask == nil else { return }
        galleryLoadTask?.cancel()
        galleryLoadTask = Task {
            defer { galleryLoadTask = nil }
            await loadGallery()
        }
    }

    /// Toggles gallery sort order and re-sorts gallery items on a background thread.
    private func handleSort() {
        gallerySortOrder = gallerySortOrder == .newestFirst ? .oldestFirst : .newestFirst
        updateLoaded { $0.gallerySortOrder = gallerySortOrder }

        guard case .content(let items) = internalGalleryState else { return }
        let capturedOrder = gallerySortOrder

        sortTask?.cancel()
        sortTask = Task { [weak self] in
            guard let self else { return }
            // Detach CPU-bound sort to background thread pool.
            let sorted = await Task.detached(priority: .userInitiated) {
                items.sorted { lhs, rhs in
                    switch capturedOrder {
                    case .newestFirst:
                        return (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
                    case .oldestFirst:
                        return (lhs.creationDate ?? .distantFuture) < (rhs.creationDate ?? .distantFuture)
                    }
                }
            }.value
            guard !Task.isCancelled, self.gallerySortOrder == capturedOrder else { return }
            self.sortedGalleryItems = sorted
            self.updateLoaded { $0.sections = self.buildSections() }
            self.sortTask = nil
        }
    }

    private func handleSelectCharacter(id: Int) {
        guard let character = characters.first(where: { $0.id == id }) else { return }
        _route.send(.showCharacterDetail(character))
    }

    private func handleSelectGalleryPhoto(localIdentifier: String) {
        _route.send(.showPhotoDetail(localIdentifier: localIdentifier))
    }

    // MARK: - Private — Initial Load Task

    /// Shared task body for viewDidLoad and retryLoad.
    /// Caller is responsible for setting _state = .loading before calling.
    private func makeInitialLoadTask() -> Task<Void, Never> {
        Task { [weak self] in
            guard let self else { return }
            async let gallery: Void = loadGallery()
            async let chars: Void = fetchCharacters(page: 1, isInitialLoad: true)
            _ = await (gallery, chars)
            guard !Task.isCancelled else { return }
            // If fetchCharacters already set .error, keep it. Otherwise commit .loaded.
            if case .loading = _state {
                _state = .loaded(CharacterListLoadedData(
                    sections: buildSections(),
                    pagination: .idle,
                    gallerySortOrder: gallerySortOrder,
                    isRefreshing: false
                ))
            }
            loadTask = nil
        }
    }

    // MARK: - Private — Gallery Observer

    private func bindGalleryObserver() {
        galleryObserverCancellable = galleryChangeObserver.photoLibraryDidChange
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                Task { @MainActor [weak self] in
                    self?.send(.reloadGallery)
                }
            }
    }

    // MARK: - Private — Data Loading

    private func loadGallery() async {
        do {
            let items = try await fetchGalleryItemsUseCase.execute()
            guard !Task.isCancelled else { return }
            if items.isEmpty {
                internalGalleryState = .hidden
                sortedGalleryItems = []
            } else {
                internalGalleryState = .content(items)
                let capturedOrder = gallerySortOrder
                // Detach CPU-bound sort to background thread pool.
                let sorted = await Task.detached(priority: .userInitiated) {
                    items.sorted { lhs, rhs in
                        switch capturedOrder {
                        case .newestFirst:
                            return (lhs.creationDate ?? .distantPast) > (rhs.creationDate ?? .distantPast)
                        case .oldestFirst:
                            return (lhs.creationDate ?? .distantFuture) < (rhs.creationDate ?? .distantFuture)
                        }
                    }
                }.value
                guard !Task.isCancelled, gallerySortOrder == capturedOrder else { return }
                sortedGalleryItems = sorted
            }
        } catch is CancellationError {
            return
        } catch let error as GalleryError {
            switch error {
            case .accessDenied, .accessRestricted:
                internalGalleryState = .permissionDenied
                sortedGalleryItems = []
            }
        } catch {
            internalGalleryState = .hidden
            sortedGalleryItems = []
        }
        guard !Task.isCancelled else { return }
        // Update gallery section in current loaded state (only if already .loaded).
        updateLoaded { $0.sections = buildSections() }
    }

    /// - Parameter isInitialLoad: When true, failures set `.error` state instead of
    ///   triggering pagination error. Must be false for refresh and pagination calls.
    private func fetchCharacters(page: Int, isInitialLoad: Bool = false) async {
        defer { fetchTask = nil }

        do {
            let result = try await fetchCharactersUseCase.execute(page: page)
            guard !Task.isCancelled else { return }

            currentPage = page
            totalPages = result.info.totalPages

            let existingIDs = Set(characters.map(\.id))
            let fresh = result.results.filter { !existingIDs.contains($0.id) }
            characters.append(contentsOf: fresh)

            if !isInitialLoad {
                updateLoaded { data in
                    data.pagination = .idle
                    data.sections = buildSections()
                }
            }
            // For initial load, makeInitialLoadTask builds the final state.

        } catch is CancellationError {
            if !isInitialLoad { updateLoaded { $0.pagination = .idle } }
        } catch {
            if isInitialLoad {
                _state = .error(message: ErrorMapper.message(for: error))
            } else {
                paginationFailed = true
                updateLoaded { $0.pagination = .error }
                _events.send(.showError(ErrorMapper.message(for: error)))
            }
        }
    }

    // MARK: - Private — Section Building

    private func buildSections() -> [CharacterListSectionModel] {
        var sections: [CharacterListSectionModel] = []

        switch internalGalleryState {
        case .content:
            sections.append(CharacterListSectionModel(
                section: .gallery,
                items: sortedGalleryItems.map { .photo(CharacterListViewDataMapper.map($0)) }
            ))
        case .permissionDenied:
            sections.append(CharacterListSectionModel(
                section: .gallery,
                items: [.permissionDenied]
            ))
        case .hidden:
            break
        }

        if !characters.isEmpty {
            sections.append(CharacterListSectionModel(
                section: .characters,
                items: characters.map { .character(CharacterListViewDataMapper.map($0)) }
            ))
        }

        return sections
    }

    // MARK: - Private — State Helpers

    private var isRefreshing: Bool {
        if case .loaded(let data) = _state { return data.isRefreshing }
        return false
    }

    /// Applies a mutation to `CharacterListLoadedData` when state is `.loaded`.
    /// No-op if current state is `.loading` or `.error`.
    private func updateLoaded(_ transform: (inout CharacterListLoadedData) -> Void) {
        guard case .loaded(var data) = _state else { return }
        transform(&data)
        _state = .loaded(data)
    }
}

// MARK: - InternalGalleryState

private enum InternalGalleryState {
    case hidden
    case content([GalleryPhoto])
    case permissionDenied
}
