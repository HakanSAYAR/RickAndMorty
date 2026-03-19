//
//  PhotoDetailViewModelTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Combine
import Foundation
@testable import RickAndMorty

// MARK: - PhotoDetailViewModelTests

@MainActor
struct PhotoDetailViewModelTests {

    private func makeSUT(
        imageSource: PhotoImageSource = .remote(nil),
        characterName: String = "Rick Sanchez",
        characterId: Int? = 1,
        showDownloadButton: Bool = false,
        saveUseCase: MockSavePhotoUseCase = MockSavePhotoUseCase()
    ) -> PhotoDetailViewModel {
        PhotoDetailViewModel(
            imageSource: imageSource,
            characterName: characterName,
            characterId: characterId,
            showDownloadButton: showDownloadButton,
            savePhotoUseCase: saveUseCase
        )
    }

    // MARK: - navigationTitle

    @Test func navigationTitle_equalsCharacterName() {
        #expect(makeSUT(characterName: "Rick Sanchez").navigationTitle == "Rick Sanchez")
    }

    // MARK: - showDownloadButton

    @Test func showDownloadButton_true_whenFromCharacterDetail() {
        #expect(makeSUT(showDownloadButton: true).showDownloadButton == true)
    }

    @Test func showDownloadButton_false_whenFromGallery() {
        #expect(makeSUT(imageSource: .local("id-123"), showDownloadButton: false).showDownloadButton == false)
    }

    // MARK: - viewState — initial

    @Test func viewState_beforeViewDidLoad_isIdle() {
        let sut = makeSUT()
        var received: [PhotoDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        #expect(received == [.idle])
    }

    // MARK: - viewState — after viewDidLoad

    @Test func viewDidLoad_emitsLoadedState() {
        let source = PhotoImageSource.remote(URL(string: "https://example.com/img.jpg"))
        let sut = makeSUT(imageSource: source, characterName: "Rick")
        var received: [PhotoDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()

        guard case .loaded(let viewData) = received.last else {
            Issue.record("Expected .loaded state")
            return
        }
        #expect(viewData.characterName == "Rick")
        #expect(viewData.imageSource == source)
    }

    @Test func viewDidLoad_emitsLoadedState_withLocalSource() {
        let sut = makeSUT(imageSource: .local("id-99"), characterName: "Morty")
        var received: [PhotoDetailState] = []
        let cancellable = sut.viewState.sink { received.append($0) }
        defer { cancellable.cancel() }

        sut.viewDidLoad()

        guard case .loaded(let viewData) = received.last else {
            Issue.record("Expected .loaded state")
            return
        }
        #expect(viewData.imageSource == .local("id-99"))
    }

    // MARK: - saveButtonTapped — events

    @Test func saveButtonTapped_success_sendsSaveSuccessEvent() async {
        let mock = MockSavePhotoUseCase()
        mock.result = .saved
        let sut = makeSUT(showDownloadButton: true, saveUseCase: mock)
        var events: [PhotoDetailEvent] = []
        let cancellable = sut.events.sink { events.append($0) }
        defer { cancellable.cancel() }

        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))
        for _ in 0..<5 { await Task.yield() }

        #expect(mock.executeCallCount == 1)
        if case .saveSuccess = events.first { } else { Issue.record("Expected .saveSuccess") }
    }

    @Test func saveButtonTapped_alreadyExists_sendsAlreadySavedEvent() async {
        let mock = MockSavePhotoUseCase()
        mock.result = .alreadyExists
        let sut = makeSUT(characterId: 42, showDownloadButton: true, saveUseCase: mock)
        var events: [PhotoDetailEvent] = []
        let cancellable = sut.events.sink { events.append($0) }
        defer { cancellable.cancel() }

        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))
        for _ in 0..<5 { await Task.yield() }

        #expect(mock.lastCharacterId == 42)
        if case .alreadySaved = events.first { } else { Issue.record("Expected .alreadySaved") }
    }

    @Test func saveButtonTapped_permissionDenied_sendsPermissionDeniedEvent() async {
        let mock = MockSavePhotoUseCase()
        mock.saveError = PhotoSavingError.permissionDenied
        let sut = makeSUT(showDownloadButton: true, saveUseCase: mock)
        var events: [PhotoDetailEvent] = []
        let cancellable = sut.events.sink { events.append($0) }
        defer { cancellable.cancel() }

        sut.saveButtonTapped(imageData: Data([0x01]))
        for _ in 0..<5 { await Task.yield() }

        if case .permissionDenied = events.first { } else { Issue.record("Expected .permissionDenied") }
    }

    @Test func saveButtonTapped_genericFailure_sendsSaveErrorEvent() async {
        let mock = MockSavePhotoUseCase()
        mock.saveError = MockError.generic
        let sut = makeSUT(showDownloadButton: true, saveUseCase: mock)
        var events: [PhotoDetailEvent] = []
        let cancellable = sut.events.sink { events.append($0) }
        defer { cancellable.cancel() }

        sut.saveButtonTapped(imageData: Data([0x01]))
        for _ in 0..<5 { await Task.yield() }

        if case .saveError = events.first { } else { Issue.record("Expected .saveError") }
    }

    @Test func saveButtonTapped_nilData_doesNotCallUseCase() async {
        let mock = MockSavePhotoUseCase()
        let sut = makeSUT(showDownloadButton: true, saveUseCase: mock)

        sut.saveButtonTapped(imageData: nil)
        for _ in 0..<5 { await Task.yield() }

        #expect(mock.executeCallCount == 0)
    }

    @Test func saveButtonTapped_nilCharacterId_doesNotCallUseCase() async {
        let mock = MockSavePhotoUseCase()
        let sut = makeSUT(characterId: nil, showDownloadButton: true, saveUseCase: mock)

        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))
        for _ in 0..<5 { await Task.yield() }

        #expect(mock.executeCallCount == 0)
    }

    @Test func saveButtonTapped_showDownloadButtonFalse_doesNotCallUseCase() async {
        let mock = MockSavePhotoUseCase()
        let sut = makeSUT(showDownloadButton: false, saveUseCase: mock)

        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))
        for _ in 0..<5 { await Task.yield() }

        #expect(mock.executeCallCount == 0)
    }

    // MARK: - Task ownership — double-tap cancellation

    @Test func saveButtonTapped_doubleTap_firstTaskCancelled_onlyOneEventEmitted() async {
        // SlowSavePhotoUseCase suspends at Task.yield(), allowing cancellation before return.
        final class SlowSavePhotoUseCase: SaveImageToGalleryUseCaseProtocol {
            var executeCallCount = 0
            func execute(characterId: Int, imageData: Data) async throws -> SaveImageResult {
                executeCallCount += 1
                await Task.yield()
                try Task.checkCancellation()
                return .saved
            }
        }

        let slow = SlowSavePhotoUseCase()
        let sut = PhotoDetailViewModel(
            imageSource: .remote(nil),
            characterName: "Rick Sanchez",
            characterId: 1,
            showDownloadButton: true,
            savePhotoUseCase: slow
        )
        var events: [PhotoDetailEvent] = []
        let cancellable = sut.events.sink { events.append($0) }
        defer { cancellable.cancel() }

        // First tap — task starts but has not yet resumed past yield()
        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))
        // Second tap — cancels first task, starts a new one
        sut.saveButtonTapped(imageData: Data([0xFF, 0xD8]))

        for _ in 0..<10 { await Task.yield() }

        // Only second task completes; first is cancelled → exactly one .saveSuccess
        #expect(events.count == 1)
        if case .saveSuccess = events.first { } else { Issue.record("Expected .saveSuccess") }
    }
}
