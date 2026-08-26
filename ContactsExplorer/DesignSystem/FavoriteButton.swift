//
//  FavoriteButton.swift
//  ContactsExplorer
//

import SwiftUI

struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? .yellow : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
        .sensoryFeedback(.selection, trigger: isFavorite)
    }
}

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview {
    HStack(spacing: 24) {
        FavoriteButton(isFavorite: false, action: {})
        FavoriteButton(isFavorite: true, action: {})
    }
}
#endif
