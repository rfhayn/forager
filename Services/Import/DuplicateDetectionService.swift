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
/// M10.6: Scoped to user's current visibility — only matches recipes with matching
/// householdKey to prevent ghost duplicates from previous/inaccessible households.
enum DuplicateDetectionService {

    /// Check for duplicates of a draft recipe within the user's visible scope.
    /// Returns the first match found (exact URL preferred over fuzzy title), or nil.
    /// - Parameter householdKey: Current household key, or nil if personal scope.
    static func checkForDuplicate(
        title: String,
        sourceURL: String?,
        householdKey: String?,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        // Strategy 1: Exact URL match
        if let url = sourceURL, !url.isEmpty,
           let result = checkExactURL(url, householdKey: householdKey, context: context) {
            return result
        }

        // Strategy 2: Fuzzy title match
        if let result = checkFuzzyTitle(title, householdKey: householdKey, context: context) {
            return result
        }

        return nil
    }

    // MARK: - Scope Predicate

    /// Builds a predicate that limits results to the user's visible recipes.
    /// In household: householdKey == key. Personal: householdKey == nil.
    private static func scopePredicate(householdKey: String?) -> NSPredicate {
        if let key = householdKey {
            return NSPredicate(format: "householdKey == %@", key)
        } else {
            return NSPredicate(format: "householdKey == nil")
        }
    }

    // MARK: - Strategy 1: Exact URL Match

    private static func checkExactURL(
        _ url: String,
        householdKey: String?,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        let request = Recipe.fetchRequest()
        let urlPredicate = NSPredicate(format: "sourceURL == %@", url)
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            urlPredicate,
            scopePredicate(householdKey: householdKey)
        ])
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
        householdKey: String?,
        context: NSManagedObjectContext
    ) -> DuplicateResult? {
        let normalized = normalizeTitle(title)
        guard !normalized.isEmpty else { return nil }

        // Fetch recent recipes to compare against (scoped to visible recipes only)
        // Limit to 100 most recent to keep performance bounded
        let request = Recipe.fetchRequest()
        request.predicate = scopePredicate(householdKey: householdKey)
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
