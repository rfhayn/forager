//
//  SampleDataSeeder.swift
//  forager
//
//  M7.6.3: Sample data for first-launch onboarding
//  Seeds realistic recipes, grocery list, meal plan, and staple templates
//  so new users see populated tabs during the onboarding walkthrough.
//

import CoreData
import Foundation

/// M7.6.3: Idempotent sample data seeding for first-launch onboarding
///
/// Responsibilities:
/// - Seed sample recipes with parsed ingredients
/// - Seed a grocery list with items across categories
/// - Seed a meal plan with planned meals
/// - Seed staple ingredient templates
/// - Clear all sample data on user request (preserves default categories)
///
/// Called from PersistenceController.performOneTimeSetup() after DefaultSeeder.
final class SampleDataSeeder {

    private static let hasSeededKey = "hasSeededSampleData"
    private static let hasClearedKey = "hasClearedSampleData"

    // MARK: - Public API

    /// True when sample data was seeded and hasn't been cleared yet.
    /// Used by coach mark overlay to decide whether to show "Clear Sample Data".
    static var hasSampleData: Bool {
        UserDefaults.standard.bool(forKey: hasSeededKey)
            && !UserDefaults.standard.bool(forKey: hasClearedKey)
    }

    /// Seeds sample data if this is a fresh install that hasn't been seeded or cleared.
    /// Idempotent: gated by UserDefaults flags.
    static func seedSampleDataIfNeeded(in context: NSManagedObjectContext) {
        // Never re-seed if user already cleared or if already seeded
        if UserDefaults.standard.bool(forKey: hasClearedKey) {
            return
        }
        if UserDefaults.standard.bool(forKey: hasSeededKey) {
            return
        }

        #if DEBUG
        print("🌱 M7.6.3: Seeding sample data for onboarding...")
        #endif

        let stapleTemplates = createStapleTemplates(in: context)
        let recipes = createSampleRecipes(in: context, stapleTemplates: stapleTemplates)
        createSampleGroceryList(in: context)
        createSampleMealPlan(in: context, recipes: recipes)

        UserDefaults.standard.set(true, forKey: hasSeededKey)

        #if DEBUG
        print("✅ M7.6.3: Sample data seeding complete")
        #endif
    }

    /// Removes all user-created data (recipes, lists, meal plans, templates).
    /// Preserves default categories from DefaultSeeder.
    /// Called from the onboarding "Clear Sample Data" button.
    static func clearSampleData(in context: NSManagedObjectContext) {
        #if DEBUG
        print("🧹 M7.6.3: Clearing sample data...")
        #endif

        // Delete planned meals first (child of both MealPlan and Recipe)
        deleteAll(PlannedMeal.self, in: context)

        // Delete meal plans
        deleteAll(MealPlan.self, in: context)

        // Delete grocery list items, then lists
        deleteAll(GroceryListItem.self, in: context)
        deleteAll(WeeklyList.self, in: context)

        // Delete ingredients, then recipes
        deleteAll(Ingredient.self, in: context)
        deleteAll(Recipe.self, in: context)

        // Delete non-default ingredient templates
        let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        if let templates = try? context.fetch(templateRequest) {
            for template in templates {
                context.delete(template)
            }
        }

        // Save
        if context.hasChanges {
            do {
                try context.save()
                #if DEBUG
                print("✅ M7.6.3: Sample data cleared")
                #endif
            } catch {
                #if DEBUG
                print("❌ M7.6.3: Failed to clear sample data: \(error)")
                #endif
            }
        }

        UserDefaults.standard.set(true, forKey: hasClearedKey)
    }

    // MARK: - Staple Templates

    private static func createStapleTemplates(in context: NSManagedObjectContext) -> [String: IngredientTemplate] {
        let staples: [(name: String, category: String)] = [
            ("butter", "Dairy & Fridge"),
            ("eggs", "Dairy & Fridge"),
            ("milk", "Dairy & Fridge"),
            ("salt", "Boxed & Canned"),
            ("olive oil", "Boxed & Canned")
        ]

        var templates: [String: IngredientTemplate] = [:]

        for staple in staples {
            let template = IngredientTemplate(context: context)
            template.id = UUID()
            template.name = staple.name
            template.canonicalName = staple.name
            template.category = staple.category
            template.isStaple = true
            template.usageCount = 1
            template.dateCreated = Date()
            template.updatedAt = Date()
            templates[staple.name] = template
        }

        return templates
    }

    // MARK: - Sample Recipes

    private static func createSampleRecipes(
        in context: NSManagedObjectContext,
        stapleTemplates: [String: IngredientTemplate]
    ) -> [Recipe] {
        var recipes: [Recipe] = []

        // Recipe 1: Chicken Stir Fry
        let stirFry = createRecipe(
            in: context,
            title: "Chicken Stir Fry",
            prepTime: 15,
            cookTime: 15,
            servings: 4,
            instructions: """
            1. Cut chicken into bite-sized pieces and season with salt.
            2. Heat sesame oil in a large skillet or wok over high heat.
            3. Cook chicken until golden, about 5 minutes. Remove and set aside.
            4. Add broccoli and minced garlic, stir fry for 3 minutes.
            5. Return chicken, add soy sauce, and toss to combine.
            6. Serve over cooked rice.
            """,
            ingredients: [
                ("1 lb chicken breast", 1.0, "lb", "chicken breast", "Deli & Meat"),
                ("3 tbsp soy sauce", 3.0, "tbsp", "soy sauce", "Boxed & Canned"),
                ("3 cloves garlic", 3.0, nil, "garlic", "Produce"),
                ("2 cups broccoli florets", 2.0, "cup", "broccoli", "Produce"),
                ("1 cup rice", 1.0, "cup", "rice", "Boxed & Canned"),
                ("1 tbsp sesame oil", 1.0, "tbsp", "sesame oil", "Boxed & Canned")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(stirFry)

        // Recipe 2: Pasta Primavera
        let pasta = createRecipe(
            in: context,
            title: "Pasta Primavera",
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            instructions: """
            1. Cook penne pasta according to package directions. Drain and set aside.
            2. Heat olive oil in a large skillet over medium-high heat.
            3. Sauté zucchini and bell pepper for 3-4 minutes until tender-crisp.
            4. Add halved cherry tomatoes and cook 2 minutes more.
            5. Toss pasta with vegetables, drizzle with olive oil, and top with parmesan.
            """,
            ingredients: [
                ("8 oz penne pasta", 8.0, "oz", "penne pasta", "Boxed & Canned"),
                ("1 medium zucchini", 1.0, nil, "zucchini", "Produce"),
                ("1 bell pepper", 1.0, nil, "bell pepper", "Produce"),
                ("1 cup cherry tomatoes", 1.0, "cup", "cherry tomatoes", "Produce"),
                ("2 tbsp olive oil", 2.0, "tbsp", "olive oil", "Boxed & Canned"),
                ("1/4 cup parmesan", 0.25, "cup", "parmesan", "Dairy & Fridge")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(pasta)

        // Recipe 3: Simple Green Salad
        let salad = createRecipe(
            in: context,
            title: "Simple Green Salad",
            prepTime: 10,
            cookTime: 0,
            servings: 2,
            instructions: """
            1. Wash and dry mixed greens, place in a large bowl.
            2. Slice cucumber and halve cherry tomatoes.
            3. Thinly slice red onion.
            4. Toss vegetables with greens.
            5. Drizzle with olive oil and a squeeze of fresh lemon. Season with salt.
            """,
            ingredients: [
                ("4 cups mixed greens", 4.0, "cup", "mixed greens", "Produce"),
                ("1 cucumber", 1.0, nil, "cucumber", "Produce"),
                ("1/2 cup cherry tomatoes", 0.5, "cup", "cherry tomatoes", "Produce"),
                ("1/4 red onion", 0.25, nil, "red onion", "Produce"),
                ("2 tbsp olive oil", 2.0, "tbsp", "olive oil", "Boxed & Canned"),
                ("1 lemon", 1.0, nil, "lemon", "Produce")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(salad)

        return recipes
    }

    /// Helper to create a single recipe with its ingredients and templates.
    /// Each ingredient tuple: (displayText, numericValue, standardUnit?, templateName, categoryName)
    private static func createRecipe(
        in context: NSManagedObjectContext,
        title: String,
        prepTime: Int16,
        cookTime: Int16,
        servings: Int16,
        instructions: String,
        ingredients: [(String, Double, String?, String, String)],
        stapleTemplates: [String: IngredientTemplate]
    ) -> Recipe {
        let recipe = Recipe(context: context)
        recipe.id = UUID()
        recipe.title = title
        recipe.prepTime = prepTime
        recipe.cookTime = cookTime
        recipe.servings = servings
        recipe.instructions = instructions
        recipe.isFavorite = false
        recipe.usageCount = 0
        recipe.dateCreated = Date()

        for (index, item) in ingredients.enumerated() {
            let (displayText, numericValue, standardUnit, templateName, categoryName) = item

            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = displayText
            ingredient.displayText = displayText
            ingredient.numericValue = numericValue
            ingredient.standardUnit = standardUnit
            ingredient.isParseable = true
            ingredient.parseConfidence = 1.0
            ingredient.sortOrder = Int16(index)
            ingredient.recipe = recipe

            // Link to existing staple template or create a new one
            if let existing = stapleTemplates[templateName] {
                ingredient.ingredientTemplate = existing
                existing.usageCount += 1
            } else {
                let template = findOrCreateTemplate(
                    named: templateName,
                    category: categoryName,
                    in: context
                )
                ingredient.ingredientTemplate = template
            }
        }

        return recipe
    }

    /// Finds an existing template by name or creates a new one.
    /// Simplified version for seeder use — doesn't go through full normalization pipeline.
    private static func findOrCreateTemplate(
        named name: String,
        category: String,
        in context: NSManagedObjectContext
    ) -> IngredientTemplate {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[cd] %@", name)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            existing.usageCount += 1
            return existing
        }

        let template = IngredientTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.canonicalName = name.lowercased()
        template.category = category
        template.isStaple = false
        template.usageCount = 1
        template.dateCreated = Date()
        template.updatedAt = Date()
        return template
    }

    // MARK: - Sample Grocery List

    private static func createSampleGroceryList(in context: NSManagedObjectContext) {
        let list = WeeklyList(context: context)
        list.id = UUID()
        list.name = "This Week's Groceries"
        list.isCompleted = false
        list.dateCreated = Date()

        let items: [(name: String, displayText: String, numericValue: Double, unit: String?, category: String, isCompleted: Bool)] = [
            ("chicken breast",   "1 lb chicken breast",    1.0, "lb",  "Deli & Meat",         false),
            ("broccoli",         "2 cups broccoli",        2.0, "cup", "Produce",              false),
            ("garlic",           "1 head garlic",          1.0, nil,   "Produce",              false),
            ("penne pasta",      "8 oz penne pasta",       8.0, "oz",  "Boxed & Canned",      false),
            ("cherry tomatoes",  "1 pint cherry tomatoes",  1.0, "pint","Produce",              false),
            ("parmesan",         "1/4 cup parmesan",        0.25,"cup", "Dairy & Fridge",       false),
            ("milk",             "1 gal milk",              1.0, "gal", "Dairy & Fridge",       true),
            ("eggs",             "1 dozen eggs",            12.0, nil,  "Dairy & Fridge",       true)
        ]

        for (index, item) in items.enumerated() {
            let listItem = GroceryListItem(context: context)
            listItem.id = UUID()
            listItem.name = item.name
            listItem.displayText = item.displayText
            listItem.numericValue = item.numericValue
            listItem.standardUnit = item.unit
            listItem.categoryName = item.category
            listItem.isParseable = true
            listItem.parseConfidence = 1.0
            listItem.isCompleted = item.isCompleted
            listItem.sortOrder = Int16(index)
            listItem.weeklyList = list
            if item.isCompleted {
                listItem.dateCompleted = Date().addingTimeInterval(-3600)
            }
        }
    }

    // MARK: - Sample Meal Plan

    private static func createSampleMealPlan(in context: NSManagedObjectContext, recipes: [Recipe]) {
        guard recipes.count >= 3 else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find next Monday as start date
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilMonday = (9 - weekday) % 7  // Sunday=1, Monday=2
        let startDate = calendar.date(byAdding: .day, value: daysUntilMonday == 0 ? 0 : daysUntilMonday, to: today)!

        let mealPlan = MealPlan(context: context)
        mealPlan.id = UUID()
        mealPlan.name = "Sample Week"
        mealPlan.startDate = startDate
        mealPlan.duration = 7
        mealPlan.isActive = true
        mealPlan.isCompleted = false
        mealPlan.createdDate = Date()

        // Monday dinner: Chicken Stir Fry
        let monday = createPlannedMeal(
            in: context,
            date: startDate,
            mealType: "dinner",
            recipe: recipes[0],
            mealPlan: mealPlan
        )
        _ = monday

        // Wednesday dinner: Pasta Primavera
        let wednesday = createPlannedMeal(
            in: context,
            date: calendar.date(byAdding: .day, value: 2, to: startDate)!,
            mealType: "dinner",
            recipe: recipes[1],
            mealPlan: mealPlan
        )
        _ = wednesday

        // Friday dinner: Simple Green Salad
        let friday = createPlannedMeal(
            in: context,
            date: calendar.date(byAdding: .day, value: 4, to: startDate)!,
            mealType: "dinner",
            recipe: recipes[2],
            mealPlan: mealPlan
        )
        _ = friday
    }

    private static func createPlannedMeal(
        in context: NSManagedObjectContext,
        date: Date,
        mealType: String,
        recipe: Recipe,
        mealPlan: MealPlan
    ) -> PlannedMeal {
        let meal = PlannedMeal(context: context)
        meal.id = UUID()
        meal.date = date
        meal.mealType = mealType
        meal.servings = recipe.servings
        meal.scaleFactor = 1.0
        meal.isCompleted = false
        meal.createdDate = Date()
        meal.recipe = recipe
        meal.mealPlan = mealPlan
        return meal
    }

    // MARK: - Helpers

    private static func deleteAll<T: NSManagedObject>(_ type: T.Type, in context: NSManagedObjectContext) {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        if let objects = try? context.fetch(request) {
            for object in objects {
                context.delete(object)
            }
        }
    }
}
