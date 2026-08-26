//
//  SwitchableContactsRepository.swift
//  ContactsExplorerTests
//

import Foundation
import Synchronization
@testable import ContactsExplorer

/// A repository whose behaviour can change mid-test, for the cases that are only interesting because
/// something changed between two loads: a refresh that starts failing, or access granted in Settings
/// while the app sat in the background.
final class SwitchableContactsRepository: ContactsRepository {
    private struct State {
        var authorizationStatus: ContactsAuthorizationStatus
        var isFailing = false
    }

    private let contacts: [Contact]
    private let state: Mutex<State>

    init(contacts: [Contact], authorizationStatus: ContactsAuthorizationStatus = .granted) {
        self.contacts = contacts
        self.state = Mutex(State(authorizationStatus: authorizationStatus))
    }

    func startFailing() {
        state.withLock { $0.isFailing = true }
    }

    func grantAccess() {
        state.withLock { $0.authorizationStatus = .granted }
    }

    func authorizationStatus() -> ContactsAuthorizationStatus {
        state.withLock(\.authorizationStatus)
    }

    func requestAccess() async throws -> Bool {
        authorizationStatus() == .granted
    }

    func fetchContacts() async throws -> [Contact] {
        if state.withLock(\.isFailing) { throw TestError.boom }
        return contacts
    }

    func fetchFullImageData(for contactID: String) async throws -> Data? {
        if state.withLock(\.isFailing) { throw TestError.boom }
        return contacts.first { $0.id == contactID }?.thumbnailData
    }
}
