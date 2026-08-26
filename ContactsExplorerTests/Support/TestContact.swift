//
//  TestContact.swift
//  ContactsExplorerTests
//

import Foundation
@testable import ContactsExplorer

/// Builds `Contact` values for tests without repeating every field at each call site.
enum TestContact {
    static func make(
        id: String = "contact-1",
        givenName: String = "",
        familyName: String = "",
        fullName: String = "Test Contact",
        organizationName: String = "",
        phoneNumbers: [String] = [],
        emails: [String] = [],
        birthday: Date? = nil,
        thumbnailData: Data? = nil
    ) -> Contact {
        Contact(
            id: id,
            givenName: givenName,
            familyName: familyName,
            fullName: fullName,
            organizationName: organizationName,
            phoneNumbers: phoneNumbers.enumerated().map {
                Contact.LabeledValue(index: $0.offset, label: "mobile", value: $0.element)
            },
            emails: emails.enumerated().map {
                Contact.LabeledValue(index: $0.offset, label: "home", value: $0.element)
            },
            birthday: birthday,
            thumbnailData: thumbnailData
        )
    }
}
