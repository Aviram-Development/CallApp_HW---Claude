//
//  ContactsListViewModel.swift
//  ContactsExplorer
//

import Foundation
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactsList")

@MainActor
@Observable
final class ContactsListViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case permissionDenied
        case failed
    }

    private(set) var state: LoadState = .idle
    var searchText = ""

    /// Shared with the detail screen, so a star toggled there shows up here.
    let favorites: FavoritesModel

    private var contacts: [Contact] = []
    private let loadContacts: LoadContactsUseCase
    private let matcher = ContactSearchMatcher()
    private let sectionBuilder = ContactSectionBuilder()

    init(dependencies: AppDependencies, favorites: FavoritesModel) {
        self.loadContacts = LoadContactsUseCase(repository: dependencies.contactsRepository)
        self.favorites = favorites
    }

    // MARK: - Derived state

    /// The grouped, filtered list the view renders.
    ///
    /// Computed rather than cached on purpose. `@Observable` then invalidates it automatically when
    /// the contacts, the query or the favourites change, with no cache to go stale. The view reads it
    /// into a local so one render costs one evaluation — the old code called its equivalent twice per
    /// render, once for the list and once again to decide whether to show the empty state.
    var sections: [ContactSection] {
        let matched = matcher.filter(contacts, query: searchText)
        return sectionBuilder.sections(
            for: matched,
            favoriteIDs: favorites.favoriteIDs,
            // While searching, every row is already a deliberate result; pinning some of them again
            // at the top would just read as duplicates.
            includeFavoritesSection: !isSearching
        )
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isEmptyOfContacts: Bool {
        state == .loaded && contacts.isEmpty
    }

    // MARK: - Loading

    /// Called when the list appears. Safe to call repeatedly; only the first attempt does work.
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
