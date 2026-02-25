//
//  ShareViewController.swift
//  ForagerShareExtension
//
//  M10.1.7: Minimal share extension — extracts URL, hands off to main app.
//  No UI shown. Writes URL to App Group UserDefaults, opens main app
//  via forager://import URL scheme, then completes the extension request.
//

import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extractURLAndHandoff()
    }

    // MARK: - URL Extraction + Handoff

    private func extractURLAndHandoff() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            complete()
            return
        }

        // Search attachments for a URL
        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.handoffURL(url)
                            } else if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                                self?.handoffURL(url)
                            } else {
                                self?.complete()
                            }
                        }
                    }
                    return
                }
            }
        }

        // No URL found in attachments
        complete()
    }

    private func handoffURL(_ url: URL) {
        // Write URL to App Group shared container
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.richhayn.forager") else {
            complete()
            return
        }
        sharedDefaults.set(url.absoluteString, forKey: "pendingImportURL")

        // Open main app via registered URL scheme
        guard let appURL = URL(string: "forager://import") else {
            complete()
            return
        }

        extensionContext?.open(appURL) { [weak self] success in
            if !success {
                // URL remains in App Group defaults — consumed on next app launch
                #if DEBUG
                print("⚠️ Could not open main app. URL saved for next launch.")
                #endif
            }
            self?.complete()
        }
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
