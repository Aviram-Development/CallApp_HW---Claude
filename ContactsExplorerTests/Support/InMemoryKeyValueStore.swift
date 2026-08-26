//
//  InMemoryKeyValueStore.swift
//  ContactsExplorerTests
//

import Foundation
import Synchronization
@testable import ContactsExplorer

/// A `KeyValueStore` that keeps everything in memory, so favourites tests never touch the real
/// user defaults of the machine running the suite.
final class InMemoryKeyValueStore: KeyValueStore {
    private let storage = Mutex<[String: [String]]>([:])

    init(initialValues: [String: [String]] = [:]) {
        storage.withLock { $0 = initialValues }
    }

    func stringArray(forKey key: String) -> [String]? {
        storage.withLock { $0[key] }
    }

    func setStringArray(_ value: [String], forKey key: String) {
        storage.withLock { $0[key] = value }
    }
}
