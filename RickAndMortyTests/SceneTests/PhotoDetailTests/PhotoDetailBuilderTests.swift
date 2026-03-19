//
//  PhotoDetailBuilderTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import UIKit
@testable import RickAndMorty

// MARK: - PhotoDetailBuilderTests

@MainActor
struct PhotoDetailBuilderTests {

    @Test func make_returnsCorrectViewControllerType() {
        let scene = PhotoDetailBuilder.make(
            imageSource: .remote(nil),
            characterName: "Rick",
            characterId: 1,
            showDownloadButton: true,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        let vc: UIViewController = scene.viewController
        #expect(vc is PhotoDetailViewController)
    }

    @Test func make_returnsCorrectViewModelType() {
        let scene = PhotoDetailBuilder.make(
            imageSource: .remote(nil),
            characterName: "Rick",
            characterId: 1,
            showDownloadButton: true,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        #expect(scene.viewModel is PhotoDetailViewModel)
    }

    @Test func make_injectsCharacterNameIntoViewModel() {
        let scene = PhotoDetailBuilder.make(
            imageSource: .remote(nil),
            characterName: "Morty Smith",
            characterId: 2,
            showDownloadButton: false,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        #expect(scene.viewModel.navigationTitle == "Morty Smith")
    }

    @Test func make_injectsShowDownloadButtonIntoViewModel() {
        let scene = PhotoDetailBuilder.make(
            imageSource: .local("id-1"),
            characterName: "",
            characterId: nil,
            showDownloadButton: false,
            savePhotoUseCase: MockSavePhotoUseCase()
        )
        #expect(scene.viewModel.showDownloadButton == false)
    }
}
