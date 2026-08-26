//
//  FavoritesStore.swift
//  ContactsExplorer
//

import Foundation

/// Persistence for the set of favourited contact identifiers.
nonisolated protocol FavoritesStore: Sendable {
    func load() -> Set<String>
    func save(_ ids: Set<String>)
}

/// Stores favourites in `UserDefaults`.
///
/// A set of identifiers is small, flat and read once at launch, so `UserDefaults` is the right size
/// of tool here — reaching for SwiftData or a file would be more machinery than the data deserves.
nonisolated struct UserDefaultsFavoritesStore: FavoritesStore {
    // Unchanged from the original implementation on purpose: anyone already running the app keeps
    // the favourites they had before this refactor.
    private static let favoriteContactIDsKey = "favoriteContactIDs"

    private let keyValueStore: KeyValueStore

    init(keyValueStore: KeyValueStore = UserDefaultsKeyValueStore()) {
        self.keyValueStore = keyValueStore
    }

    func load() -> Set<String> {
        Set(keyValueStore.stringArray(forKey: Self.favoriteContactIDsKey) ?? [])
    }

    func save(_ ids: Set<String>) {
        keyValueStore.setStringArray(Array(ids), forKey: Self.favoriteContactIDsKey)
    }
}
