//
//  CharacterDetailState.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - CharacterDetailState

enum CharacterDetailState {
    case idle
    case loaded(CharacterDetailViewData)
}

nonisolated extension CharacterDetailState: Equatable {}
