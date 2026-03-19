//
//  GalleryChangeObserverProxy.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos
import Combine

// MARK: - GalleryChangePublishing

protocol GalleryChangePublishing {
    var photoLibraryDidChange: AnyPublisher<Void, Never> { get }
}

// MARK: - GalleryChangeObserverProxy
//
// Wraps PHPhotoLibraryChangeObserver in a Combine publisher.
// Self-registers on init, unregisters on deinit.

final class GalleryChangeObserverProxy: NSObject, PHPhotoLibraryChangeObserver, GalleryChangePublishing {

    // MARK: - GalleryChangePublishing

    nonisolated(unsafe) let photoLibraryDidChange: AnyPublisher<Void, Never>

    // MARK: - Private

    // nonisolated(unsafe): let constant, never mutated after init.
    nonisolated(unsafe) private let subject = PassthroughSubject<Void, Never>()

    // MARK: - Init / Deinit

    nonisolated override init() {
        photoLibraryDidChange = subject.eraseToAnyPublisher()
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - PHPhotoLibraryChangeObserver

    // nonisolated: PHKit calls this from an arbitrary background thread.
    // Dispatching to @MainActor happens explicitly inside the Task body.
    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor [subject] in
            subject.send()
        }
    }
}
