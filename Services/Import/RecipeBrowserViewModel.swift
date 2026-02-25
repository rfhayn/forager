//
//  RecipeBrowserViewModel.swift
//  forager
//
//  Created for M10.1.9: In-app browser for recipe import
//  Manages WKWebView state and recipe extraction from loaded pages.
//  Replaces share extension with Paprika-style browse-and-import UX.
//

import Foundation
import WebKit
import Combine

// MARK: - Recipe Browser View Model

/// Manages WKWebView navigation state and recipe extraction for the in-app browser.
/// Uses KVO to observe WKWebView properties (URL, title, loading, progress, canGoBack/Forward).
/// Extraction pipes rendered HTML through RecipeJSONLDExtractor → SchemaRecipeMapper.
@MainActor @Observable
class RecipeBrowserViewModel {

    // MARK: - Navigation State

    var currentURL: URL?
    var urlText: String = ""
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var isLoading: Bool = false
    var estimatedProgress: Double = 0
    var pageTitle: String = ""

    // MARK: - Extraction State

    var isExtracting: Bool = false

    // MARK: - Private

    private weak var webView: WKWebView?
    private var observations: [NSKeyValueObservation] = []

    // MARK: - WebView Setup

    /// Called by UIViewRepresentable coordinator to connect KVO observations.
    func setWebView(_ webView: WKWebView) {
        self.webView = webView
        setupObservations(webView)
    }

    // MARK: - Navigation

    func navigate(to urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Add https:// if no scheme present
        let urlCandidate: String
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            urlCandidate = trimmed
        } else {
            urlCandidate = "https://\(trimmed)"
        }

        guard let url = URL(string: urlCandidate) else { return }
        webView?.load(URLRequest(url: url))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    // MARK: - Recipe Extraction

    /// Extract recipe JSON-LD from the currently loaded page.
    /// User already waited for page load, so no settle delay needed
    /// (unlike WKWebViewExtractor's 2s wait for headless rendering).
    func extractRecipeFromCurrentPage() async -> ImportDraftRecipe? {
        guard let webView = webView else { return nil }
        isExtracting = true
        defer { isExtracting = false }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Get rendered HTML from live WKWebView
        guard let html = try? await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String else {
            return nil
        }

        // Pipe through JSON-LD extractor (same path as WKWebViewExtractor)
        var context = ExtractionContext()
        context.extractorChain.append("browser")

        guard let (recipeDict, updatedContext) = RecipeJSONLDExtractor.extractRecipeDict(
            from: html,
            context: &context
        ) else {
            return nil
        }

        let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        let draft = SchemaRecipeMapper.map(
            recipeDict,
            sourceURL: currentURL?.absoluteString,
            extractionMethod: updatedContext.extractorChain.last ?? "browser",
            extractionTimeMs: elapsedMs
        )

        return draft
    }

    // MARK: - KVO Observations

    private func setupObservations(_ webView: WKWebView) {
        observations.removeAll()

        observations.append(webView.observe(\.url, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.currentURL = wv.url
                if let url = wv.url?.absoluteString {
                    self?.urlText = url
                }
            }
        })

        observations.append(webView.observe(\.title, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.pageTitle = wv.title ?? ""
            }
        })

        observations.append(webView.observe(\.isLoading, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.isLoading = wv.isLoading
            }
        })

        observations.append(webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.estimatedProgress = wv.estimatedProgress
            }
        })

        observations.append(webView.observe(\.canGoBack, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.canGoBack = wv.canGoBack
            }
        })

        observations.append(webView.observe(\.canGoForward, options: .new) { [weak self] wv, _ in
            Task { @MainActor in
                self?.canGoForward = wv.canGoForward
            }
        })
    }
}
