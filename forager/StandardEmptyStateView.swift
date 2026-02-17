//
//  StandardEmptyStateView.swift
//  forager
//
//  Created for UI consistency - M4.3.5
//  Provides a standardized empty state pattern used across all main tabs
//

import SwiftUI

/// Standardized empty state view for consistency across the app
/// Uses blue icons, consistent spacing, and unified button styling
struct StandardEmptyStateView: View {
    let iconName: String
    let title: String
    let subtitle: String
    let buttonIcon: String
    let buttonText: String
    let buttonAction: () -> Void
    let isButtonDisabled: Bool
    
    init(
        iconName: String,
        title: String,
        subtitle: String,
        buttonIcon: String,
        buttonText: String,
        isButtonDisabled: Bool = false,
        buttonAction: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.title = title
        self.subtitle = subtitle
        self.buttonIcon = buttonIcon
        self.buttonText = buttonText
        self.isButtonDisabled = isButtonDisabled
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundStyle(ForagerTheme.accentPrimary)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(ForagerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: buttonAction) {
                HStack {
                    Image(systemName: buttonIcon)
                    Text(buttonText)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(ForagerTheme.accentPrimary)
                .cornerRadius(ForagerTheme.Radius.md)
            }
            .disabled(isButtonDisabled)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    StandardEmptyStateView(
        iconName: "list.clipboard",
        title: "No Grocery Lists",
        subtitle: "Generate your first list to get started!",
        buttonIcon: "cart.badge.plus",
        buttonText: "Generate from Staples",
        buttonAction: { }
    )
}
