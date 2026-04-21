//
//  GroceryListItemService.swift
//  forager
//
//  M9.16: Unified service for GroceryListItem creation.
//  Consolidates 6 independent creation paths into a single pipeline
//  with consistent template resolution, category assignment,
//  cross-store safety, and merge logic.
//

import Foundation
import CoreData

@MainActor
class GroceryListItemService: ObservableObject {

    // MARK: - Properties

    @Published var errorMessage: String?

    private let viewContext: NSManagedObjectContext
    private let templateService: IngredientTemplateService
    private let mergeService: GroceryMergeService
    private let parsingService: IngredientParsingService

    // MARK: - Initialization

    init(
        context: NSManagedObjectContext,
        templateService: IngredientTemplateService,
        parsingService: IngredientParsingService,
        mergeService: GroceryMergeService = GroceryMergeService()
    ) {
        self.viewContext = context
        self.templateService = templateService
        self.parsingService = parsingService
        self.mergeService = mergeService
    }

    // MARK: - Core: Add Single Item

    /// Unified pipeline for adding a single grocery list item.
    /// All creation paths should call this method.
    @discardableResult
    func addItem(
        to list: WeeklyList,
        name: String,
        cleanName: String? = nil,
        structured: StructuredQuantity? = nil,
        existingTemplate: IngredientTemplate? = nil,
        scaleFactor: Double = 1.0,
        sourceRecipe: Recipe? = nil,
        source: String = "manual",
        mergeWithExisting: Bool = true,
        skipSave: Bool = false
    ) -> GroceryListItem? {
        errorMessage = nil

        // Step 1: Clean name extraction
        let resolvedCleanName = cleanName
            ?? IngredientParsingService.extractCleanIngredientName(from: name)

        // Step 2: Structured quantity
        let resolvedStructured = structured
            ?? parsingService.parseToStructured(text: name)

        // Step 3: Template resolution
        let template = existingTemplate
            ?? templateService.findOrCreateTemplate(name: resolvedCleanName)

        // Step 4: Category resolution (cross-store safe)
        let category = resolveCategory(for: template, targetList: list)

        // Step 5: Scale
        let scaledValue: Double
        if scaleFactor != 1.0 && resolvedStructured.isParseable,
           let numVal = resolvedStructured.numericValue, numVal > 0 {
            scaledValue = numVal * scaleFactor
        } else {
            scaledValue = resolvedStructured.numericValue ?? 0
        }

        // Step 6: Merge check
        if mergeWithExisting {
            if let existingItem = findExistingItem(named: resolvedCleanName, in: list) {
                let existingInput = GroceryMergeInput(
                    numericValue: existingItem.numericValue,
                    standardUnit: existingItem.standardUnit,
                    isParseable: existingItem.isParseable,
                    parseConfidence: Double(existingItem.parseConfidence)
                )
                let incomingInput = GroceryMergeInput(
                    numericValue: scaledValue,
                    standardUnit: resolvedStructured.standardUnit,
                    isParseable: resolvedStructured.isParseable,
                    parseConfidence: Double(resolvedStructured.parseConfidence)
                )
                let result = mergeService.merge(existing: existingInput, incoming: incomingInput)

                existingItem.numericValue = result.numericValue
                existingItem.parseConfidence = max(Float(result.parseConfidence), 0.8)
                if result.didMergeQuantity {
                    existingItem.displayText = result.displayText
                    existingItem.standardUnit = result.standardUnit
                    existingItem.name = "\(result.displayText) \(resolvedCleanName)"
                }
                if let recipe = sourceRecipe {
                    existingItem.addToSourceRecipes(recipe)
                }
                // Ensure category is set even on merged items
                if existingItem.categoryEntity == nil, let cat = category {
                    existingItem.categoryEntity = cat
                }

                if !skipSave { save("merge grocery item") }
                return existingItem
            }
        }

        // Step 7: Create new item
        // M9.32: Use clean name with quantity for grocery display — strip qualifiers/prep notes
        let groceryDisplayName: String
        let qtyText = resolvedStructured.displayText
        if qtyText.isEmpty || qtyText == "0" {
            groceryDisplayName = resolvedCleanName
        } else {
            groceryDisplayName = "\(qtyText) \(resolvedCleanName)"
        }

        let item = GroceryListItem(context: viewContext)
        // Co-locate with parent list to prevent CloudKit zone conflict (error 134040).
        // Core Data relationship-based store inference is unreliable under dual-store
        // mirroring; explicit assign is required (fix-groceryitem-multi-zone-assignment).
        if let parentStore = list.objectID.persistentStore {
            viewContext.assign(item, to: parentStore)
        }
        item.id = UUID()
        item.name = groceryDisplayName
        item.categoryEntity = category
        item.isCompleted = false
        item.source = source

        // Quantity fields
        if scaleFactor != 1.0 && resolvedStructured.isParseable,
           let numVal = resolvedStructured.numericValue, numVal > 0 {
            item.numericValue = scaledValue
            item.displayText = mergeService.formatDisplayText(value: scaledValue, unit: resolvedStructured.standardUnit)
        } else {
            item.numericValue = resolvedStructured.numericValue ?? 0
            item.displayText = resolvedStructured.displayText
        }
        item.standardUnit = resolvedStructured.standardUnit
        item.isParseable = resolvedStructured.isParseable
        item.parseConfidence = max(resolvedStructured.parseConfidence, 0.8)

        // Sort order
        let existingCount = (list.items as? Set<GroceryListItem>)?.count ?? 0
        item.sortOrder = Int16(existingCount)

        // M18.1.2: Store snapshot from template's preferred store
        item.store = resolveStore(for: template, targetList: list)

        // Relationships
        list.addToItems(item)
        if let recipe = sourceRecipe {
            item.addToSourceRecipes(recipe)
        }

        // M9.15: HouseholdKey inheritance from parent WeeklyList
        item.household = list.household
        item.householdKey = list.householdKey

        if !skipSave { save("add grocery item") }
        return item
    }

    // MARK: - Batch: Add Ingredients from Recipe

    /// Add multiple ingredients from a recipe to a grocery list.
    /// Handles template resolution, category assignment, scaling, and merge.
    /// Add multiple ingredients from a recipe to a grocery list.
    /// Handles template resolution, category assignment, scaling, and merge.
    /// Pass `skipSave: true` when the caller manages the save transaction
    /// (e.g., MealPlanService.generateGroceryList which saves the entire list at once).
    @discardableResult
    func addIngredients(
        _ ingredients: [Ingredient],
        to list: WeeklyList,
        scaleFactor: Double = 1.0,
        sourceRecipe: Recipe? = nil,
        mergeWithExisting: Bool = true,
        skipSave: Bool = false
    ) -> [GroceryListItem] {
        var results: [GroceryListItem] = []

        for ingredient in ingredients {
            guard let ingredientName = ingredient.name, !ingredientName.isEmpty else { continue }

            let cleanName = IngredientParsingService.extractCleanIngredientName(from: ingredientName)

            // Build structured quantity from ingredient's existing parsed data
            let structured = StructuredQuantity(
                numericValue: ingredient.numericValue,
                standardUnit: ingredient.standardUnit,
                displayText: ingredient.displayText ?? "1",
                isParseable: ingredient.isParseable,
                parseConfidence: ingredient.parseConfidence,
                parserUsed: nil
            )

            let recipe = sourceRecipe ?? ingredient.recipe

            if let item = addItem(
                to: list,
                name: ingredientName,
                cleanName: cleanName,
                structured: structured,
                existingTemplate: ingredient.ingredientTemplate,
                scaleFactor: scaleFactor,
                sourceRecipe: recipe,
                source: recipe != nil ? "Recipe: \(recipe?.title ?? "Unknown Recipe")" : "recipe",
                mergeWithExisting: mergeWithExisting,
                skipSave: true
            ) {
                results.append(item)
            }
        }

        if !skipSave { save("add ingredients batch") }
        return results
    }

    // MARK: - Batch: Add Staples

    /// Add staple templates to a grocery list.
    @discardableResult
    func addStaples(
        _ templates: [IngredientTemplate],
        to list: WeeklyList
    ) -> [GroceryListItem] {
        var results: [GroceryListItem] = []
        let baseIndex = (list.items as? Set<GroceryListItem>)?.count ?? 0

        for (index, template) in templates.enumerated() {
            let item = GroceryListItem(context: viewContext)
            // Co-locate with parent list to prevent CloudKit zone conflict (134040).
            if let parentStore = list.objectID.persistentStore {
                viewContext.assign(item, to: parentStore)
            }
            item.id = UUID()
            item.name = template.name
            item.displayText = "1"
            item.numericValue = 1.0
            item.standardUnit = nil
            item.isParseable = true
            item.parseConfidence = 1.0
            item.isCompleted = false
            item.source = "staples"
            item.sortOrder = Int16(baseIndex + index)

            // Category from template, with cross-store safety
            item.categoryEntity = resolveCategory(for: template, targetList: list)

            // M18.1.2: Store snapshot from template's preferred store
            item.store = resolveStore(for: template, targetList: list)

            list.addToItems(item)

            // M9.15: HouseholdKey inheritance
            item.household = list.household
            item.householdKey = list.householdKey

            results.append(item)
        }

        save("add staples batch")
        return results
    }

    // MARK: - Category Resolution

    /// Resolve category for a template in the context of a target list.
    /// Handles cross-store safety for dual-store CloudKit setups.
    func resolveCategory(
        for template: IngredientTemplate?,
        targetList: WeeklyList
    ) -> Category? {
        guard let cat = template?.categoryEntity else { return nil }

        let targetStore = targetList.objectID.persistentStore
        let catStore = cat.objectID.persistentStore

        // Same store or store info unavailable — direct assignment is safe
        if targetStore == catStore || targetStore == nil || catStore == nil {
            return cat
        }

        // Cross-store — lookup by name in target list's household scope
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let catName = cat.name ?? ""
        if let hk = targetList.householdKey {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == %@", catName, hk
            )
        } else {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == nil", catName
            )
        }
        request.fetchLimit = 1
        return (try? viewContext.fetch(request))?.first
    }

    // MARK: - Store Resolution

    /// M18.1.2: Resolve store for a template in the context of a target list.
    /// Handles cross-store safety for dual-store CloudKit setups.
    /// Mirrors resolveCategory pattern.
    func resolveStore(
        for template: IngredientTemplate?,
        targetList: WeeklyList
    ) -> Store? {
        guard let store = template?.preferredStore else {
            // M18.2: Return default "No Store" entity instead of nil
            return lookupDefaultStore(householdKey: targetList.householdKey)
        }

        let targetPersistentStore = targetList.objectID.persistentStore
        let storePersistentStore = store.objectID.persistentStore

        if targetPersistentStore == storePersistentStore
            || targetPersistentStore == nil
            || storePersistentStore == nil {
            return store
        }

        // Cross-store — lookup by name in target list's household scope
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        let storeName = store.name ?? ""
        if let hk = targetList.householdKey {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == %@", storeName, hk
            )
        } else {
            request.predicate = NSPredicate(
                format: "name ==[c] %@ AND householdKey == nil", storeName
            )
        }
        request.fetchLimit = 1
        return (try? viewContext.fetch(request))?.first
    }

    // M18.2: Lookup default "No Store" entity by isDefault flag
    private func lookupDefaultStore(householdKey: String?) -> Store? {
        let request: NSFetchRequest<Store> = Store.fetchRequest()
        if let key = householdKey {
            request.predicate = NSPredicate(format: "isDefault == YES AND householdKey == %@", key)
        } else {
            request.predicate = NSPredicate(format: "isDefault == YES AND householdKey == nil")
        }
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }

    // MARK: - Template Helpers

    /// Find templates without categories from a set of ingredients.
    /// Used by UI to show CategoryAssignmentModal before adding.
    func findUncategorizedTemplates(
        for ingredients: [Ingredient]
    ) -> [IngredientTemplate] {
        var seen = Set<NSManagedObjectID>()
        var uncategorized: [IngredientTemplate] = []

        for ingredient in ingredients {
            guard let template = ingredient.ingredientTemplate else { continue }
            guard !seen.contains(template.objectID) else { continue }
            seen.insert(template.objectID)

            if template.categoryEntity == nil ||
               template.categoryEntity?.name?.lowercased() == "uncategorized" {
                uncategorized.append(template)
            }
        }

        return uncategorized
    }

    // MARK: - Merge Helpers

    /// Find an existing uncompleted item in a list with the same normalized name.
    private func findExistingItem(named targetName: String, in list: WeeklyList) -> GroceryListItem? {
        guard let items = list.items as? Set<GroceryListItem> else { return nil }
        let normalizedTarget = templateService.normalize(name: targetName)
        // M9.32: Also resolve the target's canonical name for template-based matching
        let targetCanonical = IngredientTemplate.canonicalName(from: normalizedTarget)

        return items.first { item in
            guard !item.isCompleted else { return false }
            guard let itemName = item.name else { return false }

            // M9.32: Extract clean name from stored text and compare normalized canonical
            let cleanItemName = IngredientParsingService.extractCleanIngredientName(from: itemName)
            let normalizedItem = templateService.normalize(name: cleanItemName)
            let itemCanonical = IngredientTemplate.canonicalName(from: normalizedItem)
            return itemCanonical == targetCanonical || normalizedItem == normalizedTarget
        }
    }

    // MARK: - Error Handling

    @discardableResult
    private func save(_ operation: String) -> Bool {
        guard viewContext.hasChanges else { return true }
        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "Failed to \(operation)"
            #if DEBUG
            print("❌ GroceryListItemService: Failed to \(operation): \(error)")
            #endif
            viewContext.rollback()
            return false
        }
    }
}
