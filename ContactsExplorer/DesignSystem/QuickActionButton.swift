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

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview {
    HStack(spacing: 10) {
        QuickActionButton(title: "Call", systemImage: "phone.fill") {}
        QuickActionButton(title: "Message", systemImage: "message.fill") {}
        QuickActionButton(title: "Mail", systemImage: "envelope.fill") {}
    }
    .padding()
}
#endif
