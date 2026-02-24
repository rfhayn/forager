//
//  DuplicateDetectionService.swift
//  forager
//
//  Created for M10.1.6: Duplicate detection
//  Two strategies: exact sourceURL match, fuzzy title match (Levenshtein distance < 3).
//

import Foundation
import CoreData

// MARK: - Duplicate Detection Service

/// Detects whether an imported recipe already exists in the database.
/// Strategy 1: Exact sourceURL match (cheapest, most reliable).
/// Strategy 2: Fuzzy title match using Levenshtein distance < 3 on normalized titles.
enum DuplicateDetectionService {

    /// Check for duplicates of a draft recipe.
    /// Returns the first match found (exact URL preferred over fuzzy title), or nil.
    static func checkForDuplicate(
        title: String,
        sourceURL: String?,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        // Strategy 1: Exact URL match
        if let url = sourceURL, !url.isEmpty,
           let result = checkExactURL(url, context: context) {
            return result
        }

        // Strategy 2: Fuzzy title match
        if let result = checkFuzzyTitle(title, context: context) {
            return result
        }

        return nil
    }

    // MARK: - Strategy 1: Exact URL Match

    private static func checkExactURL(
        _ url: String,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        let request = Recipe.fetchRequest()
        request.predicate = NSPredicate(format: "sourceURL == %@", url)
        request.fetchLimit = 1

        guard let recipes = try? context.fetch(request),
              let existing = recipes.first else {
            return nil
        }

        return .exactURL(existing.objectID)
    }

    // MARK: - Strategy 2: Fuzzy Title Match

    /// Finds recipes with similar titles (Levenshtein distance < 3).
    /// Normalizes both titles to lowercase, trimmed, before comparison.
    private static func checkFuzzyTitle(
        _ title: String,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        let normalized = normalizeTitle(title)
        guard !normalized.isEmpty else { return nil }

        // Fetch recent recipes to compare against
        // Limit to 100 most recent to keep performance bounded
        let request = Recipe.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        request.fetchLimit = 100

        guard let recipes = try? context.fetch(request) else { return nil }

        for recipe in recipes {
            guard let existingTitle = recipe.title else { continue }
            let normalizedExisting = normalizeTitle(existingTitle)
            let distance = levenshteinDistance(normalized, normalizedExisting)

            if distance < 3 {
                return .fuzzyTitle(recipe.objectID, title: existingTitle, distance: distance)
            }
        }

        return nil
    }

    // MARK: - Helpers

    private static func normalizeTitle(_ title: String) -> String {
        title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Compute Levenshtein edit distance between two strings.
    /// Uses Wagner-Fischer algorithm with O(min(m,n)) space.
    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        // Optimize: use shorter string as columns
        if m < n { return levenshteinDistance(s2, s1) }

        // Single-row DP (O(n) space)
        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    curr[j] = prev[j - 1]
                } else {
                    curr[j] = 1 + min(prev[j], curr[j - 1], prev[j - 1])
                }
            }
            swap(&prev, &curr)
        }

        return prev[n]
    }
}
