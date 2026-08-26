//
//  PreviewContactsRepository.swift
//  ContactsExplorer
//

#if DEBUG
import Foundation

/// A `ContactsRepository` backed by `PreviewData`, so previews render a populated list without a
/// permission prompt or a seeded simulator address book.
nonisolated struct PreviewContactsRepository: ContactsRepository {
    var stubbedAuthorizationStatus: ContactsAuthorizationStatus = .granted
    var contacts: [Contact] = PreviewData.contacts()

    func authorizationStatus() -> ContactsAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAccess() async throws -> Bool {
        stubbedAuthorizationStatus == .granted
    }

    func fetchContacts() async throws -> [Contact] {
        contacts
    }

    func fetchFullImageData(for contactID: String) async throws -> Data? {
        contacts.first { $0.id == contactID }?.thumbnailData
    }
}

/// Favourites that live only for the lifetime of the preview.
nonisolated struct InMemoryFavoritesStore: FavoritesStore {
    var initialIDs: Set<String> = []

    func load() -> Set<String> { initialIDs }
    func save(_ ids: Set<String>) {}
}

extension AppDependencies {
    static func preview(
        authorizationStatus: ContactsAuthorizationStatus = .granted,
        contacts: [Contact] = PreviewData.contacts(),
        favoriteIDs: Set<String> = ["contact-emma"]
    ) -> AppDependencies {
        AppDependencies(
            contactsRepository: PreviewContactsRepository(
                stubbedAuthorizationStatus: authorizationStatus,
                contacts: contacts
            ),
            favoritesStore: InMemoryFavoritesStore(initialIDs: favoriteIDs)
        )
    }
}
#endif
