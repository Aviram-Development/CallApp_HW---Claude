//
//  CNContactsRepository.swift
//  ContactsExplorer
//

import Contacts
import Foundation

/// The `Contacts`-framework implementation of `ContactsRepository`.
///
/// This is an `actor` on purpose. `CNContactStore.enumerateContacts` is *synchronous and blocking*,
/// and the project builds with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so a plain type here
/// would run that blocking call straight on the main thread and freeze the UI for the length of the
/// fetch. Actor isolation moves the work onto a background executor and — unlike `@concurrent` on a
/// shared mutable type — needs no unchecked `Sendable` escape hatch to be safe.
actor CNContactsRepository: ContactsRepository {
    /// One store for the lifetime of the repository. `CNContactStore` is expensive to construct, and
    /// actor isolation guarantees we never touch this one from two tasks at once.
    private let store = CNContactStore()

    nonisolated func authorizationStatus() -> ContactsAuthorizationStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized, .limited:
            // Limited access still yields contacts, just fewer of them. Nothing above this layer
            // needs to care about the difference.
            .granted
        case .notDetermined:
            .notDetermined
        case .denied, .restricted:
            .denied
        @unknown default:
            .denied
        }
    }

    func requestAccess() async throws -> Bool {
        try await store.requestAccess(for: .contacts)
    }

    func fetchContacts() async throws -> [Contact] {
        let request = CNContactFetchRequest(keysToFetch: Contact.fetchKeys)
        request.sortOrder = .userDefault

        var contacts: [Contact] = []
        try store.enumerateContacts(with: request) { cnContact, _ in
            contacts.append(Contact(cnContact))
        }

        // `.userDefault` orders by the user's Contacts preference, but the list sections by
        // `sortKey`, so sort by the same key here to keep order and section headers in agreement.
        return contacts.sorted { $0.sortKey.localizedStandardCompare($1.sortKey) == .orderedAscending }
    }

    func fetchFullImageData(for contactID: String) async throws -> Data? {
        guard authorizationStatus() == .granted else { return nil }
        let keys = [CNContactImageDataKey as CNKeyDescriptor]
        return try store.unifiedContact(withIdentifier: contactID, keysToFetch: keys).imageData
    }
}
