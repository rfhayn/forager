import Foundation

// MARK: - Recipe URL Discovery

/// Selects recipe URLs for a test run from seed list, previous runs, and sitemap discovery.
struct RecipeDiscovery {

    struct SelectedURL: Codable {
        let url: String
        let source: URLSource
        let site: String

        enum URLSource: String, Codable {
            case reuse
            case seed
            case discovered
        }
    }

    private let dataDir: URL
    private let resultsDir: URL
    private let targetCount: Int
    private let reusePercentage: Int

    init(dataDir: URL, resultsDir: URL, targetCount: Int = 50, reusePercentage: Int = 40) {
        self.dataDir = dataDir
        self.resultsDir = resultsDir
        self.targetCount = targetCount
        self.reusePercentage = reusePercentage
    }

    // MARK: - Public API

    /// Select URLs for a run. Returns exactly targetCount URLs (or fewer if seed exhausted).
    func selectURLs(rerunLast: Bool = false, specificURLs: [String]? = nil) -> [SelectedURL] {
        // Specific URLs override everything
        if let urls = specificURLs, !urls.isEmpty {
            return urls.map { SelectedURL(url: $0, source: .seed, site: siteTag(for: $0)) }
        }

        var seedList = loadSeedList()
        let previousURLs = loadPreviousURLs()

        // --rerun-last: use exact same URLs
        if rerunLast {
            return previousURLs
        }

        var selected: [SelectedURL] = []
        var usedURLs = Set<String>()

        // Step 1: Reuse from previous run
        let reuseCount = min(targetCount * reusePercentage / 100, previousURLs.count)
        let reused = previousURLs.shuffled().prefix(reuseCount)
        for url in reused {
            selected.append(SelectedURL(url: url.url, source: .reuse, site: url.site))
            usedURLs.insert(url.url)
        }

        // Step 2: Fill from seed list (excluding broken and already-used)
        let healthySeed = seedList.entries.filter { !$0.broken && !usedURLs.contains($0.url) }
        let needed = targetCount - selected.count
        let newPicks = healthySeed.shuffled().prefix(needed)
        for entry in newPicks {
            selected.append(SelectedURL(url: entry.url, source: .seed, site: entry.site))
            usedURLs.insert(entry.url)
        }

        // Step 3: If still short, try sitemap discovery
        if selected.count < targetCount {
            let shortfall = targetCount - selected.count
            let discovered = discoverFromSitemaps(count: shortfall + 20, excluding: usedURLs)
            for url in discovered.prefix(shortfall) {
                selected.append(url)
                usedURLs.insert(url.url)
                // Add to seed list for future runs
                seedList.entries.append(SeedEntry(url: url.url, site: url.site, broken: false, source: "discovered"))
            }
            saveSeedList(seedList)
        }

        // Warn if seed list is running low
        let healthyRemaining = seedList.entries.filter { !$0.broken }.count - selected.count
        if healthyRemaining < 50 {
            printErr("⚠️  Seed list running thin — \(healthyRemaining) healthy URLs remaining. Consider adding more.")
        }

        return selected.shuffled()
    }

    /// Mark a URL as broken (won't be selected again).
    func markBroken(url: String, reason: String) {
        var seedList = loadSeedList()
        if let idx = seedList.entries.firstIndex(where: { $0.url == url }) {
            seedList.entries[idx].broken = true
            seedList.entries[idx].brokenReason = reason
            saveSeedList(seedList)
        }
    }

    /// Pull a replacement URL from the seed list.
    func getReplacement(excluding: Set<String>) -> SelectedURL? {
        let seedList = loadSeedList()
        let healthy = seedList.entries.filter { !$0.broken && !excluding.contains($0.url) }
        guard let pick = healthy.randomElement() else { return nil }
        return SelectedURL(url: pick.url, source: .seed, site: pick.site)
    }

    /// Save the URLs from this run for future reuse.
    func savePreviousURLs(_ urls: [SelectedURL]) {
        let path = resultsDir.appendingPathComponent("previous-urls.json")
        if let data = try? JSONEncoder().encode(urls) {
            try? data.write(to: path)
        }
    }

    // MARK: - Seed List I/O

    struct SeedList: Codable {
        var entries: [SeedEntry]
    }

    struct SeedEntry: Codable {
        let url: String
        let site: String
        var broken: Bool
        var brokenReason: String?
        var source: String?  // "curated" or "discovered"
    }

    func loadSeedList() -> SeedList {
        let path = dataDir.appendingPathComponent("recipe-urls.json")
        guard let data = try? Data(contentsOf: path),
              let list = try? JSONDecoder().decode(SeedList.self, from: data) else {
            return SeedList(entries: [])
        }
        return list
    }

    private func saveSeedList(_ list: SeedList) {
        let path = dataDir.appendingPathComponent("recipe-urls.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(list) {
            try? data.write(to: path)
        }
    }

    private func loadPreviousURLs() -> [SelectedURL] {
        let path = resultsDir.appendingPathComponent("previous-urls.json")
        guard let data = try? Data(contentsOf: path),
              let urls = try? JSONDecoder().decode([SelectedURL].self, from: data) else {
            return []
        }
        return urls
    }

    // MARK: - Sitemap Discovery

    struct SitemapSource: Codable {
        let site: String
        let sitemap: String
    }

    private func discoverFromSitemaps(count: Int, excluding: Set<String>) -> [SelectedURL] {
        let sourcesPath = dataDir.appendingPathComponent("sitemap-sources.json")
        guard let data = try? Data(contentsOf: sourcesPath),
              let sources = try? JSONDecoder().decode([SitemapSource].self, from: data) else {
            printErr("⚠️  No sitemap-sources.json found — can't discover new URLs")
            return []
        }

        var discovered: [SelectedURL] = []
        for source in sources.shuffled() {
            if discovered.count >= count { break }

            guard let sitemapURL = URL(string: source.sitemap),
                  let sitemapData = try? Data(contentsOf: sitemapURL),
                  let sitemapXML = String(data: sitemapData, encoding: .utf8) else {
                continue
            }

            let urls = parseRecipeURLsFromSitemap(sitemapXML)
                .filter { !excluding.contains($0) }
                .shuffled()

            for url in urls.prefix(count - discovered.count) {
                discovered.append(SelectedURL(url: url, source: .discovered, site: source.site))
            }
        }

        if !discovered.isEmpty {
            printErr("📡 Discovered \(discovered.count) new URLs from sitemaps")
        }
        return discovered
    }

    private func parseRecipeURLsFromSitemap(_ xml: String) -> [String] {
        // Simple regex extraction of <loc> URLs that look like recipes
        let locPattern = #"<loc>(https?://[^<]+)</loc>"#
        guard let regex = try? NSRegularExpression(pattern: locPattern) else { return [] }
        let range = NSRange(xml.startIndex..., in: xml)
        let matches = regex.matches(in: xml, range: range)

        return matches.compactMap { match -> String? in
            guard let urlRange = Range(match.range(at: 1), in: xml) else { return nil }
            let url = String(xml[urlRange])
            // Filter for recipe-looking URLs
            let lower = url.lowercased()
            if lower.contains("/recipe/") || lower.contains("/recipes/") {
                return url
            }
            return nil
        }
    }

    // MARK: - Helpers

    func siteTag(for url: String) -> String {
        guard let host = URL(string: url)?.host else { return "unknown" }
        return host.replacingOccurrences(of: "www.", with: "")
            .components(separatedBy: ".").first ?? host
    }
}

func printErr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
