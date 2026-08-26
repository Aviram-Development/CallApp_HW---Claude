//
//  ContactRow.swift
//  ContactsExplorer
//

import SwiftUI

struct ContactRow: View {
    let contact: Contact
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ContactAvatarView(contact: contact, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            // The name and its subtitle are one thing to read out; the star stays separate so it
            // remains its own action.
            .accessibilityElement(children: .combine)

            Spacer(minLength: 8)

            FavoriteButton(isFavorite: isFavorite, action: onToggleFavorite)
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    /// The first phone number, or failing that the organization — whichever adds something the
    /// display name has not already said.
    private var subtitle: String? {
        if let phoneNumber = contact.phoneNumbers.first {
            return phoneNumber.value
        }
        let organization = contact.organizationName
        return organization.isEmpty || organization == contact.displayName ? nil : organization
    }
}

#Preview {
    List(PreviewData.contacts()) { contact in
        ContactRow(contact: contact, isFavorite: contact.id == "contact-emma") {}
    }
    .listStyle(.plain)
}
