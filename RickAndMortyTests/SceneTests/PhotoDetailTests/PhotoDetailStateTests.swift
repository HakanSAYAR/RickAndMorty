//
//  PhotoDetailStateTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - PhotoDetailStateTests

struct PhotoDetailStateTests {

    private let viewData = PhotoDetailViewData(
        imageSource: .remote(URL(string: "https://example.com/img.jpg")),
        characterName: "Rick Sanchez"
    )

    // MARK: - Equatable

    @Test func idle_equalsIdle() {
        #expect(PhotoDetailState.idle == PhotoDetailState.idle)
    }

    @Test func loaded_equalsSameViewData() {
        #expect(PhotoDetailState.loaded(viewData) == PhotoDetailState.loaded(viewData))
    }

    @Test func loaded_notEqualsIdle() {
        #expect(PhotoDetailState.loaded(viewData) != PhotoDetailState.idle)
    }

    @Test func loaded_notEqualsDifferentCharacterName() {
        let other = PhotoDetailViewData(imageSource: .remote(nil), characterName: "Morty")
        #expect(PhotoDetailState.loaded(viewData) != PhotoDetailState.loaded(other))
    }

    @Test func loaded_notEqualsDifferentImageSource() {
        let other = PhotoDetailViewData(imageSource: .local("id-1"), characterName: "Rick Sanchez")
        #expect(PhotoDetailState.loaded(viewData) != PhotoDetailState.loaded(other))
    }
}
