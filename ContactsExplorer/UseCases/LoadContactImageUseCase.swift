//
//  LoadContactImageUseCase.swift
//  ContactsExplorer
//

import Foundation

/// Fetches the full-resolution image for one contact.
///
/// The list only ever carries thumbnails; the detail screen upgrades to the full image once it is on
/// screen. This used to run inside `ContactDetailView` itself, which put a blocking Contacts call on
/// the main actor and gave the view a second, private copy of the permission check.
nonisolated struct LoadContactImageUseCase {
    private let repository: ContactsRepository

    init(repository: ContactsRepository) {
        self.repository = repository
    }

    func callAsFunction(contactID: String) async throws -> Data? {
        try await repository.fetchFullImageData(for: contactID)
    }
}
