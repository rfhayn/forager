//
//  IngredientTokenizer.swift
//  forager
//
//  Created for M8.4 Phase 8: Shared tokenizer for ML inference and correction export
//  Extracted from MLIngredientParser.tokenize() to ensure token consistency
//  across inference and training data generation.
//

import Foundation

// MARK: - Punctuation Set (must match TOKENIZER_SPEC.md)

/// Punctuation characters that get split into separate tokens.
/// Hyphens (-) and apostrophes (') are NOT split — part of compound words/contractions.
private let tokenizerPunctuation: Set<Character> = [
    ".", ",", ";", ":", "!", "?",
    "(", ")", "[", "]", "{", "}",
    "\"", "/"
]

// MARK: - Shared Tokenizer

/// Tokenize ingredient text following the frozen TOKENIZER_SPEC contract.
/// Used by MLIngredientParser (inference) and ParsingTelemetryService (export).
///
/// Pipeline: NFKD normalize → strip diacritics → lowercase → whitespace normalize → punctuation split → truncate.
/// Cross-validate against Tools/ml-training/data/tokenizer_test_vectors.json.
func foragerTokenize(_ text: String, maxTokens: Int = 64) -> [String] {
    // Step 1: NFKD normalization (NOT NFD — Swift's .decomposedStringWithCanonicalMapping is NFD)
    guard let normalized = text.applyingTransform(
        StringTransform("NFKD"), reverse: false
    ) else { return text.split(separator: " ").map(String.init) }

    // Step 2: Strip combining marks (diacritics) — matches Python's encode('ascii','ignore')
    // After NFKD, ñ becomes n + combining tilde (U+0303). Stripping Unicode category M
    // characters produces the ASCII-folded form the model was trained on.
    let stripped = String(normalized.unicodeScalars.filter {
        !CharacterSet.nonBaseCharacters.contains($0)
    })

    // Step 3: Lowercase
    let lowered = stripped.lowercased()

    // Step 4: Whitespace normalization (strip + collapse)
    let collapsed = lowered.split(omittingEmptySubsequences: true,
                                   whereSeparator: \.isWhitespace)
                           .joined(separator: " ")

    // Step 5: Punctuation splitting
    // Periods (.) and slashes (/) between digits are NOT split — preserves decimals and fractions
    let chars = Array(collapsed)
    var result: [Character] = []
    for (i, char) in chars.enumerated() {
        if tokenizerPunctuation.contains(char) {
            let prevIsDigit = i > 0 && chars[i - 1].isNumber
            let nextIsDigit = i < chars.count - 1 && chars[i + 1].isNumber
            if (char == "." || char == "/") && prevIsDigit && nextIsDigit {
                // Keep . and / between digits (decimals: 14.5, fractions: 1/4)
                result.append(char)
            } else {
                result.append(" ")
                result.append(char)
                result.append(" ")
            }
        } else {
            result.append(char)
        }
    }

    let tokens = String(result)
        .split(omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        .map(String.init)

    // Step 6: Truncate to maxTokens
    return Array(tokens.prefix(maxTokens))
}
