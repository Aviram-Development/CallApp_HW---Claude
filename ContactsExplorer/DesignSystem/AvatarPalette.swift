//
//  AvatarPalette.swift
//  ContactsExplorer
//

import SwiftUI

/// Assigns each contact without a photo a stable colour, so the list reads as a set of distinct
/// people rather than a column of identical grey circles.
nonisolated enum AvatarPalette {
    private static let colors: [Color] = [
        .blue, .indigo, .purple, .pink, .red, .orange, .brown, .teal, .green, .cyan
    ]

    static func color(for contact: Contact) -> Color {
        colors[stableHash(of: contact.id) % colors.count]
    }

    /// A hand-rolled FNV-1a hash rather than `String.hashValue`.
    ///
    /// Swift seeds `Hashable` randomly per process, so using it here would give a contact a
    /// different colour every time the app launched.
    private static func stableHash(of string: String) -> Int {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(Int.max))
    }
}
