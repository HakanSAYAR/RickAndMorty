//
//  GalleryPhotoEntityTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - GalleryPhotoEntityTests

struct GalleryPhotoEntityTests {

    // MARK: - Equality

    @Test func equality_basedOnLocalIdentifier() {
        let date = Date()
        let a = GalleryPhoto(localIdentifier: "abc", creationDate: date)
        let b = GalleryPhoto(localIdentifier: "abc", creationDate: nil)
        #expect(a == b)
    }

    @Test func inequality_differentIdentifiers() {
        let a = GalleryPhoto(localIdentifier: "abc", creationDate: nil)
        let b = GalleryPhoto(localIdentifier: "xyz", creationDate: nil)
        #expect(a != b)
    }

    // MARK: - Hashing

    @Test func hash_basedOnLocalIdentifier() {
        let a = GalleryPhoto(localIdentifier: "id-1", creationDate: Date())
        let b = GalleryPhoto(localIdentifier: "id-1", creationDate: nil)
        var ha = Hasher(); a.hash(into: &ha)
        var hb = Hasher(); b.hash(into: &hb)
        #expect(ha.finalize() == hb.finalize())
    }

    // MARK: - Properties

    @Test func properties_areStoredCorrectly() {
        let date = Date(timeIntervalSince1970: 0)
        let photo = GalleryPhoto(localIdentifier: "test-id", creationDate: date)
        #expect(photo.localIdentifier == "test-id")
        #expect(photo.creationDate == date)
    }

    @Test func creationDate_canBeNil() {
        let photo = GalleryPhoto(localIdentifier: "test-id", creationDate: nil)
        #expect(photo.creationDate == nil)
    }
}
