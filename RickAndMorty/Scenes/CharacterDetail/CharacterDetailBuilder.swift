//
//  CharacterDetailBuilder.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - CharacterDetailScene

struct CharacterDetailScene {
    let viewController: CharacterDetailViewController
    let viewModel: any CharacterDetailViewModelProtocol
}

// MARK: - CharacterDetailBuilder

enum CharacterDetailBuilder {
    static func make(character: Character) -> CharacterDetailScene {
        let viewModel = CharacterDetailViewModel(character: character)
        let viewController = CharacterDetailViewController(viewModel: viewModel)
        return CharacterDetailScene(viewController: viewController, viewModel: viewModel)
    }
}
