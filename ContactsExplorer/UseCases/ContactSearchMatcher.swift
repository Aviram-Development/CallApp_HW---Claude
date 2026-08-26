//
//  ContactSearchMatcher.swift
//  ContactsExplorer
//

import Foundation

/// Decides which contacts a search query matches.
///
/// A pure value type over plain values: no view, no store, no framework. That is the whole point of
/// pulling it out — this logic previously lived inside `ContactsListView`, where it could not be
/// tested and where a stray `print` ran once per contact per keystroke.
nonisolated struct ContactSearchMatcher {
    private static let nameComparison: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    /// Characters that may appear in a written phone number alongside the digits.
    private static let phonePunctuation = CharacterSet(charactersIn: "+-(). ")

    func filter(_ contacts: [Contact], query: String) -> [Contact] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return contacts }
        return contacts.filter { matches($0, query: query) }
    }

    func matches(_ contact: Contact, query: String) -> Bool {
        if matchesName(contact, query: query) {
            return true
        }
        // Only fall through to a digit comparison when the query actually looks like a phone number.
        // Without this, typing "Emma" would strip to an empty digit string and match every contact
        // that has a phone number at all.
        guard isPhoneNumberQuery(query) else { return false }
        return matchesPhoneNumber(contact, query: query)
    }

    private func matchesName(_ contact: Contact, query: String) -> Bool {
        // The organization is included so that searching a company name finds the people who work
        // there, not only cards that have no person name of their own.
        let haystacks = [contact.displayName, contact.organizationName]
        return haystacks.contains { $0.range(of: query, options: Self.nameComparison) != nil }
    }

    private func matchesPhoneNumber(_ contact: Contact, query: String) -> Bool {
        let queryDigits = Self.digits(of: query)
        guard !queryDigits.isEmpty else { return false }
        // Compare digits only, so "0541234567" finds a number stored as "+972 54-123-4567".
        return contact.phoneNumbers.contains { Self.digits(of: $0.value).contains(queryDigits) }
    }

    private func isPhoneNumberQuery(_ query: String) -> Bool {
        query.contains(where: \.isWholeNumber)
            && query.unicodeScalars.allSatisfy { $0.properties.numericType != nil || Self.phonePunctuation.contains($0) }
    }

    private static func digits(of string: String) -> String {
        String(string.filter(\.isWholeNumber))
    }
}
