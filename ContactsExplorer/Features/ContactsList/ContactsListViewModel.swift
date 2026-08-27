//
//  ContactsListViewModel.swift
//  ContactsExplorer
//

import Foundation

@MainActor
@Observable
final class ContactsListViewModel {
    /// Which slice of the address book a tab shows. The two tabs differ only in this, so they share
    /// one view model type rather than duplicating search, sectioning and the load states.
    enum Scope {
        case all
        case favorites
    }

    typealias LoadState = ContactsModel.LoadState

    var searchText = ""

    let scope: Scope
    /// Shared with the detail screen and the other tab, so a star toggled anywhere shows up here.
    let favorites: FavoritesModel

    private let contactsModel: ContactsModel
    private let matcher = ContactSearchMatcher()
    private let sectionBuilder = ContactSectionBuilder()

    init(contacts: ContactsModel, favorites: FavoritesModel, scope: Scope = .all) {
        self.contactsModel = contacts
        self.favorites = favorites
        self.scope = scope
    }

    // MARK: - Derived state

    var state: LoadState { contactsModel.state }

    /// The grouped, filtered list the view renders.
    ///
    /// Computed rather than cached on purpose. `@Observable` then invalidates it automatically when
    /// the contacts, the query or the favourites change, with no cache to go stale. The view reads it
    /// into a local so one render costs one evaluation — the old code called its equivalent twice per
    /// render, once for the list and once again to decide whether to show the empty state.
    var sections: [ContactSection] {
        let matched = matcher.filter(scopedContacts, query: searchText)

        switch scope {
        case .all:
            return sectionBuilder.sections(
                for: matched,
                favoriteIDs: favorites.favoriteIDs,
                // While searching, every row is already a deliberate result; pinning some of them
                // again at the top would just read as duplicates.
                includeFavoritesSection: !isSearching
            )
        case .favorites:
            // Everything here is a favourite already, so an A–Z split would only put a header above
            // each of a handful of rows. One untitled group instead — the tab is the title.
            guard !matched.isEmpty else { return [] }
            return [ContactSection(title: "", contacts: matched, isFavorites: true)]
        }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    /// The address book itself is empty, as opposed to never having loaded.
    var isEmptyOfContacts: Bool {
        contactsModel.isEmptyOfContacts
    }

    /// This tab has nothing to show: no contacts at all, or no favourites yet.
    var isEmptyOfScopedContacts: Bool {
        state == .loaded && scopedContacts.isEmpty
    }

    private var scopedContacts: [Contact] {
        switch scope {
        case .all:
            contactsModel.contacts
        case .favorites:
            contactsModel.contacts.filter { favorites.favoriteIDs.contains($0.id) }
        }
    }

    // MARK: - Loading

    func loadIfNeeded() async {
        await contactsModel.loadIfNeeded()
    }

    func load() async {
        await contactsModel.load()
    }

    func reloadIfPermissionMayHaveChanged() async {
        await contactsModel.reloadIfPermissionMayHaveChanged()
    }
}
