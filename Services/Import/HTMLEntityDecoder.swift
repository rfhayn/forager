//
//  HTMLEntityDecoder.swift
//  forager
//
//  Created for M10.1.1: Import models + extraction infrastructure
//  Extracted from spike extractor — decodes HTML entities in JSON-LD strings.
//  Applied before JSON parsing to prevent parse failures (25% of spike sites had entities).
//

import Foundation

enum HTMLEntityDecoder {

    /// 16 named entities + common typographic entities found in recipe JSON-LD
    private static let namedEntities: [(String, String)] = [
        ("&amp;", "&"),
        ("&lt;", "<"),
        ("&gt;", ">"),
        ("&quot;", "\""),
        ("&#39;", "'"),
        ("&apos;", "'"),
        ("&#x27;", "'"),
        ("&#x2F;", "/"),
        ("&nbsp;", " "),
        ("&#8217;", "\u{2019}"),  // Right single quote
        ("&#8216;", "\u{2018}"),  // Left single quote
        ("&#8220;", "\u{201C}"),  // Left double quote
        ("&#8221;", "\u{201D}"),  // Right double quote
        ("&#8211;", "\u{2013}"),  // En dash
        ("&#8212;", "\u{2014}"),  // Em dash
        ("&#176;", "\u{00B0}"),   // Degree sign
        ("&#xBC;", "\u{00BC}"),   // Fraction 1/4
        ("&#xBD;", "\u{00BD}"),   // Fraction 1/2
        ("&#xBE;", "\u{00BE}"),   // Fraction 3/4
    ]

    /// Decode HTML entities in a string. Handles named entities, decimal (&#123;),
    /// and hex (&#xBD;) numeric character references.
    static func decode(_ string: String) -> String {
        var result = string

        // Named/known entities
        for (entity, replacement) in namedEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Decimal numeric entities like &#123;
        if let regex = try? NSRegularExpression(pattern: #"&#(\d+);"#) {
            let nsResult = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsResult.length))
            for match in matches.reversed() {
                let fullRange = match.range
                let numRange = match.range(at: 1)
                if let num = Int(nsResult.substring(with: numRange)),
                   let scalar = Unicode.Scalar(num) {
                    result = (result as NSString).replacingCharacters(in: fullRange, with: String(scalar))
                }
            }
        }

        return result
    }

    /// Check whether a string contains HTML entities that need decoding
    static func containsEntities(_ string: String) -> Bool {
        string.contains("&amp;") || string.contains("&#") || string.contains("&lt;")
    }
}
