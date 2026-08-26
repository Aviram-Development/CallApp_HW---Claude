//
//  ContactsRepository.swift
//  ContactsExplorer
//

import Foundation

/// Everything the app needs from the device address book.
///
/// A protocol so the view models can be driven by a fake in tests: reading real contacts otherwise
/// requires a permission prompt and whatever happens to be in the simulator's address book, which is
/// not something a test can assert against.
nonisolated protocol ContactsRepository: Sendable {
    /// The current permission state. Synchronous and cheap — safe to call while laying out a view.
    func authorizationStatus() -> ContactsAuthorizationStatus

    /// Prompts for contacts access. Only meaningful once: the system ignores later calls.
    /// - Returns: whether access was granted.
    func requestAccess() async throws -> Bool

    /// Every contact on the device, sorted for display.
    func fetchContacts() async throws -> [Contact]

    /// The full-resolution image for one contact, which is deliberately excluded from
    /// `fetchContacts` — loading every full image up front would cost far more than it is worth.
    func fetchFullImageData(for contactID: String) async throws -> Data?
}
