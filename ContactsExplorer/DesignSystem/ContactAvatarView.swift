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
            if let image = decodedImage {
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

    /// Goes through `ContactImageCache` rather than calling `UIImage(data:)` here: `body` runs on
    /// every re-evaluation of the row, and decoding the same photo each time is what made scrolling
    /// a list of contacts with photos stutter.
    private var decodedImage: UIImage? {
        if let imageData {
            return ContactImageCache.image(for: contact.id, kind: .full, data: imageData)
        }
        guard let thumbnailData = contact.thumbnailData else { return nil }
        return ContactImageCache.image(for: contact.id, kind: .thumbnail, data: thumbnailData)
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

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
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
#endif
