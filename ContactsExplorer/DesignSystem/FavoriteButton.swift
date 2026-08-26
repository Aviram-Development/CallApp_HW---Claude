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

#Preview {
    HStack(spacing: 24) {
        FavoriteButton(isFavorite: false, action: {})
        FavoriteButton(isFavorite: true, action: {})
    }
}
