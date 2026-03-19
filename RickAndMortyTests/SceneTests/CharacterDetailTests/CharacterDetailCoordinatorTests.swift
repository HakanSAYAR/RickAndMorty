//
//  CharacterDetailCoordinatorTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - CharacterDetailCoordinatorTests

@MainActor
struct CharacterDetailCoordinatorTests {

    // MARK: - Helpers

    private func makeSUT(character: Character = .stub()) -> (
        sut: CharacterDetailCoordinator,
        nav: UINavigationController
    ) {
        let nav = UINavigationController()
        let sut = CharacterDetailCoordinator(
            navigationController: nav,
            character: character,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        return (sut, nav)
    }

    // MARK: - Start

    @Test func start_setsRootViewControllerToCharacterDetailVC() {
        let (sut, _) = makeSUT()
        sut.start()
        #expect(sut.rootViewController is CharacterDetailViewController)
    }

    @Test func start_pushesCharacterDetailVCOntoNavigationStack() {
        let (sut, nav) = makeSUT()
        sut.start()
        #expect(nav.viewControllers.last is CharacterDetailViewController)
    }

    @Test func start_initialChildrenIsEmpty() {
        let (sut, _) = makeSUT()
        sut.start()
        #expect(sut.children.isEmpty)
    }

    @Test func start_navigationTitleMatchesCharacterName() {
        let (sut, nav) = makeSUT(character: .stub(name: "Rick Sanchez"))
        sut.start()
        nav.viewControllers.last?.loadViewIfNeeded()
        #expect(nav.viewControllers.last?.title == "Rick Sanchez")
    }
}
