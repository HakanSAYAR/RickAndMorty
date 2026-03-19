//
//  GalleryChangeObserverProxyTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Combine
@testable import RickAndMorty

// MARK: - GalleryChangeObserverProxyTests

struct GalleryChangeObserverProxyTests {

    // MARK: - Publisher emission

    @Test func photoLibraryDidChange_emitsOnPublisher() async {
        let proxy = GalleryChangeObserverProxy()
        var cancellables = Set<AnyCancellable>()

        let emitted = await withCheckedContinuation { continuation in
            var didResume = false
            proxy.photoLibraryDidChange
                .sink {
                    guard !didResume else { return }
                    didResume = true
                    continuation.resume(returning: true)
                }
                .store(in: &cancellables)

            // Simulate PHKit calling back — bypasses the real photo library.
            proxy.photoLibraryDidChange(MockPHChange())
        }

        #expect(emitted == true)
    }

    @Test func photoLibraryDidChange_multipleCallbacks_emitsEachTime() async {
        let proxy = GalleryChangeObserverProxy()
        var cancellables = Set<AnyCancellable>()
        var count = 0

        proxy.photoLibraryDidChange
            .sink { count += 1 }
            .store(in: &cancellables)

        proxy.photoLibraryDidChange(MockPHChange())
        proxy.photoLibraryDidChange(MockPHChange())

        // Flush two Task { @MainActor in } dispatches enqueued by the proxy
        await MainActor.run {}
        await MainActor.run {}

        #expect(count == 2)
    }

    // MARK: - Stale-callback guard (weak capture)

    @Test func deinit_publisherCompletesNoFurtherEmissions() async {
        var cancellables = Set<AnyCancellable>()
        var count = 0

        var proxy: GalleryChangeObserverProxy? = GalleryChangeObserverProxy()
        proxy?.photoLibraryDidChange
            .sink { count += 1 }
            .store(in: &cancellables)

        proxy?.photoLibraryDidChange(MockPHChange())
        await MainActor.run {}  // flush Task { @MainActor in } dispatch from the proxy

        proxy = nil   // triggers deinit → PHPhotoLibrary.unregisterChangeObserver

        // Any lingering DispatchQueue.main.async from before deinit may still fire —
        // this verifies the count doesn't grow further after nil.
        let countAfterDeinit = count
        await MainActor.run {}  // flush any remaining dispatch before asserting
        #expect(count == countAfterDeinit)
    }
}

// MARK: - MockPHChange

import Photos

/// Minimal PHChange subclass — enough to satisfy the method signature.
private final class MockPHChange: PHChange, @unchecked Sendable {}
