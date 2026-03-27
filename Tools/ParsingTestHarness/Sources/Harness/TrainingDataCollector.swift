import Foundation

// MARK: - Training Data Collector

/// Collects AI-labeled parsing results as training data for the BiLSTM-CRF ML model.
/// Accumulates entries across runs, deduplicating by raw ingredient text (latest wins).
struct TrainingDataCollector {

    // MARK: - Data Types

    struct TrainingDataEntry: Codable {
        let rawText: String
        let sanitizedText: String

        // AI parse (ground truth for training)
        let aiName: String
        let aiQuantity: Double?
        let aiUnit: String?
        let aiNotes: String?

        // Local parse (for comparison / error analysis)
        let localName: String
        let localQuantity: Double?
        let localUnit: String?
        let localNotes: String?
        let localConfidence: Float
        let localParserUsed: String

        // Metadata
        let agreement: String
        let source: String
        let collectedAt: String
    }

    struct TrainingDataFile: Codable {
        var version: Int
        var entries: [TrainingDataEntry]
        var lastUpdated: String

        init(version: Int = 1, entries: [TrainingDataEntry], lastUpdated: String) {
            self.version = version
            self.entries = entries
            self.lastUpdated = lastUpdated
        }
    }

    // MARK: - BIO Export Types

    struct BIOTaggedSample: Codable {
        let tokens: [String]
        let tags: [String]
        let rawText: String
    }

    struct BIOExportFile: Codable {
        let version: Int
        let generatedAt: String
        let sampleCount: Int
        let samples: [BIOTaggedSample]

        init(version: Int = 1, generatedAt: String, sampleCount: Int, samples: [BIOTaggedSample]) {
            self.version = version
            self.generatedAt = generatedAt
            self.sampleCount = sampleCount
            self.samples = samples
        }
    }

    // MARK: - Collect

    /// Extract training entries from recipe results that have AI data.
    func collect(from recipeResults: [ParsingEvaluator.RecipeResult]) -> [TrainingDataEntry] {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        var entries: [TrainingDataEntry] = []

        for recipe in recipeResults {
            for ingredient in recipe.ingredients {
                guard let ai = ingredient.ai else { continue }

                let comparison = ResultComparer.compare(ingredient: ingredient)

                entries.append(TrainingDataEntry(
                    rawText: ingredient.raw,
                    sanitizedText: ingredient.sanitized,
                    aiName: ai.name,
                    aiQuantity: ai.quantity,
                    aiUnit: ai.unit,
                    aiNotes: ai.notes,
                    localName: ingredient.hybrid.name,
                    localQuantity: ingredient.hybrid.quantity,
                    localUnit: ingredient.hybrid.unit,
                    localNotes: ingredient.hybrid.notes,
                    localConfidence: ingredient.hybrid.confidence,
                    localParserUsed: ingredient.hybrid.parserUsed,
                    agreement: comparison.agreement.rawValue,
                    source: recipe.url,
                    collectedAt: timestamp
                ))
            }
        }

        return entries
    }

    // MARK: - Load / Save with Deduplication

    /// Load existing training data from a file.
    func load(from url: URL) -> TrainingDataFile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TrainingDataFile.self, from: data)
    }

    /// Save new entries, merging with any existing data. Deduplicates by rawText (latest wins).
    /// Returns the total entry count after merge.
    @discardableResult
    func save(newEntries: [TrainingDataEntry], to url: URL) -> Int {
        var existing = load(from: url)?.entries ?? []

        // Build index of existing entries by rawText for O(1) lookup
        var indexByRawText: [String: Int] = [:]
        for (i, entry) in existing.enumerated() {
            indexByRawText[entry.rawText] = i
        }

        // Merge: latest wins for duplicates, append new
        for entry in newEntries {
            if let existingIdx = indexByRawText[entry.rawText] {
                existing[existingIdx] = entry
            } else {
                indexByRawText[entry.rawText] = existing.count
                existing.append(entry)
            }
        }

        let file = TrainingDataFile(
            entries: existing,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(file) {
            try? data.write(to: url, options: .atomic)
        }

        return existing.count
    }

    // MARK: - BIO Export for ML Training

    /// Export training data as BIO-tagged token sequences suitable for BiLSTM-CRF training.
    func exportForMLTraining(from url: URL, to exportURL: URL) -> Int {
        guard let file = load(from: url) else {
            printErr("No training data found at \(url.path)")
            return 0
        }

        var samples: [BIOTaggedSample] = []

        for entry in file.entries {
            let tokens = foragerTokenize(entry.sanitizedText)
            guard !tokens.isEmpty else { continue }

            let tags = assignBIOTags(
                tokens: tokens,
                name: entry.aiName,
                quantity: entry.aiQuantity,
                unit: entry.aiUnit,
                notes: entry.aiNotes
            )

            samples.append(BIOTaggedSample(
                tokens: tokens,
                tags: tags,
                rawText: entry.rawText
            ))
        }

        let exportFile = BIOExportFile(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            sampleCount: samples.count,
            samples: samples
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(exportFile) {
            try? data.write(to: exportURL, options: .atomic)
        }

        return samples.count
    }

    // MARK: - BIO Tagging

    /// Assign BIO tags to tokens based on the AI-parsed fields.
    /// Tags: B-QTY, I-QTY, B-UNIT, I-UNIT, B-NAME, I-NAME, B-NOTE, I-NOTE, O
    private func assignBIOTags(
        tokens: [String],
        name: String,
        quantity: Double?,
        unit: String?,
        notes: String?
    ) -> [String] {
        var tags = Array(repeating: "O", count: tokens.count)
        var claimed = Array(repeating: false, count: tokens.count)

        // Tag quantity tokens first (usually at the start)
        if let qty = quantity {
            let qtyStr = formatQuantity(qty)
            let qtyTokens = foragerTokenize(qtyStr)
            if let range = findTokenRange(qtyTokens, in: tokens, claimed: claimed) {
                tagRange(range, prefix: "QTY", tags: &tags, claimed: &claimed)
            }
        }

        // Tag unit tokens
        if let unitStr = unit, !unitStr.isEmpty {
            let unitTokens = foragerTokenize(unitStr)
            if let range = findTokenRange(unitTokens, in: tokens, claimed: claimed) {
                tagRange(range, prefix: "UNIT", tags: &tags, claimed: &claimed)
            }
        }

        // Tag name tokens
        if !name.isEmpty {
            let nameTokens = foragerTokenize(name)
            if let range = findTokenRange(nameTokens, in: tokens, claimed: claimed) {
                tagRange(range, prefix: "NAME", tags: &tags, claimed: &claimed)
            }
        }

        // Tag notes tokens
        if let notesStr = notes, !notesStr.isEmpty {
            let notesTokens = foragerTokenize(notesStr)
            if let range = findTokenRange(notesTokens, in: tokens, claimed: claimed) {
                tagRange(range, prefix: "NOTE", tags: &tags, claimed: &claimed)
            }
        }

        return tags
    }

    /// Find a contiguous subsequence of target tokens within the source tokens.
    private func findTokenRange(_ target: [String], in source: [String], claimed: [Bool]) -> Range<Int>? {
        guard !target.isEmpty, target.count <= source.count else { return nil }

        for i in 0...(source.count - target.count) {
            // Skip if first position is already claimed
            if claimed[i] { continue }

            var match = true
            for j in 0..<target.count {
                if source[i + j] != target[j] || claimed[i + j] {
                    match = false
                    break
                }
            }
            if match {
                return i..<(i + target.count)
            }
        }
        return nil
    }

    /// Apply B-/I- prefix tags for a range.
    private func tagRange(_ range: Range<Int>, prefix: String, tags: inout [String], claimed: inout [Bool]) {
        for (offset, idx) in range.enumerated() {
            tags[idx] = (offset == 0 ? "B-\(prefix)" : "I-\(prefix)")
            claimed[idx] = true
        }
    }

    /// Format a quantity for tokenization matching.
    private func formatQuantity(_ qty: Double) -> String {
        if qty == qty.rounded() && qty < 10000 {
            return String(Int(qty))
        }
        return String(qty)
    }
}
