//
//  Contact.swift
//  ContactsExplorer
//

import Foundation

/// A contact, as the app understands it.
///
/// Deliberately free of any `Contacts` import: the mapping from `CNContact` lives in
/// `Contact+CNContact.swift`, which keeps the domain model — and everything that reasons about it —
/// testable without the Contacts framework or a permission prompt.
nonisolated struct Contact: Identifiable {
    /// One labelled entry from a contact card, such as a phone number or an email address.
    struct LabeledValue: Identifiable, Hashable {
        /// Derived from the entry's position and content rather than a fresh `UUID`, so that
        /// re-fetching the same contact produces the same identity and SwiftUI can diff it.
        let id: String
        let label: String
        let value: String

        init(index: Int, label: String, value: String) {
            self.id = "\(index)\u{1}\(label)\u{1}\(value)"
            self.label = label
            self.value = value
        }
    }

    /// Shown in place of a name when a card carries nothing at all to identify it by.
    static let noNamePlaceholder = "No Name"

    /// The bucket for contacts whose name does not begin with a letter, and for those with no name.
    static let nonLetterSectionTitle = "#"

    let id: String
    let givenName: String
    let familyName: String
    let fullName: String
    let organizationName: String
    let phoneNumbers: [LabeledValue]
    let emails: [LabeledValue]
    let birthday: Date?
    let thumbnailData: Data?

    /// The name to show for this contact, resolved once.
    let displayName: String

    /// `displayName` folded for comparison, and the basis of `sectionTitle`.
    ///
    /// Stored, not computed. It used to be evaluated inside the fetch's sort comparator, which meant
    /// one `folding(options:locale:)` allocation *per comparison* — O(n log n) of them per fetch —
    /// and once more per contact on every render, since `sections` is recomputed each body pass.
    let sortKey: String

    /// The A–Z index title for this contact. Anything that does not begin with a letter, including
    /// a card with no name at all, files under "#".
    let sectionTitle: String

    init(
        id: String,
        givenName: String,
        familyName: String,
        fullName: String,
        organizationName: String,
        phoneNumbers: [LabeledValue],
        emails: [LabeledValue],
        birthday: Date?,
        thumbnailData: Data?
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.fullName = fullName
        self.organizationName = organizationName
        self.phoneNumbers = phoneNumbers
        self.emails = emails
        self.birthday = birthday
        self.thumbnailData = thumbnailData

        let name = Self.resolvedName(
            fullName: fullName,
            organizationName: organizationName,
            phoneNumbers: phoneNumbers,
            emails: emails
        )
        self.displayName = name ?? Self.noNamePlaceholder

        // Note this folds the *resolved* name, not `displayName`. Sectioning off the placeholder
        // would file every nameless card under "N" for "No Name", next to Noah and Nadia — and would
        // move them to a different letter the moment the placeholder is localized.
        let sortKey = (name ?? "").folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: .current
        )
        self.sortKey = sortKey

        if let first = sortKey.first, first.isLetter {
            self.sectionTitle = String(first).uppercased()
        } else {
            self.sectionTitle = Self.nonLetterSectionTitle
        }
    }

    /// The best name this card can offer, or `nil` when it has none.
    ///
    /// Kept separate from `displayName` so that sectioning can tell "has no name" apart from
    /// "is named No Name".
    private static func resolvedName(
        fullName: String,
        organizationName: String,
        phoneNumbers: [LabeledValue],
        emails: [LabeledValue]
    ) -> String? {
        if !fullName.isEmpty {
            return fullName
        }
        if !organizationName.isEmpty {
            return organizationName
        }
        return phoneNumbers.first?.value ?? emails.first?.value
    }

    var initials: String {
        let nameInitials = [givenName.first, familyName.first].compactMap { $0 }
        if !nameInitials.isEmpty {
            return String(nameInitials).uppercased()
        }
        if let organizationInitial = organizationName.first {
            return String(organizationInitial).uppercased()
        }
        return Self.nonLetterSectionTitle
    }

    /// Orders contacts the way the list displays them: by `sortKey`, so that sort order and section
    /// headers can never disagree.
    ///
    /// Lives here rather than in a repository so there is one definition of display order, applied
    /// once, that no new repository implementation can forget.
    static func isOrderedBefore(_ lhs: Contact, _ rhs: Contact) -> Bool {
        lhs.sortKey.localizedStandardCompare(rhs.sortKey) == .orderedAscending
    }
}

// Identity is the contact identifier and nothing else. The synthesized conformance would have folded
// in every stored property — including `thumbnailData`, so each comparison hashed a whole image, and
// the per-instance `LabeledValue` identities, so no two fetches of the same contact ever compared
// equal. That broke `List` diffing and `NavigationStack` path matching alike.
nonisolated extension Contact: Hashable {
    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
