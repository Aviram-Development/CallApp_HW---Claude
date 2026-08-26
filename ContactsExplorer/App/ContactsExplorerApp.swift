//
//  ContactsExplorerApp.swift
//  ContactsExplorer
//

import SwiftUI

@main
struct ContactsExplorerApp: App {
    /// Built once, here, and passed down explicitly from this point on.
    private let dependencies: AppDependencies

    @State private var favorites: FavoritesModel

    init() {
        let dependencies = AppDependencies.live()
        self.dependencies = dependencies
        _favorites = State(wrappedValue: FavoritesModel(favoritesStore: dependencies.favoritesStore))
    }

    var body: some Scene {
        WindowGroup {
            ContactsListView(dependencies: dependencies, favorites: favorites)
        }
    }
}
