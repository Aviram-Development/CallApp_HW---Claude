//
//  LiquidGlass.swift
//  ContactsExplorer
//

import SwiftUI

/// Liquid Glass, with a graceful fall back for the versions that do not have it.
///
/// The deployment target is iOS 18, so `glassEffect` cannot simply be called at the use site without
/// scattering `#available` checks through the views. These two wrappers hold the version check in one
/// place; callers just say what shape they want.
extension View {
    /// A circular Liquid Glass background — used for the contact detail quick actions.
    ///
    /// `interactive()` is what makes the glass flex and highlight under a finger; without it the
    /// circle is glass in appearance only and taps feel dead.
    @ViewBuilder
    func liquidGlassCircle() -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .circle)
        } else {
            background(.ultraThinMaterial, in: .circle)
                .overlay(
                    Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        }
    }
}

/// Groups adjacent glass elements so they blend and morph as one piece of material.
///
/// Without the container each circle refracts in isolation and neighbours sitting close together read
/// as separate stickers rather than as one control strip. A no-op before iOS 26.
struct LiquidGlassGroup<Content: View>: View {
    var spacing: CGFloat?

    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}
