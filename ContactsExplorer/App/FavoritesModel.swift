//
//  FavoritesModel.swift
//  ContactsExplorer
//

import Foundation

/// The favourite contacts, shared by every screen that can change them.
///
/// One object owns the set, so starring a contact on the detail screen is immediately reflected in
/// the list behind it. The alternative — each screen keeping its own copy — is exactly the drift this
/// exists to prevent.
@MainActor
@Observable
final class FavoritesModel {
    private(set) var favoriteIDs: Set<String>

    private let toggleFavorite: ToggleFavoriteUseCase

    init(favoritesStore: FavoritesStore) {
        self.favoriteIDs = favoritesStore.load()
        self.toggleFavorite = ToggleFavoriteUseCase(favoritesStore: favoritesStore)
    }

    func isFavorite(_ contact: Contact) -> Bool {
        favoriteIDs.contains(contact.id)
    }

    func toggle(_ contact: Contact) {
        favoriteIDs = toggleFavorite(contactID: contact.id, in: favoriteIDs)
    }
}
