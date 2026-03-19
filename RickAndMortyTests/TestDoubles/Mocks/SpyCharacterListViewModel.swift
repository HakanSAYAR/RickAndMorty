//
//  SpyCharacterListViewModel.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import Combine
@testable import RickAndMorty

// MARK: - SpyCharacterListViewModel
// Drives CharacterListViewController's render pipeline in integration tests.
// Tracks which actions the VC sent and allows emitting arbitrary states.

@MainActor
final class SpyCharacterListViewModel: CharacterListViewModelProtocol {

    // MARK: - Protocol Outputs

    private let stateSubject: CurrentValueSubject<CharacterListState, Never>
    private let eventsSubject = PassthroughSubject<CharacterListEvent, Never>()
    private let routeSubject = PassthroughSubject<CharacterListRoute, Never>()

    var state: AnyPublisher<CharacterListState, Never> { stateSubject.eraseToAnyPublisher() }
    var events: AnyPublisher<CharacterListEvent, Never> { eventsSubject.eraseToAnyPublisher() }
    var route: AnyPublisher<CharacterListRoute, Never> { routeSubject.eraseToAnyPublisher() }

    // MARK: - Call Tracking

    private(set) var receivedActions: [CharacterListAction] = []

    var viewDidLoadCalled: Bool { receivedActions.contains { if case .viewDidLoad = $0 { true } else { false } } }
    var refreshCalled: Bool { receivedActions.contains { if case .refresh = $0 { true } else { false } } }
    var sortCalled: Bool { receivedActions.contains { if case .sort = $0 { true } else { false } } }

    // MARK: - Init

    init(initialState: CharacterListState = .loaded(CharacterListLoadedData(
        sections: [],
        pagination: .idle,
        gallerySortOrder: .newestFirst,
        isRefreshing: false
    ))) {
        stateSubject = CurrentValueSubject(initialState)
    }

    // MARK: - Test Helpers

    func emit(_ state: CharacterListState) {
        stateSubject.send(state)
    }

    // MARK: - CharacterListViewModelProtocol

    func send(_ action: CharacterListAction) {
        receivedActions.append(action)
    }
}
