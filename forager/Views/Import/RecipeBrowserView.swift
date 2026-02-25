//
//  RecipeBrowserView.swift
//  forager
//
//  Created for M10.1.9: In-app browser for recipe import
//  Paprika-style browse-and-import: navigate to recipe → tap Import → preview → save.
//  Presented as fullScreenCover from RecipeListView.
//

import SwiftUI
import WebKit

// MARK: - Recipe Browser View

/// Full-screen in-app browser for navigating to recipe pages and importing them.
/// Address bar + navigation controls + WKWebView + "Import This Recipe" button.
/// Extraction flows into existing RecipeImportSheet for preview/save/duplicate handling.
struct RecipeBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var importService: RecipeImportService

    @State private var viewModel = RecipeBrowserViewModel()
    @State private var showingImportSheet = false
    @State private var extractionFailed = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                if viewModel.isLoading {
                    ProgressView(value: viewModel.estimatedProgress)
                        .tint(ForagerTheme.accentPrimary)
                }

                // Address bar
                addressBar

                // Web content
                WebViewRepresentable(viewModel: viewModel)
            }
            .navigationTitle(viewModel.pageTitle.isEmpty ? "Browse for Recipe" : viewModel.pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await extractRecipe() }
                    } label: {
                        Label("Import This Recipe", systemImage: "square.and.arrow.down")
                    }
                    .disabled(viewModel.isExtracting || viewModel.currentURL == nil)
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                RecipeImportSheet(importService: importService)
            }
            .alert("No Recipe Found", isPresented: $extractionFailed) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("We couldn't find recipe data on this page. Try navigating directly to a recipe page.")
            }
        }
    }

    // MARK: - Address Bar

    private var addressBar: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            // Navigation buttons
            Button(action: viewModel.goBack) {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)

            Button(action: viewModel.goForward) {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)

            // URL field
            TextField("Search or enter URL", text: $viewModel.urlText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .onSubmit {
                    viewModel.navigate(to: viewModel.urlText)
                }

            // Reload / Stop
            if viewModel.isLoading {
                Button(action: { viewModel.reload() }) {
                    Image(systemName: "xmark")
                }
            } else {
                Button(action: { viewModel.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.currentURL == nil)
            }
        }
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .background(ForagerTheme.surfaceSecondary)
    }

    // MARK: - Actions

    private func extractRecipe() async {
        guard let draft = await viewModel.extractRecipeFromCurrentPage() else {
            extractionFailed = true
            return
        }
        importService.state = .needsReview(draft)
        showingImportSheet = true
    }
}

// MARK: - WKWebView UIViewRepresentable

/// Wraps WKWebView for SwiftUI. Coordinator handles WKNavigationDelegate.
struct WebViewRepresentable: UIViewRepresentable {
    var viewModel: RecipeBrowserViewModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        viewModel.setWebView(webView)

        // Load a default search page
        if let url = URL(string: "https://www.google.com") {
            webView.load(URLRequest(url: url))
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed — KVO handles state sync
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            // Allow all navigation — user is browsing freely
            .allow
        }
    }
}
