//
//  ContactImageCache.swift
//  ContactsExplorer
//

import UIKit

/// Decoded contact photos, kept so that a row does not re-decode its image on every render.
///
/// `UIImage(data:)` was previously called straight from `ContactAvatarView.body`, which runs on the
/// main actor every time a row is re-evaluated — scrolling, favouriting, or typing a character into
/// the search field. Each pass re-decoded the same JPEG from scratch. With the cache in front of it
/// a given photo is decoded once and then handed back.
///
/// `@MainActor` rather than relying on `NSCache`'s own thread safety: the only caller is a view
/// body, and actor isolation is a stronger guarantee than a footnote.
@MainActor
enum ContactImageCache {
    /// Distinguishes the list thumbnail from the full-resolution photo, which are different images
    /// for the same contact and must not share an entry.
    enum Kind: String {
        case thumbnail
        case full
    }

    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        // Roughly a few screens' worth of rows, plus the detail photos visited along the way.
        // `NSCache` also evicts under memory pressure on its own.
        cache.countLimit = 200
        return cache
    }()

    /// The decoded image for one contact, decoding it only if it is not already cached.
    static func image(for contactID: String, kind: Kind, data: Data) -> UIImage? {
        let key = "\(contactID)\u{1}\(kind.rawValue)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
