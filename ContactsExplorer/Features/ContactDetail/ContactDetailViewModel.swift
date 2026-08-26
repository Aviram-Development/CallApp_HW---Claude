//
//  ContactDetailViewModel.swift
//  ContactsExplorer
//

import Foundation
import os

private let logger = Logger(subsystem: "com.shaibalassiano.ContactsExplorer", category: "ContactDetail")

@MainActor
@Observable
final class ContactDetailViewModel {
    let contact: Contact

    /// The full-resolution image, once it has arrived. Until then the view falls back to the
    /// thumbnail already carried by the contact, so the header never flashes empty.
    private(set) var fullImageData: Data?

    private let loadImage: LoadContactImageUseCase

    init(contact: Contact, dependencies: AppDependencies) {
        self.contact = contact
        self.loadImage = LoadContactImageUseCase(repository: dependencies.contactsRepository)
    }

    func loadFullImage() async {
        do {
            fullImageData = try await loadImage(contactID: contact.id)
        } catch {
            // Not worth surfacing: the thumbnail is already on screen and looks fine.
            logger.error("Loading contact image failed: \(String(describing: error))")
        }
    }
}
