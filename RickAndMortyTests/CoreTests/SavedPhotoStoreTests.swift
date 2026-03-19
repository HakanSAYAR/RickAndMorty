//
//  SavedPhotoStoreTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
import Foundation
@testable import RickAndMorty

// MARK: - SavedPhotoStoreTests

@MainActor
struct SavedPhotoStoreTests {

    // MARK: - Helper

    private func makeStore() -> SavedPhotoStore {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        return SavedPhotoStore(defaults: defaults)
    }

    private func makeStoreWithSharedDefaults() -> (SavedPhotoStore, UserDefaults) {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        return (SavedPhotoStore(defaults: defaults), defaults)
    }

    // MARK: - localIdentifier(for:) — empty state

    @Test func localIdentifier_unknownCharacterId_returnsNil() async {
        let store = makeStore()
        let result = await store.localIdentifier(for: 42)
        #expect(result == nil)
    }

    @Test func localIdentifier_idZero_returnsNil() async {
        let store = makeStore()
        let result = await store.localIdentifier(for: 0)
        #expect(result == nil)
    }

    // MARK: - save + localIdentifier round-trip

    @Test func save_thenLookup_returnsStoredIdentifier() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-abc")
        let result = await store.localIdentifier(for: 1)
        #expect(result == "photo-abc")
    }

    @Test func save_multipleMappings_eachLookupReturnsCorrectIdentifier() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-1")
        await store.save(characterId: 2, localIdentifier: "photo-2")
        await store.save(characterId: 3, localIdentifier: "photo-3")

        let r1 = await store.localIdentifier(for: 1)
        let r2 = await store.localIdentifier(for: 2)
        let r3 = await store.localIdentifier(for: 3)

        #expect(r1 == "photo-1")
        #expect(r2 == "photo-2")
        #expect(r3 == "photo-3")
    }

    @Test func save_overwriteExistingCharacterId_returnsLatestIdentifier() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "old-photo")
        await store.save(characterId: 1, localIdentifier: "new-photo")
        let result = await store.localIdentifier(for: 1)
        #expect(result == "new-photo")
    }

    // MARK: - remove(characterId:)

    @Test func removeByCharacterId_existingMapping_returnsNilAfterRemoval() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-abc")
        await store.remove(characterId: 1)
        let result = await store.localIdentifier(for: 1)
        #expect(result == nil)
    }

    @Test func removeByCharacterId_unknownId_doesNotAffectOtherEntries() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-1")
        await store.remove(characterId: 999)
        let result = await store.localIdentifier(for: 1)
        #expect(result == "photo-1")
    }

    @Test func removeByCharacterId_removesOnlyTargetEntry() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-1")
        await store.save(characterId: 2, localIdentifier: "photo-2")
        await store.remove(characterId: 1)

        let r1 = await store.localIdentifier(for: 1)
        let r2 = await store.localIdentifier(for: 2)

        #expect(r1 == nil)
        #expect(r2 == "photo-2")
    }

    // MARK: - remove(localIdentifier:)

    @Test func removeByLocalIdentifier_existingEntry_removesCorrectCharacter() async {
        let store = makeStore()
        await store.save(characterId: 5, localIdentifier: "target-photo")
        await store.save(characterId: 6, localIdentifier: "other-photo")
        await store.remove(localIdentifier: "target-photo")

        let r5 = await store.localIdentifier(for: 5)
        let r6 = await store.localIdentifier(for: 6)

        #expect(r5 == nil)
        #expect(r6 == "other-photo")
    }

    @Test func removeByLocalIdentifier_unknownIdentifier_doesNotAffectExistingEntries() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-1")
        await store.remove(localIdentifier: "nonexistent-photo")
        let result = await store.localIdentifier(for: 1)
        #expect(result == "photo-1")
    }

    // MARK: - allMappings()

    @Test func allMappings_emptyStore_returnsEmptyDictionary() async {
        let store = makeStore()
        let mappings = await store.allMappings()
        #expect(mappings.isEmpty)
    }

    @Test func allMappings_afterSaves_containsAllEntries() async {
        let store = makeStore()
        await store.save(characterId: 10, localIdentifier: "photo-10")
        await store.save(characterId: 20, localIdentifier: "photo-20")

        let mappings = await store.allMappings()

        #expect(mappings.count == 2)
        #expect(mappings[10] == "photo-10")
        #expect(mappings[20] == "photo-20")
    }

    @Test func allMappings_afterRemoval_doesNotContainRemovedEntry() async {
        let store = makeStore()
        await store.save(characterId: 1, localIdentifier: "photo-1")
        await store.save(characterId: 2, localIdentifier: "photo-2")
        await store.remove(characterId: 1)

        let mappings = await store.allMappings()

        #expect(mappings.count == 1)
        #expect(mappings[2] == "photo-2")
    }

    // MARK: - Persistence

    @Test func persistence_savedDataSurvivesNewInstance() async {
        let (store1, defaults) = makeStoreWithSharedDefaults()
        await store1.save(characterId: 1, localIdentifier: "persisted-photo")

        let store2 = SavedPhotoStore(defaults: defaults)
        let result = await store2.localIdentifier(for: 1)

        #expect(result == "persisted-photo")
    }

    @Test func persistence_removedDataDoesNotSurviveNewInstance() async {
        let (store1, defaults) = makeStoreWithSharedDefaults()
        await store1.save(characterId: 1, localIdentifier: "temp-photo")
        await store1.remove(characterId: 1)

        let store2 = SavedPhotoStore(defaults: defaults)
        let result = await store2.localIdentifier(for: 1)

        #expect(result == nil)
    }

    @Test func persistence_multipleEntries_allSurviveNewInstance() async {
        let (store1, defaults) = makeStoreWithSharedDefaults()
        await store1.save(characterId: 1, localIdentifier: "photo-1")
        await store1.save(characterId: 2, localIdentifier: "photo-2")

        let store2 = SavedPhotoStore(defaults: defaults)
        let mappings = await store2.allMappings()

        #expect(mappings.count == 2)
        #expect(mappings[1] == "photo-1")
        #expect(mappings[2] == "photo-2")
    }
}
