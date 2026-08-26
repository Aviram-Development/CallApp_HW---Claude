//
//  UseCaseTests.swift
//  ContactsExplorerTests
//

import Foundation
import Testing
@testable import ContactsExplorer

@Suite("LoadContactsUseCase")
struct LoadContactsUseCaseTests {
    @Test("Already-granted permission fetches without prompting")
    func grantedFetchesWithoutPrompting() async throws {
        let expected = [TestContact.make(id: "a")]
        let repository = FakeContactsRepository(authorizationStatus: .granted, contacts: expected)

        let outcome = try await LoadContactsUseCase(repository: repository)()

        #expect(outcome == .loaded(expected))
        #expect(repository.requestAccessCallCount == 0)
        #expect(repository.fetchContactsCallCount == 1)
    }

    @Test("An undecided permission is requested, then the contacts are fetched")
    func notDeterminedPromptsThenFetches() async throws {
        let expected = [TestContact.make(id: "a")]
        let repository = FakeContactsRepository(
            authorizationStatus: .notDetermined,
            accessGranted: true,
            contacts: expected
        )

        let outcome = try await LoadContactsUseCase(repository: repository)()

        #expect(outcome == .loaded(expected))
        #expect(repository.requestAccessCallCount == 1)
    }

    @Test("Refusing the prompt reports permission denied and fetches nothing")
    func refusingThePromptDenies() async throws {
        let repository = FakeContactsRepository(
            authorizationStatus: .notDetermined,
            accessGranted: false
        )

        let outcome = try await LoadContactsUseCase(repository: repository)()

        #expect(outcome == .permissionDenied)
        #expect(repository.fetchContactsCallCount == 0)
    }

    // Once refused, the system will not show the prompt again -- only Settings can change the
    // answer -- so re-asking would be a silent no-op that looks like a broken button.
    @Test("A previous refusal is not re-prompted")
    func deniedDoesNotReprompt() async throws {
        let repository = FakeContactsRepository(authorizationStatus: .denied)

        let outcome = try await LoadContactsUseCase(repository: repository)()

        #expect(outcome == .permissionDenied)
        #expect(repository.requestAccessCallCount == 0)
        #expect(repository.fetchContactsCallCount == 0)
    }

    @Test("A fetch failure propagates")
    func fetchFailurePropagates() async {
        let repository = FakeContactsRepository(authorizationStatus: .granted, fetchError: TestError.boom)

        await #expect(throws: TestError.self) {
            try await LoadContactsUseCase(repository: repository)()
        }
    }
}

@Suite("ToggleFavoriteUseCase")
struct ToggleFavoriteUseCaseTests {
    @Test("Toggling an unfavourited contact adds it, and persists")
    func togglingAddsAndPersists() {
        let keyValueStore = InMemoryKeyValueStore()
        let favoritesStore = UserDefaultsFavoritesStore(keyValueStore: keyValueStore)

        let updated = ToggleFavoriteUseCase(favoritesStore: favoritesStore)(contactID: "a", in: [])

        #expect(updated == ["a"])
        #expect(favoritesStore.load() == ["a"])
    }

    @Test("Toggling a favourited contact removes it, and persists")
    func togglingRemovesAndPersists() {
        let keyValueStore = InMemoryKeyValueStore()
        let favoritesStore = UserDefaultsFavoritesStore(keyValueStore: keyValueStore)

        let updated = ToggleFavoriteUseCase(favoritesStore: favoritesStore)(contactID: "a", in: ["a", "b"])

        #expect(updated == ["b"])
        #expect(favoritesStore.load() == ["b"])
    }

    @Test("Toggling twice returns to the starting state")
    func togglingTwiceIsIdentity() {
        let toggle = ToggleFavoriteUseCase(favoritesStore: UserDefaultsFavoritesStore(
            keyValueStore: InMemoryKeyValueStore()
        ))

        let once = toggle(contactID: "a", in: ["b"])
        let twice = toggle(contactID: "a", in: once)

        #expect(twice == ["b"])
    }
}

@Suite("LoadContactImageUseCase")
struct LoadContactImageUseCaseTests {
    @Test("The full image is fetched for the requested contact")
    func fetchesTheRequestedImage() async throws {
        let expected = Data([0x01, 0x02])
        let repository = FakeContactsRepository(authorizationStatus: .granted, fullImageData: expected)

        let data = try await LoadContactImageUseCase(repository: repository)(contactID: "a")

        #expect(data == expected)
        #expect(repository.requestedImageIDs == ["a"])
    }

    @Test("A contact with no image yields nil rather than failing")
    func missingImageIsNotAnError() async throws {
        let repository = FakeContactsRepository(authorizationStatus: .granted, fullImageData: nil)
        #expect(try await LoadContactImageUseCase(repository: repository)(contactID: "a") == nil)
    }
}
