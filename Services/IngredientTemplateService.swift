import Foundation
import CoreData

class IngredientTemplateService: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var lastSearchDuration: TimeInterval = 0
    @Published var popularIngredients: [IngredientTemplate] = []
    @Published var errorMessage: String?

    // M9.13: Factory for creating HouseholdScoped entities in correct store (ADR 014)
    var factory: ManagedObjectFactory?

    // M10.6.11: Household key for scoping newly created templates.
    // Set via provider closure (app-level) or direct property (child contexts).
    var householdKey: String?
    var householdKeyProvider: (() -> String?)?

    /// Resolved household key: direct value takes priority, then provider closure.
    private var resolvedHouseholdKey: String? {
        householdKey ?? householdKeyProvider?()
    }

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
        
        // Strip only preparation qualifiers before checking preserve-plural lists.
        // Identity qualifiers (ground, fresh, frozen, etc.) are kept so they participate
        // in plural matching — "frozen peas" stays intact, "diced tomatoes" → "tomatoes".
        let preparationPrefixes = [
            "diced ", "chopped ", "sliced ", "minced ", "crushed ", "grated ",
            "shredded ", "halved ", "quartered ",
            "small ", "large ", "medium "
        ]

        var checkName = lowercased
        for prefix in preparationPrefixes {
            if checkName.hasPrefix(prefix) {
                checkName = String(checkName.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // M10.6.5: Template names use SINGULAR form. The quantity handles plurality.
        // "2 avocados" → template="avocado", qty=2.
        // Only genuinely plural items (beans, oats, chips, peas) stay plural.

        // Check if this ingredient (after stripping qualifiers) should stay plural
        if alwaysPlural.contains(checkName) {
            return checkName
        }

        // If the original (with qualifiers) is in the list, use that
        if alwaysPlural.contains(lowercased) {
            return lowercased
        }

        let words = checkName.split(separator: " ").map(String.init)

        // M8.3.1: Check if the LAST WORD is inherently plural
        // Handles compound names like "black beans", "red pepper flakes", "tortilla strips"
        let alwaysPluralSuffixes: Set<String> = [
            "beans", "chickpeas", "chips", "croutons", "crumbs",
            "flakes", "greens", "lentils", "noodles", "oats",
            "peas", "seeds", "sprinkles", "strips"
        ]
        if words.count > 1, let lastWord = words.last,
           alwaysPluralSuffixes.contains(lastWord) {
            return checkName
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
    // Strips only PREPARATION qualifiers that describe what you DO to an ingredient.
    // Identity qualifiers that describe what an ingredient IS are preserved.
    //
    // Stripped (preparation): "diced tomato" → "tomato", "chopped onion" → "onion"
    // Preserved (identity): "ground beef" stays, "dark chocolate" stays, "frozen peas" stays
    //
    // Rationale: Training data (68,846 samples from strangetom) shows identity qualifiers
    // are consistently labeled NAME, not PREP. Stripping them loses critical product info:
    //   "ground beef" (46x NAME) ≠ "beef"
    //   "ground cinnamon" (79x NAME) ≠ "cinnamon"
    //   "dark chocolate" (88x NAME) ≠ "chocolate"
    //   "unsalted butter" (797x NAME) ≠ "butter"
    //   "whole milk" (125x NAME) ≠ "milk"
    //   "dried cranberries" (35x NAME) ≠ "cranberries"
    //   "frozen peas" (46x NAME) ≠ "peas"
    private func removeVariations(_ name: String) -> String {
        let lowercased = name.lowercased()

        // ONLY strip pure preparation qualifiers — these describe cutting/processing
        // and don't change what the ingredient IS for shopping purposes.
        // All other qualifiers (identity, freshness, quality, type) are preserved
        // because they describe fundamentally different products or store locations.
        let preparationQualifiers = [
            "diced", "chopped", "sliced", "minced", "crushed", "grated",
            "shredded", "halved", "quartered",
            "small", "large", "medium"
        ]

        var result = lowercased

        // Remove preparation qualifiers from start of name
        // Loop to handle multiple qualifiers (e.g., "diced sliced tomato")
        var changed = true
        while changed {
            changed = false
            for qualifier in preparationQualifiers {
                // Try matching with space (e.g., "diced tomato")
                if result.hasPrefix(qualifier + " ") {
                    result = String(result.dropFirst((qualifier + " ").count))
                    changed = true
                    break
                }
                // Try matching without space (e.g., "dicedtomato")
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
        // M10.6.14: Strip trailing unit words (belt-and-suspenders for LLM artifacts like "garlic clove")
        let words = normalized.split(separator: " ").map(String.init)
        if words.count >= 2 {
            let unitSuffixWords: Set<String> = [
                "clove", "cloves", "slice", "slices", "piece", "pieces",
                "sprig", "sprigs", "stick", "sticks", "stalk", "stalks",
                "bunch", "bunches", "wedge", "wedges"
            ]
            if let lastWord = words.last?.lowercased(), unitSuffixWords.contains(lastWord) {
                normalized = words.dropLast().joined(separator: " ")
            }
        }
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)

        // M10.6.15 Phase 0c: Strip parenthetical qualifiers — "(peeled and deveined)" etc.
        normalized = normalized.replacingOccurrences(
            of: #"\s*\([^)]*\)\s*"#, with: " ", options: .regularExpression
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        // M9.12 Phase 0c2: Strip comma-separated prep notes — "shrimp, peeled and deveined, tails removed" → "shrimp"
        // Multi-word comma qualifiers aren't caught by the regex parser's single-word comma pattern
        if let commaRange = normalized.range(of: ",") {
            normalized = String(normalized[normalized.startIndex..<commaRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // M10.6.15 Phase 0d: Strip trailing single-character words (artifacts like "avocado s")
        let trimWords = normalized.split(separator: " ").map(String.init)
        if trimWords.count >= 2, let last = trimWords.last, last.count == 1, last.lowercased() != "a" {
            normalized = trimWords.dropLast().joined(separator: " ")
        }

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
    
    // M10.6.18: Build householdKey predicate for scoped fetches (ADR 013)
    private func householdKeyPredicate() -> NSPredicate {
        if let key = resolvedHouseholdKey {
            return NSPredicate(format: "householdKey == %@", key)
        } else {
            return NSPredicate(format: "householdKey == nil")
        }
    }

    /// M10.6.18: Scoped by householdKey (ADR 013) to prevent ghost template results
    func searchTemplates(query: String, limit: Int = 10) -> [IngredientTemplate] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()

        var predicates: [NSPredicate] = [householdKeyPredicate()]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", query))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

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

    /// M10.6.18: Scoped by householdKey (ADR 013) to prevent ghost template results
    func loadPopularIngredients(limit: Int = 20) -> [IngredientTemplate] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "usageCount > 0"),
            householdKeyPredicate()
        ])
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
    
    // M9.12: Look up the "Uncategorized" Category entity for the current household scope.
    // Used as default when no category is provided to findOrCreateTemplate.
    private func lookupUncategorizedCategory() -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let key = resolvedHouseholdKey
        if let key = key {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == %@", "Uncategorized", key)
        } else {
            request.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", "Uncategorized")
        }
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    // M7.2.3 Phase 3.3: Updated to use HouseholdIngredientTemplateRepository
    func findOrCreateTemplate(name: String, category: Category? = nil) -> IngredientTemplate {
        // M4.3.5: Normalize ingredient name before lookup/creation
        let normalizedName = normalize(name: name)

        Task { @MainActor in DebugLogService.shared.log("findOrCreate: name=\(normalizedName), resolvedHouseholdKey=\(self.resolvedHouseholdKey ?? "nil")", category: "Template") }

        // M7.2.3 Phase 3.3: Use HouseholdIngredientTemplateRepository for semantic uniqueness
        let repository = HouseholdIngredientTemplateRepository(context: context)

        do {
            // Pass caller's category (nil if not specified) — repository only updates
            // existing templates when an explicit category is provided
            // M10.6.11: Pass household key so new templates are scoped correctly
            let template = try repository.findOrCreate(
                name: normalizedName,
                category: category,
                isStaple: false,
                householdKey: resolvedHouseholdKey
            )

            // M9.12: Default new/uncategorized templates to "Uncategorized" entity.
            // Only applied when template has no category — never overwrites real categories.
            // Cross-store safety: verify the category is in the same store as the template
            // to prevent cross-store relationship failures in dual-store CloudKit setups.
            if template.categoryEntity == nil {
                if let uncategorized = lookupUncategorizedCategory() {
                    let templateStore = template.objectID.persistentStore
                    let categoryStore = uncategorized.objectID.persistentStore
                    if templateStore == nil || categoryStore == nil || templateStore == categoryStore {
                        template.categoryEntity = uncategorized
                    }
                    // If stores differ, skip — category will be assigned at the UI layer
                }
            }

            Task { @MainActor in DebugLogService.shared.log("repository returned: existing=\(template.dateCreated != nil && template.usageCount > 0 ? "yes" : "new"), template.householdKey=\(template.householdKey ?? "nil")", category: "Template") }

            // M10.6.18: Always sync householdKey — the nil case matters for personal scope.
            // Previously `if let` skipped nil, leaving ghost householdKeys on reused templates.
            if template.householdKey != resolvedHouseholdKey {
                template.householdKey = resolvedHouseholdKey
            }

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
            Task { @MainActor in DebugLogService.shared.log("catch fallback: creating manual template, householdKey=\(self.resolvedHouseholdKey ?? "nil")", category: "Template") }
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

            // M9.13: Use factory when available for correct store assignment (ADR 014)
            let template: IngredientTemplate
            if let factory = factory,
               let factoryTemplate = try? factory.make(IngredientTemplate.self, configure: { t in
                   t.id = UUID()
                   t.name = normalizedName
                   t.canonicalName = canonical
                   t.categoryEntity = category
                   t.householdKey = self.resolvedHouseholdKey
                   t.usageCount = 1
                   t.dateCreated = Date()
                   t.updatedAt = Date()
               }) {
                template = factoryTemplate
            } else {
                template = IngredientTemplate(context: context)
                template.id = UUID()
                template.name = normalizedName
                template.canonicalName = canonical
                template.categoryEntity = category
                // M10.6.12: Fallback path must set householdKey — without it, templates
                // created during import are invisible in household-scoped IngredientsView
                template.householdKey = resolvedHouseholdKey
                template.usageCount = 1
                template.dateCreated = Date()
                template.updatedAt = Date()
            }
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
    /// M10.6.18: Scoped by householdKey (ADR 013)
    func migrateExistingTemplates() {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = householdKeyPredicate()

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

                    // M9.12: Preserve categoryEntity if keeper lacks one
                    if keeper.categoryEntity == nil, let dupCategory = duplicate.categoryEntity {
                        keeper.categoryEntity = dupCategory
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
    /// M10.6.18: Scoped by householdKey (ADR 013)
    func findDuplicateTemplates() -> [(name: String, templates: [IngredientTemplate])] {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = householdKeyPredicate()

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
            #if DEBUG
            print("Error finding duplicate templates: \(error)")
            #endif
            return []
        }
    }

    // MARK: - M7.5: Public CRUD Methods

    /// Updates a template's name, category, and staple status.
    /// Name is normalized through the standard pipeline (preserves sanitization chokepoint).
    func updateTemplate(_ template: IngredientTemplate, name: String, category: Category?, isStaple: Bool) {
        clearError()

        let normalizedName = normalize(name: name)
        template.name = normalizedName
        template.canonicalName = IngredientTemplate.canonicalName(from: normalizedName)
        template.categoryEntity = category
        template.isStaple = isStaple
        template.updatedAt = Date()

        save("update template")
    }

    /// Updates just the category assignment on a template (M9.12: via relationship)
    func updateCategory(_ template: IngredientTemplate, category: Category?) {
        clearError()
        template.categoryEntity = category
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
