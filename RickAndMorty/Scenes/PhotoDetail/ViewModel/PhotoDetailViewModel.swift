//
//  PhotoDetailViewModel.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import Combine

// MARK: - PhotoDetailViewModelProtocol

@MainActor
protocol PhotoDetailViewModelProtocol: AnyObject {
    var navigationTitle: String { get }
    var showDownloadButton: Bool { get }
    var viewState: AnyPublisher<PhotoDetailState, Never> { get }
    var events: AnyPublisher<PhotoDetailEvent, Never> { get }

    func viewDidLoad()
    func saveButtonTapped(imageData: Data?)
}

// MARK: - PhotoDetailViewModel

@MainActor
final class PhotoDetailViewModel: PhotoDetailViewModelProtocol {

    // MARK: - PhotoDetailViewModelProtocol

    let navigationTitle: String
    let showDownloadButton: Bool
    var viewState: AnyPublisher<PhotoDetailState, Never> { $state.eraseToAnyPublisher() }
    var events: AnyPublisher<PhotoDetailEvent, Never> { _events.eraseToAnyPublisher() }

    // MARK: - Private Output

    @Published private var state: PhotoDetailState = .idle
    private let _events = PassthroughSubject<PhotoDetailEvent, Never>()

    // MARK: - Private

    private let imageSource: PhotoImageSource
    private let characterName: String
    private let characterId: Int?
    private let savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    init(
        imageSource: PhotoImageSource,
        characterName: String,
        characterId: Int?,
        showDownloadButton: Bool,
        savePhotoUseCase: SaveImageToGalleryUseCaseProtocol
    ) {
        self.imageSource = imageSource
        self.characterName = characterName
        self.characterId = characterId
        self.navigationTitle = characterName
        self.showDownloadButton = showDownloadButton
        self.savePhotoUseCase = savePhotoUseCase
    }

    // MARK: - Lifecycle

    deinit {
        saveTask?.cancel()
    }

    // MARK: - Input

    func viewDidLoad() {
        state = .loaded(PhotoDetailViewData(imageSource: imageSource, characterName: characterName))
    }

    func saveButtonTapped(imageData: Data?) {
        // imageData nil: image not yet loaded, silently no-op
        guard showDownloadButton, let characterId, let imageData else { return }
        saveTask?.cancel()
        saveTask = Task {
            do {
                let result = try await savePhotoUseCase.execute(characterId: characterId, imageData: imageData)
                switch result {
                case .saved:         _events.send(.saveSuccess)
                case .alreadyExists: _events.send(.alreadySaved)
                }
            } catch is CancellationError {
                return
            } catch PhotoSavingError.permissionDenied {
                _events.send(.permissionDenied)
            } catch {
                _events.send(.saveError(ErrorMapper.message(for: error)))
            }
        }
    }
}
