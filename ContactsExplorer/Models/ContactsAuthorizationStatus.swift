//
//  ContactsAuthorizationStatus.swift
//  ContactsExplorer
//

/// The app's own view of contacts permission, so nothing above the service layer needs to import
/// `Contacts` or reason about the cases (`.limited`, `.restricted`) that we treat identically.
nonisolated enum ContactsAuthorizationStatus {
    /// The user has not been asked yet.
    case notDetermined
    /// We may read contacts. Covers both full and limited access.
    case granted
    /// We may not read contacts, and asking again will not help.
    case denied
}
