//
//  CharacterListViewModelTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Combine
import Foundation
@testable import RickAndMorty

// MARK: - CharacterListViewModelTests

@MainActor
struct CharacterListViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        fetchResults: [Result<CharacterPage, Error>] = [],
        fetchDefault: Result<CharacterPage, Error> = .success(CharacterPage.stub()),
        galleryResult: Result<[GalleryPhoto], Error> = .success([])
    ) -> (sut: CharacterListViewModel, fetchUseCase: MockFetchCharactersUseCase, galleryUseCase: MockFetchGalleryItemsUseCase) {
        let fetchUseCase = MockFetchCharactersUseCase()
        fetchUseCase.resultsQueue = fetchResults
        fetchUseCase.defaultResult = fetchDefault
        let galleryUseCase = MockFetchGalleryItemsUseCase()
        galleryUseCase.result = galleryResult
        let sut = CharacterListViewModel(
            fetchCharactersUseCase: fetchUseCase,
            fetchGalleryItemsUseCase: galleryUseCase,
            galleryChangeObserver: StubGalleryChangePublisher()
        )
        return (sut, fetchUseCase, galleryUseCase)
    }

    /// Yields control to let @MainActor Tasks created by the VM run to completion.
    private func drain() async {
        for _ in 0..<5 { await Task.yield() }
    }

    private func latestLoadedData(from sut: CharacterListViewModel) -> CharacterListLoadedData? {
        var result: CharacterListLoadedData?
        let cancellable = sut.state.sink { if case .loaded(let d) = $0 { result = d } }
        cancellable.cancel()
        return result
    }

    private func latestCharacterIDs(from sut: CharacterListViewModel) -> [Int] {
        latestLoadedData(from: sut)?
            .sections.first { $0.section == .characters }?
            .items.compactMap { if case .character(let v) = $0 { v.id } else { nil } }
            ?? []
    }

    private func latestGalleryIdentifiers(from sut: CharacterListViewModel) -> [String] {
        latestLoadedData(from: sut)?
            .sections.first { $0.section == .gallery }?
            .items.compactMap { if case .photo(let v) = $0 { v.localIdentifier } else { nil } }
            ?? []
    }

    // MARK: - Initial State

    @Test func initialState_isIdle() {
        let (sut, _, _) = makeSUT()
        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        guard case .loaded(let data) = states.first else {
            Issue.record("Expected .loaded initial state")
            return
        }
        #expect(!data.isRefreshing)
        #expect(data.sections.isEmpty)
        #expect(data.pagination == .idle)
    }

    // MARK: - viewDidLoad

    @Test func viewDidLoad_immediatelySetsLoadingState() {
        let (sut, _, _) = makeSUT()
        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.viewDidLoad)

        #expect(states.contains { if case .loading = $0 { true } else { false } })
    }

    @Test func viewDidLoad_success_populatesCharactersSection() async {
        let character = Character.stub(id: 1)
        let (sut, _, _) = makeSUT(
            fetchDefault: .success(CharacterPage.stub(characters: [character]))
        )
        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.viewDidLoad)
        await drain()

        guard case .loaded(let data) = states.last else {
            Issue.record("Expected .loaded final state")
            return
        }
        #expect(!data.isRefreshing)
        #expect(data.sections.contains { $0.section == .characters })
        let characterItems = data.sections.first { $0.section == .characters }?.items ?? []
        #expect(characterItems.count == 1)
    }

    @Test func viewDidLoad_apiFailure_setsErrorState_notEvent() async {
        // Initial load errors surface via .error state.
        // Alert-based events are reserved for pagination failures.
        let (sut, _, _) = makeSUT(fetchDefault: .failure(MockError.generic))
        var events: [CharacterListEvent] = []
        let eventCancellable = sut.events.sink { events.append($0) }
        defer { eventCancellable.cancel() }

        var states: [CharacterListState] = []
        let stateCancellable = sut.state.sink { states.append($0) }
        defer { stateCancellable.cancel() }

        sut.send(.viewDidLoad)
        await drain()

        #expect(states.last.map { if case .error = $0 { true } else { false } } == true)
        #expect(events.isEmpty)
    }

    // MARK: - Gallery

    @Test func gallery_success_showsGallerySection() async {
        let items = [GalleryPhoto.stub(localIdentifier: "id-1")]
        let (sut, _, _) = makeSUT(galleryResult: .success(items))
        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.viewDidLoad)
        await drain()

        let loadedStates = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let data) = state { return data }
            return nil
        }
        let gallerySections = loadedStates.compactMap { $0.sections.first { $0.section == .gallery } }
        #expect(!gallerySections.isEmpty)
        let galleryItems = gallerySections.last?.items ?? []
        #expect(galleryItems.contains { if case .photo = $0 { true } else { false } })
    }

    @Test func gallery_permissionDenied_showsPermissionDeniedItem() async {
        let (sut, _, _) = makeSUT(galleryResult: .failure(GalleryError.accessDenied))
        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.viewDidLoad)
        await drain()

        let loadedData = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let d) = state { return d } else { return nil }
        }.last
        let galleryItems = loadedData?.sections.first { $0.section == .gallery }?.items ?? []
        #expect(galleryItems.contains { $0 == .permissionDenied })
    }

    // MARK: - Pagination

    @Test func loadNextPage_fetchesWhenMorePagesExist() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let page2 = CharacterPage.stub(pages: 2, characters: [.stub(id: 2)])
        let (sut, fetchUseCase, _) = makeSUT(
            fetchResults: [.success(page1), .success(page2)]
        )

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = fetchUseCase.executeCallCount
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterLoad + 1)
    }

    @Test func loadNextPage_failure_setsPaginationErrorState() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, _, _) = makeSUT(
            fetchResults: [.success(page1)],
            fetchDefault: .failure(MockError.generic)
        )

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.loadNextPage)
        await drain()

        let pagination = states.compactMap { state -> PaginationState? in
            if case .loaded(let d) = state { return d.pagination } else { return nil }
        }.last
        #expect(pagination == .error)
    }

    @Test func loadNextPage_doesNotFetchWhenOnLastPage() async {
        let singlePage = CharacterPage.stub(pages: 1, characters: [.stub()])
        let (sut, fetchUseCase, _) = makeSUT(fetchDefault: .success(singlePage))

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = fetchUseCase.executeCallCount
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterLoad)
    }

    // MARK: - Retry

    @Test func retryPagination_whenNotFailed_isNoOp() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, fetchUseCase, _) = makeSUT(fetchDefault: .success(page1))

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = fetchUseCase.executeCallCount
        sut.send(.retryPagination)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterLoad)
    }

    @Test func retryPagination_afterFailure_triggersNewFetch() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let page2 = CharacterPage.stub(pages: 2, characters: [.stub(id: 2)])
        let (sut, fetchUseCase, _) = makeSUT(
            fetchResults: [.success(page1), .failure(MockError.generic), .success(page2)]
        )

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.loadNextPage)
        await drain()

        let callsBeforeRetry = fetchUseCase.executeCallCount
        sut.send(.retryPagination)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsBeforeRetry + 1)
    }

    // MARK: - Refresh

    @Test func refresh_setsRefreshingState() async {
        let (sut, _, _) = makeSUT()
        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.refresh)

        let isRefreshing = states.compactMap { state -> Bool? in
            if case .loaded(let d) = state { return d.isRefreshing } else { return nil }
        }.contains(true)
        #expect(isRefreshing)
    }

    @Test func refresh_resetsCharactersBeforeReloading() async {
        let char1 = Character.stub(id: 1)
        let char2 = Character.stub(id: 2)
        let (sut, _, _) = makeSUT(
            fetchResults: [.success(CharacterPage.stub(characters: [char1]))],
            fetchDefault: .success(CharacterPage.stub(characters: [char2]))
        )

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.refresh)
        await drain()

        var latestData: CharacterListLoadedData?
        let cancellable = sut.state.sink { state in
            if case .loaded(let d) = state { latestData = d }
        }
        defer { cancellable.cancel() }

        await drain()
        let characters = latestData?.sections.first { $0.section == .characters }?.items ?? []
        #expect(characters.count == 1)
        if case .character(let viewData) = characters.first {
            #expect(viewData.id == char2.id)
        }
    }

    // MARK: - Gallery Sort

    @Test func sort_afterLoad_reversesGalleryItemOrder() async {
        let old = Date(timeIntervalSince1970: 1000)
        let mid = Date(timeIntervalSince1970: 2000)
        let new = Date(timeIntervalSince1970: 3000)
        let items = [
            GalleryPhoto.stub(localIdentifier: "new", creationDate: new),
            GalleryPhoto.stub(localIdentifier: "mid", creationDate: mid),
            GalleryPhoto.stub(localIdentifier: "old", creationDate: old)
        ]
        let (sut, _, _) = makeSUT(galleryResult: .success(items))

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.sort)
        await drain()

        let loadedData = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let d) = state { return d } else { return nil }
        }.last
        let galleryItems = loadedData?.sections.first { $0.section == .gallery }?.items ?? []
        let identifiers = galleryItems.compactMap { item -> String? in
            if case .photo(let g) = item { return g.localIdentifier }
            return nil
        }
        #expect(identifiers == ["old", "mid", "new"])
        #expect(loadedData?.gallerySortOrder == .oldestFirst)
    }

    @Test func refresh_afterSort_preservesSortOrder() async {
        let items = [GalleryPhoto.stub(localIdentifier: "id-1")]
        let (sut, _, _) = makeSUT(galleryResult: .success(items))

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.sort)

        sut.send(.refresh)
        await drain()

        var latestData: CharacterListLoadedData?
        let cancellable = sut.state.sink { state in
            if case .loaded(let d) = state { latestData = d }
        }
        defer { cancellable.cancel() }

        await drain()
        #expect(latestData?.gallerySortOrder == .oldestFirst)
    }

    @Test func sort_withoutGalleryContent_keepsStateConsistent() async {
        let (sut, _, _) = makeSUT(galleryResult: .failure(GalleryError.accessDenied))

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.sort)

        let loadedData = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let d) = state { return d } else { return nil }
        }.last
        #expect(loadedData?.gallerySortOrder == .oldestFirst)
        let hasPhotoContent = loadedData?.sections.contains { section in
            section.items.contains { if case .photo = $0 { true } else { false } }
        }
        #expect(hasPhotoContent == false)
    }

    @Test func sort_doesNotAffectCharacterSection() async {
        let characters = [Character.stub(id: 1), Character.stub(id: 2), Character.stub(id: 3)]
        let galleryItems = [GalleryPhoto.stub(localIdentifier: "photo-1")]
        let (sut, _, _) = makeSUT(
            fetchDefault: .success(CharacterPage.stub(characters: characters)),
            galleryResult: .success(galleryItems)
        )

        sut.send(.viewDidLoad)
        await drain()

        let idsBefore = latestCharacterIDs(from: sut)

        sut.send(.sort)
        await drain()

        let idsAfter = latestCharacterIDs(from: sut)
        #expect(idsBefore == idsAfter)
    }

    @Test func sort_repeatedTap_returnsToOriginalOrder() async {
        let old = Date(timeIntervalSince1970: 1000)
        let mid = Date(timeIntervalSince1970: 2000)
        let new = Date(timeIntervalSince1970: 3000)
        let items = [
            GalleryPhoto.stub(localIdentifier: "new", creationDate: new),
            GalleryPhoto.stub(localIdentifier: "mid", creationDate: mid),
            GalleryPhoto.stub(localIdentifier: "old", creationDate: old)
        ]
        let (sut, _, _) = makeSUT(galleryResult: .success(items))

        sut.send(.viewDidLoad)
        await drain()

        let initialOrder = latestGalleryIdentifiers(from: sut)

        sut.send(.sort)
        await drain()

        sut.send(.sort)
        await drain()

        #expect(latestGalleryIdentifiers(from: sut) == initialOrder)
    }

    // MARK: - Load Error / Retry

    @Test func retryLoad_afterError_success_transitionsToLoaded() async {
        let (sut, _, _) = makeSUT(
            fetchResults: [.failure(MockError.generic)],
            fetchDefault: .success(CharacterPage.stub(characters: [.stub(id: 1)]))
        )

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.retryLoad)
        await drain()

        let hasLoaded = states.contains { if case .loaded = $0 { true } else { false } }
        #expect(hasLoaded)
        let finalData = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let d) = state { return d } else { return nil }
        }.last
        #expect(finalData?.sections.contains { $0.section == .characters } == true)
    }

    @Test func viewDidLoad_clearsErrorStateImmediately() async {
        let (sut, _, _) = makeSUT(fetchDefault: .failure(MockError.generic))

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        // Precondition: error state after failed load
        #expect(states.last.map { if case .error = $0 { true } else { false } } == true)

        // Second viewDidLoad — must immediately set .loading, before any Task runs
        sut.send(.viewDidLoad)
        #expect(states.last.map { if case .loading = $0 { true } else { false } } == true)
    }

    @Test func paginationError_doesNotSetErrorState() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, _, _) = makeSUT(
            fetchResults: [.success(page1)],
            fetchDefault: .failure(MockError.generic)
        )

        sut.send(.viewDidLoad)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.loadNextPage)
        await drain()

        let hasErrorState = states.contains { if case .error = $0 { true } else { false } }
        #expect(!hasErrorState)
        let pagination = states.compactMap { state -> PaginationState? in
            if case .loaded(let d) = state { return d.pagination } else { return nil }
        }.last
        #expect(pagination == .error)
    }

    // MARK: - reloadGallery

    @Test func reloadGallery_duringInitialLoad_isSkipped() {
        let (sut, _, galleryUseCase) = makeSUT()

        sut.send(.viewDidLoad)
        sut.send(.reloadGallery)

        #expect(galleryUseCase.executeCallCount == 0)
    }

    @Test func reloadGallery_afterInitialLoad_triggersGalleryFetch() async {
        let (sut, _, galleryUseCase) = makeSUT()

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = galleryUseCase.executeCallCount
        sut.send(.reloadGallery)
        await drain()

        #expect(galleryUseCase.executeCallCount == callsAfterLoad + 1)
    }

    // MARK: - Pagination Idempotency

    @Test func loadNextPage_whileFetchInFlight_doesNotStartSecondTask() async {
        let page1 = CharacterPage.stub(pages: 3, characters: [.stub(id: 1)])
        let page2 = CharacterPage.stub(pages: 3, characters: [.stub(id: 2)])
        let (sut, fetchUseCase, _) = makeSUT(
            fetchResults: [.success(page1), .success(page2)]
        )

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = fetchUseCase.executeCallCount
        sut.send(.loadNextPage)
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterLoad + 1)
    }

    @Test func loadNextPage_duringInitialLoad_isBlocked() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, fetchUseCase, _) = makeSUT(fetchDefault: .success(page1))

        sut.send(.viewDidLoad)
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == 1)
    }

    @Test func loadNextPage_afterPaginationFailure_isBlocked() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, fetchUseCase, _) = makeSUT(
            fetchResults: [.success(page1)],
            fetchDefault: .failure(MockError.generic)
        )

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.loadNextPage)
        await drain()

        let callsAfterFailure = fetchUseCase.executeCallCount
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterFailure)
    }

    @Test func loadNextPage_calledMultipleTimes_createsOneTask() async {
        let page1 = CharacterPage.stub(pages: 5, characters: [.stub(id: 1)])
        let (sut, fetchUseCase, _) = makeSUT(fetchResults: [.success(page1)])

        sut.send(.viewDidLoad)
        await drain()

        let callsAfterLoad = fetchUseCase.executeCallCount
        sut.send(.loadNextPage)
        sut.send(.loadNextPage)
        sut.send(.loadNextPage)
        sut.send(.loadNextPage)
        await drain()

        #expect(fetchUseCase.executeCallCount == callsAfterLoad + 1)
    }

    // MARK: - Regression

    @Test func refresh_resetsPaginationState() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let (sut, _, _) = makeSUT(
            fetchResults: [.success(page1), .failure(MockError.generic)],
            fetchDefault: .success(CharacterPage.stub(pages: 1, characters: [.stub(id: 1)]))
        )

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.loadNextPage)
        await drain()

        sut.send(.refresh)
        await drain()

        var latestData: CharacterListLoadedData?
        let cancellable = sut.state.sink { state in
            if case .loaded(let d) = state { latestData = d }
        }
        defer { cancellable.cancel() }

        await drain()
        #expect(latestData?.pagination == .idle)
    }

    @Test func sort_doesNotAffectPaginationState() async {
        let page1 = CharacterPage.stub(pages: 2, characters: [.stub(id: 1)])
        let items = [GalleryPhoto.stub(localIdentifier: "id-1")]
        let (sut, _, _) = makeSUT(
            fetchResults: [.success(page1)],
            fetchDefault: .failure(MockError.generic),
            galleryResult: .success(items)
        )

        sut.send(.viewDidLoad)
        await drain()

        sut.send(.loadNextPage)
        await drain()

        var states: [CharacterListState] = []
        let cancellable = sut.state.sink { states.append($0) }
        defer { cancellable.cancel() }

        sut.send(.sort)
        await drain()

        let loadedData = states.compactMap { state -> CharacterListLoadedData? in
            if case .loaded(let d) = state { return d } else { return nil }
        }.last
        #expect(loadedData?.pagination == .error)
        #expect(loadedData?.gallerySortOrder == .oldestFirst)
    }

    // MARK: - Route

    @Test func selectCharacter_sendsShowCharacterDetailRoute() async {
        let character = Character.stub(id: 42, name: "Morty Smith")
        let (sut, _, _) = makeSUT(
            fetchDefault: .success(CharacterPage.stub(characters: [character]))
        )

        sut.send(.viewDidLoad)
        await drain()

        var routes: [CharacterListRoute] = []
        let cancellable = sut.route.sink { routes.append($0) }
        defer { cancellable.cancel() }

        sut.send(.selectCharacter(id: 42))

        #expect(routes.count == 1)
        guard case .showCharacterDetail(let selectedCharacter) = routes.first else {
            Issue.record("Expected .showCharacterDetail route")
            return
        }
        #expect(selectedCharacter.id == 42)
    }

    @Test func selectGalleryPhoto_sendsShowPhotoDetailRoute() {
        let (sut, _, _) = makeSUT()
        var routes: [CharacterListRoute] = []
        let cancellable = sut.route.sink { routes.append($0) }
        defer { cancellable.cancel() }

        sut.send(.selectGalleryPhoto(localIdentifier: "photo-abc"))

        #expect(routes.count == 1)
        guard case .showPhotoDetail(let identifier) = routes.first else {
            Issue.record("Expected .showPhotoDetail route")
            return
        }
        #expect(identifier == "photo-abc")
    }

    // MARK: - Lifecycle / deinit

    @Test func deinit_whileLoadInFlight_doesNotCrash() async {
        // Verifies that deallocating CharacterListViewModel mid-flight does not
        // trigger an unowned/retain-cycle crash or leave dangling callbacks.
        var sut: CharacterListViewModel? = makeSUT().sut
        sut?.send(.viewDidLoad)
        // Release before tasks complete — should cancel cleanly.
        sut = nil
        await drain()
        // If we reach here without EXC_BAD_ACCESS or assertion the test passes.
    }
}
