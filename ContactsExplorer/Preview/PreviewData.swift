//
//  PreviewData.swift
//  ContactsExplorer
//

#if DEBUG
import UIKit

/// Fixtures for SwiftUI previews and tests.
///
/// Wrapped in `#if DEBUG` so none of it — including the UIKit image rendering below — reaches a
/// release build. Its predecessor, `MockGenerator`, shipped in the app target and had no call sites
/// at all, because the project contained no previews to use it.
nonisolated enum PreviewData {
    /// A fully populated contact: two phone numbers, two emails, a birthday and a thumbnail.
    static func contact() -> Contact {
        Contact(
            id: "contact-emma",
            givenName: "Emma",
            familyName: "Stone",
            fullName: "Emma Stone",
            organizationName: "Willow Studio",
            phoneNumbers: [
                Contact.LabeledValue(index: 0, label: "mobile", value: "+972 54-123-4567"),
                Contact.LabeledValue(index: 1, label: "work", value: "03-612-3456")
            ],
            emails: [
                Contact.LabeledValue(index: 0, label: "home", value: "emma@example.com"),
                Contact.LabeledValue(index: 1, label: "work", value: "emma.stone@example.com")
            ],
            birthday: date(year: 1988, month: 11, day: 6),
            thumbnailData: imageData(color: .systemIndigo)
        )
    }

    /// A contact with a name and nothing else — exercises the empty-details branch of the detail view.
    static func bareContact() -> Contact {
        Contact(
            id: "contact-maya",
            givenName: "Maya",
            familyName: "Levi",
            fullName: "Maya Levi",
            organizationName: "",
            phoneNumbers: [],
            emails: [],
            birthday: nil,
            thumbnailData: nil
        )
    }

    /// A spread covering each `displayName` fallback: a full name, a first name only, an
    /// organization with no person name, and a card with nothing but a phone number.
    static func contacts() -> [Contact] {
        [
            contact(),
            Contact(
                id: "contact-james",
                givenName: "James",
                familyName: "Chen",
                fullName: "James Chen",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(index: 0, label: "mobile", value: "(212) 555-0187")],
                emails: [Contact.LabeledValue(index: 0, label: "work", value: "james.chen@example.com")],
                birthday: date(year: 1990, month: 3, day: 14),
                thumbnailData: nil
            ),
            bareContact(),
            Contact(
                id: "contact-noah",
                givenName: "Noah",
                familyName: "Davis",
                fullName: "Noah Davis",
                organizationName: "",
                phoneNumbers: [],
                emails: [Contact.LabeledValue(index: 0, label: "home", value: "noah.davis@example.com")],
                birthday: nil,
                thumbnailData: nil
            ),
            Contact(
                id: "contact-olivia",
                givenName: "Olivia",
                familyName: "",
                fullName: "Olivia",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(index: 0, label: "mobile", value: "052-876-5432")],
                emails: [],
                birthday: nil,
                thumbnailData: imageData(color: .systemTeal)
            ),
            Contact(
                id: "contact-pizza",
                givenName: "",
                familyName: "",
                fullName: "",
                organizationName: "Pizza Palace",
                phoneNumbers: [Contact.LabeledValue(index: 0, label: "main", value: "09-765-4321")],
                emails: [],
                birthday: nil,
                thumbnailData: nil
            ),
            Contact(
                id: "contact-unknown",
                givenName: "",
                familyName: "",
                fullName: "",
                organizationName: "",
                phoneNumbers: [Contact.LabeledValue(index: 0, label: "mobile", value: "058-112-2334")],
                emails: [],
                birthday: nil,
                thumbnailData: nil
            )
        ]
    }

    static func date(year: Int, month: Int, day: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func imageData(color: UIColor) -> Data? {
        let size = CGSize(width: 240, height: 240)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()
    }
}
#endif
