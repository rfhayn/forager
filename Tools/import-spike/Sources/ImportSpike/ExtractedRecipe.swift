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

/// Classification of extraction success level.
enum ExtractionSuccessLevel: String, Codable {
    /// Title + ingredients + instructions all present
    case full
    /// Title + ingredients present, instructions or other fields missing
    case partial
    /// Below partial — not a usable recipe
    case failure
}

/// Aggregate report across all tested sites.
/// Uses custom Codable to serialize computed summary metrics alongside raw results.
struct ExtractionReport: Codable {
    let generatedAt: String
    let totalSites: Int
    let results: [SiteExtractionResult]

    // Computed metrics (also serialized via custom encode)
    var jsonLDFoundCount: Int { results.filter(\.jsonLDFound).count }
    var recipeFoundCount: Int { results.filter(\.recipeFound).count }
    var fullExtractionCount: Int {
        results.filter { classifySuccess($0) == .full }.count
    }
    var partialExtractionCount: Int {
        results.filter { classifySuccess($0) == .partial }.count
    }
    var failureCount: Int {
        results.filter { classifySuccess($0) == .failure }.count
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

    var extractionMethodDistribution: [String: Int] {
        var dist: [String: Int] = [:]
        for r in results {
            dist[r.extractionMethod, default: 0] += 1
        }
        return dist
    }

    /// Classify a site result into success levels using strict criteria.
    /// Full: title + ingredients + instructions all present.
    /// Partial: title + ingredients present.
    /// Failure: anything below partial.
    func classifySuccess(_ result: SiteExtractionResult) -> ExtractionSuccessLevel {
        guard let recipe = result.recipe else { return .failure }
        let hasTitle = recipe.title != nil
        let hasIngredients = recipe.ingredients != nil && !(recipe.ingredients?.isEmpty ?? true)
        let hasInstructions = recipe.instructions != nil
        if hasTitle && hasIngredients && hasInstructions { return .full }
        if hasTitle && hasIngredients { return .partial }
        return .failure
    }

    // MARK: - Custom Codable (serialize computed metrics)

    enum CodingKeys: String, CodingKey {
        case generatedAt, totalSites, results, summary
    }

    struct SummaryPayload: Codable {
        let jsonLDFound: Int
        let recipeFound: Int
        let fullExtraction: Int
        let partialExtraction: Int
        let failure: Int
        let noExtraction: Int
        let blocked: Int
        let medianExtractionTimeMs: Int
        let extractionMethodDistribution: [String: Int]
        let edgeCases: EdgeCaseCounts
    }

    struct EdgeCaseCounts: Codable {
        let graphWrappers: Int
        let arrayTypes: Int
        let howToSteps: Int
        let howToSections: Int
        let htmlEntities: Int
        let unusualYields: Int
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(generatedAt, forKey: .generatedAt)
        try container.encode(totalSites, forKey: .totalSites)
        try container.encode(results, forKey: .results)
        try container.encode(SummaryPayload(
            jsonLDFound: jsonLDFoundCount,
            recipeFound: recipeFoundCount,
            fullExtraction: fullExtractionCount,
            partialExtraction: partialExtractionCount,
            failure: failureCount,
            noExtraction: noExtractionCount,
            blocked: blockedCount,
            medianExtractionTimeMs: medianExtractionTimeMs,
            extractionMethodDistribution: extractionMethodDistribution,
            edgeCases: EdgeCaseCounts(
                graphWrappers: graphWrapperCount,
                arrayTypes: arrayTypeCount,
                howToSteps: howToStepsCount,
                howToSections: howToSectionsCount,
                htmlEntities: htmlEntitiesCount,
                unusualYields: unusualYieldCount
            )
        ), forKey: .summary)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
        totalSites = try container.decode(Int.self, forKey: .totalSites)
        results = try container.decode([SiteExtractionResult].self, forKey: .results)
    }

    init(generatedAt: String, totalSites: Int, results: [SiteExtractionResult]) {
        self.generatedAt = generatedAt
        self.totalSites = totalSites
        self.results = results
    }
}
