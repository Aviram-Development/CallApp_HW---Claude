//
//  QuickActionButton.swift
//  ContactsExplorer
//

import SwiftUI

/// One of the call / message / mail buttons under the contact detail header.
///
/// A Liquid Glass circle with its caption underneath, the way Phone and Contacts present the same
/// three actions — rather than the tinted rounded rectangle this used to be.
struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    private let diameter: CGFloat = 56

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22))
                    .frame(width: diameter, height: diameter)
                    .liquidGlassCircle()
                Text(title)
                    .font(.caption)
            }
            // Only the circle and its caption are the target; the gaps between buttons are not.
            .contentShape(.rect)
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
#Preview("On a background") {
    ZStack {
        LinearGradient(
            colors: [.orange, .purple, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        LiquidGlassGroup(spacing: 20) {
            HStack(spacing: 20) {
                QuickActionButton(title: "Call", systemImage: "phone.fill") {}
                QuickActionButton(title: "Message", systemImage: "message.fill") {}
                QuickActionButton(title: "Mail", systemImage: "envelope.fill") {}
            }
        }
    }
}

#Preview("On a plain background") {
    LiquidGlassGroup(spacing: 20) {
        HStack(spacing: 20) {
            QuickActionButton(title: "Call", systemImage: "phone.fill") {}
            QuickActionButton(title: "Message", systemImage: "message.fill") {}
            QuickActionButton(title: "Mail", systemImage: "envelope.fill") {}
        }
    }
    .padding()
}
#endif
