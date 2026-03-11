import Foundation
import CoreData

/// M7.5: Service for managing Recipe and Ingredient CRUD operations
/// All recipe/ingredient writes go through this service — views never call context.save() directly.
/// Accepts IngredientParsingService via init for M8.4 forward-compatibility.
@MainActor
class RecipeService: ObservableObject {

    // MARK: - Properties

    private let viewContext: NSManagedObjectContext
    private let parsingService: IngredientParsingService

    // M9.13: Factory for creating HouseholdScoped entities in correct store (ADR 014)
    var factory: ManagedObjectFactory?

    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Initialization

    init(context: NSManagedObjectContext, parsingService: IngredientParsingService) {
        self.viewContext = context
        self.parsingService = parsingService
    }

    // MARK: - Recipe CRUD

    /// Creates a new recipe with basic metadata
    /// M9.13: Routes through ManagedObjectFactory for correct store assignment (ADR 014)
    func createRecipe(title: String, servings: Int16, prepTime: Int16 = 0, cookTime: Int16 = 0,
                      instructions: String? = nil, sourceURL: String? = nil) -> Recipe? {
        clearError()

        let recipe: Recipe
        if let factory = factory {
            guard let factoryRecipe = try? factory.make(Recipe.self, configure: { r in
                r.id = UUID()
                r.title = title
                r.servings = servings
                r.prepTime = prepTime
                r.cookTime = cookTime
                r.instructions = instructions
                r.sourceURL = sourceURL
                r.dateCreated = Date()
                r.usageCount = 0
                r.isFavorite = false
            }) else {
                errorMessage = "Failed to create recipe"
                return nil
            }
            recipe = factoryRecipe
        } else {
            recipe = Recipe(context: viewContext)
            recipe.id = UUID()
            recipe.title = title
            recipe.servings = servings
            recipe.prepTime = prepTime
            recipe.cookTime = cookTime
            recipe.instructions = instructions
            recipe.sourceURL = sourceURL
            recipe.dateCreated = Date()
            recipe.usageCount = 0
            recipe.isFavorite = false
        }

        return save("create recipe") ? recipe : nil
    }

    /// Updates recipe metadata (title, servings, times, instructions, etc.)
    func updateRecipe(_ recipe: Recipe, title: String? = nil, servings: Int16? = nil,
                      prepTime: Int16? = nil, cookTime: Int16? = nil,
                      instructions: String? = nil, sourceURL: String? = nil) {
        clearError()

        if let title = title { recipe.title = title }
        if let servings = servings { recipe.servings = servings }
        if let prepTime = prepTime { recipe.prepTime = prepTime }
        if let cookTime = cookTime { recipe.cookTime = cookTime }
        if let instructions = instructions { recipe.instructions = instructions }
        if let sourceURL = sourceURL { recipe.sourceURL = sourceURL }

        save("update recipe")
    }

    /// Deletes a recipe (cascade deletes its Ingredient entities per Core Data rules)
    func deleteRecipe(_ recipe: Recipe) {
        clearError()
        viewContext.delete(recipe)
        save("delete recipe")
    }

    /// Toggles favorite status on a recipe
    func toggleFavorite(_ recipe: Recipe) {
        clearError()
        recipe.isFavorite.toggle()
        save("toggle favorite")
    }

    /// Increments usage count and updates lastUsed date
    func markAsUsed(_ recipe: Recipe) {
        clearError()
        recipe.usageCount += 1
        recipe.lastUsed = Date()
        save("mark recipe as used")
    }

    /// Duplicates a recipe including all ingredients with their structured data
    /// M9.13: Routes through ManagedObjectFactory for correct store assignment (ADR 014)
    func duplicateRecipe(_ recipe: Recipe) -> Recipe? {
        clearError()

        let copy: Recipe
        if let factory = factory {
            guard let factoryCopy = try? factory.make(Recipe.self, configure: { r in
                r.id = UUID()
                r.title = "\(recipe.title ?? "Recipe") (Copy)"
                r.servings = recipe.servings
                r.prepTime = recipe.prepTime
                r.cookTime = recipe.cookTime
                r.instructions = recipe.instructions
                r.sourceURL = recipe.sourceURL
                r.tags = recipe.tags
                r.dateCreated = Date()
                r.usageCount = 0
                r.isFavorite = false
            }) else {
                errorMessage = "Failed to duplicate recipe"
                return nil
            }
            copy = factoryCopy
        } else {
            copy = Recipe(context: viewContext)
            copy.id = UUID()
            copy.title = "\(recipe.title ?? "Recipe") (Copy)"
            copy.servings = recipe.servings
            copy.prepTime = recipe.prepTime
            copy.cookTime = recipe.cookTime
            copy.instructions = recipe.instructions
            copy.sourceURL = recipe.sourceURL
            copy.tags = recipe.tags
            copy.dateCreated = Date()
            copy.usageCount = 0
            copy.isFavorite = false
            copy.householdKey = recipe.householdKey
        }

        // Duplicate all ingredients with structured data
        if let ingredients = recipe.ingredients as? Set<Ingredient> {
            for original in ingredients {
                let ingredient = Ingredient(context: viewContext)
                ingredient.id = UUID()
                ingredient.name = original.name
                ingredient.notes = original.notes
                ingredient.sortOrder = original.sortOrder
                ingredient.numericValue = original.numericValue
                ingredient.standardUnit = original.standardUnit
                ingredient.displayText = original.displayText
                ingredient.isParseable = original.isParseable
                ingredient.parseConfidence = original.parseConfidence
                ingredient.ingredientTemplate = original.ingredientTemplate
                ingredient.recipe = copy
            }
        }

        return save("duplicate recipe") ? copy : nil
    }

    // MARK: - Ingredient Operations

    /// Adds an ingredient to a recipe using pre-parsed structured data
    /// Keeps parsing concern separate from persistence concern
    func addIngredient(to recipe: Recipe, name: String,
                       numericValue: Double = 0, standardUnit: String? = nil,
                       displayText: String? = nil, isParseable: Bool = false,
                       parseConfidence: Float = 0, notes: String? = nil,
                       template: IngredientTemplate? = nil) -> Ingredient? {
        clearError()

        let ingredient = Ingredient(context: viewContext)
        ingredient.id = UUID()
        ingredient.name = name
        ingredient.numericValue = numericValue
        ingredient.standardUnit = standardUnit
        ingredient.displayText = displayText
        ingredient.isParseable = isParseable
        ingredient.parseConfidence = parseConfidence
        ingredient.notes = notes
        ingredient.ingredientTemplate = template
        ingredient.recipe = recipe

        // Set sort order to end of list
        let existingCount = (recipe.ingredients as? Set<Ingredient>)?.count ?? 0
        ingredient.sortOrder = Int16(existingCount)

        return save("add ingredient") ? ingredient : nil
    }

    /// Adds an ingredient from a StructuredQuantity (convenience for parse→service pipeline)
    func addIngredient(to recipe: Recipe, parsed: StructuredQuantity, name: String,
                       template: IngredientTemplate? = nil) -> Ingredient? {
        return addIngredient(
            to: recipe,
            name: name,
            numericValue: parsed.numericValue ?? 0,
            standardUnit: parsed.standardUnit,
            displayText: parsed.displayText,
            isParseable: parsed.isParseable,
            parseConfidence: parsed.parseConfidence,
            template: template
        )
    }

    /// Updates an existing ingredient's properties
    func updateIngredient(_ ingredient: Ingredient, name: String? = nil,
                          numericValue: Double? = nil, standardUnit: String? = nil,
                          displayText: String? = nil, isParseable: Bool? = nil,
                          parseConfidence: Float? = nil, notes: String? = nil,
                          template: IngredientTemplate? = nil) {
        clearError()

        if let name = name { ingredient.name = name }
        if let numericValue = numericValue { ingredient.numericValue = numericValue }
        if let standardUnit = standardUnit { ingredient.standardUnit = standardUnit }
        if let displayText = displayText { ingredient.displayText = displayText }
        if let isParseable = isParseable { ingredient.isParseable = isParseable }
        if let parseConfidence = parseConfidence { ingredient.parseConfidence = parseConfidence }
        if let notes = notes { ingredient.notes = notes }
        if let template = template { ingredient.ingredientTemplate = template }

        save("update ingredient")
    }

    /// Removes an ingredient from its recipe
    func removeIngredient(_ ingredient: Ingredient) {
        clearError()
        viewContext.delete(ingredient)
        save("remove ingredient")
    }

    /// Reorders ingredients within a recipe
    func reorderIngredients(_ ingredients: [Ingredient]) {
        clearError()
        for (index, ingredient) in ingredients.enumerated() {
            ingredient.sortOrder = Int16(index)
        }
        save("reorder ingredients")
    }

    // MARK: - Batch Operations

    /// Saves the current context, used when views perform multiple operations
    /// that should be committed together
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
        guard viewContext.hasChanges else { return true }

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "Failed to \(operation)"
            #if DEBUG
            print("❌ RecipeService: Failed to \(operation): \(error)")
            #endif
            viewContext.rollback()
            return false
        }
    }
}
