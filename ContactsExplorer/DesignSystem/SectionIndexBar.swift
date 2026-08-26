//
//  SectionIndexBar.swift
//  ContactsExplorer
//

import SwiftUI

/// The A–Z scrubber down the trailing edge of the contacts list.
///
/// SwiftUI has no equivalent of `UITableView`'s section index, so this is hand-built: a column of
/// titles with a drag gesture that maps a vertical position onto a section. Reporting on drag as
/// well as on tap is what makes it feel like the system control rather than a row of small buttons.
struct SectionIndexBar: View {
    let titles: [String]
    let onSelect: (String) -> Void

    @State private var selectedTitle: String?

    private let itemHeight: CGFloat = 13

    var body: some View {
        VStack(spacing: 0) {
            ForEach(titles, id: \.self) { title in
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(height: itemHeight)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 20)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: .capsule)
        .contentShape(.rect)
        .gesture(scrubGesture)
        .sensoryFeedback(.selection, trigger: selectedTitle)
        // Individually the letters are far too small to be usable targets, and the list itself is
        // already fully navigable, so this is offered to assistive technology as one adjustable
        // control rather than as two dozen unlabelled ones.
        .accessibilityElement()
        .accessibilityLabel("Section index")
        .accessibilityHint("Swipe up or down to jump between sections")
        .accessibilityAdjustableAction(step)
    }

    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // The bar's vertical padding sits above the first title, so subtract it before
                // dividing, or every hit lands one row low.
                let index = Int((value.location.y - 8) / itemHeight)
                select(at: index)
            }
            .onEnded { _ in selectedTitle = nil }
    }

    private func step(_ direction: AccessibilityAdjustmentDirection) {
        let current = selectedTitle.flatMap { titles.firstIndex(of: $0) } ?? 0
        select(at: direction == .increment ? current + 1 : current - 1)
    }

    private func select(at index: Int) {
        guard let title = titles[safe: index], title != selectedTitle else { return }
        selectedTitle = title
        onSelect(title)
    }
}

private extension Array {
    /// Bounds-checked access, so dragging past either end of the bar simply does nothing.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Previews are compiled into release builds too, so they have to be excluded
// explicitly -- otherwise they would drag PreviewData into the shipping binary,
// which is the very thing moving it behind #if DEBUG was meant to prevent.
#if DEBUG
#Preview {
    SectionIndexBar(titles: ["\u{2605}"] + (65...90).map { String(UnicodeScalar($0)!) } + ["#"]) { _ in }
}
#endif
