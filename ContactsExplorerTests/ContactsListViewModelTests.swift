//
//  ContactsListViewModelTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@MainActor
@Suite("ContactsListViewModel")
struct ContactsListViewModelTests {
    private static let anna = TestContact.make(id: "anna", fullName: "Anna Adams", phoneNumbers: ["555-0100"])
    private static let bella = TestContact.make(id: "bella", fullName: "Bella Brooks", phoneNumbers: ["555-0199"])
    private static let contacts = [anna, bella]

    // MARK: - Loading

    @Test("Loading moves from idle to loaded and groups the contacts")
    func loadsAndSections() async {
        let viewModel = Self.makeViewModel()
        #expect(viewModel.state == .idle)

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.sections.map(\.title) == ["A", "B"])
        #expect(viewModel.sections.flatMap(\.contacts) == Self.contacts)
    }

    @Test("loadIfNeeded does nothing once a load has already happened")
    func loadIfNeededIsIdempotent() async {
        let repository = FakeContactsRepository(authorizationStatus: .granted, contacts: Self.contacts)
        let viewModel = Self.makeViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        #expect(repository.fetchContactsCallCount == 1)
    }

    @Test("A refusal leaves the view model in its permission-denied state")
    func permissionDenied() async {
        let viewModel = Self.makeViewModel(
            repository: FakeContactsRepository(authorizationStatus: .denied)
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .permissionDenied)
        #expect(viewModel.sections.isEmpty)
    }

    @Test("A failure with nothing on screen shows the failure state")
    func failureWithNothingLoaded() async {
        let viewModel = Self.makeViewModel(
            repository: FakeContactsRepository(authorizationStatus: .granted, fetchError: .boom)
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .failed)
    }

    // A pull-to-refresh that fails should not blank out the list the user is currently reading.
    @Test("A failed refresh keeps the contacts already on screen")
    func failedRefreshKeepsExistingContacts() async {
        let repository = SwitchableContactsRepository(contacts: Self.contacts)
        let viewModel = Self.makeViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        repository.startFailing()
        await viewModel.load()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.sections.flatMap(\.contacts) == Self.contacts)
    }

    @Test("An address book with no contacts is distinguishable from one that never loaded")
    func emptyAddressBook() async {
        let viewModel = Self.makeViewModel(
            repository: FakeContactsRepository(authorizationStatus: .granted, contacts: [])
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.isEmptyOfContacts)
    }

    // MARK: - Returning from Settings

    @Test("Returning to the foreground retries only while permission is the blocker")
    func retriesOnlyFromThePermissionState() async {
        let repository = FakeContactsRepository(authorizationStatus: .granted, contacts: Self.contacts)
        let viewModel = Self.makeViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        await viewModel.reloadIfPermissionMayHaveChanged()

        // Already loaded, so foregrounding must not trigger a redundant fetch.
        #expect(repository.fetchContactsCallCount == 1)
    }

    @Test("Access granted in Settings takes effect on return")
    func retriesAfterAccessIsGranted() async {
        let repository = SwitchableContactsRepository(
            contacts: Self.contacts,
            authorizationStatus: .denied
        )
        let viewModel = Self.makeViewModel(repository: repository)
        await viewModel.loadIfNeeded()
        #expect(viewModel.state == .permissionDenied)

        repository.grantAccess()
        await viewModel.reloadIfPermissionMayHaveChanged()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.sections.flatMap(\.contacts) == Self.contacts)
    }

    // MARK: - Search

    @Test("Searching filters the sections")
    func searchFilters() async {
        let viewModel = Self.makeViewModel()
        await viewModel.loadIfNeeded()

        viewModel.searchText = "bella"

        #expect(viewModel.isSearching)
        #expect(viewModel.sections.flatMap(\.contacts) == [Self.bella])
    }

    @Test("Searching by phone number filters the sections")
    func searchFiltersByPhoneNumber() async {
        let viewModel = Self.makeViewModel()
        await viewModel.loadIfNeeded()

        viewModel.searchText = "5550199"

        #expect(viewModel.sections.flatMap(\.contacts) == [Self.bella])
    }

    @Test("Clearing the query restores the whole list")
    func clearingSearchRestoresEverything() async {
        let viewModel = Self.makeViewModel()
        await viewModel.loadIfNeeded()

        viewModel.searchText = "bella"
        viewModel.searchText = ""

        #expect(!viewModel.isSearching)
        #expect(viewModel.sections.flatMap(\.contacts) == Self.contacts)
    }

    @Test("A query matching nothing produces no sections at all")
    func searchWithNoMatches() async {
        let viewModel = Self.makeViewModel()
        await viewModel.loadIfNeeded()

        viewModel.searchText = "zzzz"

        #expect(viewModel.sections.isEmpty)
    }

    // MARK: - Favourites

    @Test("Favouriting pins a contact and persists the change")
    func favoritingPinsAndPersists() async {
        let keyValueStore = InMemoryKeyValueStore()
        let favoritesStore = UserDefaultsFavoritesStore(keyValueStore: keyValueStore)
        let viewModel = Self.makeViewModel(favoritesStore: favoritesStore)
        await viewModel.loadIfNeeded()

        viewModel.favorites.toggle(Self.bella)

        #expect(viewModel.sections.first?.isFavorites == true)
        #expect(viewModel.sections.first?.contacts == [Self.bella])
        #expect(favoritesStore.load() == ["bella"])
    }

    @Test("Favourites saved on a previous launch are pinned from the start")
    func favoritesSurviveRelaunch() async {
        let keyValueStore = InMemoryKeyValueStore(initialValues: ["favoriteContactIDs": ["anna"]])
        let viewModel = Self.makeViewModel(
            favoritesStore: UserDefaultsFavoritesStore(keyValueStore: keyValueStore)
        )

        await viewModel.loadIfNeeded()

        #expect(viewModel.sections.first?.contacts == [Self.anna])
    }

    @Test("The favourites section is suppressed while searching")
    func noFavoritesSectionWhileSearching() async {
        let viewModel = Self.makeViewModel()
        await viewModel.loadIfNeeded()
        viewModel.favorites.toggle(Self.bella)

        viewModel.searchText = "b"

        #expect(viewModel.sections.allSatisfy { !$0.isFavorites })
    }

    // MARK: - Helpers

    private static func makeViewModel(
        repository: ContactsRepository = FakeContactsRepository(
            authorizationStatus: .granted,
            contacts: ContactsListViewModelTests.contacts
        ),
        favoritesStore: FavoritesStore = UserDefaultsFavoritesStore(keyValueStore: InMemoryKeyValueStore())
    ) -> ContactsListViewModel {
        let dependencies = AppDependencies(contactsRepository: repository, favoritesStore: favoritesStore)
        return ContactsListViewModel(
            contacts: ContactsModel(dependencies: dependencies),
            favorites: FavoritesModel(favoritesStore: favoritesStore)
        )
    }
}
