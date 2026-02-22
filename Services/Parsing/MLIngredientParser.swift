//
//  MLIngredientParser.swift
//  forager
//
//  Created for M8.4: ML-Powered Parsing
//  BiLSTM-CRF ingredient parser: CoreML emissions + Swift Viterbi decoding
//

import Foundation
import CoreML

// MARK: - MLIngredientParser

/// ML-powered ingredient parser using a BiLSTM-CRF model.
/// Pipeline: tokenize → vocabulary lookup → CoreML emissions → Viterbi decode → assemble result.
/// Returns `nil` from `init` if any resource (model, vocabulary, transitions) is unavailable,
/// allowing HybridIngredientParser to skip the ML tier gracefully.
class MLIngredientParser: IngredientParser {

    let parserName = "ml"

    private let model: IngredientTaggerEmissions
    private let vocabulary: [String: Int]
    private let viterbiDecoder: ViterbiDecoder

    // MARK: - Initialization

    init?() {
        guard let model = try? IngredientTaggerEmissions(configuration: MLModelConfiguration()) else {
            return nil
        }
        guard let vocab = Self.loadVocabulary(),
              let decoder = Self.loadViterbiDecoder() else {
            return nil
        }
        self.model = model
        self.vocabulary = vocab
        self.viterbiDecoder = decoder
    }

    // MARK: - IngredientParser Protocol

    func parse(_ input: String) -> ParserResult {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else {
            return fallbackResult(input)
        }

        // Map tokens to vocabulary IDs (unknown → UNK=0)
        let tokenIds = tokens.map { vocabulary[$0] ?? 0 }

        // CoreML emission scores
        guard let emissions = runEmissionModel(tokenIds: tokenIds) else {
            return fallbackResult(input)
        }

        // Viterbi decode (CRF step, in Swift)
        let labelSequence = viterbiDecoder.decode(emissions: emissions)

        // Assemble structured result from token-label pairs
        return assembleResult(tokens: tokens, labels: labelSequence, emissions: emissions, originalText: input)
    }

    // MARK: - Tokenizer (delegates to shared foragerTokenize)

    /// Tokenize input text following the frozen tokenizer contract.
    /// Delegates to shared `foragerTokenize()` in IngredientTokenizer.swift.
    func tokenize(_ text: String) -> [String] {
        return foragerTokenize(text)
    }

    // MARK: - CoreML Inference

    private func runEmissionModel(tokenIds: [Int]) -> [[Float]]? {
        guard let inputArray = try? MLMultiArray(
            shape: [1, tokenIds.count as NSNumber],
            dataType: .int32
        ) else { return nil }

        for (i, id) in tokenIds.enumerated() {
            inputArray[[0, i] as [NSNumber]] = NSNumber(value: Int32(id))
        }

        guard let output = try? model.prediction(token_ids: inputArray) else {
            return nil
        }

        // Extract emissions from MLMultiArray [1, seq_len, 7] using subscript access
        // Do NOT assume contiguous Float32 layout — Neural Engine may use Float16
        let emissions = output.emissions
        let seqLen = emissions.shape[1].intValue
        let numLabels = emissions.shape[2].intValue

        var result = [[Float]]()
        for t in 0..<seqLen {
            var row = [Float]()
            for j in 0..<numLabels {
                row.append(emissions[[0, t, j] as [NSNumber]].floatValue)
            }
            result.append(row)
        }
        return result
    }

    // MARK: - Result Assembly

    private func assembleResult(tokens: [String], labels: [String], emissions: [[Float]], originalText: String) -> ParserResult {
        var qtyTokens: [String] = []
        var unitTokens: [String] = []
        var nameTokens: [String] = []
        var noteTokens: [String] = []

        for (token, label) in zip(tokens, labels) {
            switch label {
            case "QTY":
                qtyTokens.append(token)
            case "UNIT":
                unitTokens.append(token)
            case "NAME", "MODIFIER":
                nameTokens.append(token)
            case "PREP", "COMMENT":
                noteTokens.append(token)
            default:
                break // OTHER — punctuation, dropped
            }
        }

        let quantity = parseQuantity(qtyTokens)
        let unit = standardizeUnit(unitTokens.joined(separator: " "))
        let name = nameTokens.joined(separator: " ")
        let notes: String? = noteTokens.isEmpty ? nil : noteTokens.joined(separator: " ")
        let confidence = calculateConfidence(emissions: emissions)

        return ParserResult(
            name: name.isEmpty ? originalText.trimmingCharacters(in: .whitespacesAndNewlines) : name,
            quantity: quantity,
            unit: unit,
            notes: notes,
            confidence: confidence,
            originalText: originalText,
            parserUsed: parserName
        )
    }

    // MARK: - Quantity Parsing

    /// Parse numeric quantity from QTY-labeled tokens.
    /// Handles: integers, decimals, fractions (regular and Unicode fraction slash), mixed fractions.
    private func parseQuantity(_ tokens: [String]) -> Double? {
        guard !tokens.isEmpty else { return nil }
        let joined = tokens.joined(separator: " ")

        // Simple number: "2", "1.5", "0.75"
        if let value = Double(joined) {
            return value
        }

        // Fraction: "1/2", "3/4", or NFKD-decomposed "1⁄2" (U+2044 fraction slash)
        if tokens.count == 1 {
            for sep in [Character("/"), Character("\u{2044}")] {
                if joined.contains(sep) {
                    let parts = joined.split(separator: sep)
                    if parts.count == 2,
                       let num = Double(parts[0]),
                       let den = Double(parts[1]),
                       den != 0 {
                        return num / den
                    }
                }
            }
        }

        // Mixed fraction: "1 1/2" → 1.5, "2 3/4" → 2.75
        if tokens.count == 2, let whole = Double(tokens[0]) {
            for sep in [Character("/"), Character("\u{2044}")] {
                if tokens[1].contains(sep) {
                    let fracParts = tokens[1].split(separator: sep)
                    if fracParts.count == 2,
                       let num = Double(fracParts[0]),
                       let den = Double(fracParts[1]),
                       den != 0 {
                        return whole + num / den
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Confidence from Emission Softmax

    /// Geometric mean of max per-token softmax probability.
    /// High when model is confident about all tokens, low when uncertain about any token.
    private func calculateConfidence(emissions: [[Float]]) -> Float {
        guard !emissions.isEmpty else { return 0.0 }

        var logProbSum: Float = 0.0
        for row in emissions {
            // Numerically stable softmax
            let maxVal = row.max() ?? 0.0
            let exps = row.map { exp($0 - maxVal) }
            let sumExps = exps.reduce(0, +)
            let maxProb = (exps.max() ?? 0.0) / sumExps
            logProbSum += log(max(maxProb, 1e-10))
        }

        return min(exp(logProbSum / Float(emissions.count)), 1.0)
    }

    // MARK: - Unit Standardization

    private func standardizeUnit(_ unit: String) -> String? {
        let lowered = unit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lowered.isEmpty else { return nil }

        let unitMap: [String: String] = [
            "cup": "cup", "cups": "cup", "c": "cup",
            "tablespoon": "tbsp", "tablespoons": "tbsp", "tbsp": "tbsp", "tbs": "tbsp",
            "teaspoon": "tsp", "teaspoons": "tsp", "tsp": "tsp", "ts": "tsp",
            "ounce": "oz", "ounces": "oz", "oz": "oz",
            "pound": "lb", "pounds": "lb", "lb": "lb", "lbs": "lb",
            "gram": "g", "grams": "g", "g": "g",
            "kilogram": "kg", "kilograms": "kg", "kg": "kg",
            "liter": "l", "liters": "l", "l": "l",
            "milliliter": "ml", "milliliters": "ml", "ml": "ml",
            "fl oz": "fl oz", "fluid ounce": "fl oz", "fluid ounces": "fl oz",
            "pint": "pint", "pints": "pint", "pt": "pint",
            "quart": "quart", "quarts": "quart", "qt": "quart",
            "gallon": "gallon", "gallons": "gallon", "gal": "gallon",
            "can": "can", "cans": "can",
            "package": "package", "packages": "package", "pkg": "package",
            "clove": "clove", "cloves": "clove",
            "slice": "slice", "slices": "slice",
            "piece": "piece", "pieces": "piece", "pc": "piece",
            "bunch": "bunch", "bunches": "bunch",
            "head": "head", "heads": "head",
            "stick": "stick", "sticks": "stick",
            "bag": "bag", "bags": "bag",
            "bottle": "bottle", "bottles": "bottle",
            "box": "box", "boxes": "box",
            "jar": "jar", "jars": "jar",
            "sprig": "sprig", "sprigs": "sprig"
        ]

        return unitMap[lowered] ?? lowered
    }

    // MARK: - Fallback

    private func fallbackResult(_ input: String) -> ParserResult {
        ParserResult(
            name: input.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: nil, unit: nil, notes: nil,
            confidence: 0.0, originalText: input, parserUsed: parserName
        )
    }

    // MARK: - Resource Loading

    private static func loadVocabulary() -> [String: Int]? {
        guard let url = Bundle.main.url(forResource: "vocabulary", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([String: Int].self, from: data)
    }

    private static func loadViterbiDecoder() -> ViterbiDecoder? {
        guard let url = Bundle.main.url(forResource: "transitions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        // Key: "label_names" (not "labels" — matches actual JSON structure)
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let transitions = dict["transitions"] as? [[Double]],
              let startTransitions = dict["start_transitions"] as? [Double],
              let endTransitions = dict["end_transitions"] as? [Double],
              let labelNames = dict["label_names"] as? [String] else { return nil }
        return ViterbiDecoder(
            transitions: transitions.map { $0.map { Float($0) } },
            startTransitions: startTransitions.map { Float($0) },
            endTransitions: endTransitions.map { Float($0) },
            labels: labelNames
        )
    }
}
