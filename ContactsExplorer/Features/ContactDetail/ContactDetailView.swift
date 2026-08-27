//
//  ContactDetailView.swift
//  ContactsExplorer
//

import SwiftUI

struct ContactDetailView: View {
    @Environment(\.openURL) private var openURL

    @State private var viewModel: ContactDetailViewModel
    private let favorites: FavoritesModel

    init(contact: Contact, dependencies: AppDependencies, favorites: FavoritesModel) {
        _viewModel = State(wrappedValue: ContactDetailViewModel(contact: contact, dependencies: dependencies))
        self.favorites = favorites
    }

    private var contact: Contact { viewModel.contact }

    var body: some View {
        List {
            header
            phoneNumbers
            emails
            noDetailsNotice
            info
        }
        .navigationTitle(contact.displayName)
        .navigationBarTitleDisplayMode(.inline)
        // A pushed detail screen is a dead end, not a place to switch tabs from, and the floating
        // iOS 26 tab bar would otherwise sit on top of the last row of emails.
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FavoriteButton(isFavorite: favorites.isFavorite(contact)) {
                    favorites.toggle(contact)
                }
            }
        }
        .task {
            await viewModel.loadFullImage()
        }
    }

    // MARK: - Header

    private var header: some View {
        Section {
            VStack(spacing: 12) {
                ContactAvatarView(contact: contact, imageData: viewModel.fullImageData, size: 120)

                VStack(spacing: 2) {
                    Text(contact.displayName)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    // Only worth showing when it is not already doing duty as the display name.
                    if !contact.organizationName.isEmpty, contact.organizationName != contact.displayName {
                        Text(contact.organizationName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                quickActions
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private var quickActions: some View {
        let firstPhoneNumber = contact.phoneNumbers.first?.value
        let firstEmail = contact.emails.first?.value

        if firstPhoneNumber != nil || firstEmail != nil {
            LiquidGlassGroup(spacing: 20) {
                HStack(spacing: 20) {
                    if let firstPhoneNumber {
                        QuickActionButton(title: "Call", systemImage: "phone.fill") {
                            open(.call, firstPhoneNumber)
                        }
                        QuickActionButton(title: "Message", systemImage: "message.fill") {
                            open(.message, firstPhoneNumber)
                        }
                    }
                    if let firstEmail {
                        QuickActionButton(title: "Mail", systemImage: "envelope.fill") {
                            open(.mail, firstEmail)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Details

    @ViewBuilder
    private var phoneNumbers: some View {
        if !contact.phoneNumbers.isEmpty {
            Section("Phone Numbers") {
                ForEach(contact.phoneNumbers) { phoneNumber in
                    actionableRow(label: phoneNumber.label, value: phoneNumber.value) {
                        open(.call, phoneNumber.value)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emails: some View {
        if !contact.emails.isEmpty {
            Section("Emails") {
                ForEach(contact.emails) { email in
                    actionableRow(label: email.label, value: email.value) {
                        open(.mail, email.value)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noDetailsNotice: some View {
        if contact.phoneNumbers.isEmpty && contact.emails.isEmpty {
            Section {
                Text("This contact has no phone numbers or emails.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var info: some View {
        if !contact.organizationName.isEmpty || contact.birthday != nil {
            Section("Info") {
                if !contact.organizationName.isEmpty {
                    LabeledContent("Organization", value: contact.organizationName)
                }
                if let birthday = contact.birthday {
                    LabeledContent("Birthday", value: birthday.formatted(date: .long, time: .omitted))
                }
            }
        }
    }

    /// A phone number or email address: tap to act on it, long-press to copy it.
    private func actionableRow(label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .foregroundStyle(Color.accentColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .contextMenu {
            Button("Copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = value
            }
        }
    }

    // MARK: - Links

    private enum LinkKind: String {
        case call = "tel"
        case message = "sms"
        case mail = "mailto"
    }

    private func open(_ kind: LinkKind, _ value: String) {
        // `tel:` and `sms:` only accept digits and a leading "+"; a number stored as
        // "+972 54-123-4567" has to be stripped down before it will open.
        let recipient: String = switch kind {
        case .call, .message: value.filter { $0.isWholeNumber || $0 == "+" }
        case .mail: value
        }
        guard !recipient.isEmpty else { return }

        // Built through `URLComponents` rather than by encoding with `.urlHostAllowed` and splicing
        // the string together. Neither a phone number nor an email address is a URL *host*, and that
        // set excludes "@" — so `mailto:` recipients were being escaped to "emma%40example.com".
        // Mail happens to decode that again, but the escaping was never correct.
        var components = URLComponents()
        components.scheme = kind.rawValue
        components.path = recipient
        guard let url = components.url else { return }
        openURL(url)
    }
}

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview("Full contact") {
    NavigationStack {
        let dependencies = AppDependencies.preview()
        ContactDetailView(
            contact: PreviewData.contact(),
            dependencies: dependencies,
            favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
        )
    }
}

#Preview("Name only") {
    NavigationStack {
        let dependencies = AppDependencies.preview()
        ContactDetailView(
            contact: PreviewData.bareContact(),
            dependencies: dependencies,
            favorites: FavoritesModel(favoritesStore: dependencies.favoritesStore)
        )
    }
}
#endif
