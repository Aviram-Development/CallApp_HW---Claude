//
//  ToggleFavoriteUseCase.swift
//  ContactsExplorer
//

import Foundation

/// Flips one contact's favourite state and persists the result.
///
/// Returns the new set rather than mutating shared state, so there is exactly one place that decides
/// what "toggled" means and the view model simply adopts the answer. Both the list and the detail
/// screen route through this, which is what keeps the star consistent between them.
nonisolated struct ToggleFavoriteUseCase {
    private let favoritesStore: FavoritesStore

    init(favoritesStore: FavoritesStore) {
        self.favoritesStore = favoritesStore
    }

    func callAsFunction(contactID: String, in favoriteIDs: Set<String>) -> Set<String> {
        var updated = favoriteIDs
        if updated.contains(contactID) {
            updated.remove(contactID)
        } else {
            updated.insert(contactID)
        }
        favoritesStore.save(updated)
        return updated
    }
}
