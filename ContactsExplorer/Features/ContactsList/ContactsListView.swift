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

    init(dependencies: AppDependencies, favorites: FavoritesModel) {
        self.dependencies = dependencies
        _viewModel = State(wrappedValue: ContactsListViewModel(dependencies: dependencies, favorites: favorites))
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Contacts")
                .navigationDestination(for: Contact.self) { contact in
                    ContactDetailView(
                        contact: contact,
                        dependencies: dependencies,
                        favorites: viewModel.favorites
                    )
                }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            // Coming back from Settings having granted access should just work, rather than leaving
            // the user on the permission screen wondering what else to press.
            guard phase == .active else { return }
            Task { await viewModel.reloadIfPermissionMayHaveChanged() }
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
        if viewModel.isEmptyOfContacts {
            emptyAddressBookView
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
                    Section {
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
                    } header: {
                        Text(section.title)
                    }
                    .id(section.id)
                }
            }
            .listStyle(.plain)
            .overlay(alignment: .trailing) {
                if let indexTitles = indexTitles(for: sections) {
                    SectionIndexBar(titles: indexTitles) { title in
                        proxy.scrollTo(title, anchor: .top)
                    }
                    .padding(.trailing, 2)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Name or phone number")
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

    /// The index bar earns its space only when browsing a list long enough to need it.
    private func indexTitles(for sections: [ContactSection]) -> [String]? {
        guard !viewModel.isSearching, sections.count > 2 else { return nil }
        return sections.map(\.id)
    }

    private var emptyAddressBookView: some View {
        ContentUnavailableView {
            Label("No Contacts", systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text("Contacts you add on this device will appear here.")
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

#Preview("Loaded") {
    let dependencies = AppDependencies.preview()
    ContactsListView(
        dependencies: dependencies,
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}

#Preview("Permission denied") {
    let dependencies = AppDependencies.preview(authorizationStatus: .denied)
    ContactsListView(
        dependencies: dependencies,
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}

#Preview("Empty address book") {
    let dependencies = AppDependencies.preview(contacts: [])
    ContactsListView(
        dependencies: dependencies,
        favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
    )
}
