//
//  ContactsModel.swift
//  ContactsExplorer
//

import Foundation
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "Contacts")

/// The device address book, loaded once and shared by every tab.
///
/// Split out of `ContactsListViewModel` when the tab bar arrived: Favourites and Contacts are two
/// screens over the *same* contacts, and a view model each would mean fetching and holding the whole
/// address book twice. Loading lives here; each tab's view model keeps only its own query and scope.
///
/// Owned at the app level and passed down explicitly, exactly like `FavoritesModel`.
@MainActor
@Observable
final class ContactsModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case permissionDenied
        case failed
    }

    private(set) var state: LoadState = .idle
    private(set) var contacts: [Contact] = []

    private let loadContacts: LoadContactsUseCase

    init(dependencies: AppDependencies) {
        self.loadContacts = LoadContactsUseCase(repository: dependencies.contactsRepository)
    }

    var isEmptyOfContacts: Bool {
        state == .loaded && contacts.isEmpty
    }

    /// Called when a list appears. Safe to call repeatedly — and from every tab — because only the
    /// first attempt does work.
    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        // Only take over the screen with a spinner when there is nothing to show behind it.
        if contacts.isEmpty {
            state = .loading
        }
        do {
            switch try await loadContacts() {
            case .loaded(let fetched):
                contacts = fetched
                state = .loaded
            case .permissionDenied:
                state = .permissionDenied
            }
        } catch {
            logger.error("Loading contacts failed: \(String(describing: error))")
            // A failed refresh should not throw away a list the user is already looking at.
            if contacts.isEmpty {
                state = .failed
            }
        }
    }

    /// Called when the app returns to the foreground, so granting access in Settings takes effect on
    /// return instead of leaving the user staring at the permission screen.
    func reloadIfPermissionMayHaveChanged() async {
        guard state == .permissionDenied else { return }
        await load()
    }
}
