//
//  ListItemEntityTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - ListItemEntityTests

struct ListItemEntityTests {

    @Test func listItem_character_isHashable() {
        let c = Character.stub(id: 1)
        let item = ListItem.character(c)
        var set: Set<ListItem> = []
        set.insert(item)
        #expect(set.count == 1)
    }

    @Test func listItem_galleryPhoto_isHashable() {
        let photo = GalleryPhoto(localIdentifier: "x", creationDate: nil)
        let item = ListItem.galleryPhoto(photo)
        var set: Set<ListItem> = []
        set.insert(item)
        #expect(set.count == 1)
    }

    @Test func listItem_character_equality() {
        let item1 = ListItem.character(.stub(id: 1))
        let item2 = ListItem.character(.stub(id: 1))
        #expect(item1 == item2)
    }

    @Test func listItem_differentCases_areNotEqual() {
        let character = ListItem.character(.stub(id: 1))
        let photo = ListItem.galleryPhoto(GalleryPhoto(localIdentifier: "x", creationDate: nil))
        #expect(character != photo)
    }

    // MARK: - SortOption

    @Test func sortOption_equality() {
        #expect(SortOption.newestFirst == SortOption.newestFirst)
        #expect(SortOption.oldestFirst == SortOption.oldestFirst)
        #expect(SortOption.newestFirst != SortOption.oldestFirst)
    }

    // MARK: - PermissionStatus

    @Test func permissionStatus_equality() {
        #expect(PermissionStatus.authorized == PermissionStatus.authorized)
        #expect(PermissionStatus.denied != PermissionStatus.authorized)
        #expect(PermissionStatus.notDetermined != PermissionStatus.restricted)
    }
}
