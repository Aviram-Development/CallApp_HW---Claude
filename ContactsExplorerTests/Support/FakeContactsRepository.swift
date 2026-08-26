//
//  FakeContactsRepository.swift
//  ContactsExplorerTests
//

import Foundation
import Synchronization
@testable import ContactsExplorer

enum TestError: Error, Equatable {
    case boom
}

/// A scriptable stand-in for the device address book.
///
/// Lets tests drive every branch of the permission flow and the failure paths, none of which are
/// reachable against a real `CNContactStore` without a permission prompt and a populated simulator.
final class FakeContactsRepository: ContactsRepository {
    private struct Recording {
        var requestAccessCallCount = 0
        var fetchContactsCallCount = 0
        var requestedImageIDs: [String] = []
    }

    private let stubbedAuthorizationStatus: ContactsAuthorizationStatus
    private let accessGranted: Bool
    private let contacts: [Contact]
    private let fullImageData: Data?
    private let fetchError: TestError?

    private let recording = Mutex(Recording())

    init(
        authorizationStatus: ContactsAuthorizationStatus,
        accessGranted: Bool = true,
        contacts: [Contact] = [],
        fullImageData: Data? = nil,
        fetchError: TestError? = nil
    ) {
        self.stubbedAuthorizationStatus = authorizationStatus
        self.accessGranted = accessGranted
        self.contacts = contacts
        self.fullImageData = fullImageData
        self.fetchError = fetchError
    }

    var requestAccessCallCount: Int { recording.withLock(\.requestAccessCallCount) }
    var fetchContactsCallCount: Int { recording.withLock(\.fetchContactsCallCount) }
    var requestedImageIDs: [String] { recording.withLock(\.requestedImageIDs) }

    func authorizationStatus() -> ContactsAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAccess() async throws -> Bool {
        recording.withLock { $0.requestAccessCallCount += 1 }
        return accessGranted
    }

    func fetchContacts() async throws -> [Contact] {
        recording.withLock { $0.fetchContactsCallCount += 1 }
        if let fetchError { throw fetchError }
        return contacts
    }

    func fetchFullImageData(for contactID: String) async throws -> Data? {
        recording.withLock { $0.requestedImageIDs.append(contactID) }
        if let fetchError { throw fetchError }
        return fullImageData
    }
}
