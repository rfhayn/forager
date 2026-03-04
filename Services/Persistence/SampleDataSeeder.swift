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

    private static let hasSeededKey = "hasSeededSampleData_v2"
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
            ("salt", "Pantry"),
            ("olive oil", "Pantry")
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
                ("3 tbsp soy sauce", 3.0, "tbsp", "soy sauce", "Pantry"),
                ("3 cloves garlic", 3.0, nil, "garlic", "Produce"),
                ("2 cups broccoli florets", 2.0, "cup", "broccoli", "Produce"),
                ("1 cup rice", 1.0, "cup", "rice", "Pantry"),
                ("1 tbsp sesame oil", 1.0, "tbsp", "sesame oil", "Pantry")
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
                ("8 oz penne pasta", 8.0, "oz", "penne pasta", "Pantry"),
                ("1 medium zucchini", 1.0, nil, "zucchini", "Produce"),
                ("1 bell pepper", 1.0, nil, "bell pepper", "Produce"),
                ("1 cup cherry tomatoes", 1.0, "cup", "cherry tomatoes", "Produce"),
                ("2 tbsp olive oil", 2.0, "tbsp", "olive oil", "Pantry"),
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
                ("2 tbsp olive oil", 2.0, "tbsp", "olive oil", "Pantry"),
                ("1 lemon", 1.0, nil, "lemon", "Produce")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(salad)

        // Recipe 4: Honey Garlic Salmon
        let salmon = createRecipe(
            in: context,
            title: "Honey Garlic Salmon",
            prepTime: 10,
            cookTime: 15,
            servings: 4,
            instructions: """
            1. Pat salmon fillets dry and season with salt and pepper.
            2. Whisk together honey, soy sauce, and minced garlic in a small bowl.
            3. Heat olive oil in an oven-safe skillet over medium-high heat.
            4. Sear salmon skin-side up for 3 minutes until golden.
            5. Flip, pour honey garlic sauce over the top.
            6. Transfer skillet to 400°F oven for 8-10 minutes until flaky.
            7. Garnish with sesame seeds and sliced green onions.
            """,
            ingredients: [
                ("4 salmon fillets", 4.0, nil, "salmon fillets", "Deli & Meat"),
                ("3 tbsp honey", 3.0, "tbsp", "honey", "Pantry"),
                ("2 tbsp soy sauce", 2.0, "tbsp", "soy sauce", "Pantry"),
                ("4 cloves garlic", 4.0, nil, "garlic", "Produce"),
                ("1 tbsp sesame seeds", 1.0, "tbsp", "sesame seeds", "Pantry"),
                ("2 green onions", 2.0, nil, "green onions", "Produce")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(salmon)

        // Recipe 5: Chocolate Chip Cookies
        let cookies = createRecipe(
            in: context,
            title: "Chocolate Chip Cookies",
            prepTime: 15,
            cookTime: 12,
            servings: 24,
            instructions: """
            1. Preheat oven to 375°F. Line baking sheets with parchment paper.
            2. Cream together butter and both sugars until light and fluffy.
            3. Beat in eggs one at a time, then add vanilla extract.
            4. Whisk flour, baking soda, and salt in a separate bowl.
            5. Gradually mix dry ingredients into wet until just combined.
            6. Fold in chocolate chips.
            7. Drop rounded tablespoons onto prepared sheets, spacing 2 inches apart.
            8. Bake 10-12 minutes until edges are golden but centers look soft.
            9. Cool on pan 5 minutes, then transfer to wire rack.
            """,
            ingredients: [
                ("2 1/4 cups all-purpose flour", 2.25, "cup", "all-purpose flour", "Pantry"),
                ("1 cup butter", 1.0, "cup", "butter", "Dairy & Fridge"),
                ("3/4 cup granulated sugar", 0.75, "cup", "granulated sugar", "Pantry"),
                ("3/4 cup brown sugar", 0.75, "cup", "brown sugar", "Pantry"),
                ("2 eggs", 2.0, nil, "eggs", "Dairy & Fridge"),
                ("1 tsp vanilla extract", 1.0, "tsp", "vanilla extract", "Pantry"),
                ("1 tsp baking soda", 1.0, "tsp", "baking soda", "Pantry"),
                ("2 cups chocolate chips", 2.0, "cup", "chocolate chips", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(cookies)

        // Recipe 6: Beef Tacos
        let tacos = createRecipe(
            in: context,
            title: "Beef Tacos",
            prepTime: 10,
            cookTime: 15,
            servings: 4,
            instructions: """
            1. Heat olive oil in a skillet over medium-high heat.
            2. Cook ground beef, breaking it up, until browned. Drain excess fat.
            3. Add taco seasoning and water per packet directions. Simmer 5 minutes.
            4. Warm tortillas in a dry skillet or microwave.
            5. Assemble tacos with beef, shredded cheese, lettuce, and salsa.
            6. Squeeze fresh lime over the top and serve.
            """,
            ingredients: [
                ("1 lb ground beef", 1.0, "lb", "ground beef", "Deli & Meat"),
                ("1 packet taco seasoning", 1.0, nil, "taco seasoning", "Pantry"),
                ("8 small flour tortillas", 8.0, nil, "flour tortillas", "Bakery & Bread"),
                ("1 cup shredded cheddar", 1.0, "cup", "shredded cheddar", "Dairy & Fridge"),
                ("2 cups shredded lettuce", 2.0, "cup", "shredded lettuce", "Produce"),
                ("1/2 cup salsa", 0.5, "cup", "salsa", "Pantry"),
                ("2 limes", 2.0, nil, "limes", "Produce")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(tacos)

        // Recipe 7: Tomato Basil Soup
        let soup = createRecipe(
            in: context,
            title: "Tomato Basil Soup",
            prepTime: 10,
            cookTime: 30,
            servings: 6,
            instructions: """
            1. Heat olive oil in a large pot over medium heat.
            2. Sauté diced onion until softened, about 5 minutes.
            3. Add minced garlic and cook 1 minute more.
            4. Pour in crushed tomatoes and vegetable broth. Bring to a simmer.
            5. Cook 20 minutes, stirring occasionally.
            6. Stir in heavy cream and fresh basil leaves.
            7. Blend with an immersion blender until smooth. Season with salt and pepper.
            """,
            ingredients: [
                ("2 cans crushed tomatoes", 2.0, nil, "crushed tomatoes", "Pantry"),
                ("2 cups vegetable broth", 2.0, "cup", "vegetable broth", "Pantry"),
                ("1 medium onion", 1.0, nil, "onion", "Produce"),
                ("3 cloves garlic", 3.0, nil, "garlic", "Produce"),
                ("1/2 cup heavy cream", 0.5, "cup", "heavy cream", "Dairy & Fridge"),
                ("1/4 cup fresh basil", 0.25, "cup", "fresh basil", "Produce"),
                ("2 tbsp olive oil", 2.0, "tbsp", "olive oil", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(soup)

        // Recipe 8: Sheet Pan Lemon Chicken
        let lemonChicken = createRecipe(
            in: context,
            title: "Sheet Pan Lemon Chicken",
            prepTime: 15,
            cookTime: 35,
            servings: 4,
            instructions: """
            1. Preheat oven to 425°F. Line a sheet pan with foil.
            2. Toss chicken thighs with olive oil, lemon juice, oregano, salt, and pepper.
            3. Cut potatoes into 1-inch chunks. Trim green beans.
            4. Arrange chicken, potatoes, and green beans on the pan in a single layer.
            5. Scatter lemon slices and whole garlic cloves over everything.
            6. Roast 30-35 minutes until chicken reaches 165°F and potatoes are golden.
            """,
            ingredients: [
                ("2 lbs chicken thighs", 2.0, "lb", "chicken thighs", "Deli & Meat"),
                ("1 lb baby potatoes", 1.0, "lb", "baby potatoes", "Produce"),
                ("8 oz green beans", 8.0, "oz", "green beans", "Produce"),
                ("2 lemons", 2.0, nil, "lemons", "Produce"),
                ("6 cloves garlic", 6.0, nil, "garlic", "Produce"),
                ("1 tsp dried oregano", 1.0, "tsp", "dried oregano", "Pantry"),
                ("3 tbsp olive oil", 3.0, "tbsp", "olive oil", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(lemonChicken)

        // Recipe 9: Black Bean Quesadillas
        let quesadillas = createRecipe(
            in: context,
            title: "Black Bean Quesadillas",
            prepTime: 10,
            cookTime: 10,
            servings: 4,
            instructions: """
            1. Drain and rinse black beans. Mash half roughly with a fork.
            2. Mix beans with cumin, chili powder, and a pinch of salt.
            3. Spread bean mixture on one half of each tortilla.
            4. Top with shredded cheese and diced jalapeño.
            5. Fold tortillas in half.
            6. Cook in a dry skillet over medium heat, 3 minutes per side until crispy and cheese melts.
            7. Cut into wedges. Serve with sour cream and salsa.
            """,
            ingredients: [
                ("1 can black beans", 1.0, nil, "black beans", "Pantry"),
                ("4 large flour tortillas", 4.0, nil, "flour tortillas", "Bakery & Bread"),
                ("2 cups shredded Mexican cheese", 2.0, "cup", "shredded Mexican cheese", "Dairy & Fridge"),
                ("1 jalapeño", 1.0, nil, "jalapeño", "Produce"),
                ("1 tsp cumin", 1.0, "tsp", "cumin", "Pantry"),
                ("1/2 tsp chili powder", 0.5, "tsp", "chili powder", "Pantry"),
                ("1/2 cup sour cream", 0.5, "cup", "sour cream", "Dairy & Fridge"),
                ("1/2 cup salsa", 0.5, "cup", "salsa", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(quesadillas)

        // Recipe 10: Banana Bread
        let bananaBread = createRecipe(
            in: context,
            title: "Banana Bread",
            prepTime: 15,
            cookTime: 55,
            servings: 10,
            instructions: """
            1. Preheat oven to 350°F. Grease a 9x5-inch loaf pan.
            2. Mash ripe bananas in a large bowl.
            3. Stir in melted butter, sugar, egg, and vanilla.
            4. Mix in flour, baking soda, and a pinch of salt until just combined.
            5. Fold in walnuts if using.
            6. Pour batter into prepared pan.
            7. Bake 50-55 minutes until a toothpick comes out clean.
            8. Cool in pan 10 minutes, then turn out onto a wire rack.
            """,
            ingredients: [
                ("3 ripe bananas", 3.0, nil, "bananas", "Produce"),
                ("1/3 cup melted butter", 0.33, "cup", "butter", "Dairy & Fridge"),
                ("3/4 cup sugar", 0.75, "cup", "granulated sugar", "Pantry"),
                ("1 egg", 1.0, nil, "eggs", "Dairy & Fridge"),
                ("1 tsp vanilla extract", 1.0, "tsp", "vanilla extract", "Pantry"),
                ("1 1/2 cups all-purpose flour", 1.5, "cup", "all-purpose flour", "Pantry"),
                ("1 tsp baking soda", 1.0, "tsp", "baking soda", "Pantry"),
                ("1/2 cup chopped walnuts", 0.5, "cup", "walnuts", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(bananaBread)

        // Recipe 11: Greek Chicken Bowl
        let greekBowl = createRecipe(
            in: context,
            title: "Greek Chicken Bowl",
            prepTime: 20,
            cookTime: 15,
            servings: 4,
            instructions: """
            1. Season chicken breast with oregano, garlic powder, salt, and pepper.
            2. Grill or pan-sear chicken over medium-high heat, 6-7 minutes per side.
            3. Let rest 5 minutes, then slice.
            4. Cook rice or warm pita bread.
            5. Dice cucumber, halve cherry tomatoes, slice red onion, and crumble feta.
            6. Assemble bowls: rice base, sliced chicken, vegetables, feta, and olives.
            7. Drizzle with tzatziki or plain yogurt mixed with lemon juice.
            """,
            ingredients: [
                ("1.5 lbs chicken breast", 1.5, "lb", "chicken breast", "Deli & Meat"),
                ("1 cup rice", 1.0, "cup", "rice", "Pantry"),
                ("1 cucumber", 1.0, nil, "cucumber", "Produce"),
                ("1 cup cherry tomatoes", 1.0, "cup", "cherry tomatoes", "Produce"),
                ("1/4 red onion", 0.25, nil, "red onion", "Produce"),
                ("1/2 cup crumbled feta", 0.5, "cup", "feta cheese", "Dairy & Fridge"),
                ("1/4 cup kalamata olives", 0.25, "cup", "kalamata olives", "Pantry"),
                ("1/2 cup tzatziki", 0.5, "cup", "tzatziki", "Dairy & Fridge"),
                ("1 tsp dried oregano", 1.0, "tsp", "dried oregano", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(greekBowl)

        // Recipe 12: One-Pot Chili
        let chili = createRecipe(
            in: context,
            title: "One-Pot Chili",
            prepTime: 15,
            cookTime: 45,
            servings: 8,
            instructions: """
            1. Heat olive oil in a large Dutch oven over medium-high heat.
            2. Cook ground beef and diced onion until beef is browned. Drain fat.
            3. Add minced garlic, chili powder, cumin, and paprika. Stir 1 minute.
            4. Pour in diced tomatoes, tomato paste, and beef broth.
            5. Add drained kidney beans and black beans.
            6. Bring to a boil, then reduce heat and simmer 40 minutes, stirring occasionally.
            7. Season with salt and pepper.
            8. Serve topped with shredded cheese and sour cream.
            """,
            ingredients: [
                ("2 lbs ground beef", 2.0, "lb", "ground beef", "Deli & Meat"),
                ("1 large onion", 1.0, nil, "onion", "Produce"),
                ("4 cloves garlic", 4.0, nil, "garlic", "Produce"),
                ("1 can diced tomatoes", 1.0, nil, "diced tomatoes", "Pantry"),
                ("2 tbsp tomato paste", 2.0, "tbsp", "tomato paste", "Pantry"),
                ("1 cup beef broth", 1.0, "cup", "beef broth", "Pantry"),
                ("1 can kidney beans", 1.0, nil, "kidney beans", "Pantry"),
                ("1 can black beans", 1.0, nil, "black beans", "Pantry"),
                ("2 tbsp chili powder", 2.0, "tbsp", "chili powder", "Pantry"),
                ("1 tsp cumin", 1.0, "tsp", "cumin", "Pantry"),
                ("1 tsp paprika", 1.0, "tsp", "paprika", "Pantry")
            ],
            stapleTemplates: stapleTemplates
        )
        recipes.append(chili)

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
            ("chicken breast",    "2 lbs chicken breast",     2.0, "lb",   "Deli & Meat",     false),
            ("salmon fillets",    "4 salmon fillets",         4.0, nil,    "Deli & Meat",     false),
            ("ground beef",       "2 lbs ground beef",        2.0, "lb",   "Deli & Meat",     false),
            ("broccoli",          "2 cups broccoli",          2.0, "cup",  "Produce",         false),
            ("garlic",            "1 head garlic",            1.0, nil,    "Produce",         false),
            ("baby potatoes",     "1 lb baby potatoes",       1.0, "lb",   "Produce",         false),
            ("bananas",           "3 ripe bananas",           3.0, nil,    "Produce",         false),
            ("lemons",            "2 lemons",                 2.0, nil,    "Produce",         false),
            ("penne pasta",       "8 oz penne pasta",         8.0, "oz",   "Pantry",  false),
            ("crushed tomatoes",  "2 cans crushed tomatoes",  2.0, nil,    "Pantry",  false),
            ("chocolate chips",   "2 cups chocolate chips",   2.0, "cup",  "Pantry",  false),
            ("shredded cheddar",  "1 cup shredded cheddar",   1.0, "cup",  "Dairy & Fridge",  false),
            ("heavy cream",       "1/2 cup heavy cream",      0.5, "cup",  "Dairy & Fridge",  false),
            ("flour tortillas",   "8 flour tortillas",        8.0, nil,    "Bakery & Bread",  false),
            ("milk",              "1 gal milk",               1.0, "gal",  "Dairy & Fridge",  true),
            ("eggs",              "1 dozen eggs",             12.0, nil,    "Dairy & Fridge",  true),
            ("parmesan",          "1/4 cup parmesan",          0.25, "cup", "Dairy & Fridge",  true)
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
        guard recipes.count >= 8 else { return }

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

        // Monday: Chicken Stir Fry
        _ = createPlannedMeal(in: context, date: startDate, mealType: "dinner",
                              recipe: recipes[0], mealPlan: mealPlan)
        // Tuesday: Beef Tacos
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 1, to: startDate)!,
                              mealType: "dinner", recipe: recipes[5], mealPlan: mealPlan)
        // Wednesday: Pasta Primavera
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 2, to: startDate)!,
                              mealType: "dinner", recipe: recipes[1], mealPlan: mealPlan)
        // Thursday: Honey Garlic Salmon
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 3, to: startDate)!,
                              mealType: "dinner", recipe: recipes[3], mealPlan: mealPlan)
        // Friday: Sheet Pan Lemon Chicken
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 4, to: startDate)!,
                              mealType: "dinner", recipe: recipes[7], mealPlan: mealPlan)
        // Saturday: One-Pot Chili
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 5, to: startDate)!,
                              mealType: "dinner", recipe: recipes[11], mealPlan: mealPlan)
        // Sunday: Greek Chicken Bowl
        _ = createPlannedMeal(in: context, date: calendar.date(byAdding: .day, value: 6, to: startDate)!,
                              mealType: "dinner", recipe: recipes[10], mealPlan: mealPlan)
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
