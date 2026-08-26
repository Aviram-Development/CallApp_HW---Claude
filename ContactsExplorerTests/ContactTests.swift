//
//  ContactTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@Suite("Contact")
struct ContactTests {
    // MARK: - Identity

    // Regression test. `Contact` used to rely on synthesized `Hashable`, which folded in
    // `LabeledValue.id` — a fresh `UUID` per initialization. Two fetches of the same contact
    // therefore never compared equal, which broke `List` diffing and `NavigationStack` matching.
    @Test("Two contacts built from identical data are equal and hash alike")
    func identicalContactsAreEqual() {
        let first = ContactTests.make(id: "abc")
        let second = ContactTests.make(id: "abc")

        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        #expect(Set([first, second]).count == 1)
    }

    @Test("Identity is the contact id, not the payload")
    func identityIgnoresPayload() {
        let original = ContactTests.make(id: "abc", givenName: "Emma", thumbnailData: Data([0x01]))
        let renamed = ContactTests.make(id: "abc", givenName: "Emily", thumbnailData: Data([0x02]))
        let other = ContactTests.make(id: "xyz", givenName: "Emma")

        #expect(original == renamed)
        #expect(original != other)
    }

    @Test("Re-created labeled values keep a stable identity")
    func labeledValueIdentityIsStable() {
        let first = Contact.LabeledValue(index: 0, label: "mobile", value: "555")
        let second = Contact.LabeledValue(index: 0, label: "mobile", value: "555")
        let sameValueLaterInTheList = Contact.LabeledValue(index: 1, label: "mobile", value: "555")

        #expect(first == second)
        #expect(first.id == second.id)
        // A duplicated entry on one card still gets its own identity, so `ForEach` stays well-defined.
        #expect(first.id != sameValueLaterInTheList.id)
    }

    // MARK: - displayName

    @Test("displayName prefers the formatted full name")
    func displayNamePrefersFullName() {
        let contact = ContactTests.make(fullName: "Emma Stone", organizationName: "Willow Studio")
        #expect(contact.displayName == "Emma Stone")
    }

    @Test("displayName falls back to the organization when there is no person name")
    func displayNameFallsBackToOrganization() {
        let contact = ContactTests.make(fullName: "", organizationName: "Pizza Palace")
        #expect(contact.displayName == "Pizza Palace")
    }

    @Test("displayName falls back to the first phone number")
    func displayNameFallsBackToPhoneNumber() {
        let contact = ContactTests.make(
            fullName: "",
            organizationName: "",
            phoneNumbers: [Contact.LabeledValue(index: 0, label: "mobile", value: "058-112-2334")],
            emails: [Contact.LabeledValue(index: 0, label: "home", value: "nobody@example.com")]
        )
        #expect(contact.displayName == "058-112-2334")
    }

    @Test("displayName falls back to the first email when there is no phone number")
    func displayNameFallsBackToEmail() {
        let contact = ContactTests.make(
            fullName: "",
            organizationName: "",
            emails: [Contact.LabeledValue(index: 0, label: "home", value: "nobody@example.com")]
        )
        #expect(contact.displayName == "nobody@example.com")
    }

    @Test("displayName has a last resort")
    func displayNameLastResort() {
        #expect(ContactTests.make(fullName: "", organizationName: "").displayName == "No Name")
    }

    // MARK: - initials

    @Test("initials combine the given and family names")
    func initialsCombineNames() {
        #expect(ContactTests.make(givenName: "Emma", familyName: "Stone").initials == "ES")
    }

    @Test("initials use whichever name is present")
    func initialsUseWhicheverNameIsPresent() {
        #expect(ContactTests.make(givenName: "Olivia", familyName: "").initials == "O")
        #expect(ContactTests.make(givenName: "", familyName: "Stone").initials == "S")
    }

    @Test("initials fall back to the organization, then to a placeholder")
    func initialsFallBack() {
        let organization = ContactTests.make(givenName: "", familyName: "", organizationName: "Pizza Palace")
        #expect(organization.initials == "P")
        #expect(ContactTests.make(givenName: "", familyName: "", organizationName: "").initials == "#")
    }

    // MARK: - Sorting and sectioning

    @Test("sortKey ignores case and diacritics so sorting does not split accented names")
    func sortKeyIsFolded() {
        #expect(ContactTests.make(fullName: "Émile Zola").sortKey == "emile zola")
    }

    @Test(
        "sectionTitle is the first letter of the displayed name",
        arguments: [
            ("Emma Stone", "E"),
            ("émile Zola", "E"),
            ("pizza Palace", "P")
        ]
    )
    func sectionTitleUsesFirstLetter(fullName: String, expected: String) {
        #expect(ContactTests.make(fullName: fullName).sectionTitle == expected)
    }

    @Test("Names that do not start with a letter are filed under #")
    func sectionTitleFallsBackToHash() {
        let phoneOnly = ContactTests.make(
            fullName: "",
            organizationName: "",
            phoneNumbers: [Contact.LabeledValue(index: 0, label: "mobile", value: "058-112-2334")]
        )
        #expect(phoneOnly.sectionTitle == "#")
    }

    // Regression test. Sectioning used to key off `displayName`, so a card with nothing to show
    // fell back to the "No Name" placeholder and filed under N, next to Noah and Nadia -- and would
    // have moved to a different letter entirely the moment that string was localized.
    @Test("A nameless contact files under # rather than under its placeholder label")
    func namelessContactFilesUnderHash() {
        let nameless = ContactTests.make(fullName: "", organizationName: "")

        #expect(nameless.displayName == "No Name")
        #expect(nameless.sectionTitle == "#")
        #expect(nameless.sortKey.isEmpty)
    }

    // MARK: - Helper

    private static func make(
        id: String = "contact-1",
        givenName: String = "Emma",
        familyName: String = "Stone",
        fullName: String = "Emma Stone",
        organizationName: String = "",
        phoneNumbers: [Contact.LabeledValue] = [],
        emails: [Contact.LabeledValue] = [],
        birthday: Date? = nil,
        thumbnailData: Data? = nil
    ) -> Contact {
        Contact(
            id: id,
            givenName: givenName,
            familyName: familyName,
            fullName: fullName,
            organizationName: organizationName,
            phoneNumbers: phoneNumbers,
            emails: emails,
            birthday: birthday,
            thumbnailData: thumbnailData
        )
    }
}
