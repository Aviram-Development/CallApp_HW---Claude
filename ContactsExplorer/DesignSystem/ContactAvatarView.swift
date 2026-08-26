//
//  ContactAvatarView.swift
//  ContactsExplorer
//

import SwiftUI

/// A contact's photo, or their initials on a colour derived from their identifier.
struct ContactAvatarView: View {
    let contact: Contact
    /// A higher-resolution image to prefer over the contact's thumbnail, once one has loaded.
    var imageData: Data?
    let size: CGFloat

    init(contact: Contact, imageData: Data? = nil, size: CGFloat) {
        self.contact = contact
        self.imageData = imageData
        self.size = size
    }

    var body: some View {
        Group {
            if let data = imageData ?? contact.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                initialsAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        // The photo is decorative; the row already announces the contact's name.
        .accessibilityHidden(true)
    }

    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(AvatarPalette.color(for: contact).gradient)
            Text(contact.initials)
                .font(.system(size: size * 0.4, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

#Preview("With photo") {
    ContactAvatarView(contact: PreviewData.contact(), size: 120)
}

#Preview("Initials") {
    VStack(spacing: 16) {
        ForEach(PreviewData.contacts()) { contact in
            ContactAvatarView(contact: contact, size: 44)
        }
    }
}
