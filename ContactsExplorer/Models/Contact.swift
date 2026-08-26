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

    let id: String
    let givenName: String
    let familyName: String
    let fullName: String
    let organizationName: String
    let phoneNumbers: [LabeledValue]
    let emails: [LabeledValue]
    let birthday: Date?
    let thumbnailData: Data?

    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        }
        if !organizationName.isEmpty {
            return organizationName
        }
        return phoneNumbers.first?.value ?? emails.first?.value ?? "No Name"
    }

    var initials: String {
        let nameInitials = [givenName.first, familyName.first].compactMap { $0 }
        if !nameInitials.isEmpty {
            return String(nameInitials).uppercased()
        }
        if let organizationInitial = organizationName.first {
            return String(organizationInitial).uppercased()
        }
        return "#"
    }

    /// Sorting and sectioning both key off `displayName`, so a contact always files under the letter
    /// it visibly starts with. `CNContactFormatter` already honours the user's given/family display
    /// order preference, so this follows that preference rather than fighting it.
    var sortKey: String {
        displayName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    /// The A–Z index title for this contact; anything not starting with a letter files under "#".
    var sectionTitle: String {
        guard let first = sortKey.first, first.isLetter else { return "#" }
        return String(first).uppercased()
    }
}

// Identity is the contact identifier and nothing else. The synthesized conformance would have folded
// in every stored property — including `thumbnailData`, so each comparison hashed a whole image, and
// the per-instance `LabeledValue` identities, so no two fetches of the same contact ever compared
// equal. That broke `List` diffing and `NavigationStack` path matching alike.
extension Contact: Hashable {
    nonisolated static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
