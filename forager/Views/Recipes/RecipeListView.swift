import SwiftUI
import CoreData

struct RecipeListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var householdService: HouseholdService
    @EnvironmentObject private var recipeServiceM75: RecipeService
    @EnvironmentObject private var importService: RecipeImportService

    @Binding var popToRoot: Bool

    @StateObject private var recipeService = OptimizedRecipeDataService(context: PersistenceController.shared.container.viewContext)

    @State private var searchText = ""
    @State private var showingAddRecipe = false
    @State private var showingImport = false
    @State private var showingTextImport = false
    @State private var showingPhotoImport = false
    @State private var showingBrowser = false
    @State private var searchHistory: [String] = []
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""

    // M4.2.4: Updated to use SelectMealPlanSheet for multi-plan support
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
                Menu {
                    Section("Import") {
                        Button { showingBrowser = true } label: {
                            Label("Browse for Recipe", systemImage: "globe")
                        }
                        Button { showingImport = true } label: {
                            Label("Paste URL", systemImage: "link")
                        }
                        Button { showingTextImport = true } label: {
                            Label("Paste Recipe Text", systemImage: "doc.text")
                        }
                        Button { showingPhotoImport = true } label: {
                            Label("Import from Photo", systemImage: "camera")
                        }
                    }
                    Section {
                        Button { showingAddRecipe = true } label: {
                            Label("Create Manually", systemImage: "pencil.line")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecipe) {
            CreateRecipeView(context: viewContext)
        }
        .sheet(isPresented: $showingImport) {
            RecipeImportSheet(importService: importService, mode: .url)
        }
        .sheet(isPresented: $showingTextImport) {
            RecipeImportSheet(importService: importService, mode: .text)
        }
        .sheet(isPresented: $showingPhotoImport) {
            RecipeImportSheet(importService: importService, mode: .photo)
        }
        .fullScreenCover(isPresented: $showingBrowser) {
            RecipeBrowserView()
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
        .alert("Error", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
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
            ContentUnavailableView {
                Label("No Recipes Yet", systemImage: "book.closed.fill")
            } description: {
                Text("Import a recipe from a website, photo, or text — or create one from scratch")
            } actions: {
                #if DEBUG
                Button("Generate Test Recipes", systemImage: "plus.circle.fill") {
                    createSampleRecipe()
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
                #endif
                Button("Browse for Recipe", systemImage: "globe") {
                    showingBrowser = true
                }
                .buttonStyle(.borderedProminent)
                .tint(ForagerTheme.accentPrimary)
                Button("Create Manually", systemImage: "pencil.line") {
                    showingAddRecipe = true
                }
                .buttonStyle(.bordered)
            }
        } else if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            // Filter-specific empty state (e.g. no favorites)
            ContentUnavailableView {
                Label(
                    activeFilter == .favorites ? "No Favorites" : "No Recent Recipes",
                    systemImage: activeFilter == .favorites ? "heart" : "clock"
                )
            } description: {
                Text(activeFilter == .favorites
                     ? "Heart a recipe to see it here"
                     : "Mark recipes as made to see them here")
            }
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
                        withAnimation(reduceMotion ? nil : .default) { activeFilter = filter }
                    } label: {
                        FilterPill(
                            title: filter.title,
                            isSelected: activeFilter == filter
                        )
                    }
                    .accessibilityLabel("\(filter.title) filter")
                    .accessibilityValue(activeFilter == filter ? "Selected" : "Not selected")
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
    
    // M4.3.1: Updated to create 15 test recipes with overlapping ingredients
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
            
            // M4.3.5: Recipe 7 - Tests abbreviation expansion
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
            
            // M4.3.5: Recipe 8 - Tests more abbreviations
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
            
            // M4.3.5: Recipe 9 - Tests preparation & freshness descriptors
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
            
            // M4.3.5: Recipe 10 - Tests type/variety & size descriptors
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
            
            // M4.3.5: Recipe 11 - Tests quality & additional descriptors
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
        print("✅ Created 15 test recipes with comprehensive variation coverage (M4.3.5 + M8.1 + M8.3)")
        #endif
    }
    
    // Helper function to create a recipe with ingredients
    private func createRecipe(title: String, instructions: String, servings: Int16, prepTime: Int16, cookTime: Int16, ingredients: [String]) {
        guard let newRecipe = recipeServiceM75.createRecipe(
            title: title, servings: servings, prepTime: prepTime, cookTime: cookTime,
            instructions: instructions
        ) else {
            #if DEBUG
            print("❌ Error creating recipe '\(title)'")
            #endif
            return
        }

        addIngredientsWithParsing(to: newRecipe, ingredients: ingredients, in: viewContext)
        recipeServiceM75.saveContext()

        #if DEBUG
        print("✅ Saved recipe with \(ingredients.count) ingredients: '\(title)'")
        #endif
    }
    
    private func addIngredientsWithParsing(to recipe: Recipe, ingredients: [String], in context: NSManagedObjectContext) {
        let templateService = IngredientTemplateService(context: context)
        let parsingService = IngredientParsingService(context: context, templateService: templateService)
        
        for (index, text) in ingredients.enumerated() {
            // M8.4: Single parse via parseUnified (was double-parse)
            let (parsed, structured) = parsingService.parseUnified(text: text)

            let ingredient = Ingredient(context: context)
            ingredient.id = UUID()
            ingredient.name = text
            ingredient.sortOrder = Int16(index)
            ingredient.recipe = recipe
            // M9.15: Ingredient is now HouseholdScoped — inherit from parent Recipe
            ingredient.household = recipe.household
            ingredient.householdKey = recipe.householdKey

            let ingredientName = parsed.displayName
            if !ingredientName.isEmpty && ingredientName.lowercased() != "unknown ingredient" {
                ingredient.ingredientTemplate = templateService.findOrCreateTemplate(name: ingredientName)
            }

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
            deleteErrorMessage = "Failed to delete recipe: \(error.localizedDescription)"
            showingDeleteError = true
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

            // Timing pills row — always present for uniform card height
            HStack(spacing: ForagerTheme.Spacing.sm) {
                if recipe.hasRecipeTiming {
                    if recipe.prepTime > 0 {
                        timingPill(icon: "clock", text: recipe.recipeFormattedPrepTime)
                    }
                    if recipe.cookTime > 0 {
                        timingPill(icon: "flame", text: recipe.recipeFormattedCookTime)
                    }
                    if recipe.totalTime > 0 && recipe.prepTime > 0 && recipe.cookTime > 0 {
                        timingPill(icon: "timer", text: recipe.recipeFormattedTotalTime)
                    }
                } else {
                    Text(" ")
                        .font(ForagerTheme.captionFont)
                        .padding(.vertical, ForagerTheme.Spacing.xs)
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
        .foragerGlassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(recipe.recipeDisplayTitle)\(recipe.isFavorite ? ", favorite" : "")")
        .accessibilityHint("Double tap to view recipe")
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

// MARK: - M15.4: RecipeDetailView — Hero Header, Inline Scale Pills, Flat Ingredients

struct RecipeDetailView: View {
    @ObservedObject var recipe: Recipe
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var recipeServiceM75: RecipeService
    @EnvironmentObject private var parsingService: IngredientParsingService
    @EnvironmentObject private var templateService: IngredientTemplateService
    @EnvironmentObject private var matchService: IngredientMatchService
    @EnvironmentObject private var householdService: HouseholdService

    @State private var showingAddToListSheet = false
    @State private var showingMarkUsedConfirmation = false
    @State private var showingMealPlanSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // M15.4: Inline scaling state (replaces modal RecipeScalingView)
    @State private var scaleFactor: Double = 1.0
    @State private var showCustomScalePicker = false
    @State private var customWhole = 1
    @State private var customFraction = 0.0

    // M10.8: Inline ingredient editing state
    @State private var ingredientMatches: [UUID: IngredientMatchResult] = [:]
    @State private var editingIngredientId: UUID?
    @State private var editedTexts: [UUID: String] = [:]
    @State private var categoryPickerIngredientId: UUID?
    @FocusState private var focusedIngredientId: UUID?

    // M10.6.7: LLM re-parse state
    @State private var isLLMBatchParsing = false
    @State private var llmToastMessage: String?

    // M10.6.10: Autocomplete service for ingredient editing
    @StateObject private var autocompleteService: IngredientAutocompleteService
    @State private var showingIngredientAutocomplete = false

    // M10.6.9: Inline add ingredient state
    @State private var isAddingIngredient = false
    @State private var newIngredientText = ""
    @FocusState private var newIngredientFocused: Bool

    // M10.8: Inline instruction editing state
    @State private var editingStepIndex: Int?
    @State private var editedSteps: [Int: String] = [:]
    @FocusState private var focusedStepIndex: Int?

    // M10.8: Inline metadata editing state
    @State private var editingTitle = false
    @State private var editedTitle = ""
    @State private var editingPrepTime = false
    @State private var editedPrepTime = ""
    @State private var editingCookTime = false
    @State private var editedCookTime = ""
    @State private var editingServings = false
    @State private var editedServings = ""

    // M10.8: Focus tracking for inline metadata editing
    private enum MetadataFocus: Hashable {
        case title, prepTime, cookTime, servings
    }
    @FocusState private var focusedMetadata: MetadataFocus?

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var allCategories: FetchedResults<Category>

    // M10.6.8: Uses shared IngredientMatchResult via IngredientMatchService

    /// Categories filtered by household, excluding "Uncategorized"
    private var realCategories: [Category] {
        let key = householdService.currentHouseholdKey
        let scoped = allCategories.filter { key != nil ? $0.householdKey == key : $0.householdKey == nil }
        return scoped.filter { $0.displayName.lowercased() != "uncategorized" }
    }

    private let scalingService: RecipeScalingService
    private let presetScales: [Double] = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
    private let fractionOptions: [(String, Double)] = [
        ("—", 0), ("¼", 0.25), ("⅓", 0.33), ("½", 0.5), ("⅔", 0.67), ("¾", 0.75)
    ]

    init(recipe: Recipe) {
        self.recipe = recipe
        let context = PersistenceController.shared.container.viewContext
        self.scalingService = RecipeScalingService(context: context)
        // M10.6.10: Create autocomplete service for ingredient editing
        let templateSvc = IngredientTemplateService(context: context)
        let parsingSvc = IngredientParsingService(context: context, templateService: templateSvc)
        _autocompleteService = StateObject(wrappedValue: IngredientAutocompleteService(context: context, parsingService: parsingSvc))
    }

    // MARK: - Computed Properties

    private var hasIngredients: Bool {
        guard let set = recipe.ingredients else { return false }
        return !set.allObjects.isEmpty
    }

    private var sortedIngredients: [Ingredient] {
        guard let set = recipe.ingredients else { return [] }
        return (Array(set) as! [Ingredient]).sorted { ($0.sortOrder) < ($1.sortOrder) }
    }

    private var scaledIngredients: [ScaledIngredient]? {
        guard scaleFactor != 1.0 else { return nil }
        return scalingService.scale(recipe: recipe, scaleFactor: scaleFactor).scaledIngredients
    }

    private var dynamicServings: Int {
        Int(Double(recipe.servings) * scaleFactor)
    }

    // M10.8: Instruction steps from recipe.instructions (cleaned, no numbering)
    private var currentInstructionSteps: [String] {
        guard let instructions = recipe.instructions, !instructions.isEmpty else { return [] }
        return instructions.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { cleanStepText($0) }
    }

    private var ctaLabel: String {
        if scaleFactor == 1.0 {
            return "Add to Grocery List"
        } else {
            return "Add to Grocery List · \(dynamicServings) servings"
        }
    }

    // MARK: - M10.8: Ingredient Matching

    // M10.6.8: Delegates to shared IngredientMatchService

    /// Pre-compute matches for all ingredients. Called on .task{} — never during body evaluation.
    private func computeIngredientMatches() {
        let texts = sortedIngredients.map { $0.name ?? "" }
        let results = matchService.matchBatch(texts: texts)
        var matches: [UUID: IngredientMatchResult] = [:]

        for (index, result) in results.enumerated() {
            guard index < sortedIngredients.count,
                  let id = sortedIngredients[index].id else { continue }

            if var result {
                // M10.6.16: If re-match lost the category, use ingredient's linked template category
                if result.categoryName == nil,
                   let templateCategory = sortedIngredients[index].ingredientTemplate?.categoryEntity?.name,
                   !templateCategory.isEmpty {
                    result = result.withCategory(templateCategory)
                }
                matches[id] = result
            }
        }

        ingredientMatches = matches
    }

    /// Re-parse and template-match a single ingredient after edit.
    private func reMatchIngredient(id: UUID) {
        let text = editedTexts[id]
            ?? sortedIngredients.first(where: { $0.id == id })?.name
            ?? ""

        if let result = matchService.matchIngredient(text: text) {
            ingredientMatches[id] = result
        }
    }

    // MARK: - M10.6.7: LLM Re-Parse for Low Confidence / Needs Review

    /// Whether any ingredients qualify for AI re-parsing
    private var hasLLMCandidates: Bool {
        sortedIngredients.contains { ingredient in
            ingredient.parseConfidence < 0.7
                || (ingredient.ingredientTemplate?.needsReview == true)
        }
    }

    /// Re-parse ingredients with low confidence or needsReview templates via LLM.
    /// Updates ingredient text, re-links template, and refreshes match info.
    private func batchLLMReparse() async {
        let candidates = sortedIngredients.filter { ingredient in
            ingredient.parseConfidence < 0.7
                || (ingredient.ingredientTemplate?.needsReview == true)
        }
        guard !candidates.isEmpty else { return }

        isLLMBatchParsing = true

        let texts = candidates.map { $0.name ?? "" }
        let categoryNames = realCategories.map { $0.displayName }
        if let results = await parsingService.parseBatchWithLLM(texts: texts, source: .recipeIngredient, categories: categoryNames) {
            for (index, (parsed, structured, aiCategory)) in results.enumerated() {
                guard index < candidates.count else { break }
                let ingredient = candidates[index]

                // M9.12: Look up Category entity from AI-suggested category name
                let categoryEntity: Category? = {
                    guard let name = aiCategory else { return nil }
                    return realCategories.first { $0.displayName == name }
                }()
                let template = templateService.findOrCreateTemplate(
                    name: parsed.displayName,
                    category: categoryEntity
                )

                recipeServiceM75.updateIngredient(
                    ingredient,
                    name: ingredient.name ?? "",
                    numericValue: structured.numericValue,
                    standardUnit: structured.standardUnit,
                    displayText: structured.displayText,
                    isParseable: structured.isParseable,
                    parseConfidence: structured.parseConfidence,
                    template: template
                )

                if let id = ingredient.id {
                    reMatchIngredient(id: id)
                }
            }
            llmToastMessage = "AI re-parsed \(results.count) ingredients"
        } else {
            llmToastMessage = parsingService.lastLLMError ?? "AI parsing failed"
        }

        isLLMBatchParsing = false
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForagerTheme.Spacing.lg) {
                recipeHeaderSection

                ingredientsSection

                instructionsSection

                usageFooter
            }
            .padding()
        }
        .background(ForagerTheme.backgroundCanvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // M10.8: Edit Recipe removed — all editing is inline
                Menu {
                    Button { showingMealPlanSheet = true } label: {
                        Label("Add to Meal Plan", systemImage: "calendar.badge.plus")
                    }
                    Button { showingMarkUsedConfirmation = true } label: {
                        Label("Mark as Made", systemImage: "checkmark.circle")
                    }
                    Divider()
                    Button(role: .destructive) { showingDeleteConfirmation = true } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog("Mark Recipe as Used?", isPresented: $showingMarkUsedConfirmation) {
            Button("Yes, Mark as Used") {
                recipeServiceM75.markAsUsed(recipe)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will increment the usage count and update the last used date.")
        }
        .confirmationDialog("Delete Recipe?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                let recipeID = recipe.objectID
                PersistenceController.shared.performWrite({ context in
                    let toDelete = context.object(with: recipeID)
                    context.delete(toDelete)
                }, onSuccess: {
                    dismiss()
                }, onError: { error in
                    errorMessage = "Failed to delete recipe: \(error.localizedDescription)"
                    showingError = true
                })
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingAddToListSheet) {
            if hasIngredients {
                AddIngredientsToListView(recipe: recipe, context: viewContext)
            }
        }
        .sheet(isPresented: $showingMealPlanSheet) {
            SelectMealPlanSheet(recipe: recipe) { plan, date in
                if let _ = MealPlanService.shared.addRecipeToMealPlan(
                    recipe: recipe,
                    date: date,
                    mealPlan: plan
                ) {
                    #if DEBUG
                    print("Added \(recipe.title ?? "recipe") to \(plan.name ?? "plan") on \(date)")
                    #endif
                }
            }
        }
        .sheet(isPresented: $showCustomScalePicker) {
            customScalePickerSheet
        }
        // M10.8: Category picker sheet
        .sheet(isPresented: Binding(
            get: { categoryPickerIngredientId != nil },
            set: { if !$0 { categoryPickerIngredientId = nil } }
        )) {
            if let ingredientId = categoryPickerIngredientId {
                categoryPickerSheet(ingredientId: ingredientId)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .llmParsingToast(message: $llmToastMessage)
        // M10.8: Pre-compute ingredient matches on appear
        .task { computeIngredientMatches() }
        // M10.6.10: Configure autocomplete with current household
        .onAppear {
            autocompleteService.configure(householdKey: householdService.currentHouseholdKey)
        }
        // M10.8: Sync focus and commit on blur
        .onChange(of: editingIngredientId) { oldValue, newValue in
            // Commit when leaving an ingredient row
            if let oldId = oldValue, oldId != newValue,
               let ingredient = sortedIngredients.first(where: { $0.id == oldId }) {
                commitIngredientEdit(ingredient: ingredient)
            }
            // Sync focus to editing state
            focusedIngredientId = newValue
            // M10.6.10: Clear autocomplete when changing editing target
            showingIngredientAutocomplete = false
            autocompleteService.clearSuggestions()
        }
        .onChange(of: focusedIngredientId) { _, newValue in
            // When keyboard focus is lost (tapped away), exit edit mode
            if newValue == nil, let editingId = editingIngredientId,
               let ingredient = sortedIngredients.first(where: { $0.id == editingId }) {
                commitIngredientEdit(ingredient: ingredient)
                editingIngredientId = nil
            }
        }
        // M10.8: Sync focus and commit for instruction step editing
        .onChange(of: editingStepIndex) { oldValue, newValue in
            // Commit old step when switching
            if let oldIdx = oldValue, oldIdx != newValue {
                commitSingleStepEdit(index: oldIdx)
            }
            focusedStepIndex = newValue
        }
        .onChange(of: focusedStepIndex) { _, newValue in
            if newValue == nil, let idx = editingStepIndex {
                commitSingleStepEdit(index: idx)
                editingStepIndex = nil
            }
        }
        // M10.8: Commit metadata edits on focus loss
        .onChange(of: focusedMetadata) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                commitAllMetadataEdits()
            }
        }
    }

    // MARK: - Hero Header (M10.8: Inline-Editable)

    private var recipeHeaderSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            // Title + Favorite
            HStack {
                if editingTitle {
                    TextField("Recipe title", text: $editedTitle)
                        .font(ForagerTheme.detailTitle)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .focused($focusedMetadata, equals: .title)
                        .submitLabel(.done)
                        .onSubmit { commitAllMetadataEdits() }
                        .onAppear { focusedMetadata = .title }
                } else {
                    Text(recipe.recipeDisplayTitle)
                        .font(ForagerTheme.detailTitle)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .lineLimit(3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editedTitle = recipe.title ?? ""
                            editingTitle = true
                        }
                }

                Spacer()

                // Favorite toggle — always visible
                Button {
                    recipeServiceM75.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(recipe.isFavorite ? ForagerTheme.statusDangerFG : ForagerTheme.textTertiary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // Compact timing row — tappable for inline editing
            timingRow

            // Servings — tappable for inline editing
            servingsRow
        }
    }

    private var timingRow: some View {
        HStack(spacing: ForagerTheme.Spacing.md) {
            // Prep time
            if editingPrepTime {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    TextField("0", text: $editedPrepTime)
                        .keyboardType(.numberPad)
                        .frame(width: 36)
                        .focused($focusedMetadata, equals: .prepTime)
                        .onAppear { focusedMetadata = .prepTime }
                    Text("min")
                }
            } else {
                Button {
                    editedPrepTime = recipe.prepTime > 0 ? "\(recipe.prepTime)" : ""
                    editingPrepTime = true
                } label: {
                    if recipe.prepTime > 0 {
                        Label(recipe.recipeFormattedPrepTime, systemImage: "clock")
                    } else {
                        Label("Prep", systemImage: "clock")
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Cook time
            if editingCookTime {
                HStack(spacing: 4) {
                    Image(systemName: "flame")
                    TextField("0", text: $editedCookTime)
                        .keyboardType(.numberPad)
                        .frame(width: 36)
                        .focused($focusedMetadata, equals: .cookTime)
                        .onAppear { focusedMetadata = .cookTime }
                    Text("min")
                }
            } else {
                Button {
                    editedCookTime = recipe.cookTime > 0 ? "\(recipe.cookTime)" : ""
                    editingCookTime = true
                } label: {
                    if recipe.cookTime > 0 {
                        Label(recipe.recipeFormattedCookTime, systemImage: "flame")
                    } else {
                        Label("Cook", systemImage: "flame")
                            .foregroundStyle(ForagerTheme.textTertiary)
                    }
                }
                .buttonStyle(.plain)
            }

            // Total time (read-only, only shown when both times exist)
            if !editingPrepTime && !editingCookTime
                && recipe.totalTime > 0 && recipe.prepTime > 0 && recipe.cookTime > 0 {
                Label(recipe.recipeFormattedTotalTime, systemImage: "timer")
            }
        }
        .font(ForagerTheme.secondaryFont)
        .foregroundStyle(ForagerTheme.textSecondary)
    }

    private var servingsRow: some View {
        Group {
            if editingServings {
                HStack(spacing: 4) {
                    TextField("1", text: $editedServings)
                        .keyboardType(.numberPad)
                        .frame(width: 36)
                        .focused($focusedMetadata, equals: .servings)
                        .onAppear { focusedMetadata = .servings }
                    Text("servings")
                }
                .font(ForagerTheme.secondaryFont)
                .foregroundStyle(ForagerTheme.textTertiary)
            } else {
                Text(recipe.recipeServingsDescription)
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editedServings = "\(recipe.servings)"
                        editingServings = true
                    }
            }
        }
    }

    // MARK: - Ingredients Section with Scale Pills

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            // Section header with dynamic servings + AI parse
            HStack {
                Text("INGREDIENTS")
                    .font(ForagerTheme.footnoteFont)
                    .tracking(0.5)
                    .foregroundStyle(ForagerTheme.textSecondary)

                Spacer()

                if scaleFactor != 1.0 {
                    Text("\(dynamicServings) servings")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }

                // M10.6.7: AI re-parse for low confidence / needsReview ingredients
                if scaleFactor == 1.0 && parsingService.isLLMAvailable && hasLLMCandidates {
                    if isLLMBatchParsing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            Task { await batchLLMReparse() }
                        } label: {
                            AIParseLabel()
                                .font(ForagerTheme.secondaryFont)
                        }
                    }
                }
            }

            // Inline scale pills
            scalePillRow

            // M10.8: Ingredient match summary (only at 1x scale)
            if scaleFactor == 1.0 && !ingredientMatches.isEmpty {
                ingredientMatchSummary
            }

            // Flat ingredient list
            if !hasIngredients {
                Text("No ingredients found")
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, ForagerTheme.Spacing.xl)
            } else {
                ForEach(sortedIngredients, id: \.objectID) { ingredient in
                    ingredientRow(ingredient)
                    // M10.6.10: Autocomplete dropdown after editing row
                    if let iid = ingredient.id, editingIngredientId == iid {
                        autocompleteDropdown(for: ingredient)
                    }
                }
            }

            // M10.6.9: Inline add ingredient (only at 1x scale)
            if scaleFactor == 1.0 {
                if isAddingIngredient {
                    addIngredientField
                    // M10.6.10: Autocomplete dropdown for add-ingredient field
                    if editingIngredientId == nil {
                        autocompleteDropdown(for: nil)
                    }
                } else {
                    Button {
                        isAddingIngredient = true
                        showingIngredientAutocomplete = false
                        autocompleteService.clearSuggestions()
                    } label: {
                        Label("Add Ingredient", systemImage: "plus")
                            .font(ForagerTheme.bodyFont)
                            .foregroundStyle(ForagerTheme.accentPrimary)
                    }
                    .padding(.vertical, ForagerTheme.Spacing.xs)
                }
            }

            // Full-width CTA button
            if hasIngredients {
                addToListButton
            }
        }
    }

    // MARK: - Scale Pills

    private var scalePillRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ForagerTheme.Spacing.sm) {
                ForEach(presetScales, id: \.self) { scale in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { scaleFactor = scale }
                    } label: {
                        Text(scaleLabel(scale))
                            .font(ForagerTheme.footnoteFont)
                            .foregroundStyle(scaleFactor == scale ? .white : ForagerTheme.textSecondary)
                            .padding(.horizontal, ForagerTheme.Spacing.md)
                            .padding(.vertical, ForagerTheme.Spacing.sm)
                            .background(scaleFactor == scale ? ForagerTheme.accentPrimary : ForagerTheme.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
                    }
                    .accessibilityLabel("Scale recipe to \(scaleLabel(scale))")
                    .accessibilityValue(scaleFactor == scale ? "Selected" : "Not selected")
                }

                // Custom scale button
                Button { showCustomScalePicker = true } label: {
                    Image(systemName: "gearshape")
                        .font(ForagerTheme.footnoteFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                        .padding(ForagerTheme.Spacing.sm)
                        .background(ForagerTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
                }
            }
        }
    }

    private func scaleLabel(_ scale: Double) -> String {
        if scale == 0.5 { return "½×" }
        if scale == floor(scale) { return "\(Int(scale))×" }
        let whole = Int(scale)
        let fraction = scale - Double(whole)
        if abs(fraction - 0.5) < 0.01 { return "\(whole)½×" }
        return String(format: "%.1f×", scale)
    }

    private var customScalePickerSheet: some View {
        NavigationStack {
            VStack(spacing: ForagerTheme.Spacing.lg) {
                Text("\(scaleLabel(Double(customWhole) + customFraction))")
                    .font(ForagerTheme.detailTitle)
                    .foregroundStyle(ForagerTheme.textPrimary)

                HStack {
                    Picker("Whole", selection: $customWhole) {
                        ForEach(0...5, id: \.self) { n in Text("\(n)").tag(n) }
                    }
                    .pickerStyle(.wheel)

                    Picker("Fraction", selection: $customFraction) {
                        ForEach(fractionOptions, id: \.1) { label, value in
                            Text(label).tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .padding()
            .navigationTitle("Custom Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        let newScale = Double(customWhole) + customFraction
                        if newScale > 0 {
                            scaleFactor = newScale
                        }
                        showCustomScalePicker = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCustomScalePicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - M10.8: Ingredient Row — Bordered Card with Display/Edit Toggle

    /// Per-ingredient bordered card row with display/edit toggle.
    /// At 1x scale: tap to edit, category picker, context menu delete.
    /// At non-1x scale: read-only with scaled quantities.
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        let id = ingredient.id ?? UUID()
        let matchInfo = ingredientMatches[id]
        let isEditing = editingIngredientId == id && scaleFactor == 1.0
        let displayName = ingredientDisplayName(for: ingredient)
        let currentText = editedTexts[id] ?? (ingredient.name ?? "")

        return VStack(alignment: .leading, spacing: ForagerTheme.Spacing.xs) {
            // Top line: status icon + ingredient text
            HStack(spacing: ForagerTheme.Spacing.sm) {
                // M10.6.10: Three-state status indicator
                if let status = matchInfo?.status {
                    switch status {
                    case .ready:
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ForagerTheme.statusSuccessFG)
                            .font(.system(size: 14))
                    case .needsCategory:
                        Image(systemName: "circle.dashed")
                            .foregroundStyle(ForagerTheme.statusWarningFG)
                            .font(.system(size: 14))
                    case .needsTemplate:
                        HStack(spacing: ForagerTheme.Spacing.xs) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(ForagerTheme.textTertiary)
                                .font(.system(size: 14))
                            Text("NEW")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(ForagerTheme.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(ForagerTheme.backgroundTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                } else {
                    Circle()
                        .fill(ingredient.parseConfidence < 0.7 ? ForagerTheme.statusWarningFG : ForagerTheme.accentSecondary)
                        .frame(width: 8, height: 8)
                }

                if isEditing {
                    // Edit mode: full-line TextField with M10.6.10 autocomplete
                    TextField("Ingredient", text: ingredientTextBinding(id: id, original: ingredient.name ?? ""))
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedIngredientId, equals: id)
                        .onSubmit {
                            commitIngredientEdit(ingredient: ingredient)
                            editingIngredientId = nil
                        }
                        .onChange(of: editedTexts[id] ?? "") { _, newValue in
                            let text = newValue.isEmpty ? (ingredient.name ?? "") : newValue
                            if text.count >= 2 {
                                autocompleteService.debouncedSearch(fullText: text)
                                showingIngredientAutocomplete = true
                            } else {
                                showingIngredientAutocomplete = false
                                autocompleteService.clearSuggestions()
                            }
                        }
                } else if scaleFactor != 1.0 {
                    // Scaled display mode: show scaled quantities, no editing
                    Text(displayName)
                        .font(ForagerTheme.bodyFont)
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                } else {
                    // Display mode: formatted text with parsed name highlighted
                    formattedIngredientText(text: currentText, matchInfo: matchInfo)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editingIngredientId = id
                        }
                }
            }

            // Bottom line: category picker (only at 1x scale)
            if scaleFactor == 1.0 {
                categoryLabel(ingredientId: id)
                    .padding(.leading, 22) // Align under text, past the status icon
            }
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isEditing ? ForagerTheme.accentPrimary : ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .contextMenu {
            if scaleFactor == 1.0 {
                Button(role: .destructive) {
                    recipeServiceM75.removeIngredient(ingredient)
                    ingredientMatches.removeValue(forKey: id)
                    editedTexts.removeValue(forKey: id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayName)
    }

    private func ingredientDisplayName(for ingredient: Ingredient) -> String {
        // At 1x scale, ingredient.name already contains full text like "2 cups flour"
        guard scaleFactor != 1.0,
              let scaled = scaledIngredients?.first(where: { $0.name == (ingredient.name ?? "") }) else {
            return ingredient.name ?? "Unknown"
        }
        // At other scales, construct from scaled quantity + template name
        let templateName = ingredient.ingredientTemplate?.name ?? ingredient.name ?? "Unknown"
        if scaled.displayText.isEmpty {
            return templateName
        }
        return "\(scaled.displayText) \(templateName)"
    }

    // MARK: - M10.8: Ingredient Text Binding + Commit

    /// Binding for buffered ingredient text edits
    private func ingredientTextBinding(id: UUID, original: String) -> Binding<String> {
        Binding(
            get: { editedTexts[id] ?? original },
            set: { editedTexts[id] = $0 }
        )
    }

    /// Save ingredient edit to Core Data on blur/submit.
    /// Re-parses with telemetry, updates template, saves via RecipeService.
    private func commitIngredientEdit(ingredient: Ingredient) {
        guard let id = ingredient.id else { return }
        let text = editedTexts[id] ?? (ingredient.name ?? "")
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return }

        // Re-parse with full telemetry
        let (parsed, structured) = parsingService.parseUnified(text: trimmed, source: .recipeIngredient)

        // M9.12: Look up Category entity from match result category name
        let matchCategoryEntity: Category? = {
            guard let name = ingredientMatches[id]?.categoryName else { return nil }
            return realCategories.first { $0.displayName == name }
        }()
        let template = templateService.findOrCreateTemplate(
            name: parsed.displayName,
            category: matchCategoryEntity
        )

        // Update ingredient via service (single save)
        recipeServiceM75.updateIngredient(
            ingredient,
            name: trimmed,
            numericValue: structured.numericValue,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: structured.parseConfidence,
            template: template
        )

        // Clear the edit buffer for this ingredient
        editedTexts.removeValue(forKey: id)

        // Update match info
        reMatchIngredient(id: id)
    }

    // MARK: - M10.6.9: Add Ingredient Inline

    private var addIngredientField: some View {
        HStack(spacing: ForagerTheme.Spacing.sm) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(ForagerTheme.accentPrimary)
                .font(.system(size: 14))

            TextField("e.g. 2 cups flour", text: $newIngredientText)
                .font(ForagerTheme.bodyFont)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($newIngredientFocused)
                .onSubmit { commitNewIngredient() }
                .onAppear { newIngredientFocused = true }
                // M10.6.10: Trigger autocomplete while typing
                .onChange(of: newIngredientText) { _, newValue in
                    if newValue.count >= 2 {
                        autocompleteService.debouncedSearch(fullText: newValue)
                        showingIngredientAutocomplete = true
                    } else {
                        showingIngredientAutocomplete = false
                        autocompleteService.clearSuggestions()
                    }
                }
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(ForagerTheme.accentPrimary, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
    }

    private func commitNewIngredient() {
        let trimmed = newIngredientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            isAddingIngredient = false
            newIngredientText = ""
            return
        }

        let (parsed, structured) = parsingService.parseUnified(text: trimmed, source: .recipeIngredient)
        let template = templateService.findOrCreateTemplate(name: parsed.displayName)

        if let ingredient = recipeServiceM75.addIngredient(
            to: recipe,
            name: trimmed,
            numericValue: structured.numericValue ?? 0,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: structured.parseConfidence,
            template: template
        ) {
            // Update match for the new ingredient
            if let id = ingredient.id {
                if let result = matchService.matchIngredient(text: trimmed) {
                    ingredientMatches[id] = result
                }
            }
        }

        newIngredientText = ""
        isAddingIngredient = false
        showingIngredientAutocomplete = false
        autocompleteService.clearSuggestions()
    }

    // MARK: - M10.6.10: Autocomplete Dropdown + Selection

    /// Autocomplete dropdown showing template suggestions.
    /// Pass an ingredient for edit mode, or nil for add-ingredient mode.
    @ViewBuilder
    private func autocompleteDropdown(for ingredient: Ingredient?) -> some View {
        if showingIngredientAutocomplete && !autocompleteService.suggestions.isEmpty {
            VStack(spacing: 0) {
                ForEach(autocompleteService.suggestions, id: \.objectID) { template in
                    Button {
                        if let ingredient {
                            selectAutocompleteForEdit(ingredient: ingredient, template: template)
                        } else {
                            selectAutocompleteForAdd(template: template)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(template.name ?? "")
                                    .font(ForagerTheme.bodyFont)
                                    .foregroundStyle(ForagerTheme.textPrimary)
                                if let category = template.categoryEntity?.name, !category.isEmpty {
                                    Text(category)
                                        .font(ForagerTheme.captionFont)
                                        .foregroundStyle(ForagerTheme.textSecondary)
                                }
                            }
                            Spacer()
                            if template.usageCount > 0 {
                                Text("\(template.usageCount)")
                                    .font(.caption2)
                                    .foregroundStyle(ForagerTheme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(ForagerTheme.backgroundTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.xs))
                            }
                        }
                        .padding(.horizontal, ForagerTheme.Spacing.md)
                        .padding(.vertical, ForagerTheme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if template != autocompleteService.suggestions.last {
                        Divider()
                    }
                }
            }
            .background(ForagerTheme.surfacePrimary)
            .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
        }
    }

    /// Select an autocomplete template while editing an existing ingredient.
    /// Rebuilds the ingredient text with the template name, preserving quantity/unit.
    private func selectAutocompleteForEdit(ingredient: Ingredient, template: IngredientTemplate) {
        guard let id = ingredient.id else { return }
        let currentText = editedTexts[id] ?? (ingredient.name ?? "")
        let parsed = parsingService.parseIngredient(text: currentText)

        // Rebuild text as "quantity unit templateName"
        var rebuiltText = ""
        if let quantity = parsed.quantity { rebuiltText += quantity + " " }
        if let unit = parsed.unit { rebuiltText += unit + " " }
        rebuiltText += template.name ?? ""

        let (_, structured) = parsingService.parseUnified(text: rebuiltText, source: .recipeIngredient)

        // Update ingredient via service
        recipeServiceM75.updateIngredient(
            ingredient,
            name: rebuiltText,
            numericValue: structured.numericValue,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: structured.parseConfidence,
            template: template
        )

        // Clear edit buffer and autocomplete state
        editedTexts.removeValue(forKey: id)
        editingIngredientId = nil
        showingIngredientAutocomplete = false
        autocompleteService.clearSuggestions()

        // Refresh match info
        reMatchIngredient(id: id)
    }

    /// Select an autocomplete template while adding a new ingredient.
    /// Creates the ingredient with the template pre-linked.
    private func selectAutocompleteForAdd(template: IngredientTemplate) {
        let parsed = parsingService.parseIngredient(text: newIngredientText)

        var rebuiltText = ""
        if let quantity = parsed.quantity { rebuiltText += quantity + " " }
        if let unit = parsed.unit { rebuiltText += unit + " " }
        rebuiltText += template.name ?? ""

        let (_, structured) = parsingService.parseUnified(text: rebuiltText, source: .recipeIngredient)

        if let ingredient = recipeServiceM75.addIngredient(
            to: recipe,
            name: rebuiltText,
            numericValue: structured.numericValue ?? 0,
            standardUnit: structured.standardUnit,
            displayText: structured.displayText,
            isParseable: structured.isParseable,
            parseConfidence: structured.parseConfidence,
            template: template
        ) {
            if let id = ingredient.id {
                if let result = matchService.matchIngredient(text: rebuiltText) {
                    ingredientMatches[id] = result
                }
            }
        }

        newIngredientText = ""
        isAddingIngredient = false
        showingIngredientAutocomplete = false
        autocompleteService.clearSuggestions()
    }

    // MARK: - M10.8: Formatted Ingredient Text

    /// Format ingredient text with parsed name in bold accent. Uses shared IngredientMatchResult.
    @ViewBuilder
    private func formattedIngredientText(text: String, matchInfo: IngredientMatchResult?) -> some View {
        if let info = matchInfo,
           let range = text.range(of: info.parsedName, options: .caseInsensitive) {
            let prefix = String(text[text.startIndex..<range.lowerBound])
            let name = String(text[range])
            let suffix = String(text[range.upperBound...])
            HStack(spacing: 0) {
                Text(prefix)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
                Text(name)
                    .font(ForagerTheme.bodyFont)
                    .bold()
                    .foregroundStyle(ForagerTheme.accentPrimary)
                Text(suffix)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textSecondary)
            }
        } else {
            Text(text)
                .font(ForagerTheme.bodyFont)
                .foregroundStyle(ForagerTheme.textPrimary)
        }
    }

    // MARK: - M10.6.8: Ingredient Match Summary (shared component)

    // M10.6.10: Three-state summary using IngredientStatus
    private var ingredientMatchSummary: some View {
        let values = Array(ingredientMatches.values)
        let ready = values.filter { $0.status == .ready }.count
        let needsCategory = values.filter { $0.status == .needsCategory }.count
        let needsTemplate = values.filter { $0.status == .needsTemplate }.count
        return IngredientMatchSummaryView(ready: ready, needsCategory: needsCategory, needsTemplate: needsTemplate)
    }

    // MARK: - M10.8: Category Label + Picker

    /// Category label button that opens the category picker sheet.
    /// Shows colored dot + category name when assigned, "Choose Category" when empty.
    private func categoryLabel(ingredientId: UUID) -> some View {
        Button {
            categoryPickerIngredientId = ingredientId
        } label: {
            HStack(spacing: ForagerTheme.Spacing.xs) {
                if let categoryName = ingredientMatches[ingredientId]?.categoryName {
                    Circle()
                        .fill(ForagerTheme.categoryColor(for: categoryName))
                        .frame(width: 8, height: 8)
                    Text(categoryName)
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                } else {
                    Text("Choose Category")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundStyle(ForagerTheme.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    /// Sheet with colored category options for a given ingredient
    private func categoryPickerSheet(ingredientId: UUID) -> some View {
        let ingredient = sortedIngredients.first(where: { $0.id == ingredientId })
        let ingredientName = ingredient?.name ?? "Unknown"

        return NavigationStack {
            List {
                Section {
                    Text(ingredientName)
                        .font(ForagerTheme.bodyFont.weight(.medium))
                        .foregroundStyle(ForagerTheme.textPrimary)
                        .listRowBackground(Color.clear)
                }

                Section {
                    ForEach(realCategories, id: \.objectID) { category in
                        Button {
                            assignCategory(category.displayName, to: ingredientId)
                            categoryPickerIngredientId = nil
                        } label: {
                            HStack(spacing: ForagerTheme.Spacing.md) {
                                Circle()
                                    .fill(ForagerTheme.categoryColor(for: category.displayName))
                                    .frame(width: 12, height: 12)
                                Text(category.displayName)
                                    .font(ForagerTheme.bodyFont)
                                    .foregroundStyle(ForagerTheme.textPrimary)
                                Spacer()
                                if ingredientMatches[ingredientId]?.categoryName == category.displayName {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(ForagerTheme.accentPrimary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { categoryPickerIngredientId = nil }
                }
            }
        }
    }

    /// Assign a category to an ingredient's template and update match info
    private func assignCategory(_ categoryName: String, to ingredientId: UUID) {
        // Update match info
        if let existing = ingredientMatches[ingredientId] {
            ingredientMatches[ingredientId] = existing.withCategory(categoryName)
        }

        // M9.12: Look up Category entity by name, pass entity instead of String
        let categoryEntity = realCategories.first(where: { $0.displayName == categoryName })
        if let ingredient = sortedIngredients.first(where: { $0.id == ingredientId }),
           let template = ingredient.ingredientTemplate {
            templateService.updateCategory(template, category: categoryEntity)
        }
    }

    // MARK: - CTA Button

    private var addToListButton: some View {
        Button {
            showingAddToListSheet = true
        } label: {
            Text(ctaLabel)
                .font(ForagerTheme.bodyFont.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ForagerTheme.Spacing.md)
                .background(ForagerTheme.accentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm, style: .continuous))
        }
        .padding(.top, ForagerTheme.Spacing.md)
    }

    // MARK: - Instructions (M10.8: Inline-Editable)

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: ForagerTheme.Spacing.sm) {
            Text("INSTRUCTIONS")
                .font(ForagerTheme.footnoteFont)
                .tracking(0.5)
                .foregroundStyle(ForagerTheme.textSecondary)

            let steps = currentInstructionSteps
            if steps.isEmpty {
                Text("No instructions")
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textTertiary)
                    .italic()
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    instructionStepRow(index: index, step: step)
                }
            }

            // Add step button
            Button { addStep() } label: {
                Label("Add Step", systemImage: "plus.circle")
                    .font(ForagerTheme.secondaryFont)
                    .foregroundStyle(ForagerTheme.accentPrimary)
            }
            .padding(.top, ForagerTheme.Spacing.xs)
        }
    }

    /// Bordered card per instruction step with display/edit toggle
    private func instructionStepRow(index: Int, step: String) -> some View {
        let isEditing = editingStepIndex == index
        let currentText = editedSteps[index] ?? step

        return HStack(alignment: .firstTextBaseline, spacing: ForagerTheme.Spacing.md) {
            Text("\(index + 1)")
                .font(ForagerTheme.bodyFont.bold().monospacedDigit())
                .foregroundStyle(ForagerTheme.accentPrimary)
                .frame(width: 24, alignment: .trailing)

            if isEditing {
                TextField("Step \(index + 1)", text: stepTextBinding(index: index, original: step), axis: .vertical)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .lineSpacing(6)
                    .focused($focusedStepIndex, equals: index)
                    .submitLabel(.done)
                    .onSubmit {
                        commitSingleStepEdit(index: index)
                        editingStepIndex = nil
                    }
            } else {
                Text(currentText)
                    .font(ForagerTheme.bodyFont)
                    .foregroundStyle(ForagerTheme.textPrimary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingStepIndex = index
                    }
            }
        }
        .padding(.vertical, ForagerTheme.Spacing.sm)
        .padding(.horizontal, ForagerTheme.Spacing.md)
        .background(ForagerTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm)
                .stroke(isEditing ? ForagerTheme.accentPrimary : ForagerTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ForagerTheme.Radius.sm))
        .contextMenu {
            Button(role: .destructive) {
                deleteStep(at: index)
            } label: {
                Label("Delete Step", systemImage: "trash")
            }
        }
    }

    // MARK: - M10.8: Instruction Step Helpers

    /// Binding for buffered step text edits
    private func stepTextBinding(index: Int, original: String) -> Binding<String> {
        Binding(
            get: { editedSteps[index] ?? original },
            set: { editedSteps[index] = $0 }
        )
    }

    /// Save a single step edit to Core Data
    private func commitSingleStepEdit(index: Int) {
        guard let editedText = editedSteps[index] else { return }
        let trimmed = editedText.trimmingCharacters(in: .whitespacesAndNewlines)

        var steps = currentInstructionSteps
        guard index < steps.count else { return }

        if trimmed.isEmpty {
            steps.remove(at: index)
        } else {
            steps[index] = trimmed
        }

        let rebuilt = steps.joined(separator: "\n")
        recipeServiceM75.updateRecipe(recipe, instructions: rebuilt)
        editedSteps.removeValue(forKey: index)
    }

    /// Add a new empty step at the end and enter edit mode
    private func addStep() {
        let placeholder = "New step"
        var steps = currentInstructionSteps
        steps.append(placeholder)
        let rebuilt = steps.joined(separator: "\n")
        recipeServiceM75.updateRecipe(recipe, instructions: rebuilt)

        // Enter edit mode for the new step with empty text
        let newIndex = steps.count - 1
        editedSteps[newIndex] = ""
        editingStepIndex = newIndex
    }

    /// Delete a step and rebuild instructions
    private func deleteStep(at index: Int) {
        var steps = currentInstructionSteps
        guard index < steps.count else { return }
        steps.remove(at: index)
        let rebuilt = steps.joined(separator: "\n")
        recipeServiceM75.updateRecipe(recipe, instructions: rebuilt)
        editedSteps.removeAll()
        editingStepIndex = nil
    }

    // MARK: - M10.8: Metadata Commit Helpers

    /// Commit all pending metadata edits (title, prep time, cook time, servings)
    private func commitAllMetadataEdits() {
        if editingTitle {
            let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed != recipe.title {
                recipeServiceM75.updateRecipe(recipe, title: trimmed)
            }
            editingTitle = false
        }
        if editingPrepTime {
            if let value = Int16(editedPrepTime), value >= 0 {
                recipeServiceM75.updateRecipe(recipe, prepTime: value)
            }
            editingPrepTime = false
        }
        if editingCookTime {
            if let value = Int16(editedCookTime), value >= 0 {
                recipeServiceM75.updateRecipe(recipe, cookTime: value)
            }
            editingCookTime = false
        }
        if editingServings {
            if let value = Int16(editedServings), value > 0 {
                recipeServiceM75.updateRecipe(recipe, servings: value)
            }
            editingServings = false
        }
    }

    /// Strip existing step numbers like "1.", "1)", "Step 1:" from instruction text
    private func cleanStepText(_ step: String) -> String {
        let trimmed = step.trimmingCharacters(in: .whitespaces)
        let pattern = #"^(?:Step\s+)?\d+[.):]?\s*"#
        return trimmed.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    // MARK: - Usage Footer (Collapsible)

    private var usageFooter: some View {
        DisclosureGroup {
            HStack(spacing: ForagerTheme.Spacing.xl) {
                VStack(alignment: .leading) {
                    Text("Times Made")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text("\(recipe.usageCount)")
                        .font(ForagerTheme.secondaryFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
                VStack(alignment: .leading) {
                    Text("Last Used")
                        .font(ForagerTheme.captionFont)
                        .foregroundStyle(ForagerTheme.textTertiary)
                    Text(recipe.recipeLastUsedDescription)
                        .font(ForagerTheme.secondaryFont)
                        .foregroundStyle(ForagerTheme.textSecondary)
                }
            }
            .padding(.top, ForagerTheme.Spacing.sm)
        } label: {
            Text("Usage")
                .font(ForagerTheme.footnoteFont)
                .foregroundStyle(ForagerTheme.textTertiary)
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
        case .title: return ForagerTheme.accentPrimary
        case .ingredient: return ForagerTheme.accentSecondary
        case .instructions: return ForagerTheme.statusWarningFG
        }
    }
}

#Preview {
    NavigationView {
        RecipeListView(popToRoot: .constant(false))
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
