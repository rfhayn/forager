//
//  HamburgerMenuView.swift
//  forager
//
//  M7.4: Hamburger menu for accessing Categories and Settings
//  Replaces the old "More" tab from bottom navigation
//

import SwiftUI

// M7.4: Hamburger menu sheet content
struct HamburgerMenuSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ManageCategoriesView(popToRoot: .constant(false))
                    } label: {
                        Label("Categories", systemImage: "folder.badge.gearshape")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// M7.4: ViewModifier to add hamburger menu to any view
struct HamburgerMenuModifier: ViewModifier {
    @State private var showingMenu = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingMenu = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingMenu) {
                HamburgerMenuSheet()
            }
    }
}

// Extension to make it easy to apply
extension View {
    func hamburgerMenu() -> some View {
        modifier(HamburgerMenuModifier())
    }
}
