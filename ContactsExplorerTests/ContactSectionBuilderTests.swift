//
//  ContactSectionBuilderTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@Suite("ContactSectionBuilder")
struct ContactSectionBuilderTests {
    private let builder = ContactSectionBuilder()

    private let anna = TestContact.make(id: "anna", fullName: "Anna Adams")
    private let alan = TestContact.make(id: "alan", fullName: "Alan Archer")
    private let bella = TestContact.make(id: "bella", fullName: "Bella Brooks")
    private let numeric = TestContact.make(id: "numeric", fullName: "", phoneNumbers: ["058-112-2334"])

    private var contacts: [Contact] { [alan, anna, bella, numeric] }

    @Test("Contacts are grouped under their section title, in the order given")
    func groupsByTitle() {
        let sections = builder.sections(for: contacts, favoriteIDs: [])

        #expect(sections.map(\.title) == ["A", "B", "#"])
        #expect(sections[0].contacts == [alan, anna])
        #expect(sections[1].contacts == [bella])
    }

    @Test("The # bucket comes last even though it would sort first")
    func nonLetterBucketComesLast() {
        // The numeric contact is fed in first, so encounter order alone would put "#" at the top.
        let sections = builder.sections(for: [numeric, alan], favoriteIDs: [])
        #expect(sections.map(\.title) == ["A", "#"])
    }

    @Test("Favourites are pinned into a leading section")
    func favoritesArePinnedFirst() {
        let sections = builder.sections(for: contacts, favoriteIDs: ["bella"])

        #expect(sections.first?.isFavorites == true)
        #expect(sections.first?.title == "Favorites")
        #expect(sections.first?.contacts == [bella])
    }

    // A pinned favourite is a shortcut, not a move: it stays in its letter bucket too, so scrolling
    // to "B" still finds Bella.
    @Test("A pinned favourite remains in its alphabetical section")
    func favoritesAlsoStayInTheirLetterSection() {
        let sections = builder.sections(for: contacts, favoriteIDs: ["bella"])
        let letterB = sections.first { !$0.isFavorites && $0.title == "B" }

        #expect(letterB?.contacts == [bella])
    }

    @Test("No favourites means no favourites section")
    func noFavoritesSectionWhenEmpty() {
        let sections = builder.sections(for: contacts, favoriteIDs: [])
        #expect(sections.allSatisfy { !$0.isFavorites })
    }

    @Test("Favourites that are not in the list are ignored")
    func unknownFavoritesAreIgnored() {
        let sections = builder.sections(for: contacts, favoriteIDs: ["someone-who-left"])
        #expect(sections.allSatisfy { !$0.isFavorites })
    }

    @Test("The favourites section can be suppressed, for search results")
    func favoritesSectionCanBeSuppressed() {
        let sections = builder.sections(
            for: contacts,
            favoriteIDs: ["bella"],
            includeFavoritesSection: false
        )
        #expect(sections.allSatisfy { !$0.isFavorites })
        #expect(sections.map(\.title) == ["A", "B", "#"])
    }

    @Test("Sections have distinct identities so SwiftUI can diff them")
    func sectionIdentitiesAreDistinct() {
        let sections = builder.sections(for: contacts, favoriteIDs: ["bella"])
        #expect(Set(sections.map(\.id)).count == sections.count)
    }
}
