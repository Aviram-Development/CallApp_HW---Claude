//
//  ContactSectionBuilder.swift
//  ContactsExplorer
//

import Foundation

/// One rendered group in the contacts list: an A–Z bucket, or the pinned favourites group.
nonisolated struct ContactSection: Identifiable, Hashable {
    /// The title shown in the section header and in the index bar.
    let title: String
    let contacts: [Contact]
    /// Whether this is the pinned favourites group rather than an alphabetical bucket.
    let isFavorites: Bool

    var id: String { isFavorites ? "\u{2605}" : title }
}

/// Groups a sorted list of contacts into the sections the list renders.
///
/// Pure, like `ContactSearchMatcher`, so the grouping rules can be asserted directly rather than
/// inferred from a screenshot.
nonisolated struct ContactSectionBuilder {
    /// The bucket for contacts whose name does not begin with a letter, or who have no name.
    static let nonLetterTitle = Contact.nonLetterSectionTitle
    static let favoritesTitle = "Favorites"

    /// - Parameters:
    ///   - contacts: in display order, as returned by `LoadContactsUseCase`. Grouping preserves
    ///     that order rather than re-deriving it, so this stays cheap enough to run per keystroke.
    ///   - favoriteIDs: identifiers to pin into a leading favourites section.
    ///   - includeFavoritesSection: pass `false` while searching. Favourites are duplicated into the
    ///     pinned section *and* left in their letter bucket, which reads as a shortcut when browsing
    ///     but would look like duplicate results in a filtered list.
    func sections(
        for contacts: [Contact],
        favoriteIDs: Set<String>,
        includeFavoritesSection: Bool = true
    ) -> [ContactSection] {
        var sections: [ContactSection] = []

        if includeFavoritesSection {
            let favorites = contacts.filter { favoriteIDs.contains($0.id) }
            if !favorites.isEmpty {
                sections.append(
                    ContactSection(title: Self.favoritesTitle, contacts: favorites, isFavorites: true)
                )
            }
        }

        // Group by section title, keeping the order in which each title was first seen so the
        // sections follow the caller's sort rather than a re-sort of the keys.
        var order: [String] = []
        var grouped: [String: [Contact]] = [:]
        for contact in contacts {
            let title = contact.sectionTitle
            if grouped[title] == nil {
                order.append(title)
            }
            grouped[title, default: []].append(contact)
        }

        // "#" sorts before "A" but belongs at the bottom of an index, the way Contacts shows it.
        let letterTitles = order.filter { $0 != Self.nonLetterTitle }
        let titles = letterTitles + order.filter { $0 == Self.nonLetterTitle }

        sections.append(
            contentsOf: titles.map { title in
                ContactSection(title: title, contacts: grouped[title] ?? [], isFavorites: false)
            }
        )
        return sections
    }
}
