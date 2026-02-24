import Foundation

// MARK: - Extracted Recipe Model

/// A recipe extracted from a web page, with all fields optional
/// since any field may be missing from the source.
struct ExtractedRecipe: Codable {
    var title: String?
    var ingredients: [String]?
    var instructions: String?
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var totalTimeMinutes: Int?
    var servings: Int?
    var servingsRaw: String?
    var imageURL: String?
    var sourceURL: String?
    var author: String?
    var description: String?
    var cuisine: String?
    var category: String?

    // Extraction metadata
    var fieldsExtracted: Int {
        var count = 0
        if title != nil { count += 1 }
        if let i = ingredients, !i.isEmpty { count += 1 }
        if instructions != nil { count += 1 }
        if prepTimeMinutes != nil { count += 1 }
        if cookTimeMinutes != nil { count += 1 }
        if servings != nil { count += 1 }
        if imageURL != nil { count += 1 }
        if author != nil { count += 1 }
        return count
    }

    var fieldsMissing: [String] {
        var missing: [String] = []
        if title == nil { missing.append("title") }
        if ingredients == nil || ingredients?.isEmpty == true { missing.append("ingredients") }
        if instructions == nil { missing.append("instructions") }
        if prepTimeMinutes == nil { missing.append("prepTime") }
        if cookTimeMinutes == nil { missing.append("cookTime") }
        if servings == nil { missing.append("servings") }
        return missing
    }
}

// MARK: - Site Extraction Result

/// Result of extracting a recipe from a single site.
struct SiteExtractionResult: Codable {
    let siteNumber: Int
    let siteName: String
    let url: String
    let tier: Int
    let jsonLDFound: Bool
    let recipeFound: Bool
    let recipe: ExtractedRecipe?
    let extractionTimeMs: Int
    let issues: [String]
    let httpStatusCode: Int?
    let error: String?

    // Edge case flags
    let usedGraphWrapper: Bool
    let usedArrayType: Bool
    let hadHowToSteps: Bool
    let hadHowToSections: Bool
    let hadHTMLEntities: Bool
    let hadUnusualYield: Bool
    let extractionMethod: String
}

// MARK: - Extraction Report

/// Aggregate report across all tested sites.
struct ExtractionReport: Codable {
    let generatedAt: String
    let totalSites: Int
    let results: [SiteExtractionResult]

    var jsonLDFoundCount: Int { results.filter(\.jsonLDFound).count }
    var recipeFoundCount: Int { results.filter(\.recipeFound).count }
    var fullExtractionCount: Int {
        results.filter { $0.recipe?.fieldsMissing.isEmpty == true }.count
    }
    var partialExtractionCount: Int {
        results.filter { r in
            r.recipeFound && !(r.recipe?.fieldsMissing.isEmpty == true)
        }.count
    }
    var noExtractionCount: Int { results.filter { !$0.recipeFound }.count }
    var graphWrapperCount: Int { results.filter(\.usedGraphWrapper).count }
    var arrayTypeCount: Int { results.filter(\.usedArrayType).count }
    var howToStepsCount: Int { results.filter(\.hadHowToSteps).count }
    var howToSectionsCount: Int { results.filter(\.hadHowToSections).count }
    var htmlEntitiesCount: Int { results.filter(\.hadHTMLEntities).count }
    var unusualYieldCount: Int { results.filter(\.hadUnusualYield).count }
    var blockedCount: Int { results.filter { $0.httpStatusCode == 403 || $0.httpStatusCode == 429 }.count }

    var medianExtractionTimeMs: Int {
        let times = results.map(\.extractionTimeMs).sorted()
        guard !times.isEmpty else { return 0 }
        return times[times.count / 2]
    }

    var summary: [String: Any] {
        [
            "totalSites": totalSites,
            "jsonLDFound": jsonLDFoundCount,
            "recipeFound": recipeFoundCount,
            "fullExtraction": fullExtractionCount,
            "partialExtraction": partialExtractionCount,
            "noExtraction": noExtractionCount,
            "graphWrappers": graphWrapperCount,
            "arrayTypes": arrayTypeCount,
            "howToSteps": howToStepsCount,
            "howToSections": howToSectionsCount,
            "htmlEntities": htmlEntitiesCount,
            "unusualYields": unusualYieldCount,
            "blocked": blockedCount,
            "medianExtractionTimeMs": medianExtractionTimeMs
        ]
    }
}
