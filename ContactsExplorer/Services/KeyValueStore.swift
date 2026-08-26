//
//  KeyValueStore.swift
//  ContactsExplorer
//

import Foundation

/// The sliver of `UserDefaults` that this app actually uses.
///
/// Exists so persistence can be swapped for an in-memory double in tests. The favourites logic used
/// to call `UserDefaults.standard` through static methods, which meant testing it would have written
/// to the real user defaults of whatever machine ran the suite.
nonisolated protocol KeyValueStore: Sendable {
    func stringArray(forKey key: String) -> [String]?
    func setStringArray(_ value: [String], forKey key: String)
}

nonisolated struct UserDefaultsKeyValueStore: KeyValueStore {
    // `UserDefaults` is documented as thread-safe but is not annotated `Sendable`, so the
    // compiler cannot see that for itself. Reads and writes here are safe on any thread.
    nonisolated(unsafe) private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func stringArray(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key)
    }

    func setStringArray(_ value: [String], forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
