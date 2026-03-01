//
//  LLMParsingToast.swift
//  forager
//
//  M10.6.6e: Reusable toast overlay for LLM parsing feedback.
//  Capsule at bottom, auto-dismiss after 2 seconds, fade animation.
//

import SwiftUI

// MARK: - Toast View Modifier

struct LLMParsingToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.overlay(alignment: .bottom) {
            if let text = message {
                Text(text)
                    .font(ForagerTheme.footnoteFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, ForagerTheme.Spacing.lg)
                    .padding(.vertical, ForagerTheme.Spacing.sm)
                    .background(ForagerTheme.accentPrimary.opacity(0.9))
                    .clipShape(Capsule())
                    .padding(.bottom, ForagerTheme.Spacing.xl)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                message = nil
                            }
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: message)
    }
}

extension View {
    /// Show a brief toast message at the bottom of the view, auto-dismissing after 2 seconds.
    func llmParsingToast(message: Binding<String?>) -> some View {
        modifier(LLMParsingToastModifier(message: message))
    }
}
