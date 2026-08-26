//
//  AppDependencies.swift
//  ContactsExplorer
//

import Foundation

/// The app's services, resolved once at launch and handed down by initializer injection.
///
/// A plain value passed explicitly rather than a global singleton or an environment lookup: nothing
/// can reach a service it was not given, which is what makes every view model constructible in a
/// test with fakes in place of the device address book.
nonisolated struct AppDependencies {
    let contactsRepository: ContactsRepository
    let favoritesStore: FavoritesStore

    static func live() -> AppDependencies {
        AppDependencies(
            contactsRepository: CNContactsRepository(),
            favoritesStore: UserDefaultsFavoritesStore()
        )
    }
}
