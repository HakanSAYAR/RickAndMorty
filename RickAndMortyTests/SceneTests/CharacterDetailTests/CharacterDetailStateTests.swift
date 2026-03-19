//
//  CharacterDetailStateTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - CharacterDetailStateTests

struct CharacterDetailStateTests {

    private let viewData = CharacterDetailViewData(
        imageURL: URL(string: "https://example.com/rick.jpg"),
        name: "Rick Sanchez",
        rows: [DetailRowViewData(title: "Status", value: "Alive")]
    )

    // MARK: - Equatable

    @Test func idle_equalsIdle() {
        #expect(CharacterDetailState.idle == CharacterDetailState.idle)
    }

    @Test func loaded_equalsSameViewData() {
        #expect(CharacterDetailState.loaded(viewData) == CharacterDetailState.loaded(viewData))
    }

    @Test func loaded_notEqualsIdle() {
        #expect(CharacterDetailState.loaded(viewData) != CharacterDetailState.idle)
    }

    @Test func loaded_notEqualsDifferentName() {
        let other = CharacterDetailViewData(imageURL: nil, name: "Morty", rows: [])
        #expect(CharacterDetailState.loaded(viewData) != CharacterDetailState.loaded(other))
    }
}
