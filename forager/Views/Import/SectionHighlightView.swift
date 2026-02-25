//
//  SectionHighlightView.swift
//  forager
//
//  Created for M10.2.5: Section detection UI
//  Shows pasted text with color-coded line classifications.
//  User can tap lines to reclassify (title/ingredient/instruction/metadata/ignore).
//  "Continue to Preview" assembles ImportDraftRecipe from corrected classifications.
//

import SwiftUI

// MARK: - Editable Classified Line

/// A classified line that the user can reclassify by tapping
struct EditableClassifiedLine: Identifiable {
    let id = UUID()
    let text: String
    var type: LineType
    var confidence: Float
}

// MARK: - Section Highlight View

/// Shows classified recipe text with color-coded sections.
/// Users tap lines to cycle through classification types, then continue to preview.
struct SectionHighlightView: View {
    @Binding var classifiedLines: [EditableClassifiedLine]
    let onContinue: ([EditableClassifiedLine]) -> Void

    /// Cycle order when tapping a line
    private let typeOrder: [LineType] = [.ingredient, .instruction, .title, .metadata, .unknown]

    var body: some View {
        VStack(spacing: 0) {
            // Legend
            legendBar
                .padding(.horizontal, ForagerTheme.Spacing.lg)
                .padding(.vertical, ForagerTheme.Spacing.sm)

            Divider()

            // Classified lines
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach($classifiedLines) { $line in
                        lineRow(line: $line)
                    }
                }
                .padding(.horizontal, ForagerTheme.Spacing.md)
                .padding(.vertical, ForagerTheme.Spacing.sm)
            }

            Divider()

            // Summary + continue button
            bottomBar
                .padding(.horizontal, ForagerTheme.Spacing.lg)
                .padding(.vertical, ForagerTheme.Spacing.md)
        }
    }

    // MARK: - Legend

    private var legendBar: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            legendDot(.title)
            legendDot(.ingredient)
            legendDot(.instruction)
            legendDot(.metadata)
            Spacer()
            Text("Tap to reclassify")
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textTertiary)
        }
    }

    private func legendDot(_ type: LineType) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(colorForType(type))
                .frame(width: 8, height: 8)
            Text(labelForType(type))
                .font(ForagerTheme.captionFont)
                .foregroundStyle(ForagerTheme.textSecondary)
        }
    }

    // MARK: - Line Row

    private func lineRow(line: Binding<EditableClassifiedLine>) -> some View {
        Button {
            cycleType(line)
        } label: {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                // Color indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorForType(line.wrappedValue.type))
                    .frame(width: 4)

                // Line text
                Text(line.wrappedValue.text)
                    .font(.system(.body, design: line.wrappedValue.type == .ingredient ? .default : .default))
                    .foregroundStyle(
                        line.wrappedValue.type == .unknown
                            ? ForagerTheme.textTertiary
                            : ForagerTheme.textPrimary
                    )
                    .strikethrough(line.wrappedValue.type == .unknown)
                    .lineLimit(3)

                Spacer(minLength: 0)

                // Type badge
                Text(shortLabelForType(line.wrappedValue.type))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(colorForType(line.wrappedValue.type))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(colorForType(line.wrappedValue.type).opacity(0.15))
                    )
            }
            .padding(.vertical, 4)
            .padding(.horizontal, ForagerTheme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        let ingredientCount = classifiedLines.filter { $0.type == .ingredient }.count
        let instructionCount = classifiedLines.filter { $0.type == .instruction }.count

        return VStack(spacing: ForagerTheme.Spacing.sm) {
            HStack {
                Text("\(ingredientCount) ingredients, \(instructionCount) instructions")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Spacer()
            }

            Button {
                onContinue(classifiedLines)
            } label: {
                Text("Continue to Preview")
                    .font(ForagerTheme.bodyFont.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ForagerTheme.Spacing.md)
            }
            .buttonStyle(.borderedProminent)
            .tint(ForagerTheme.accentPrimary)
            .disabled(ingredientCount == 0)
        }
    }

    // MARK: - Helpers

    private func cycleType(_ line: Binding<EditableClassifiedLine>) {
        let current = line.wrappedValue.type
        guard let currentIndex = typeOrder.firstIndex(of: current) else {
            line.wrappedValue.type = typeOrder[0]
            return
        }
        let nextIndex = (currentIndex + 1) % typeOrder.count
        line.wrappedValue.type = typeOrder[nextIndex]
    }

    // MARK: - Type Colors & Labels

    private func colorForType(_ type: LineType) -> Color {
        switch type {
        case .title:         return ForagerTheme.accentSecondary
        case .ingredient:    return ForagerTheme.statusSuccessFG
        case .instruction:   return ForagerTheme.statusInfoFG
        case .metadata:      return ForagerTheme.statusWarningFG
        case .sectionHeader: return ForagerTheme.textTertiary
        case .unknown:       return ForagerTheme.textTertiary
        }
    }

    private func labelForType(_ type: LineType) -> String {
        switch type {
        case .title:         return "Title"
        case .ingredient:    return "Ingredient"
        case .instruction:   return "Instruction"
        case .metadata:      return "Info"
        case .sectionHeader: return "Header"
        case .unknown:       return "Skip"
        }
    }

    private func shortLabelForType(_ type: LineType) -> String {
        switch type {
        case .title:         return "TITLE"
        case .ingredient:    return "INGR"
        case .instruction:   return "STEP"
        case .metadata:      return "INFO"
        case .sectionHeader: return "HDR"
        case .unknown:       return "SKIP"
        }
    }
}
