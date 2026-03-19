//
//  CharacterDetailViewModelTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Combine
import Foundation
@testable import RickAndMorty

// MARK: - CharacterDetailViewModelTests

@MainActor
struct CharacterDetailViewModelTests {

    // MARK: - navigationTitle

    @Test func navigationTitle_equalsCharacterName() {
        let sut = CharacterDetailViewModel(character: .stub(name: "Rick Sanchez"))
        #expect(sut.navigationTitle == "Rick Sanchez")
    }

    // MARK: - viewState — initial

    @Test func viewState_beforeViewDidLoad_isIdle() {
        let sut = CharacterDetailViewModel(character: .stub())
        var received: [CharacterDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        // @Published sends current value on subscribe — should be .idle
        #expect(received == [.idle])
    }

    // MARK: - viewState — after viewDidLoad

    @Test func viewDidLoad_emitsLoadedState() {
        let sut = CharacterDetailViewModel(character: .stub(name: "Morty Smith"))
        var received: [CharacterDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()

        guard case .loaded(let viewData) = received.last else {
            Issue.record("Expected .loaded state")
            return
        }
        #expect(viewData.name == "Morty Smith")
    }

    @Test func viewDidLoad_loadedState_containsCorrectRows() {
        let sut = CharacterDetailViewModel(character: .stub(
            status: .alive,
            species: "Human",
            gender: .male
        ))
        var received: [CharacterDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()

        guard case .loaded(let viewData) = received.last else {
            Issue.record("Expected .loaded state")
            return
        }
        #expect(viewData.rows.count == 5)
    }

    @Test func viewDidLoad_calledTwice_emitsLoadedTwice() {
        let sut = CharacterDetailViewModel(character: .stub())
        var received: [CharacterDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()
        sut.viewDidLoad()

        let loadedCount = received.filter {
            if case .loaded = $0 { return true }
            return false
        }.count
        #expect(loadedCount == 2)
    }

    @Test func viewState_removeDuplicates_suppressesIdenticalConsecutiveEmissions() {
        let sut = CharacterDetailViewModel(character: .stub())
        var received: [CharacterDetailState] = []
        let cancellable = sut.viewState
            .removeDuplicates()
            .sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()
        sut.viewDidLoad() // same character → same viewData → duplicate suppressed

        let loadedCount = received.filter {
            if case .loaded = $0 { return true }
            return false
        }.count
        #expect(loadedCount == 1)
    }

    // MARK: - route

    @Test func imageTapped_sendsShowPhotoRoute() {
        let character = Character.stub(
            id: 42,
            name: "Rick Sanchez",
            image: "https://example.com/rick.jpg"
        )
        let sut = CharacterDetailViewModel(character: character)
        var routes: [CharacterDetailRoute] = []
        let cancellable = sut.route.sink { routes.append($0) }
        defer { cancellable.cancel() }

        sut.imageTapped()

        #expect(routes.count == 1)
        guard case .showPhoto(let url, let name, let id) = routes.first else {
            Issue.record("Expected .showPhoto route")
            return
        }
        #expect(url?.absoluteString == "https://example.com/rick.jpg")
        #expect(name == "Rick Sanchez")
        #expect(id == 42)
    }

    @Test func imageTapped_withEmptyImageURL_sendsRouteWithNilURL() {
        let sut = CharacterDetailViewModel(character: .stub(image: ""))
        var routes: [CharacterDetailRoute] = []
        let cancellable = sut.route.sink { routes.append($0) }
        defer { cancellable.cancel() }

        sut.imageTapped()

        guard case .showPhoto(let url, _, _) = routes.first else {
            Issue.record("Expected .showPhoto route")
            return
        }
        #expect(url == nil)
    }

    @Test func imageTapped_doesNotMutateViewState() {
        let sut = CharacterDetailViewModel(character: .stub())
        sut.viewDidLoad()

        var stateAfterLoad: CharacterDetailState?
        let cancellable = sut.viewState.sink { stateAfterLoad = $0 }
        defer { cancellable.cancel() }

        sut.imageTapped()

        // State must not change when navigation route is emitted
        guard case .loaded = stateAfterLoad else {
            Issue.record("State must remain .loaded after imageTapped")
            return
        }
    }
}
