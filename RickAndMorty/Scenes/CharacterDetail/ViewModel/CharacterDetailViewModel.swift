//
//  CharacterDetailViewModel.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import Combine

// MARK: - CharacterDetailViewModelProtocol

@MainActor
protocol CharacterDetailViewModelProtocol: AnyObject {
    var navigationTitle: String { get }
    var viewState: AnyPublisher<CharacterDetailState, Never> { get }
    var route: AnyPublisher<CharacterDetailRoute, Never> { get }

    func viewDidLoad()
    func imageTapped()
}

// MARK: - CharacterDetailViewModel

@MainActor
final class CharacterDetailViewModel: CharacterDetailViewModelProtocol {

    // MARK: - CharacterDetailViewModelProtocol

    let navigationTitle: String
    var viewState: AnyPublisher<CharacterDetailState, Never> { $state.eraseToAnyPublisher() }
    var route: AnyPublisher<CharacterDetailRoute, Never> { _route.eraseToAnyPublisher() }

    // MARK: - Private Output

    @Published private var state: CharacterDetailState = .idle
    private let _route = PassthroughSubject<CharacterDetailRoute, Never>()

    // MARK: - Private

    private let character: Character

    // MARK: - Init

    init(character: Character) {
        self.character = character
        self.navigationTitle = character.name
    }

    // MARK: - Input

    func viewDidLoad() {
        state = .loaded(CharacterDetailViewDataMapper.map(character))
    }

    func imageTapped() {
        _route.send(.showPhoto(
            imageURL: URL(string: character.image),
            characterName: character.name,
            characterId: character.id
        ))
    }
}
