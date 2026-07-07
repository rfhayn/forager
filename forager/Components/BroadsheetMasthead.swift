//
//  BroadsheetMasthead.swift
//  forager
//
//  reskin-provisions-press: left-aligned section masthead for pushed
//  screens. The nav bar carries only the glass capsules (back/actions);
//  the screen name renders as a broadsheet head tight beneath them —
//  full crate-label size without the system large-title air gap, and no
//  truncation against trailing bar items.
//

import SwiftUI

struct BroadsheetMasthead: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(ForagerTheme.detailTitle)
                .foregroundStyle(ForagerTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.top, ForagerTheme.Spacing.xs)
        .padding(.bottom, ForagerTheme.Spacing.sm)
    }
}
