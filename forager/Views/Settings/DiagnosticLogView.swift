//
//  DiagnosticLogView.swift
//  forager
//
//  M9.15.3: View and export persistent diagnostic logs.
//  Accessible from Settings in both Debug and Release builds.
//

import SwiftUI

struct DiagnosticLogView: View {
    @ObservedObject private var logger = DiagnosticLogger.shared
    @State private var logText: String = ""
    @State private var showingShareSheet = false
    @State private var showingClearConfirm = false
    @State private var filterLevel: DiagnosticLogger.Level?
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar

            // Log content
            ScrollViewReader { proxy in
                ScrollView {
                    Text(filteredLogText)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(ForagerTheme.Spacing.sm)
                        .id("logBottom")
                }
                .onAppear {
                    loadLog()
                    // Scroll to bottom on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.scrollTo("logBottom", anchor: .bottom)
                    }
                }
            }
        }
        .navigationTitle("Diagnostic Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    loadLog()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }

                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Menu {
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        Label("Clear Log", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Clear Diagnostic Log?", isPresented: $showingClearConfirm) {
            Button("Clear", role: .destructive) {
                logger.clear()
                loadLog()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all diagnostic log entries.")
        }
        .sheet(isPresented: $showingShareSheet) {
            DiagnosticShareSheet(fileURL: logger.fileURL)
        }
        .background(ForagerTheme.backgroundCanvas.ignoresSafeArea())
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: ForagerTheme.Spacing.xs) {
            // Stats row
            HStack {
                Text("\(logger.lineCount) lines")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Spacer()
                Text(logger.formattedFileSize)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                if !logger.isEnabled {
                    Text("PAUSED")
                        .font(.caption2.bold())
                        .foregroundStyle(ForagerTheme.statusWarningFG)
                }
            }
            .padding(.horizontal, ForagerTheme.Spacing.md)
            .padding(.top, ForagerTheme.Spacing.xs)

            // Level filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ForagerTheme.Spacing.xs) {
                    filterChip("All", level: nil)
                    filterChip("ERROR", level: .error)
                    filterChip("WARN", level: .warning)
                    filterChip("INFO", level: .info)
                    filterChip("DEBUG", level: .debug)
                }
                .padding(.horizontal, ForagerTheme.Spacing.md)
            }

            // Search
            TextField("Filter log...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .font(ForagerTheme.captionFont)
                .padding(.horizontal, ForagerTheme.Spacing.md)
                .padding(.bottom, ForagerTheme.Spacing.xs)
        }
        .background(.ultraThinMaterial)
    }

    private func filterChip(_ label: String, level: DiagnosticLogger.Level?) -> some View {
        let isSelected = filterLevel == level
        return Button(label) {
            filterLevel = level
        }
        .font(.caption2.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(isSelected ? .white : ForagerTheme.textSecondary)
        // reskin-provisions-press: printed tag corners — sharp, not capsule
        .background(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                .fill(isSelected ? ForagerTheme.accentPrimary : ForagerTheme.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs, style: .continuous)
                .stroke(isSelected ? Color.clear : ForagerTheme.borderStrong, lineWidth: 1)
        )
    }

    // MARK: - Data

    private var filteredLogText: String {
        var text = logText

        // Filter by level
        if let level = filterLevel {
            let lines = text.components(separatedBy: "\n")
            text = lines.filter { $0.contains("[\(level.rawValue)]") }.joined(separator: "\n")
        }

        // Filter by search text
        if !searchText.isEmpty {
            let lines = text.components(separatedBy: "\n")
            text = lines.filter { $0.localizedCaseInsensitiveContains(searchText) }.joined(separator: "\n")
        }

        return text.isEmpty ? "(no matching entries)" : text
    }

    private func loadLog() {
        logText = logger.readLog()
    }
}

// MARK: - Share Sheet (local — existing ShareSheet uses invitation-specific API)

private struct DiagnosticShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct DiagnosticLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DiagnosticLogView()
        }
    }
}
