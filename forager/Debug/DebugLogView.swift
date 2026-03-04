//
//  DebugLogView.swift
//  forager
//
//  M10.6.5: View for displaying and copying debug logs.
//  M10.6.13: Ungated for Release builds — accessible via Settings > Developer Tools.
//

import SwiftUI

struct DebugLogView: View {

    @StateObject private var logService = DebugLogService.shared
    @State private var copiedToast = false

    var body: some View {
        VStack(spacing: 0) {
            if logService.entries.isEmpty {
                ContentUnavailableView(
                    "No Logs Yet",
                    systemImage: "doc.text",
                    description: Text("Enable debug mode and trigger an AI parse to see logs here.")
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(logService.entries.enumerated()), id: \.offset) { index, entry in
                                Text(entry)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(colorForEntry(entry))
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .onChange(of: logService.entries.count) { _, newCount in
                        if newCount > 0 {
                            withAnimation {
                                proxy.scrollTo(newCount - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Debug Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = logService.fullLog
                    copiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copiedToast = false
                    }
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                }
                .disabled(logService.entries.isEmpty)

                Button {
                    logService.clear()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(logService.entries.isEmpty)
            }
        }
        .overlay(alignment: .bottom) {
            if copiedToast {
                Text("Copied to clipboard")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: copiedToast)
    }

    private func colorForEntry(_ entry: String) -> Color {
        if entry.contains("[ERROR]") || entry.contains("failed") || entry.contains("error") {
            return .red
        } else if entry.contains("[LLM]") {
            return .purple
        } else if entry.contains("[Settings]") {
            return .blue
        }
        return .primary
    }
}
