import Foundation
import CoreData

class IngredientTemplateService: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var lastSearchDuration: TimeInterval = 0
    @Published var popularIngredients: [IngredientTemplate] = []
    @Published var errorMessage: String?

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - M4.3.5: Ingredient Normalization
    
    // Phase 1: Case Normalization
    // Normalizes ingredient names to lowercase for consistent template matching
    // This eliminates duplicates like "Butter", "butter", "BUTTER"
    private func normalizeCase(_ name: String) -> String {
        return name.lowercased()
    }
    
    // Phase 2: Singular/Plural Normalization
    // Converts plural ingredient names to singular form
    // Handles regular plurals (eggs → egg) and irregular plurals (children → child)
    // EXCEPTION: Preserves ingredients that are inherently plural (chocolate chips, sprinkles, peas, beans)
    private func normalizePlural(_ name: String) -> String {
        let lowercased = name.lowercased()
        
        // Preserve-plural list: ingredients that should always stay plural
        // These are items typically bought/used in plural form
        let alwaysPlural = [
            "beans",
            "chickpeas",
            "chocolate chips",
            "corn chips",
            "croutons",
            "greens",
            "lentils",
            "noodles",
            "oats",
            "peas",
            "potato chips",
            "sprinkles",
            "tortilla chips"
        ]
        
        // M4.3.5 PHASE 4 FIX: Strip qualifiers BEFORE checking preserve-plural list
        // This ensures "frozen peas" matches "peas" in the list
        // We'll apply a simplified version of removeVariations just for this check
        let qualifierPrefixes = [
            "diced ", "chopped ", "sliced ", "minced ", "crushed ", "grated ",
            "shredded ", "ground ", "whole ", "halved ", "quartered ",
            "fresh ", "frozen ", "canned ", "dried ", "raw ",
            "organic ", "free-range ", "grass-fed ", "wild-caught ",
            "all-purpose ", "self-rising ", "unsalted ", "salted ",
            "extra-virgin ", "light ", "dark ", "heavy ", "lite ",
            "large ", "medium ", "small ", "baby ", "jumbo "
        ]
        
        var checkName = lowercased
        // Remove qualifiers for preserve-plural check
        for prefix in qualifierPrefixes {
            if checkName.hasPrefix(prefix) {
                checkName = String(checkName.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Items where the plural form is the natural grocery name.
        // Maps both singular and plural inputs to the preferred plural form.
        // "grape" → "grapes", "strawberries" → "strawberries"
        let preferPlural: [String: String] = [
            "grape": "grapes", "grapes": "grapes",
            "strawberry": "strawberries", "strawberries": "strawberries",
            "blueberry": "blueberries", "blueberries": "blueberries",
            "raspberry": "raspberries", "raspberries": "raspberries",
            "blackberry": "blackberries", "blackberries": "blackberries",
            "cranberry": "cranberries", "cranberries": "cranberries",
            "cherry": "cherries", "cherries": "cherries",
            "olive": "olives", "olives": "olives",
            "cracker": "crackers", "crackers": "crackers",
            "pretzel": "pretzels", "pretzels": "pretzels",
            "marshmallow": "marshmallows", "marshmallows": "marshmallows",
            "raisin": "raisins", "raisins": "raisins",
            "mushroom": "mushrooms", "mushrooms": "mushrooms",
            "pepper": "peppers", "peppers": "peppers",
            "banana": "bananas", "bananas": "bananas",
            "avocado": "avocados", "avocados": "avocados",
            "tomato": "tomatoes", "tomatoes": "tomatoes",
            "potato": "potatoes", "potatoes": "potatoes",
            "onion": "onions", "onions": "onions",
            "carrot": "carrots", "carrots": "carrots",
            "noodle": "noodles", "noodles": "noodles",
            "egg": "eggs", "eggs": "eggs",
            "shrimp": "shrimp", // uncountable
            "scallop": "scallops", "scallops": "scallops",
        ]
        if let preferred = preferPlural[checkName] {
            return preferred
        }

        // Check if this ingredient (after stripping qualifiers) should stay plural
        if alwaysPlural.contains(checkName) {
            return checkName  // Return the stripped version in plural form
        }

        // If the original (with qualifiers) is in the list, use that
        if alwaysPlural.contains(lowercased) {
            return lowercased
        }

        // M8.3.1: Check if the LAST WORD is inherently plural
        // Handles compound names like "black beans", "red pepper flakes", "tortilla strips"
        let alwaysPluralSuffixes: Set<String> = [
            "beans", "chickpeas", "chips", "croutons", "crumbs",
            "flakes", "greens", "lentils", "noodles", "oats",
            "peas", "seeds", "sprinkles", "strips",
            "snacks", "berries", "grapes", "crackers"
        ]
        let words = checkName.split(separator: " ").map(String.init)
        if words.count > 1, let lastWord = words.last,
           alwaysPluralSuffixes.contains(lastWord) {
            return checkName
        }

        // Compound items where the singular suffix should become plural
        // "fruit snack" → "fruit snacks"
        let singularSuffixToPlural: [String: String] = [
            "snack": "snacks", "berry": "berries",
            "grape": "grapes", "cracker": "crackers",
        ]
        if words.count > 1, let lastWord = words.last,
           let pluralLast = singularSuffixToPlural[lastWord] {
            var pluralized = words
            pluralized[pluralized.count - 1] = pluralLast
            return pluralized.joined(separator: " ")
        }
        
        // Irregular plurals mapping (check these next)
        let irregularPlurals: [String: String] = [
            "children": "child",
            "feet": "foot",
            "teeth": "tooth",
            "geese": "goose",
            "mice": "mouse",
            "people": "person",
            "men": "man",
            "women": "woman",
            "oxen": "ox"
        ]
        
        if let singular = irregularPlurals[lowercased] {
            return singular
        }
        
        // Regular plural patterns
        
        // Pattern 1: -ies → -y (berries → berry, cherries → cherry)
        if lowercased.hasSuffix("ies") && lowercased.count > 3 {
            let base = String(lowercased.dropLast(3))
            return base + "y"
        }
        
        // Pattern 2: -oes → -o (tomatoes → tomato, potatoes → potato)
        if lowercased.hasSuffix("oes") && lowercased.count > 3 {
            return String(lowercased.dropLast(2))
        }
        
        // Pattern 3: -ses → -s (glasses → glass)
        if lowercased.hasSuffix("ses") && lowercased.count > 3 {
            return String(lowercased.dropLast(2))
        }
        
        // Pattern 4: -ves → -f (knives → knife, loaves → loaf)
        if lowercased.hasSuffix("ves") && lowercased.count > 3 {
            let base = String(lowercased.dropLast(3))
            return base + "f"
        }
        
        // Pattern 5: -s → remove (eggs → egg, apples → apple)
        // BUT NOT: -ss words (grass, glass, etc.) or -us words (asparagus, hummus)
        if lowercased.hasSuffix("s") &&
           !lowercased.hasSuffix("ss") &&
           !lowercased.hasSuffix("us") &&
           lowercased.count > 1 {
            return String(lowercased.dropLast())
        }
        
        // No plural pattern matched, return as-is
        return lowercased
    }
    
    // Phase 3: Abbreviation Expansion
    // Expands common measurement abbreviations to full words
    // Handles tbsp → tablespoon, tsp → teaspoon, oz → ounce, etc.
    private func expandAbbreviations(_ name: String) -> String {
        // Abbreviation dictionary mapping short forms to full forms
        let abbreviationMap: [String: String] = [
            // Volume measurements
            "tbsp": "tablespoon",
            "tbs": "tablespoon",
            "tsp": "teaspoon",
            "c": "cup",
            "pt": "pint",
            "qt": "quart",
            "gal": "gallon",
            "fl oz": "fluid ounce",
            "ml": "milliliter",
            "l": "liter",
            
            // Weight measurements
            "oz": "ounce",
            "lb": "pound",
            "lbs": "pound",
            "g": "gram",
            "kg": "kilogram",
            
            // Other common abbreviations
            "pkg": "package",
            "env": "envelope"
        ]
        
        let result = name
        
        // Split into words for word-boundary matching
        let words = result.split(separator: " ").map(String.init)
        var replacedWords: [String] = []
        
        for word in words {
            // Check if word is an abbreviation
            if let fullForm = abbreviationMap[word.lowercased()] {
                replacedWords.append(fullForm)
            } else {
                replacedWords.append(word)
            }
        }
        
        return replacedWords.joined(separator: " ")
    }
    
    // Phase 4: Variation Handling
    // Removes qualifiers and descriptors to consolidate ingredient variations
    // Handles: "diced tomato" → "tomato", "fresh basil" → "basil", "all-purpose flour" → "flour"
    // ENHANCED: Also handles compound words without spaces like "largeegg" → "egg", "organictomato" → "tomato"
    // This phase reduces template fragmentation by normalizing ingredient variants
    private func removeVariations(_ name: String) -> String {
        let lowercased = name.lowercased()
        
        // Common qualifiers to remove (WITHOUT trailing space for matching)
        let qualifierWords = [
            // Preparation descriptors
            "diced", "chopped", "sliced", "minced", "crushed", "grated",
            "shredded", "ground", "whole", "halved", "quartered",
            
            // Freshness descriptors
            "fresh", "frozen", "canned", "dried", "raw",
            
            // Quality descriptors
            "organic", "free-range", "grass-fed", "wild-caught",
            
            // Type/variety descriptors (common ones)
            "all-purpose", "self-rising", "unsalted", "salted",
            "extra-virgin", "light", "dark", "heavy", "lite",
            
            // Size descriptors
            "large", "medium", "small", "baby", "jumbo"
        ]
        
        var result = lowercased
        
        // Remove qualifiers from start of name
        // Loop to handle multiple qualifiers (e.g., "fresh diced tomato" or "freshdicedt omato")
        var changed = true
        while changed {
            changed = false
            for qualifier in qualifierWords {
                // Try matching with space first (e.g., "large egg")
                if result.hasPrefix(qualifier + " ") {
                    result = String(result.dropFirst((qualifier + " ").count))
                    changed = true
                    break
                }
                // Try matching without space (e.g., "largeegg")
                // Only if there's more content after the qualifier
                else if result.hasPrefix(qualifier) && result.count > qualifier.count {
                    result = String(result.dropFirst(qualifier.count))
                    changed = true
                    break
                }
            }
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // Main normalization entry point
    // Applies all normalization phases to an ingredient name
    // Phase 1: Case normalization (lowercase)
    // Phase 2: Singular/plural normalization
    // Phase 3: Abbreviation expansion
    // Phase 4: Variation handling (qualifiers and descriptors)
    // M8.3.1: Changed from private to internal for unit test access via @testable import
    func normalize(name: String) -> String {
        var normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Phase 0: Sanitize — strip leading punctuation and residual unit words
        // Handles artifacts like "/ black pepper" (from fraction stripping) and
        // "cloves garlic" (unit word leaked into template name)
        normalized = normalized.replacingOccurrences(
            of: #"^[/\-–—.,:;]+\s*"#, with: "", options: .regularExpression
        )
        let unitPrefixes = [
            "cloves ", "clove ", "pounds ", "pound ", "cans ", "can ",
            "slices ", "slice ", "heads ", "head ", "bunches ", "bunch ",
            "pieces ", "piece ", "sprigs ", "sprig ", "sticks ", "stick ",
            "bags ", "bag ", "bottles ", "bottle ", "boxes ", "box ",
            "jars ", "jar ", "stalks ", "stalk ", "ears ", "ear "
        ]
        let lowerNormalized = normalized.lowercased()
        for prefix in unitPrefixes {
            if lowerNormalized.hasPrefix(prefix) {
                normalized = String(normalized.dropFirst(prefix.count))
                break
            }
        }
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)

        // Phase 1: Case normalization
        normalized = normalizeCase(normalized)
        
        // Phase 2: Singular/plural normalization
        normalized = normalizePlural(normalized)
        
        // Phase 3: Abbreviation expansion
        normalized = expandAbbreviations(normalized)
        
        // Phase 4: Variation handling
        normalized = removeVariations(normalized)
        
        return normalized
    }
    
    // MARK: - Template Operations
    
    func searchTemplates(query: String, limit: Int = 10) -> [IngredientTemplate] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        
        if !query.isEmpty {
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \IngredientTemplate.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)
        ]
        
        request.fetchLimit = limit
        
        do {
            let templates = try context.fetch(request)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.lastSearchDuration = duration
            return templates
        } catch {
            #if DEBUG
            print("Error searching ingredient templates: \(error)")
            #endif
            return []
        }
    }
    
    func loadPopularIngredients(limit: Int = 20) -> [IngredientTemplate] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "usageCount > 0")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \IngredientTemplate.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \IngredientTemplate.name, ascending: true)
        ]
        request.fetchLimit = limit
        
        do {
            let templates = try context.fetch(request)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.lastSearchDuration = duration
            self.popularIngredients = templates
            return templates
        } catch {
            #if DEBUG
            print("Error loading popular ingredients: \(error)")
            #endif
            return []
        }
    }
    
    // M7.2.3 Phase 3.3: Updated to use HouseholdIngredientTemplateRepository
    func findOrCreateTemplate(name: String, category: String? = nil) -> IngredientTemplate {
        // M4.3.5: Normalize ingredient name before lookup/creation
        let normalizedName = normalize(name: name)
        
        // M7.2.3 Phase 3.3: Use HouseholdIngredientTemplateRepository for semantic uniqueness
        let repository = HouseholdIngredientTemplateRepository(context: context)
        
        do {
            // Use repository's findOrCreate (handles semantic uniqueness + category/staple)
            let template = try repository.findOrCreate(
                name: normalizedName,
                category: category,
                isStaple: false  // Default to non-staple
            )
            
            // Increment usage count
            template.usageCount += 1
            template.updatedAt = Date()
            
            // Ensure UUID is set
            if template.id == nil {
                template.id = UUID()
            }
            
            // Save changes
            if context.hasChanges {
                try context.save()
            }
            
            return template
            
        } catch {
            #if DEBUG
            print("❌ M7.2.3 Phase 3.3: Error creating template: \(error)")
            #endif
            // Fallback: check context's pending objects before creating
            let canonical = IngredientTemplate.canonicalName(from: normalizedName)
            let pending = (context.insertedObjects.union(context.updatedObjects))
                .compactMap { $0 as? IngredientTemplate }
                .first { $0.canonicalName == canonical }

            if let existing = pending {
                existing.usageCount += 1
                existing.updatedAt = Date()
                return existing
            }

            let template = IngredientTemplate(context: context)
            template.id = UUID()
            template.name = normalizedName
            template.canonicalName = canonical
            template.category = category
            template.usageCount = 1
            template.dateCreated = Date()
            template.updatedAt = Date()
            return template
        }
    }
    
    func incrementUsage(template: IngredientTemplate) {
        template.usageCount += 1
        
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("Error updating template usage: \(error)")
            #endif
        }
    }
    
    func validateSearchPerformance() -> Bool {
        let _ = searchTemplates(query: "a", limit: 5)
        return lastSearchDuration < 0.1
    }
    
    // MARK: - M4.3.5: Data Migration

    // Migrates existing templates to normalized names and deduplicates collisions.
    // When two templates normalize to the same name (e.g., "Carrots" and "carrot"),
    // keeps the one with higher usage count and re-points all relationships.
    func migrateExistingTemplates() {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()

        do {
            let templates = try context.fetch(request)
            var migratedCount = 0

            // Phase 1: Normalize all names and update canonicalName
            for template in templates {
                let normalizedName = normalize(name: template.name ?? "")
                if template.name != normalizedName {
                    template.name = normalizedName
                    migratedCount += 1
                }
                // Always sync canonicalName with normalized name
                let expectedCanonical = IngredientTemplate.canonicalName(from: normalizedName)
                if template.canonicalName != expectedCanonical {
                    template.canonicalName = expectedCanonical
                }
            }

            // Phase 2: Deduplicate — group by canonicalName, merge collisions
            let grouped = Dictionary(grouping: templates) {
                IngredientTemplate.canonicalName(from: $0.name ?? "")
            }

            var mergedCount = 0
            for (_, group) in grouped where group.count > 1 {
                // Keep the template with highest usage count (stable sort by dateCreated)
                let sorted = group.sorted {
                    if $0.usageCount != $1.usageCount { return $0.usageCount > $1.usageCount }
                    return ($0.dateCreated ?? .distantPast) < ($1.dateCreated ?? .distantPast)
                }
                let keeper = sorted[0]
                let duplicates = sorted.dropFirst()

                for duplicate in duplicates {
                    // Consolidate usage count
                    keeper.usageCount += duplicate.usageCount

                    // Re-point ingredient relationships from duplicate to keeper
                    if let ingredients = duplicate.ingredients as? Set<Ingredient> {
                        for ingredient in ingredients {
                            ingredient.ingredientTemplate = keeper
                        }
                    }

                    // Preserve category if keeper lacks one
                    if (keeper.category == nil || keeper.category?.isEmpty == true),
                       let dupCategory = duplicate.category, !dupCategory.isEmpty {
                        keeper.category = dupCategory
                    }

                    // Preserve staple status
                    if duplicate.isStaple && !keeper.isStaple {
                        keeper.isStaple = true
                    }

                    context.delete(duplicate)
                    mergedCount += 1
                }
            }

            if migratedCount > 0 || mergedCount > 0 {
                try context.save()
                #if DEBUG
                print("M4.3.5: Migrated \(migratedCount) templates, merged \(mergedCount) duplicates")
                #endif
            } else {
                #if DEBUG
                print("M4.3.5: No templates needed migration")
                #endif
            }
        } catch {
            #if DEBUG
            print("Error migrating templates: \(error)")
            #endif
        }
    }

    /// Finds duplicate templates (same canonicalName) for user review.
    /// Returns pairs of (keeper, duplicates) grouped by normalized name.
    func findDuplicateTemplates() -> [(name: String, templates: [IngredientTemplate])] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()

        do {
            let templates = try context.fetch(request)
            let grouped = Dictionary(grouping: templates) {
                IngredientTemplate.canonicalName(from: self.normalize(name: $0.name ?? ""))
            }

            return grouped
                .filter { $0.value.count > 1 }
                .map { (name: $0.key, templates: $0.value) }
                .sorted { $0.name < $1.name }
        } catch {
            return []
        }
    }

    // MARK: - M7.5: Public CRUD Methods

    /// Updates a template's name, category, and staple status.
    /// Name is normalized through the standard pipeline (preserves sanitization chokepoint).
    func updateTemplate(_ template: IngredientTemplate, name: String, category: String?, isStaple: Bool) {
        clearError()

        let normalizedName = normalize(name: name)
        template.name = normalizedName
        template.canonicalName = IngredientTemplate.canonicalName(from: normalizedName)
        template.category = category
        template.isStaple = isStaple
        template.updatedAt = Date()

        save("update template")
    }

    /// Updates just the category assignment on a template
    func updateCategory(_ template: IngredientTemplate, category: String?) {
        clearError()
        template.category = category
        template.updatedAt = Date()
        save("update template category")
    }

    /// Updates just the staple status on a template
    func updateStaple(_ template: IngredientTemplate, isStaple: Bool) {
        clearError()
        template.isStaple = isStaple
        template.updatedAt = Date()
        save("update template staple")
    }

    /// Deletes a template. Ingredient relationships use READ-ONLY rules (no cascade).
    func deleteTemplate(_ template: IngredientTemplate) {
        clearError()
        context.delete(template)
        save("delete template")
    }

    /// Saves the current context for multi-step operations
    func saveContext() {
        clearError()
        save("batch save")
    }

    // MARK: - Error Handling

    private func clearError() {
        errorMessage = nil
    }

    @discardableResult
    private func save(_ operation: String) -> Bool {
        guard context.hasChanges else { return true }

        do {
            try context.save()
            return true
        } catch {
            errorMessage = "Failed to \(operation)"
            #if DEBUG
            print("❌ IngredientTemplateService: Failed to \(operation): \(error)")
            #endif
            context.rollback()
            return false
        }
    }
}
