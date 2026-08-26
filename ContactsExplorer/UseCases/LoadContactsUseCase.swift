//
//  LoadContactsUseCase.swift
//  ContactsExplorer
//

import Foundation

/// Asks for contacts permission if it has not been asked for yet, then fetches.
///
/// Worth its own type because the permission dance has more branches than it first appears — the
/// answer differs between "never asked", "asked and refused", and "granted" — and the view model
/// should not have to re-derive it.
nonisolated struct LoadContactsUseCase {
    enum Outcome: Equatable {
        case loaded([Contact])
        case permissionDenied
    }

    private let repository: ContactsRepository

    init(repository: ContactsRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> Outcome {
        switch repository.authorizationStatus() {
        case .granted:
            return .loaded(try await fetchSorted())
        case .notDetermined:
            guard try await repository.requestAccess() else { return .permissionDenied }
            return .loaded(try await fetchSorted())
        case .denied:
            // Asking again does nothing once the user has refused; only Settings can change this.
            return .permissionDenied
        }
    }

    /// Puts the contacts into display order. `ContactSectionBuilder` groups without re-sorting, and
    /// this is the single point that guarantees the order it relies on — previously each repository
    /// sorted for itself, which meant the test fakes did not sort at all.
    private func fetchSorted() async throws -> [Contact] {
        try await repository.fetchContacts().sorted(by: Contact.isOrderedBefore)
    }
}
