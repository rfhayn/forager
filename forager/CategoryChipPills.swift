// CategoryChipPills.swift
// M15.3: Category composition pills for grocery list cards
//
// PRD §5.3: Small pills with category name + count, category color
// at 12% opacity bg, full color text.

import SwiftUI

struct CategoryChipPills: View {
    let categories: [(name: String, count: Int)]

    var body: some View {
        FlowLayout(spacing: ForagerTheme.Spacing.xs) {
            ForEach(categories, id: \.name) { cat in
                Text("\(cat.name) \(cat.count)")
                    .font(ForagerTheme.tabLabel)
                    .textCase(.uppercase)
                    .foregroundStyle(ForagerTheme.categoryColor(for: cat.name))
                    .padding(.horizontal, ForagerTheme.Spacing.sm)
                    .padding(.vertical, 3)
                    .background(ForagerTheme.categoryColor(for: cat.name).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous))
            }
        }
    }
}
