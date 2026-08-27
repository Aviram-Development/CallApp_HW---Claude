//
//  ContactsExplorerApp.swift
//  ContactsExplorer
//

import SwiftUI

@main
struct ContactsExplorerApp: App {
    /// Built once, here, and passed down explicitly from this point on.
    private let dependencies: AppDependencies

    /// Owned here rather than by either tab, so the address book is fetched once and both tabs --
    /// and any tab added later -- read the same contacts and the same favourites.
    @State private var contacts: ContactsModel
    @State private var favorites: FavoritesModel

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _contacts = State(wrappedValue: ContactsModel(dependencies: dependencies))
        _favorites = State(wrappedValue: FavoritesModel(favoritesStore: dependencies.favoritesStore))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(dependencies: dependencies, contacts: contacts, favorites: favorites)
        }
    }
}
