//
//  ContactSearchMatcherTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@Suite("ContactSearchMatcher")
struct ContactSearchMatcherTests {
    private let matcher = ContactSearchMatcher()

    private let emma = TestContact.make(
        id: "emma",
        givenName: "Emma",
        familyName: "Stone",
        fullName: "Emma Stone",
        organizationName: "Willow Studio",
        phoneNumbers: ["+972 54-123-4567", "03-612-3456"]
    )
    private let james = TestContact.make(
        id: "james",
        givenName: "James",
        familyName: "Chen",
        fullName: "James Chen",
        phoneNumbers: ["(212) 555-0187"]
    )
    private let emile = TestContact.make(id: "emile", fullName: "Émile Zola")

    private var contacts: [Contact] { [emma, james, emile] }

    // MARK: - Empty query

    @Test("An empty query returns everything untouched")
    func emptyQueryReturnsEverything() {
        #expect(matcher.filter(contacts, query: "") == contacts)
        #expect(matcher.filter(contacts, query: "   ") == contacts)
    }

    // MARK: - Name matching

    @Test("Names match on a substring, ignoring case")
    func nameMatchesSubstringIgnoringCase() {
        #expect(matcher.filter(contacts, query: "stone") == [emma])
        #expect(matcher.filter(contacts, query: "EMMA") == [emma])
        #expect(matcher.filter(contacts, query: "en") == [james])
    }

    @Test("Names match regardless of diacritics, in either direction")
    func nameMatchesIgnoringDiacritics() {
        #expect(matcher.filter(contacts, query: "emile") == [emile])
        #expect(matcher.filter(contacts, query: "Émile") == [emile])
    }

    @Test("The organization is searchable even when the contact has a name of its own")
    func organizationIsSearchable() {
        #expect(matcher.filter(contacts, query: "Willow") == [emma])
    }

    @Test("A query that matches nothing returns nothing")
    func noMatches() {
        #expect(matcher.filter(contacts, query: "zzzz").isEmpty)
    }

    // MARK: - Phone matching

    @Test("Phone numbers match on digits, across different formatting")
    func phoneMatchesAcrossFormatting() {
        #expect(matcher.filter(contacts, query: "541234567") == [emma])
        #expect(matcher.filter(contacts, query: "2125550187") == [james])
    }

    @Test("Punctuation in the query is ignored")
    func phoneQueryPunctuationIgnored() {
        #expect(matcher.filter(contacts, query: "(212) 555") == [james])
        #expect(matcher.filter(contacts, query: "+972 54") == [emma])
    }

    @Test("A partial number matches anywhere in the stored number")
    func phoneMatchesPartial() {
        #expect(matcher.filter(contacts, query: "6123") == [emma])
    }

    // Regression guard on the ordering inside `matches`. Stripping a text query to its digits leaves
    // an empty string, and every phone number contains the empty string — so without the
    // "does this look like a phone number?" gate, any text query would match every contact that has
    // a number at all.
    @Test("A text query is never treated as a phone number")
    func textQueryIsNotAPhoneQuery() {
        #expect(matcher.filter(contacts, query: "Zola") == [emile])
    }

    @Test("A contact with no phone numbers is simply not a phone match")
    func contactWithoutPhoneNumbers() {
        #expect(matcher.filter(contacts, query: "555") == [james])
    }
}
