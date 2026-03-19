//
//  CharacterListAction.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

// MARK: - CharacterListAction

enum CharacterListAction {
    case viewDidLoad
    case refresh
    case loadNextPage
    case retryLoad
    case retryPagination
    case reloadGallery
    case sort
    case selectCharacter(id: Int)
    case selectGalleryPhoto(localIdentifier: String)
}
