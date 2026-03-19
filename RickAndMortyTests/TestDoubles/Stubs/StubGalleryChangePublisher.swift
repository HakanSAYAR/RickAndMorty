//
//  StubGalleryChangePublisher.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Combine
@testable import RickAndMorty

// MARK: - StubGalleryChangePublisher
// Test double for GalleryChangePublishing — never fires unless explicitly triggered.
// Prevents PHPhotoLibrary registration side effects in unit tests.

final class StubGalleryChangePublisher: GalleryChangePublishing {

    let photoLibraryDidChange: AnyPublisher<Void, Never>

    private let subject = PassthroughSubject<Void, Never>()

    init() {
        photoLibraryDidChange = subject.eraseToAnyPublisher()
    }

    func send() {
        subject.send()
    }
}
