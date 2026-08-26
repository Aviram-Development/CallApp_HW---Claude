//
//  FavoritesStoreTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@Suite("UserDefaultsFavoritesStore")
struct FavoritesStoreTests {
    @Test("An empty store has no favourites")
    func emptyStore() {
        let store = UserDefaultsFavoritesStore(keyValueStore: InMemoryKeyValueStore())
        #expect(store.load().isEmpty)
    }

    @Test("Saved favourites round-trip")
    func saveAndLoad() {
        let keyValueStore = InMemoryKeyValueStore()
        UserDefaultsFavoritesStore(keyValueStore: keyValueStore).save(["a", "b"])

        // A second instance, to prove the values came back out of storage rather than out of memory.
        #expect(UserDefaultsFavoritesStore(keyValueStore: keyValueStore).load() == ["a", "b"])
    }

    @Test("Saving replaces the previous set rather than merging into it")
    func saveReplaces() {
        let keyValueStore = InMemoryKeyValueStore()
        let store = UserDefaultsFavoritesStore(keyValueStore: keyValueStore)

        store.save(["a", "b"])
        store.save(["c"])

        #expect(store.load() == ["c"])
    }

    // The storage key is deliberately unchanged from the original implementation, so favourites
    // already on someone's device survive the refactor. This test pins that down.
    @Test("Favourites written by the previous implementation are still read")
    func readsLegacyKey() {
        let keyValueStore = InMemoryKeyValueStore(initialValues: ["favoriteContactIDs": ["legacy"]])
        #expect(UserDefaultsFavoritesStore(keyValueStore: keyValueStore).load() == ["legacy"])
    }
}
