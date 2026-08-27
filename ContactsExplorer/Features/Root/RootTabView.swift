//
//  RootTabView.swift
//  ContactsExplorer
//

import SwiftUI

/// The app's tab bar.
///
/// Both tabs are the same screen over a different slice of one shared `ContactsModel`, so switching
/// between them costs nothing and a star toggled in either is immediately reflected in the other.
/// Each tab keeps its own `NavigationStack`, which is what preserves a tab's place when you leave and
/// come back to it.
struct RootTabView: View {
    /// Adding a tab means a case here and a `Tab` below; nothing else has to know.
    enum Section: Hashable {
        case favorites
        case contacts
    }

    let dependencies: AppDependencies
    let contacts: ContactsModel
    let favorites: FavoritesModel

    @State private var selection: Section = .contacts

    var body: some View {
        TabView(selection: $selection) {
            Tab("Favorites", systemImage: "star.fill", value: Section.favorites) {
                ContactsListView(
                    dependencies: dependencies,
                    contacts: contacts,
                    favorites: favorites,
                    scope: .favorites
                )
            }

            Tab("Contacts", systemImage: "person.crop.circle.fill", value: Section.contacts) {
                ContactsListView(
                    dependencies: dependencies,
                    contacts: contacts,
                    favorites: favorites,
                    scope: .all
                )
            }
        }
    }
}

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview {
    let dependencies = AppDependencies.preview()
    RootTabView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}
#endif
