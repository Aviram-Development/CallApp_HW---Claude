//
//  ContactsListView.swift
//  ContactsExplorer
//

import SwiftUI

struct ContactsListView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @State private var viewModel: ContactsListViewModel
    @State private var path: [Contact] = []

    private let dependencies: AppDependencies

    init(
        dependencies: AppDependencies,
        contacts: ContactsModel,
        favorites: FavoritesModel,
        scope: ContactsListViewModel.Scope = .all
    ) {
        self.dependencies = dependencies
        _viewModel = State(
            wrappedValue: ContactsListViewModel(contacts: contacts, favorites: favorites, scope: scope)
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(title)
                .navigationDestination(for: Contact.self) { contact in
                    ContactDetailView(
                        contact: contact,
                        dependencies: dependencies,
                        favorites: viewModel.favorites
                    )
                }
        }
        .task {
            // Idempotent, and both tabs share one `ContactsModel`, so whichever appears first loads
            // and the other simply finds the contacts already there.
            await viewModel.loadIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings having granted access should just work, rather than leaving
            // the user on the permission screen wondering what else to press.
            guard phase == .active else { return }
            Task { await viewModel.reloadIfPermissionMayHaveChanged() }
        }
    }

    private var title: String {
        switch viewModel.scope {
        case .all: "Contacts"
        case .favorites: "Favorites"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading Contacts…")
        case .permissionDenied:
            permissionDeniedView
        case .failed:
            failedView
        case .loaded:
            loadedView
        }
    }

    @ViewBuilder
    private var loadedView: some View {
        if viewModel.isEmptyOfScopedContacts {
            emptyView
        } else {
            contactsList
        }
    }

    private var contactsList: some View {
        // Read once per render and pass the result around. The previous implementation recomputed
        // its filtered list twice on every render: once to build the rows and once to decide whether
        // to show the empty state.
        let sections = viewModel.sections

        return ScrollViewReader { proxy in
            List {
                ForEach(sections) { section in
                    // The favourites tab is one untitled group -- the tab bar already names it, and
                    // a header over every row would only add noise.
                    if section.title.isEmpty {
                        Section { rows(for: section) }.id(section.id)
                    } else {
                        Section {
                            rows(for: section)
                        } header: {
                            Text(section.title)
                        }
                        .id(section.id)
                    }
                }
            }
            .listStyle(.plain)
            // A safe-area inset rather than an overlay, so the bar reserves its own column instead
            // of floating over the disclosure chevrons at the end of each row.
            .safeAreaInset(edge: .trailing, spacing: 0) {
                if let indexTitles = indexTitles(for: sections) {
                    SectionIndexBar(titles: indexTitles) { title in
                        withAnimation { proxy.scrollTo(title, anchor: .top) }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
        // Pinned under the navigation title, the way Contacts does it, rather than hidden above the
        // first row until the list is dragged down. `.automatic` would also hand the field to the
        // tab bar on iOS 26, which is not where this app wants it.
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Name or phone number"
        )
        // Contact names are proper nouns and phone numbers are not words, so neither
        // autocapitalization nor autocorrection has anything useful to contribute here.
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .overlay {
            if viewModel.isSearching && sections.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func rows(for section: ContactSection) -> some View {
        ForEach(section.contacts) { contact in
            NavigationLink(value: contact) {
                ContactRow(
                    contact: contact,
                    isFavorite: viewModel.favorites.isFavorite(contact),
                    onToggleFavorite: { viewModel.favorites.toggle(contact) }
                )
            }
            // A favourited contact appears both in the pinned section and in its
            // letter section, so identity has to include which section it is in.
            .id("\(section.id)-\(contact.id)")
        }
    }

    /// The index bar earns its space only when browsing a list long enough to need it.
    private func indexTitles(for sections: [ContactSection]) -> [String]? {
        guard !viewModel.isSearching, sections.count > 2 else { return nil }
        return sections.map(\.id)
    }

    @ViewBuilder
    private var emptyView: some View {
        switch viewModel.scope {
        case .all:
            ContentUnavailableView {
                Label("No Contacts", systemImage: "person.crop.circle.badge.questionmark")
            } description: {
                Text("Contacts you add on this device will appear here.")
            }
        case .favorites:
            ContentUnavailableView {
                Label("No Favorites", systemImage: "star")
            } description: {
                Text("Star a contact to keep it here.")
            }
        }
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("No Access to Contacts", systemImage: "lock")
        } description: {
            Text("Allow access to your contacts in Settings to see them here.")
        } actions: {
            Button("Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(url)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label("Something Went Wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Your contacts could not be loaded. Please try again.")
        } actions: {
            Button("Try Again") {
                Task { await viewModel.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview("Loaded") {
    let dependencies = AppDependencies.preview()
    ContactsListView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}

#Preview("Favorites scope") {
    let dependencies = AppDependencies.preview()
    ContactsListView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore),
        scope: .favorites
    )
}

#Preview("No favorites yet") {
    let dependencies = AppDependencies.preview(favoriteIDs: [])
    ContactsListView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore),
        scope: .favorites
    )
}

#Preview("Permission denied") {
    let dependencies = AppDependencies.preview(authorizationStatus: .denied)
    ContactsListView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}

#Preview("Empty address book") {
    let dependencies = AppDependencies.preview(contacts: [])
    ContactsListView(
        dependencies: dependencies,
        contacts: ContactsModel(dependencies: dependencies),
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}
#endif
