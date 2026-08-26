//
//  QuickActionButton.swift
//  ContactsExplorer
//

import SwiftUI

/// One of the call / message / mail buttons under the contact detail header.
struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .frame(height: 22)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.12), in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.accentColor)
        .accessibilityLabel(title)
    }
}

#Preview {
    HStack(spacing: 10) {
        QuickActionButton(title: "Call", systemImage: "phone.fill") {}
        QuickActionButton(title: "Message", systemImage: "message.fill") {}
        QuickActionButton(title: "Mail", systemImage: "envelope.fill") {}
    }
    .padding()
}
