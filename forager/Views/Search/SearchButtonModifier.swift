// SearchButtonModifier.swift
// FUI-1.2: Global search button applied to all tab root views

import SwiftUI

struct SearchButtonModifier: ViewModifier {
    @Binding var showSearch: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(ForagerTheme.textSecondary)
                    }
                    .accessibilityLabel("Search")
                }
            }
    }
}

extension View {
    func searchButton(showSearch: Binding<Bool>) -> some View {
        modifier(SearchButtonModifier(showSearch: showSearch))
    }
}
