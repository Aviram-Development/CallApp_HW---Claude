//
//  Contact+CNContact.swift
//  ContactsExplorer
//

import Contacts

nonisolated extension Contact {
    init(_ cnContact: CNContact) {
        id = cnContact.identifier
        givenName = cnContact.givenName
        familyName = cnContact.familyName
        fullName = CNContactFormatter.string(from: cnContact, style: .fullName) ?? ""
        organizationName = cnContact.organizationName
        phoneNumbers = cnContact.phoneNumbers.enumerated().map { index, phoneNumber in
            LabeledValue(
                index: index,
                label: phoneNumber.label.map { CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: $0) } ?? "phone",
                value: phoneNumber.value.stringValue
            )
        }
        emails = cnContact.emailAddresses.enumerated().map { index, email in
            LabeledValue(
                index: index,
                label: email.label.map { CNLabeledValue<NSString>.localizedString(forLabel: $0) } ?? "email",
                value: email.value as String
            )
        }
        birthday = cnContact.birthday.flatMap { Calendar.current.date(from: $0) }
        thumbnailData = cnContact.thumbnailImageData
    }

    /// Every key the `Contact` initializer above reads. Asking `CNContactStore` for a key that is not
    /// in this list throws at access time, so the two must be kept in step.
    ///
    /// `CNContactFormatter.descriptorForRequiredKeys` is load-bearing: `fullName` is produced by the
    /// formatter, which needs its own set of keys beyond the given/family name.
    static var fetchKeys: [CNKeyDescriptor] {
        [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]
    }
}
