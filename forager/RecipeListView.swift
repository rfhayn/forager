import SwiftUI
import CoreData

struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var householdService: HouseholdService

    @Binding var popToRoot: Bool

    @StateObject private var recipeService = OptimizedRecipeDataService(context: PersistenceController.shared.container.viewContext)

    @State private var searchText = ""
    @State private var showingAddRecipe = false
    @State private var searchHistory: [String] = []

    // M4.2.4 PHASE 7: Updated to use SelectMealPlanSheet for multi-plan support
    @State private var showingMealPlanSheet = false
    @State private var selectedRecipeForMealPlan: Recipe?

    @FetchRequest(
        entity: Recipe.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Recipe.lastUsed, ascending: false),
            NSSortDescriptor(keyPath: \Recipe.title, ascending: true)
        ],
        animation: .default
    ) private var allRecipes: FetchedResults<Recipe>

    // M7.3.2: Filter recipes based on current household context
    // M7.2.2 FIX: Use currentHouseholdKey which has fallback for nil household.id
    private var recipes: [Recipe] {
        let currentHouseholdKey = householdService.currentHouseholdKey

        #if DEBUG
        print("🔍 M7.3.2 Recipe Filter Debug:")
        print("   Total recipes in fetch: \(allRecipes.count)")
        // M7.2.2 DEBUG: Check what's nil - the household or the id?
        if let household = householdService.currentHousehold {
            print("   Household exists: '\(household.name ?? "unnamed")'")
            print("   Household.id: \(household.id?.uuidString ?? "NIL")")
            print("   Derived key: \(householdService.currentHouseholdKey ?? "nil")")
        } else {
            print("   Household is nil")
        }
        print("   Current household key: \(currentHouseholdKey ?? "nil")")
        if !allRecipes.isEmpty {
            let first5 = allRecipes.prefix(5)
            for recipe in first5 {
                print("   Recipe '\(recipe.title ?? "untitled")': householdKey=\(recipe.householdKey ?? "nil")")
            }
            if allRecipes.count > 5 {
                print("   ... and \(allRecipes.count - 5) more")
            }
        }
        #endif

        return allRecipes.filter { recipe in
            if let householdKey = currentHouseholdKey {
                return recipe.householdKey == householdKey
            } else {
                return recipe.householdKey == nil
            }
        }
    }

    // M15.4: Filter and sort state
    @State private var activeFilter: RecipeFilter = .all
    @State private var sortOrder: RecipeSortOrder = .recent

    enum RecipeFilter: String, CaseIterable {
        case all, favorites, recent

        var title: String {
            switch self {
            case .all: return "All"
            case .favorites: return "Favorites"
            case .recent: return "Recent"
            }
        }
    }

    enum RecipeSortOrder {
        case recent, alphabetical, mostUsed
    }

    // M3.5: Simplified search using computed property
    private var filteredRecipes: [Recipe] {
        var result: [Recipe]

        if searchText.isEmpty {
            result = recipes
        } else {
            result = recipes.filter { recipe in
                recipe.matchesRecipeSearchQuery(searchText)
            }
        }

        // M15.4: Apply filter
        switch activeFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            result = result
                .filter { $0.lastUsed != nil }
                .sorted { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
            if result.count > 20 { result = Array(result.prefix(20)) }
        }

        // M15.4: Apply sort (unless searching, which sorts by relevance)
        if searchText.isEmpty {
            switch sortOrder {
            case .recent:
                result.sort { ($0.lastUsed ?? $0.dateCreated ?? .distantPast) > ($1.lastUsed ?? $1.dateCreated ?? .distantPast) }
            case .alphabetical:
                result.sort { $0.recipeDisplayTitle < $1.recipeDisplayTitle }
            case .mostUsed:
                result.sort { $0.usageCount > $1.usageCount }
            }
        } else {
            result.sort { first, second in
                if first.usageCount != second.usageCount {
                    return first.usageCount > second.usageCount
                }
                return first.recipeDisplayTitle < second.recipeDisplayTitle
            }
        }

        return result
    }
    
    // ENHANCED: Search result analysis for UI indicators
    private func getMatchIndicators(for recipe: Recipe) -> [SearchMatchType] {
        guard !searchText.isEmpty else { return [] }
        
        let searchTerms = searchText.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        
        var indicators: [SearchMatchType] = []
        let title = recipe.title?.lowercased() ?? ""
        let instructions = recipe.instructions?.lowercased() ?? ""
        
        let ingredientNames = (recipe.ingredients?.allObjects as? [Ingredient])?
            .compactMap { $0.name?.lowercased() } ?? []
        
        for term in searchTerms {
            if title.contains(term) {
                indicators.append(.title)
            }
            if ingredientNames.contains(where: { $0.contains(term) }) {
                indicators.append(.ingredient)
            }
            if instructions.contains(term) {
                indicators.append(.instructions)
            }
        }
        
        return Array(Set(indicators)) // Remove duplicates
    }
    
    // ENHANCED: Search history management
    private func addToSearchHistory(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !searchHistory.contains(trimmed) else { return }
        
        searchHistory.insert(trimmed, at: 0)
        if searchHistory.count > 8 {
            searchHistory = Array(searchHistory.prefix(8))
        }
        
        // Persist search history
        UserDefaults.standard.set(searchHistory, forKey: "RecipeSearchHistory")
    }
    
    // ENHANCED: Load search history
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "RecipeSearchHistory") ?? []
    }

    var body: some View {
        ZStack {
            ForagerTheme.backgroundCanvas
                .ignoresSafeArea()

            if filteredRecipes.isEmpty {
                enhancedEmptyStateView
            } else {
                recipeListContent
            }
        }
        .navigationTitle("Recipes")
        .searchable(text: $searchText)
        .searchSuggestions {
            if !searchText.isEmpty && !searchHistory.isEmpty {
                searchSuggestionsView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Menu {
                    Picker("Sort", selection: $sortOrder) {
                        Text("Recent").tag(RecipeSortOrder.recent)
                        Text("A-Z").tag(RecipeSortOrder.alphabetical)
                        Text("Most Used").tag(RecipeSortOrder.mostUsed)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAddRecipe = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            CreateRecipeView(context: viewContext)
        }
        .sheet(isPresented: $showingMealPlanSheet) {
            if let recipe = selectedRecipeForMealPlan {
                SelectMealPlanSheet(recipe: recipe) { plan, date in
                    if let _ = MealPlanService.shared.addRecipeToMealPlan(
                        recipe: recipe,
                        date: date,
                        mealPlan: plan
                    ) {
                        #if DEBUG
                        print("✅ M4.2.4: Added \(recipe.title ?? "recipe") to \(plan.name ?? "plan") on \(date)")
                        #endif
                    }
                }
            }
        }
        .onAppear {
            loadSearchHistory()
        }
        .onSubmit(of: .search) {
            if !searchText.isEmpty {
                addToSearchHistory(searchText)
            }
        }
        .onChange(of: popToRoot) { _, _ in
            if showingAddRecipe { showingAddRecipe = false }
            if showingMealPlanSheet { showingMealPlanSheet = false }
            if selectedRecipeForMealPlan != nil { selectedRecipeForMealPlan = nil }
        }
    }
    
    @ViewBuilder
    private var enhancedEmptyStateView: some View {
        if searchText.isEmpty && activeFilter == .all {
            #if DEBUG
            StandardEmptyStateView(
                iconName: "book.closed",
                title: "No Recipes Yet",
                subtitle: "Start building your recipe collection!",
                buttonIcon: "plus.circle.fill",
                buttonText: "Generate Test Recipes",
                buttonAction: createSampleRecipe
            )
            #else
            StandardEmptyStateView(
                iconName: "book.closed",
                title: "No Recipes Yet",
                subtitle: "Start building your recipe collection!",
                buttonIcon: "plus.circle.fill",
                buttonText: "Add Recipe",
                buttonAction: { showingAddRecipe = true }
            )
            #endif
        } else if !searchText.isEmpty {
            VStack(spacing: ForagerTheme.Spacing.xl) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(ForagerTheme.accentPrimary)

                VStack(spacing: ForagerTheme.Spacing.sm) {
                    Text("No Matches Found")
                        .font(ForagerTheme.cardTitle)

                    Text("No recipes found for \"\(searchText)\"")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Text("Try searching for recipe names, ingredients, or cooking methods")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .multilineTextAlignment(.center)
                }

                Button("Clear Search") { searchText = "" }
                    .buttonStyle(ForagerSecondaryButtonStyle())
            }
            .padding()
        } else {
            // Filter-specific empty state (e.g. no favorites)
            VStack(spacing: ForagerTheme.Spacing.xl) {
                Image(systemName: activeFilter == .favorites ? "heart" : "clock")
                    .font(.system(size: 60))
                    .foregroundStyle(ForagerTheme.accentPrimary)

                VStack(spacing: ForagerTheme.Spacing.sm) {
                    Text(activeFilter == .favorites ? "No Favorites" : "No Recent Recipes")
                        .font(ForagerTheme.cardTitle)

                    Text(activeFilter == .favorites
                         ? "Heart a recipe to see it here"
                         : "Mark recipes as made to see them here")
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var recipeListContent: some View {
        VStack(spacing: 0) {
            // M15.4: Filter pills
            filterPillRow

            if !searchText.isEmpty {
                searchResultHeader
            }

            List {
                ForEach(filteredRecipes, id: \.objectID) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeCardView(recipe: recipe)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: ForagerTheme.Spacing.xs,
                        leading: ForagerTheme.Spacing.lg,
                        bottom: ForagerTheme.Spacing.xs,
                        trailing: ForagerTheme.Spacing.lg
                    ))
                    .swipeActions(edge: .leading) {
                        Button {
                            selectedRecipeForMealPlan = recipe
                            showingMealPlanSheet = true
                        } label: {
                            Label("Add to Meal Plan", systemImage: "calendar.badge.plus")
                        }
                        .tint(ForagerTheme.accentPrimary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteRecipe(recipe)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(ForagerTheme.backgroundCanvas)
            .scrollContentBackground(.hidden)
        }
    }

    // M15.4: Filter pill row
    private var filterPillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                ForEach(RecipeFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation { activeFilter = filter }
                    } label: {
                        FilterPill(
                            title: filter.title,
                            isSelected: activeFilter == filter
                        )
                    }
                }
            }
            .padding(.horizontal, ForagerTheme.Spacing.lg)
            .padding(.vertical, ForagerTheme.Spacing.sm)
        }
    }

    private var searchResultHeader: some View {
        HStack {
            Text("\(filteredRecipes.count) recipe\(filteredRecipes.count == 1 ? "" : "s") found")
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textSecondary)

            Spacer()

            if !filteredRecipes.isEmpty {
                Text("Sorted by relevance")
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .padding(.horizontal, ForagerTheme.Spacing.lg)
        .padding(.vertical, ForagerTheme.Spacing.sm)
    }
    
    private var searchSuggestionsView: some View {
        ForEach(searchHistory.prefix(5), id: \.self) { historyItem in
            Button {
                searchText = historyItem
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(ForagerTheme.textTertiary)
                        .font(ForagerTheme.captionFont)
                    Text(historyItem)
                        .foregroundStyle(ForagerTheme.textPrimary)
                    Spacer()
                }
            }
        }
    }
    
    // M4.3.1: Updated to create 6 test recipes with overlapping ingredients
    private func createSampleRecipe() {
        createAllTestRecipes()
    }
    
    private func createAllTestRecipes() {
        // M4.3.5 FIX: Create recipes sequentially to avoid Core Data race conditions
        // Don't wrap in withAnimation - causes context save conflicts
        
        // Recipe 1: Chocolate Chip Cookies
        createRecipe(
                title: "Chocolate Chip Cookies",
                instructions: """
                1. Preheat oven to 375°F
                2. Mix dry ingredients
                3. Combine wet ingredients
                4. Mix everything together
                5. Drop spoonfuls on baking sheet
                6. Bake for 9-11 minutes
                """,
                servings: 24,
                prepTime: 15,
                cookTime: 10,
                ingredients: [
                    "2 eggs",
                    "1/2 cup butter",
                    "2 cups flour",
                    "1 cup chocolate chips",
                    "3/4 cup sugar",
                    "1 tsp vanilla extract"
                ]
            )
            
            // Recipe 2: Pancakes
            createRecipe(
                title: "Pancakes",
                instructions: """
                1. Mix dry ingredients in bowl
                2. Whisk eggs, milk, melted butter, vanilla
                3. Combine wet and dry ingredients
                4. Heat griddle to medium heat
                5. Pour 1/4 cup batter per pancake
                6. Flip when bubbles form
                7. Cook until golden brown
                """,
                servings: 8,
                prepTime: 5,
                cookTime: 15,
                ingredients: [
                    "2 eggs",
                    "1 cup flour",
                    "1 cup milk",
                    "2 tbsp butter",
                    "1 tsp vanilla extract",
                    "2 tsp baking powder",
                    "1 tbsp sugar"
                ]
            )
            
            // Recipe 3: Scrambled Eggs
            createRecipe(
                title: "Scrambled Eggs",
                instructions: """
                1. Crack eggs into bowl
                2. Add milk, salt, pepper
                3. Whisk until combined
                4. Melt butter in pan over medium heat
                5. Pour in egg mixture
                6. Stir gently until cooked
                7. Serve immediately
                """,
                servings: 2,
                prepTime: 2,
                cookTime: 5,
                ingredients: [
                    "4 eggs",
                    "2 tbsp butter",
                    "1/4 cup milk",
                    "1/4 tsp salt",
                    "1/8 tsp pepper"
                ]
            )
            
            // Recipe 4: Sugar Cookies
            createRecipe(
                title: "Sugar Cookies",
                instructions: """
                1. Cream butter and sugar
                2. Beat in egg and vanilla
                3. Mix dry ingredients separately
                4. Combine wet and dry ingredients
                5. Roll dough 1/4 inch thick
                6. Cut into shapes
                7. Bake at 350°F for 8-10 minutes
                """,
                servings: 36,
                prepTime: 20,
                cookTime: 8,
                ingredients: [
                    "1 egg",
                    "1/2 cup butter",
                    "2 cups flour",
                    "1 cup sugar",
                    "1 tsp vanilla extract",
                    "1 tsp baking powder",
                    "1/4 tsp salt"
                ]
            )
            
            // Recipe 5: French Toast
            createRecipe(
                title: "French Toast",
                instructions: """
                1. Whisk eggs, milk, vanilla, cinnamon, sugar
                2. Heat butter in large pan
                3. Dip bread in egg mixture
                4. Cook 2-3 minutes per side until golden
                5. Serve with syrup and berries
                """,
                servings: 4,
                prepTime: 5,
                cookTime: 10,
                ingredients: [
                    "3 eggs",
                    "1/2 cup milk",
                    "1 tbsp butter",
                    "1 tsp vanilla extract",
                    "8 slices bread",
                    "1/2 tsp cinnamon",
                    "1 tbsp sugar"
                ]
            )
            
            // Recipe 6: Brownies
            createRecipe(
                title: "Brownies",
                instructions: """
                1. Preheat oven to 350°F
                2. Melt butter and chocolate chips
                3. Stir in sugar and eggs
                4. Add cocoa, flour, vanilla, salt
                5. Pour into greased 8x8 pan
                6. Bake 25-30 minutes
                7. Cool before cutting
                """,
                servings: 16,
                prepTime: 10,
                cookTime: 25,
                ingredients: [
                    "2 eggs",
                    "1/2 cup butter",
                    "1 cup flour",
                    "1 cup chocolate chips",
                    "1 cup sugar",
                    "1/3 cup cocoa powder",
                    "1/2 tsp vanilla extract",
                    "1/4 tsp salt"
                ]
            )
            
            // M4.3.5 PHASE 3: Recipe 7 - Tests abbreviation expansion
            createRecipe(
                title: "Guacamole",
                instructions: """
                1. Mash avocados in bowl
                2. Mix in lime juice, salt, pepper
                3. Add diced tomatoes and onions
                4. Stir in cilantro
                5. Serve with chips
                """,
                servings: 4,
                prepTime: 10,
                cookTime: 0,
                ingredients: [
                    "3 avocados",
                    "2 tbsp lime juice",
                    "1 tsp salt",
                    "1/2 tsp pepper",
                    "1 c diced tomatoes",
                    "1/4 c diced onions"
                ]
            )
            
            // M4.3.5 PHASE 3: Recipe 8 - Tests more abbreviations
            createRecipe(
                title: "Chocolate Milk",
                instructions: """
                1. Pour milk into glass
                2. Add chocolate syrup
                3. Stir well
                4. Add ice if desired
                """,
                servings: 1,
                prepTime: 2,
                cookTime: 0,
                ingredients: [
                    "1 c milk",
                    "2 tbsp chocolate syrup"
                ]
            )
            
            // M4.3.5 PHASE 4: Recipe 9 - Tests preparation & freshness descriptors
            createRecipe(
                title: "Pasta Primavera",
                instructions: """
                1. Cook pasta according to package directions
                2. Sauté garlic in olive oil
                3. Add vegetables and cook until tender
                4. Toss with pasta and cheese
                5. Season with salt and pepper
                """,
                servings: 4,
                prepTime: 15,
                cookTime: 20,
                ingredients: [
                    "8 oz pasta",
                    "2 cloves minced garlic",
                    "1 cup sliced mushrooms",
                    "1/4 cup fresh basil",
                    "1/2 cup grated parmesan cheese",
                    "2 tbsp extra-virgin olive oil",
                    "1 cup chopped tomatoes",
                    "1/2 tsp salt",
                    "1/4 tsp pepper"
                ]
            )
            
            // M4.3.5 PHASE 4: Recipe 10 - Tests type/variety & size descriptors
            createRecipe(
                title: "Chicken Pot Pie",
                instructions: """
                1. Preheat oven to 375°F
                2. Cook chicken and vegetables
                3. Make cream sauce with butter and flour
                4. Combine filling in pie dish
                5. Top with pie crust
                6. Bake 35-40 minutes until golden
                """,
                servings: 6,
                prepTime: 25,
                cookTime: 40,
                ingredients: [
                    "2 cups diced chicken",
                    "1 cup frozen peas",
                    "1 cup frozen carrots",
                    "3 large eggs",
                    "1/4 cup unsalted butter",
                    "1/3 cup all-purpose flour",
                    "2 cups chicken broth",
                    "1 cup heavy cream",
                    "1 tsp salt",
                    "1/2 tsp pepper"
                ]
            )
            
            // M4.3.5 PHASE 4: Recipe 11 - Tests quality & additional descriptors
            createRecipe(
                title: "Garden Salad",
                instructions: """
                1. Wash and dry lettuce
                2. Chop vegetables
                3. Combine in large bowl
                4. Toss with dressing
                5. Top with cheese and croutons
                """,
                servings: 4,
                prepTime: 15,
                cookTime: 0,
                ingredients: [
                    "4 cups fresh lettuce",
                    "1 cup baby carrots",
                    "1/2 cup sliced cucumber",
                    "1/4 cup diced red onion",
                    "2 organic tomatoes",
                    "1/4 cup shredded cheddar cheese",
                    "1/4 cup croutons",
                    "2 tbsp salad dressing"
                ]
            )

            // M8.1: Recipe 12 - Tests LOW CONFIDENCE parsing (for yellow badge)
            createRecipe(
                title: "Simple Seasoned Rice",
                instructions: """
                1. Rinse rice under cold water
                2. Combine rice and water in pot
                3. Bring to boil, reduce heat
                4. Cover and simmer 18 minutes
                5. Fluff with fork and season
                """,
                servings: 4,
                prepTime: 5,
                cookTime: 20,
                ingredients: [
                    "2 cups rice",
                    "salt to taste",
                    "pepper as needed",
                    "a pinch of saffron",
                    "butter (room temperature, European-style, about 2 tablespoons or so)",
                    "fresh herbs to garnish"
                ]
            )

            // M8.1: Recipe 13 - More LOW CONFIDENCE ingredients
            createRecipe(
                title: "Rustic Garlic Bread",
                instructions: """
                1. Preheat oven to 375°F
                2. Slice bread lengthwise
                3. Spread garlic butter mixture
                4. Bake until golden, about 10 minutes
                5. Sprinkle with herbs
                """,
                servings: 6,
                prepTime: 10,
                cookTime: 10,
                ingredients: [
                    "1 loaf french bread",
                    "butter as desired",
                    "2-3 cloves garlic",
                    "a handful of parsley",
                    "parmesan to taste"
                ]
            )

            // M8.1: Recipe 14 - Mixed confidence ingredients
            createRecipe(
                title: "Quick Avocado Toast",
                instructions: """
                1. Toast bread until golden
                2. Mash avocado with fork
                3. Spread on toast
                4. Season and top as desired
                """,
                servings: 2,
                prepTime: 5,
                cookTime: 3,
                ingredients: [
                    "2 slices bread",
                    "1 ripe avocado",
                    "salt and pepper to taste",
                    "a drizzle of olive oil",
                    "red pepper flakes as desired",
                    "fresh lemon juice to taste"
                ]
            )

            // M8.3: Recipe 15 - Tests unicode fractions, parentheticals, compound phrases
            createRecipe(
                title: "Hearty Tortilla Soup",
                instructions: """
                1. Sauté onion and garlic in oil
                2. Add tomatoes, broth, and spices
                3. Simmer 20 minutes
                4. Add chicken and beans
                5. Serve with tortilla strips and toppings
                """,
                servings: 6,
                prepTime: 15,
                cookTime: 25,
                ingredients: [
                    "1 can (14.5 oz) diced tomatoes",
                    "½ cup sour cream",
                    "¼ tsp cayenne",
                    "one and a half cups chicken broth",
                    "two cloves garlic",
                    "⅓ cup chopped cilantro",
                    "2-3 cups shredded chicken",
                    "1 can (15 oz) black beans",
                    "a handful of tortilla strips",
                    "lime juice to taste"
                ]
            )

        #if DEBUG
        print("✅ Created 15 test recipes with comprehensive variation coverage (M4.3.5 Phase 4 + M8.1 + M8.3)")
        #endif
    }
    
    // Helper function to create a recipe with ingredients
    private func createRecipe(title: String, instructions: String, servings: Int16, prepTime: Int16, cookTime: Int16, ingredients: [String]) {
        let newRecipe = Recipe(context: viewContext)
        newRecipe.id = UUID()
        newRecipe.title = title
        newRecipe.instructions = instructions
        newRecipe.servings = servings
        newRecipe.prepTime = prepTime
        newRecipe.cookTime = cookTime
        newRecipe.usageCount = 0
        newRecipe.dateCreated = Date()
        newRecipe.isFavorite = false
        
        do {
            try viewContext.save()
            #if DEBUG
            print("✅ Saved recipe: '\(title)'")
            #endif
            
            addIngredientsWithParsing(to: newRecipe, ingredients: ingredients, in: viewContext)
            #if DEBUG
            print("   - Created \(ingredients.count) ingredients for '\(title)'")
            #endif
            
            try viewContext.save()
            #if DEBUG
            print("✅ Saved ingredients for: '\(title)'")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error creating recipe '\(title)': \(error)")
            print("   Error details: \(error.localizedDescription)")
            #endif
            viewContext.rollback()
        }
    }
    
    private func addIngredientsWithParsing(to recipe: Recipe, ingredients: [String], in context: NSManagedObjectContext) {
        let templateService = IngredientTemplateService(context: context)
        let parsingService = IngredientParsingService(context: context, templateService: templateService)
        
        for (index, text) in ingredients.enumerated() {
            let parsed = parsingService.parseIngredient(text: text)
            let structured = parsingService.parseToStructured(text: text)
            
            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = text
            ingredient.sortOrder = Int16(index)
            ingredient.recipe = recipe
            
            // M4.3.5 FIX: Create/link ingredient template (was missing!)
            // Extract ingredient name from parsed result and create template
            let ingredientName = parsed.displayName
            #if DEBUG
            print("      Parsing '\(text)' -> template name: '\(ingredientName)'")
            #endif
            
            if !ingredientName.isEmpty && ingredientName.lowercased() != "unknown ingredient" {
                ingredient.ingredientTemplate = templateService.findOrCreateTemplate(name: ingredientName)
            } else {
                #if DEBUG
                print("      ⚠️ WARNING: Skipping template creation for empty/unknown ingredient")
                #endif
            }
            
            // M4.3.1 FIX: Populate all structured quantity fields
            ingredient.displayText = structured.displayText
            ingredient.numericValue = structured.numericValue ?? 0.0
            ingredient.standardUnit = structured.standardUnit
            ingredient.isParseable = structured.isParseable
            ingredient.parseConfidence = structured.parseConfidence
        }
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        let recipeID = recipe.objectID
        PersistenceController.shared.performWrite({ context in
            let toDelete = context.object(with: recipeID)
            context.delete(toDelete)
        }, onError: { error in
            #if DEBUG
            print("Error deleting recipe: \(error)")
            #endif
        })
    }
}

// MARK: - M15.4: Card-Based Recipe Row

struct RecipeCardView: View {
    @ObservedObject var recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            // Title
            Text(recipe.recipeDisplayTitle)
                .font(ForagerTheme.cardTitle)
                .foregroundStyle(ForagerTheme.textPrimary)
                .lineLimit(2)

            // Timing pills row
            if recipe.hasRecipeTiming {
                HStack(spacing: ForagerTheme.Spacing.sm) {
                    if recipe.prepTime > 0 {
                        timingPill(icon: "clock", text: recipe.recipeFormattedPrepTime)
                    }
                    if recipe.cookTime > 0 {
                        timingPill(icon: "flame", text: recipe.recipeFormattedCookTime)
                    }
                    if recipe.totalTime > 0 && recipe.prepTime > 0 && recipe.cookTime > 0 {
                        timingPill(icon: "timer", text: recipe.recipeFormattedTotalTime)
                    }
                }
            }

            // Metadata row
            HStack {
                Text(recipe.recipeServingsDescription)
                    .font(ForagerTheme.captionFont)
                    .foregroundStyle(ForagerTheme.textTertiary)

                Spacer()

                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.statusDangerFG)
                }
            }
        }
        .foragerCard()
    }

    private func timingPill(icon: String, text: String) -> some View {
        HStack(spacing: ForagerTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(ForagerTheme.captionFont)
            Text(text)
                .font(ForagerTheme.captionFont)
        }
        .foregroundStyle(ForagerTheme.accentSecondary)
        .padding(.horizontal, ForagerTheme.Spacing.sm)
        .padding(.vertical, ForagerTheme.Spacing.xs)
        .background(ForagerTheme.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
    }
}

// MARK: - M3 PHASE 4: RecipeDetailView with Scaling Integration - M3.5: USES COMPUTED PROPERTIES

struct RecipeDetailView: View {
    @ObservedObject var recipe: Recipe
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var categories: FetchedResults<Category>
    
    @State private var showingAddToListSheet = false
    @State private var showingMarkUsedConfirmation = false
    @State private var showingEditSheet = false
    
    // M4.2.4 PHASE 7: Updated to use SelectMealPlanSheet for multi-plan support
    @State private var showingMealPlanSheet = false
    
    // M3 PHASE 4: Recipe Scaling State
    @State private var showingScalingSheet = false
    private let scalingService: RecipeScalingService

    // M3 PHASE 4: Initialize scaling service
    init(recipe: Recipe) {
        self.recipe = recipe
        self.scalingService = RecipeScalingService(
            context: PersistenceController.shared.container.viewContext
        )
    }
    
    private var groupedIngredients: [String: [Ingredient]] {
        guard let ingredientsSet = recipe.ingredients else { return [:] }
        let ingredientsList = Array(ingredientsSet) as! [Ingredient]
        
        return Dictionary(grouping: ingredientsList) { ingredient in
            ingredient.ingredientTemplate?.category ?? "Uncategorized"
        }
    }
    
    private var sortedCategoryNames: [String] {
        let categoryOrder = categories.compactMap { $0.name }
        var sortedNames = groupedIngredients.keys.sorted()
        
        sortedNames.sort { first, second in
            let firstIndex = categoryOrder.firstIndex(of: first) ?? Int.max
            let secondIndex = categoryOrder.firstIndex(of: second) ?? Int.max
            return firstIndex < secondIndex
        }
        
        return sortedNames
    }
    
    private var hasIngredients: Bool {
        return !(groupedIngredients.isEmpty)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                recipeHeaderSection
                
                if recipe.hasRecipeTiming {
                    timingSection
                }
                
                usageAnalyticsSection
                
                ingredientsSection
                
                if let instructions = recipe.instructions, !instructions.isEmpty {
                    instructionsSection(instructions)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // M3 PHASE 4: Scaling button
                Button(action: {
                    showingScalingSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                }
                
                Button(action: {
                    showingMarkUsedConfirmation = true
                }) {
                    Image(systemName: "checkmark.circle")
                }
                
                // M4.2: Add to Meal Plan menu
                Menu {
                    Button {
                        showingMealPlanSheet = true
                    } label: {
                        Label("Add to Meal Plan", systemImage: "calendar.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .confirmationDialog("Mark Recipe as Used?", isPresented: $showingMarkUsedConfirmation) {
            Button("Yes, Mark as Used") {
                // M3.5: Use recordRecipeUsage() convenience method
                recipe.recordRecipeUsage()
                do {
                    try viewContext.save()
                    #if DEBUG
                    print("Recipe marked as used successfully")
                    #endif
                } catch {
                    #if DEBUG
                    print("Error marking recipe as used: \(error)")
                    #endif
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will increment the usage count and update the last used date.")
        }
        .sheet(isPresented: $showingAddToListSheet) {
            if hasIngredients {
                AddIngredientsToListView(recipe: recipe, context: viewContext)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeView(recipe: recipe, context: viewContext)
        }
        .sheet(isPresented: $showingScalingSheet) {
            RecipeScalingView(recipe: recipe, scalingService: scalingService)
        }
        // M4.2.4 PHASE 7: Updated to use SelectMealPlanSheet for multi-plan support
        .sheet(isPresented: $showingMealPlanSheet) {
            SelectMealPlanSheet(recipe: recipe) { plan, date in
                // M4.2.4: Add recipe to selected plan and date
                // Recipe tracking now happens in MealPlanService.addRecipeToMealPlan
                if let _ = MealPlanService.shared.addRecipeToMealPlan(
                    recipe: recipe,
                    date: date,
                    mealPlan: plan
                ) {
                    #if DEBUG
                    print("✅ M4.2.4: Added \(recipe.title ?? "recipe") to \(plan.name ?? "plan") on \(date)")
                    #endif
                } else {
                    #if DEBUG
                    print("❌ M4.2.4: Failed to add recipe (date may already be occupied)")
                    #endif
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var recipeHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // M3.5: Use recipeDisplayTitle
                Text(recipe.recipeDisplayTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Spacer()
                
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
            }
            
            // M3.5: Use recipeServingsDescription (no need for conditional)
            HStack {
                Image(systemName: "person.2")
                    .foregroundColor(.secondary)
                Text(recipe.recipeServingsDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timing")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                if recipe.prepTime > 0 {
                    VStack {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Prep")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // M3.5: Use recipeFormattedPrepTime
                        Text(recipe.recipeFormattedPrepTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if recipe.cookTime > 0 {
                    VStack {
                        Image(systemName: "flame")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Cook")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // M3.5: Use recipeFormattedCookTime
                        Text(recipe.recipeFormattedCookTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if recipe.prepTime > 0 && recipe.cookTime > 0 {
                    VStack {
                        Image(systemName: "timer")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        // M3.5: Use recipeFormattedTotalTime
                        Text(recipe.recipeFormattedTotalTime)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var usageAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Usage")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "chart.bar")
                            .foregroundColor(.blue)
                        Text("Times Made")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(recipe.usageCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        Text("Last Used")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // M3.5: Use recipeLastUsedDescription
                    Text(recipe.recipeLastUsedDescription)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    showingAddToListSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cart.badge.plus")
                        Text("Add to List")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(!hasIngredients)
            }
            
            if groupedIngredients.isEmpty {
                Text("No ingredients found")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(sortedCategoryNames, id: \.self) { categoryName in
                    let categoryIngredients = groupedIngredients[categoryName] ?? []
                    
                    if !categoryIngredients.isEmpty {
                        categoryHeaderView(categoryName: categoryName, count: categoryIngredients.count)
                        
                        ForEach(categoryIngredients, id: \.objectID) { ingredient in
                            ingredientRowView(ingredient: ingredient)
                        }
                    }
                }
            }
        }
    }
    
    private func categoryHeaderView(categoryName: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ForagerTheme.categoryColor(for: categoryName))
                .frame(width: 12, height: 12)
                .overlay(
                    Text(categoryEmoji(for: categoryName))
                        .font(.system(size: 8))
                )
            
            Text(categoryName.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(6)
    }
    
    // M3: Updated to use displayText - M3.5: USES COMPUTED PROPERTIES
    // M8.1: Added low-confidence badge and edit context menu
    private func ingredientRowView(ingredient: Ingredient) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.secondary.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    // M3.5: Use ingredientDisplayName (handles nil)
                    Text(ingredient.ingredientDisplayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    // M8.3.1: Raised threshold from 0.5 to 0.7 for medium-confidence visibility
                    if ingredient.parseConfidence < 0.7 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                            .help("Tap to edit - parsing confidence low")
                    }
                }

                // M4.3.1: Removed redundant displayText tag
                // The ingredient name already includes quantity info
                // Only show notes if they exist

                if let notes = ingredient.notes?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.leading, 8)
    }
    
    
    
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Instructions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(instructions)
                .font(.body)
                .lineSpacing(4)
        }
    }

    private func categoryEmoji(for categoryName: String) -> String {
        switch categoryName {
        case "Produce": return "🥬"
        case "Deli & Meat": return "🥩"
        case "Dairy & Fridge": return "🥛"
        case "Bread & Frozen": return "🍞"
        case "Boxed & Canned": return "📦"
        case "Snacks, Drinks, & Other": return "🥤"
        default: return "📋"
        }
    }
}

// MARK: - Search Match Types

enum SearchMatchType: CaseIterable, Hashable {
    case title
    case ingredient
    case instructions
    
    var displayName: String {
        switch self {
        case .title: return "Name"
        case .ingredient: return "Ingredient"
        case .instructions: return "Instructions"
        }
    }
    
    var iconName: String {
        switch self {
        case .title: return "textformat"
        case .ingredient: return "leaf"
        case .instructions: return "list.bullet"
        }
    }
    
    var color: Color {
        switch self {
        case .title: return .blue
        case .ingredient: return .green
        case .instructions: return .orange
        }
    }
}

#Preview {
    NavigationView {
        RecipeListView(popToRoot: .constant(false))
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
