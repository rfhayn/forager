import SwiftUI
import CoreData

struct AddIngredientsToListView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    let recipe: Recipe
    
    // M4.3.2: Servings state for scaled recipe addition
    @State private var selectedServings: Int
    private let scalingService: RecipeScalingService
    private let templateService: IngredientTemplateService
    private let mergeService: GroceryMergeService
    
    @State private var selectedIngredients: Set<UUID> = []
    @State private var isProcessing = false
    @State private var processingMessage = "Processing..."
    @State private var targetWeeklyList: WeeklyList?
    
    // MARK: - Category Assignment Modal States
    @State private var showingCategoryAssignment = false
    @State private var uncategorizedTemplates: [IngredientTemplate] = []
    @State private var pendingAddOperation: (() -> Void)?
    
    // M2.2.6 - STEP 1: Add Category FetchRequest (add this after your existing @State properties)
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
    ) private var categories: FetchedResults<Category>
    
    // M4.3.2: Initialize with optional targetServings parameter
    init(recipe: Recipe, targetServings: Int? = nil, context: NSManagedObjectContext) {
        self.recipe = recipe
        
        // Default to recipe's servings if not specified
        let servings = targetServings ?? Int(recipe.servings)
        _selectedServings = State(initialValue: servings)
        
        // Initialize services (regular properties, not @StateObject)
        self.scalingService = RecipeScalingService(context: context)
        self.templateService = IngredientTemplateService(context: context)
        self.mergeService = GroceryMergeService()
    }
    
    // M4.3.2: Computed property for scale factor
    private var scaleFactor: Double {
        guard recipe.servings > 0 else { return 1.0 }
        return Double(selectedServings) / Double(recipe.servings)
    }
    
    // M4.3.2 Phase 2: Compute scaled ingredients using RecipeScalingService
    private var scaledIngredients: [Ingredient] {
        guard let ingredientsSet = recipe.ingredients else { return [] }
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        
        // If no scaling needed, return originals sorted
        guard scaleFactor != 1.0 else {
            return ingredients.sorted { $0.sortOrder < $1.sortOrder }
        }
        
        // Use RecipeScalingService to scale the recipe
        let scaledRecipe = scalingService.scale(recipe: recipe, scaleFactor: scaleFactor)
        
        // Map scaled ingredients back to original ingredient objects with updated display
        // We need to preserve the original Ingredient objects but update their display
        var scaledIngredientsList: [Ingredient] = []
        
        for scaledIng in scaledRecipe.scaledIngredients {
            // Find the corresponding original ingredient
            if let originalIng = ingredients.first(where: { $0.name == scaledIng.originalText || $0.name == scaledIng.name }) {
                // Create a copy of the ingredient with scaled displayText
                let copy = originalIng // Using the original object
                // Note: We'll handle display differently in the UI since we can't modify Core Data objects
                scaledIngredientsList.append(copy)
            }
        }
        
        return scaledIngredientsList.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    // M4.3.2 Phase 2: Store original displayText for showing comparison
    private var originalDisplayTexts: [UUID: String] {
        guard let ingredientsSet = recipe.ingredients else { return [:] }
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        
        var dict: [UUID: String] = [:]
        for ingredient in ingredients {
            if let id = ingredient.id {
                dict[id] = ingredient.displayText ?? ""
            }
        }
        return dict
    }
    
    // M4.3.2 Phase 2: Get scaled display text for an ingredient
    private func scaledDisplayText(for ingredient: Ingredient) -> String {
        guard scaleFactor != 1.0 else {
            return ingredient.displayText ?? ""
        }
        
        // If ingredient has numeric value, scale it
        if ingredient.isParseable && ingredient.numericValue > 0 {
            let scaledValue = ingredient.numericValue * scaleFactor
            
            // Format the scaled quantity (simplified inline formatting)
            let fractionString = formatToFraction(scaledValue)
            
            if let unit = ingredient.standardUnit, !unit.isEmpty {
                return "\(fractionString) \(unit)"
            } else {
                return fractionString
            }
        } else {
            // Non-parseable items don't scale
            return ingredient.displayText ?? ""
        }
    }
    
    // M4.3.2 Phase 2: Format decimal to fraction for kitchen-friendly display
    private func formatToFraction(_ value: Double) -> String {
        let whole = Int(value)
        let fractional = value - Double(whole)
        
        // Common kitchen fractions with tolerance
        let fractions: [(value: Double, display: String)] = [
            (0.125, "1/8"),
            (0.25, "1/4"),
            (0.333, "1/3"),
            (0.5, "1/2"),
            (0.666, "2/3"),
            (0.75, "3/4")
        ]
        
        // Find closest fraction (within 0.05 tolerance)
        for (fracValue, fracDisplay) in fractions {
            if abs(fractional - fracValue) < 0.05 {
                if whole > 0 {
                    return "\(whole) \(fracDisplay)"
                } else {
                    return fracDisplay
                }
            }
        }
        
        // No close fraction - use decimal
        if whole > 0 && fractional > 0.01 {
            return String(format: "%.2f", value)
        } else if whole > 0 {
            return "\(whole)"
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    // M2.2.6 - ADDED: Computed properties for custom category grouping
    // M4.3.2 Phase 2: Updated to use scaledIngredients
    private var groupedIngredients: [String: [Ingredient]] {
        return Dictionary(grouping: scaledIngredients) { ingredient in
            ingredient.ingredientTemplate?.category ?? "Uncategorized"
        }
    }

    private var sortedCategoryNames: [String] {
        let grouped = groupedIngredients
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.displayName, $0.sortOrder) })
        
        return grouped.keys.sorted { category1, category2 in
            // Handle "Uncategorized" - put it at the end
            if category1 == "Uncategorized" && category2 != "Uncategorized" { return false }
            if category2 == "Uncategorized" && category1 != "Uncategorized" { return true }
            if category1 == "Uncategorized" && category2 == "Uncategorized" { return false }
            
            // Use custom sort order for real categories
            let order1 = categoryMap[category1] ?? Int16.max
            let order2 = categoryMap[category2] ?? Int16.max
            
            if order1 == order2 {
                return category1 < category2 // Fallback to alphabetical
            }
            return order1 < order2
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isProcessing {
                    processingView
                } else {
                    ingredientSelectionView
                }
            }
            .navigationTitle("Add to Grocery List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Selected") {
                        addSelectedToGroceryListWithCategoryCheck()
                    }
                    .disabled(selectedIngredients.isEmpty)
                }
            }
        }
        .onAppear {
            preselectAllIngredients()
        }
        .sheet(isPresented: $showingCategoryAssignment) {
            CategoryAssignmentModal(
                uncategorizedTemplates: uncategorizedTemplates,
                onAssignmentsComplete: {
                    if let operation = pendingAddOperation {
                        operation()
                        pendingAddOperation = nil
                    }
                }
            )
            .environment(\.managedObjectContext, viewContext)
        }
    }
    
    // MARK: - Enhanced Add to List Process with Category Assignment
    
    private func addSelectedToGroceryListWithCategoryCheck() {
        isProcessing = true
        processingMessage = "Preparing ingredients..."
        
        // Step 1: Prepare ingredients and create/update templates
        prepareIngredientsAndTemplates { success in
            if success {
                // Step 2: Check for uncategorized templates
                checkForUncategorizedTemplates { uncategorized in
                    if !uncategorized.isEmpty {
                        // Step 3: Show category assignment modal
                        DispatchQueue.main.async {
                            self.isProcessing = false
                            self.uncategorizedTemplates = uncategorized
                            self.pendingAddOperation = {
                                self.proceedWithExistingAddFlow()
                            }
                            self.showingCategoryAssignment = true
                        }
                    } else {
                        // Step 4: Proceed with existing flow
                        self.proceedWithExistingAddFlow()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.processingMessage = "Failed to prepare ingredients"
                    self.isProcessing = false
                }
            }
        }
    }
    
    // IMPROVED: Updated ingredient parsing with clean names for templates
    private func prepareIngredientsAndTemplates(completion: @escaping (Bool) -> Void) {
        guard let ingredientsSet = recipe.ingredients else {
            completion(false)
            return
        }
        
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        let selectedIngredientsList = ingredients.filter { ingredient in
            guard let id = ingredient.id else { return false }
            return selectedIngredients.contains(id)
        }
        
        // M8.3.1: Route all template creation through findOrCreateTemplate
        for ingredient in selectedIngredientsList {
            guard let fullName = ingredient.name?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !fullName.isEmpty else { continue }

            let cleanName = extractCleanIngredientName(from: fullName)
            let template = templateService.findOrCreateTemplate(name: cleanName)
            ingredient.ingredientTemplate = template
        }

        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
            completion(true)
        } catch {
            #if DEBUG
            print("Error saving templates: \(error)")
            #endif
            completion(false)
        }
    }
    
    // FIXED: Check for templates that need category assignment
    private func checkForUncategorizedTemplates(completion: @escaping ([IngredientTemplate]) -> Void) {
        guard let ingredientsSet = recipe.ingredients else {
            completion([])
            return
        }
        
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        let selectedIngredientsList = ingredients.filter { ingredient in
            guard let id = ingredient.id else { return false }
            return selectedIngredients.contains(id)
        }
        
        let uncategorized = selectedIngredientsList.compactMap { ingredient -> IngredientTemplate? in
            // Check if ingredient has a linked template
            guard let template = ingredient.ingredientTemplate else {
                return nil
            }
            
            // Check if template needs category assignment
            if let category = template.category,
               !category.isEmpty,
               category.lowercased() != "uncategorized" {
                return nil  // Already has category
            }
            
            return template
        }
        
        // Deduplicate templates by ID
        let uniqueTemplates = Array(Set(uncategorized.compactMap { $0.id }))
            .compactMap { id in uncategorized.first { $0.id == id } }
        
        completion(uniqueTemplates)
    }
    
    private func proceedWithExistingAddFlow() {
        guard !selectedIngredients.isEmpty else {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.presentationMode.wrappedValue.dismiss()
            }
            return
        }
        
        // Call list selection UI
        DispatchQueue.main.async {
            // Ensure we're in processing state before showing list selection
            self.isProcessing = false
        }
        
        // Present list selection sheet
        presentListSelection()
    }
    
    private func presentListSelection() {
        // This is a simple implementation showing how list selection works
        // In a production app, you might present a sheet to select the list
        
        // For now, fetch the most recent weekly list or create one
        let request: NSFetchRequest<WeeklyList> = WeeklyList.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WeeklyList.dateCreated, ascending: false)]
        request.fetchLimit = 1
        
        do {
            if let weeklyList = try viewContext.fetch(request).first {
                targetWeeklyList = weeklyList
                addToShoppingList(targetList: weeklyList)
            } else {
                // Create a new list if none exist
                let newList = WeeklyList(context: viewContext)
                newList.id = UUID()
                newList.name = "Shopping List"
                newList.dateCreated = Date()
                
                try viewContext.save()
                targetWeeklyList = newList
                addToShoppingList(targetList: newList)
            }
        } catch {
            #if DEBUG
            print("Error fetching/creating weekly list: \(error)")
            #endif
            processingMessage = "Error accessing shopping lists"
            isProcessing = false
        }
    }
    
    // Core function that adds selected ingredients to the target list
    private func addToShoppingList(targetList: WeeklyList) {
        guard let ingredientsSet = recipe.ingredients else {
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        let selectedIngredientsToAdd = ingredients.filter { ingredient in
            guard let id = ingredient.id else { return false }
            return selectedIngredients.contains(id)
        }
        
        guard !selectedIngredientsToAdd.isEmpty else {
            isProcessing = false
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        let existingItems = fetchExistingItems(in: targetList)
        var mergeCount = 0
        
        for ingredient in selectedIngredientsToAdd {
            // M4.3.2 Phase 2: Use SCALED displayText from our scaling function
            let fullIngredientText = scaledDisplayText(for: ingredient)
            
            // But use clean name for template operations and duplicate detection
            let cleanName: String
            if let ingredientTemplate = ingredient.ingredientTemplate {
                cleanName = ingredientTemplate.name ?? extractCleanIngredientName(from: fullIngredientText)
            } else {
                cleanName = extractCleanIngredientName(from: fullIngredientText)
            }
            
            #if DEBUG
            print("DEBUG: Processing ingredient '\(fullIngredientText)' -> clean: '\(cleanName)' (scale: \(scaleFactor)x)")
            #endif
            
            // Check for existing items by clean name
            if let existingItem = findExistingItem(named: cleanName, in: existingItems) {
                // M8.3.2: Numeric merge via GroceryMergeService
                let existing = GroceryMergeInput(
                    numericValue: existingItem.numericValue,
                    standardUnit: existingItem.standardUnit,
                    isParseable: existingItem.isParseable,
                    parseConfidence: Double(existingItem.parseConfidence)
                )
                let incoming = GroceryMergeInput(
                    numericValue: ingredient.isParseable ? ingredient.numericValue * scaleFactor : 0,
                    standardUnit: ingredient.standardUnit,
                    isParseable: ingredient.isParseable,
                    parseConfidence: Double(ingredient.parseConfidence)
                )
                let result = mergeService.merge(existing: existing, incoming: incoming)

                existingItem.numericValue = result.numericValue
                existingItem.parseConfidence = Float(result.parseConfidence)
                if result.didMergeQuantity {
                    existingItem.displayText = result.displayText
                    existingItem.standardUnit = result.standardUnit
                }

                existingItem.addToSourceRecipes(recipe)

                mergeCount += 1
                #if DEBUG
                print("Merged quantities for '\(cleanName)': \(result.displayText) (didMerge: \(result.didMergeQuantity))")
                #endif
            } else {
                // Create new item
                let listItem = GroceryListItem(context: viewContext)
                listItem.id = UUID()
                listItem.name = cleanName
                
                // M4.3.2 Phase 2: Copy SCALED quantity fields
                listItem.displayText = fullIngredientText  // Already scaled from scaledDisplayText()
                
                // Scale the numeric value if parseable
                if ingredient.isParseable && ingredient.numericValue > 0 {
                    listItem.numericValue = ingredient.numericValue * scaleFactor
                } else {
                    listItem.numericValue = ingredient.numericValue
                }
                
                listItem.standardUnit = ingredient.standardUnit
                listItem.isParseable = ingredient.isParseable
                listItem.parseConfidence = ingredient.parseConfidence
                
                listItem.isCompleted = false
                listItem.source = "Recipe: \(recipe.title ?? "Unknown Recipe")"
                
                // M4.3.1: Add recipe to sourceRecipes relationship
                listItem.addToSourceRecipes(recipe)
                
                // Use proper category assignment logic
                if let template = ingredient.ingredientTemplate,
                   let categoryString = template.category,
                   !categoryString.isEmpty {
                    listItem.categoryName = categoryString
                    #if DEBUG
                    print("Assigned category '\(categoryString)' to '\(cleanName)'")
                    #endif
                } else {
                    listItem.categoryName = "UNCATEGORIZED"
                    #if DEBUG
                    print("Assigned UNCATEGORIZED to '\(cleanName)'")
                    #endif
                }
                
                targetList.addToItems(listItem)
                #if DEBUG
                print("Created new item: \(fullIngredientText)")
                #endif
            }
        }
        
        do {
            try viewContext.save()
            
            // M4.3.2 Phase 2: Enhanced success message with scale info
            let scaleInfo = scaleFactor != 1.0 ? " (scaled \(String(format: "%.1f", scaleFactor))x)" : ""
            #if DEBUG
            print("Successfully added \(selectedIngredientsToAdd.count) ingredients\(scaleInfo)")
            #endif
            if mergeCount > 0 {
                #if DEBUG
                print("Merged quantities for \(mergeCount) existing items")
                #endif
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.presentationMode.wrappedValue.dismiss()
            }
        } catch {
            #if DEBUG
            print("Error saving grocery list items: \(error)")
            #endif
            DispatchQueue.main.async {
                self.processingMessage = "Error saving items"
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchExistingItems(in weeklyList: WeeklyList) -> [GroceryListItem] {
        guard let itemsSet = weeklyList.items else { return [] }
        return Array(itemsSet) as! [GroceryListItem]
    }
    
    private func findExistingItem(named targetName: String, in items: [GroceryListItem]) -> GroceryListItem? {
        return items.first { item in
            guard let itemName = item.name else { return false }
            let cleanItemName = extractCleanIngredientName(from: itemName)
            return cleanItemName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                   targetName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func extractCleanIngredientName(from fullText: String) -> String {
        let text = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var cleaned = text
        
        // Remove measurements with units (comprehensive pattern)
        let measurementPattern = #"^[\d/.\s-]*(cups?|tbsp?|tsp?|tablespoons?|teaspoons?|pounds?|lbs?|ounces?|oz|grams?|g|kilograms?|kg|liters?|l|milliliters?|ml|eggs?|egg)\s+"#
        if let regex = try? NSRegularExpression(pattern: measurementPattern, options: .caseInsensitive) {
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                range: NSRange(cleaned.startIndex..., in: cleaned),
                withTemplate: ""
            )
        }
        
        // Remove common quantity words
        let quantityWords = ["large", "medium", "small", "whole", "half", "fresh", "dried", "frozen", "canned", "chopped", "diced", "sliced", "minced"]
        for word in quantityWords {
            let pattern = "\\b\(word)\\b\\s*"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    range: NSRange(cleaned.startIndex..., in: cleaned),
                    withTemplate: ""
                )
            }
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
    
    private func findExistingTemplate(cleanName: String) -> IngredientTemplate? {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[cd] %@", cleanName)
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            #if DEBUG
            print("Error fetching template: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - View Helpers
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text(processingMessage)
                .foregroundColor(.secondary)
        }
    }
    
    private var ingredientSelectionView: some View {
        VStack(spacing: 0) {
            headerSection
            
            // M4.3.2: Servings adjustment section
            servingsSection
            
            List {
                if groupedIngredients.isEmpty {
                    Text("No ingredients available")
                        .foregroundColor(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedCategoryNames, id: \.self) { categoryName in
                        let categoryIngredients = groupedIngredients[categoryName] ?? []
                        
                        if !categoryIngredients.isEmpty {
                            Section(header: categoryHeaderSimple(categoryName: categoryName, count: categoryIngredients.count)) {
                                ForEach(categoryIngredients, id: \.objectID) { ingredient in
                                    ingredientRow(ingredient)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            
            selectionSummary
        }
    }
    
    // M4.3.2: Servings adjustment UI section
    private var servingsSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                // Original servings (read-only)
                HStack {
                    Text("Recipe makes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(recipe.servings) servings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // Adjustable servings
                HStack {
                    Text("Adding for:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Stepper(value: $selectedServings, in: 1...100) {
                        Text("\(selectedServings) servings")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedServings != recipe.servings ? .blue : .primary)
                    }
                }
                
                // Show scale factor if different from original
                if selectedServings != recipe.servings {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Quantities will be scaled \(scaleFactor, specifier: "%.1f")×")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGroupedBackground))
            
            Divider()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recipe: \(recipe.title ?? "Unknown Recipe")")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let ingredientsSet = recipe.ingredients {
                Text("\(ingredientsSet.count) ingredients available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // IMPROVED: Better ingredient status display in AddIngredientsToListView
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(spacing: 12) {
            Button(action: {
                toggleIngredientSelection(ingredient)
            }) {
                Image(systemName: isSelected(ingredient) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected(ingredient) ? .green : .gray)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name ?? "Unknown ingredient")
                    .font(.body)
                    .foregroundColor(.primary)
                
                // M4.3.2 Phase 2: Show scaled quantities with original for reference
                HStack(spacing: 4) {
                    // Show scaled displayText
                    let scaled = scaledDisplayText(for: ingredient)
                    if !scaled.isEmpty {
                        Text(scaled)
                            .font(.caption)
                            .foregroundColor(scaleFactor != 1.0 ? .blue : .secondary)
                        
                        // Show original quantity for reference when scaled
                        if scaleFactor != 1.0, let originalId = ingredient.id,
                           let original = originalDisplayTexts[originalId],
                           !original.isEmpty && original != scaled {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("(was: \(original))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    
                    Spacer()
                    
                    // IMPROVED: Show actual category status
                    ingredientStatusView(for: ingredient)
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleIngredientSelection(ingredient)
        }
    }
    
    // FIXED: Status view logic - show category if exists, "Needs Category" if template exists but no category
    @ViewBuilder
    private func ingredientStatusView(for ingredient: Ingredient) -> some View {
        // Check if ingredient already has a linked template
        if let existingTemplate = ingredient.ingredientTemplate {
            // Template exists - check if it has a category
            if let category = existingTemplate.category,
               !category.isEmpty,
               category.lowercased() != "uncategorized" {
                // Has category - show it with color dot
                HStack(spacing: 4) {
                    Circle()
                        .fill(ForagerTheme.categoryColor(for: category))
                        .frame(width: 8, height: 8)
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(ForagerTheme.categoryColor(for: category))
                }
            } else {
                // Template exists but needs category - orange warning
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Needs Category")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        } else {
            // No template exists yet - check if one exists in database
            let cleanName = extractCleanIngredientName(from: ingredient.name ?? "")
            let existingTemplate = findExistingTemplate(cleanName: cleanName)
            
            if let template = existingTemplate {
                // Template exists in database but not linked - check category
                if let category = template.category,
                   !category.isEmpty,
                   category.lowercased() != "uncategorized" {
                    // Has category
                    HStack(spacing: 4) {
                        Circle()
                            .fill(ForagerTheme.categoryColor(for: category))
                            .frame(width: 8, height: 8)
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(ForagerTheme.categoryColor(for: category))
                    }
                } else {
                    // Template exists but needs category
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Needs Category")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                // No template exists - will create new
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("New Template")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var selectionSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(selectedIngredients.count) ingredients selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if selectedIngredients.count > 0 {
                    Button("Select All") {
                        preselectAllIngredients()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    private func categoryHeaderSimple(categoryName: String, count: Int) -> some View {
        HStack {
            Text(categoryName.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    
    private func isSelected(_ ingredient: Ingredient) -> Bool {
        guard let id = ingredient.id else { return false }
        return selectedIngredients.contains(id)
    }
    
    private func toggleIngredientSelection(_ ingredient: Ingredient) {
        guard let id = ingredient.id else { return }
        
        if selectedIngredients.contains(id) {
            selectedIngredients.remove(id)
        } else {
            selectedIngredients.insert(id)
        }
    }
    
    private func preselectAllIngredients() {
        guard let ingredientsSet = recipe.ingredients else { return }
        
        let ingredients = Array(ingredientsSet) as! [Ingredient]
        selectedIngredients = Set(ingredients.compactMap { $0.id })
    }
}
