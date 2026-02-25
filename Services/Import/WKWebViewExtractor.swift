//
//  WKWebViewExtractor.swift
//  forager
//
//  Created for M10.1.5: WKWebView fallback extractor
//  Loads URLs in a headless WKWebView to capture JS-rendered recipe JSON-LD.
//  ~30% of recipe sites inject JSON-LD via client-side JS (WordPress WPRM/Tasty plugins).
//  Uses the URL from input, ignores pre-fetched HTML, renders JS, then pipes through JSON-LD extractor.
//

import Foundation
import WebKit

// MARK: - WKWebView Recipe Extractor

/// Fallback extractor that renders pages in a headless WKWebView to capture
/// JS-injected JSON-LD. Used when URLSession HTML lacks recipe structured data.
///
/// Flow: load URL → wait for navigation finish + 2s JS settle → extract rendered HTML
/// → pipe through RecipeJSONLDExtractor → return ImportDraftRecipe.
///
/// Assumption: WKWebView renders JS without being in a view hierarchy.
/// Validated on iOS 18+. If this breaks, fallback: add invisible WKWebView to window.
@MainActor
class WKWebViewExtractor: NSObject, RecipeExtractor, WKNavigationDelegate {

    let extractorName = "wkwebview"

    /// JS settle time after DOMContentLoaded (seconds).
    /// 2s covers most WordPress recipe plugins (WPRM, Tasty, WP Delicious).
    private let settleTime: TimeInterval = 2.0

    /// Maximum total time before extracting whatever HTML is available.
    private let timeout: TimeInterval = 8.0

    private var continuation: CheckedContinuation<String?, Never>?
    private var webView: WKWebView?
    private var timeoutTask: Task<Void, Never>?

    // MARK: - RecipeExtractor Protocol

    func extract(from input: RecipeExtractionInput) async throws -> ImportDraftRecipe? {
        guard case .html(_, let url) = input else { return nil }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Render the page in WKWebView
        guard let renderedHTML = await loadAndRender(url: url) else {
            return nil
        }

        // Pipe rendered HTML through JSON-LD extractor
        var context = ExtractionContext()
        context.extractorChain.append(extractorName)

        guard let (recipeDict, updatedContext) = RecipeJSONLDExtractor.extractRecipeDict(
            from: renderedHTML,
            context: &context
        ) else {
            return nil
        }

        let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        var draft = SchemaRecipeMapper.map(
            recipeDict,
            sourceURL: url.absoluteString,
            extractionMethod: updatedContext.extractorChain.last ?? extractorName,
            extractionTimeMs: elapsedMs
        )

        // Enhance title from HTML metadata when JSON-LD name is incomplete
        RecipeJSONLDExtractor.enhanceTitleFromHTML(&draft, html: renderedHTML)

        return draft
    }

    // MARK: - WKWebView Rendering

    /// Load a URL in WKWebView and return rendered HTML after JS execution.
    /// Returns nil if the page fails to load entirely.
    private func loadAndRender(url: URL) async -> String? {
        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            let config = WKWebViewConfiguration()
            config.suppressesIncrementalRendering = true
            let webView = WKWebView(frame: .zero, configuration: config)
            webView.navigationDelegate = self
            self.webView = webView

            webView.load(URLRequest(url: url))

            // Timeout: extract whatever HTML is available after max wait
            self.timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(self?.timeout ?? 8.0) * 1_000_000_000)
                self?.finishExtraction()
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Wait for JS settle time before extracting
        Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.settleTime * 1_000_000_000))
            self.finishExtraction()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        resumeContinuation(with: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        resumeContinuation(with: nil)
    }

    // MARK: - HTML Extraction

    /// Extract rendered HTML from WKWebView and resume the continuation.
    /// Safe to call multiple times — only the first call resumes.
    private func finishExtraction() {
        guard let webView = self.webView, self.continuation != nil else { return }

        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
            Task { @MainActor in
                self?.resumeContinuation(with: result as? String)
            }
        }
    }

    /// Resume continuation exactly once, then clean up resources.
    private func resumeContinuation(with html: String?) {
        guard let continuation = self.continuation else { return }
        self.continuation = nil
        cleanup()
        continuation.resume(returning: html)
    }

    private func cleanup() {
        timeoutTask?.cancel()
        timeoutTask = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView = nil
    }
}
