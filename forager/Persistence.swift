import CoreData
import CloudKit

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - IngredientTemplate Migration Support (STEP 4 - ADDED)
extension IngredientTemplate {
    
    // Add these inside your existing IngredientTemplate extension:

    /// Safely toggles staple status with error handling
    func toggleStapleStatus() -> Bool {
        guard let context = managedObjectContext else {
            print("❌ Cannot toggle staple status - no managed object context")
            return false
        }
        
        isStaple.toggle()
        
        do {
            if context.hasChanges {
                try context.save()
                print("✅ Staple status updated for: \(name ?? "Unknown")")
                return true
            }
            return true // No changes needed
        } catch {
            print("❌ Failed to save staple status change: \(error)")
            isStaple.toggle() // Revert the change
            return false
        }
    }

    /// Updates category assignment with validation
    func assignCategory(_ newCategory: String?) -> Bool {
        guard let context = managedObjectContext else {
            print("❌ Cannot assign category - no managed object context")
            return false
        }
        
        let oldCategory = category
        category = newCategory
        
        do {
            if context.hasChanges {
                try context.save()
                print("✅ Category updated for \(name ?? "Unknown"): \(oldCategory ?? "None") → \(newCategory ?? "None")")
                return true
            }
            return true // No changes needed
        } catch {
            print("❌ Failed to save category assignment: \(error)")
            category = oldCategory // Revert the change
            return false
        }
    }

    // MARK: - Migration Support
    
    /// Migrates existing staples from GroceryItem.isStaple to IngredientTemplate.isStaple
    /// This is a one-time migration that preserves all existing staple data
    static func migrateStaplesFromGroceryItems(in context: NSManagedObjectContext) {
        print("🔄 Starting staples migration from GroceryItem to IngredientTemplate...")
        
        // Fetch all staples from GroceryItem
        let stapleRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        stapleRequest.predicate = NSPredicate(format: "isStaple == YES")
        
        do {
            let existingStaples = try context.fetch(stapleRequest)
            print("📦 Found \(existingStaples.count) existing staples to migrate")
            
            var migratedCount = 0
            let skippedCount = 0
            
            for staple in existingStaples {
                let stapleName = staple.name ?? "Unknown"
                
                // Check if IngredientTemplate already exists for this name
                let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
                templateRequest.predicate = NSPredicate(format: "name ==[c] %@", stapleName)
                templateRequest.fetchLimit = 1
                
                if let existingTemplate = try context.fetch(templateRequest).first {
                    // Template exists, just mark as staple
                    existingTemplate.isStaple = true
                    
                    // Preserve category if staple has one and template doesn't
                    if existingTemplate.category?.isEmpty != false,
                       let stapleCategory = staple.category,
                       !stapleCategory.isEmpty {
                        existingTemplate.category = stapleCategory
                    }
                    
                    print("✅ Updated existing template '\(stapleName)' as staple")
                    migratedCount += 1
                } else {
                    // Create new IngredientTemplate from staple
                    let newTemplate = IngredientTemplate(context: context)
                    newTemplate.id = UUID()
                    newTemplate.name = stapleName
                    newTemplate.isStaple = true
                    newTemplate.usageCount = 1 // Start with usage count
                    
                    // Preserve category assignment
                    if let stapleCategory = staple.category, !stapleCategory.isEmpty {
                        newTemplate.category = stapleCategory
                    } else {
                        newTemplate.category = "Uncategorized"
                    }
                    
                    print("🆕 Created new template '\(stapleName)' as staple in '\(newTemplate.category ?? "Uncategorized")'")
                    migratedCount += 1
                }
            }
            
            // Save the migration
            if context.hasChanges {
                try context.save()
                print("✅ Migration completed: \(migratedCount) migrated, \(skippedCount) skipped")
                
                // Mark migration as complete
                UserDefaults.standard.set(true, forKey: "StaplesMigrationCompleted")
                UserDefaults.standard.set(Date(), forKey: "StaplesMigrationDate")
            } else {
                print("ℹ️ No changes needed during migration")
            }
            
        } catch {
            print("❌ Migration error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Migration Status
    
    /// Check if staples migration has been completed
    static var isMigrationCompleted: Bool {
        return UserDefaults.standard.bool(forKey: "StaplesMigrationCompleted")
    }
    
    /// Get migration completion date
    static var migrationDate: Date? {
        return UserDefaults.standard.object(forKey: "StaplesMigrationDate") as? Date
    }
    
    // MARK: - Validation
    
    /// Validate migration success
    static func validateMigration(in context: NSManagedObjectContext) -> (success: Bool, report: String) {
        var report = "📊 STAPLES MIGRATION VALIDATION\n\n"
        
        do {
            // Count original staples
            let stapleRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            stapleRequest.predicate = NSPredicate(format: "isStaple == YES")
            let originalStaplesCount = try context.count(for: stapleRequest)
            
            // Count migrated templates
            let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            templateRequest.predicate = NSPredicate(format: "isStaple == YES")
            let migratedTemplatesCount = try context.count(for: templateRequest)
            
            report += "✅ Original staples: \(originalStaplesCount)\n"
            report += "✅ Migrated templates: \(migratedTemplatesCount)\n\n"
            
            if let migrationDate = migrationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                report += "📅 Migration completed: \(formatter.string(from: migrationDate))\n"
            }
            
            let success = migratedTemplatesCount > 0 || originalStaplesCount == 0
            report += success ? "\n🎯 Migration validation: PASSED" : "\n❌ Migration validation: FAILED"
            
            return (success, report)
            
        } catch {
            report += "❌ Validation error: \(error.localizedDescription)"
            return (false, report)
        }
    }
}

// MARK: - Category Extensions for Uncategorized Management
extension Category {
    
    /// Ensures Uncategorized category always appears last in sort order
    static func updateSortOrderForUncategorized(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.sortOrder, ascending: true)]
        
        do {
            let categories = try context.fetch(request)
            var sortOrder: Int16 = 0
            
            // Assign sort orders, skipping Uncategorized
            for category in categories {
                if category.displayName.lowercased() != "uncategorized" {
                    category.sortOrder = sortOrder
                    sortOrder += 1
                }
            }
            
            // Always put Uncategorized last
            if let uncategorized = categories.first(where: { $0.displayName.lowercased() == "uncategorized" }) {
                uncategorized.sortOrder = sortOrder
                print("✅ Uncategorized category moved to position \(sortOrder)")
            }
            
        } catch {
            print("❌ Error updating sort order for Uncategorized: \(error)")
        }
    }
    
    /// Migrates all nil ingredient template assignments to Uncategorized category
    static func migrateNilAssignmentsToUncategorized(in context: NSManagedObjectContext) {
        // First, ensure Uncategorized category exists
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "name ==[c] %@", "Uncategorized")
        
        do {
            let existingUncategorized = try context.fetch(categoryRequest)
            let uncategorizedCategory: Category
            
            if let existing = existingUncategorized.first {
                uncategorizedCategory = existing
                print("ℹ️ Found existing Uncategorized category")
            } else {
                // Create Uncategorized category if it doesn't exist
                uncategorizedCategory = Category(context: context)
                uncategorizedCategory.id = UUID()
                uncategorizedCategory.name = "Uncategorized"
                uncategorizedCategory.normalizedName = Category.normalizedName(from: "Uncategorized") // M7.1.3: Populate semantic key
                uncategorizedCategory.updatedAt = Date() // M7.1.3: Set timestamp
                uncategorizedCategory.color = "#9E9E9E" // Gray color
                uncategorizedCategory.isDefault = false // Custom category, not a default
                uncategorizedCategory.dateCreated = Date()
                uncategorizedCategory.sortOrder = Int16.max // Will be corrected by updateSortOrderForUncategorized
                print("✅ Created Uncategorized category")
            }
            
            // Now migrate all nil assignments
            let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            templateRequest.predicate = NSPredicate(format: "category == nil OR category == ''")
            
            let templatesWithNilCategory = try context.fetch(templateRequest)
            
            if !templatesWithNilCategory.isEmpty {
                for template in templatesWithNilCategory {
                    template.category = uncategorizedCategory.displayName
                }
                print("✅ Migrated \(templatesWithNilCategory.count) ingredient templates to Uncategorized")
            } else {
                print("ℹ️ No ingredient templates needed migration to Uncategorized")
            }
            
            // Update sort orders to ensure Uncategorized is last
            updateSortOrderForUncategorized(in: context)
            
        } catch {
            print("❌ Error during migration to Uncategorized: \(error)")
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()
    
    // M7.2.2: Serial queue for synchronizing one-time setup
    private static let setupQueue = DispatchQueue(label: "com.forager.setup", qos: .userInitiated)

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create comprehensive sample data with categories
        addSampleData(to: viewContext)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    // Enhanced sample data method with category relationships
    private static func addSampleData(to context: NSManagedObjectContext) {
        #if DEBUG
        // ONLY ensure categories exist in sample data - don't call migration here
        Category.ensureDefaultCategories(in: context)
        
        // Fetch categories for relationship assignment
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        let categories = (try? context.fetch(categoryRequest)) ?? []
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.displayName, $0) })
        
        // M7.2.2: Sample Grocery Items - NO STAPLES (isStaple = false for all)
        // Staples are user-created only, not part of sample data
        let groceryItems = [
            ("Bananas", "Produce", false),
            ("Apples", "Produce", false),
            ("Strawberries", "Produce", false),
            ("Grapes", "Produce", false),
            ("Cucumbers", "Produce", false),
            ("Peppers", "Produce", false),
            ("Ham", "Deli & Meat", false),
            ("Bologna", "Deli & Meat", false),
            ("Bread", "Bread & Frozen", false),
            ("Kids Yogurt", "Dairy & Fridge", false),
            ("Milk 2%", "Dairy & Fridge", false),
            ("Milk 1%", "Dairy & Fridge", false)
        ]
        
        var groceryItemsDict: [String: GroceryItem] = [:]
        
        for (name, categoryName, isStaple) in groceryItems {
            let item = GroceryItem(context: context)
            item.id = UUID()
            item.name = name
            item.category = categoryName // Keep for legacy compatibility
            item.categoryEntity = categoryDict[categoryName] // Set relationship
            item.isStaple = isStaple
            item.dateCreated = Date().addingTimeInterval(-Double.random(in: 0...30) * 24 * 60 * 60)
            if isStaple {
                item.lastPurchased = Date().addingTimeInterval(-Double.random(in: 1...14) * 24 * 60 * 60)
            }
            groceryItemsDict[name] = item
        }
        
        // Sample Tags
        let tagData = [
            ("Quick & Easy", "#FF6B6B"),
            ("Healthy", "#4ECDC4"),
            ("Comfort Food", "#45B7D1"),
            ("Vegetarian", "#96CEB4"),
            ("30 Minutes", "#FECA57"),
            ("Leftovers", "#FF9FF3")
        ]
        
        var tagsDict: [String: Tag] = [:]
        
        for (name, color) in tagData {
            let tag = Tag(context: context)
            tag.id = UUID()
            tag.name = name
            tag.color = color
            tag.dateCreated = Date()
            tagsDict[name] = tag
        }
        
        // Sample Recipes with realistic data
        let recipeData = [
            ("Chicken Stir Fry", "Heat oil in wok. Add chicken and cook until done. Add vegetables and stir fry for 5 minutes. Season with soy sauce.", 4, 15, 10, 5),
            ("Spaghetti Carbonara", "Cook pasta. In pan, cook eggs and cheese mixture. Combine with hot pasta. Add pepper and serve.", 2, 10, 20, 8),
            ("Banana Bread", "Preheat oven to 350°F. Mix dry ingredients. In separate bowl, mash bananas and mix with wet ingredients. Combine and bake for 1 hour.", 8, 20, 60, 2),
            ("Fried Rice", "Cook rice day before. Heat oil, scramble eggs, add rice and vegetables. Season with soy sauce.", 4, 10, 15, 12)
        ]
        
        for (title, instructions, servings, prepTime, cookTime, usageCount) in recipeData {
            let recipe = Recipe(context: context)
            recipe.id = UUID()
            recipe.title = title
            recipe.instructions = instructions
            recipe.servings = Int16(servings)
            recipe.prepTime = Int16(prepTime)
            recipe.cookTime = Int16(cookTime)
            recipe.usageCount = Int32(usageCount)
            recipe.dateCreated = Date().addingTimeInterval(-Double.random(in: 0...60) * 24 * 60 * 60)
            recipe.lastUsed = Date().addingTimeInterval(-Double.random(in: 0...30) * 24 * 60 * 60)
            recipe.isFavorite = usageCount > 5
            recipe.sourceURL = "https://example.com/recipe/\(title.lowercased().replacingOccurrences(of: " ", with: "-"))"
        }
        
        // Sample Weekly List
        let weeklyList = WeeklyList(context: context)
        weeklyList.id = UUID()
        weeklyList.name = "Weekly Shopping - \(DateFormatter.shortDate.string(from: Date()))"
        weeklyList.dateCreated = Date()
        weeklyList.isCompleted = false
        weeklyList.notes = "Don't forget to check for coupons!"
        
        // Sample Grocery List Items
        let listItems = [
            ("Bananas", "2 bunches", false, "staples"),
            ("Milk", "1 gallon", false, "staples"),
            ("Tomatoes", "1 lb", true, "recipe"),
            ("Special Ice Cream", "1 pint", false, "manual")
        ]
        
        for (name, quantity, isCompleted, source) in listItems {
            let listItem = GroceryListItem(context: context)
            listItem.id = UUID()
            listItem.name = name
            listItem.displayText = quantity
            listItem.numericValue = 0.0
            listItem.isParseable = false
            listItem.parseConfidence = 0.0
            listItem.isCompleted = isCompleted
            listItem.source = source
            listItem.sortOrder = Int16(listItems.firstIndex(where: { $0.0 == name }) ?? 0)
            if isCompleted {
                listItem.dateCompleted = Date().addingTimeInterval(-Double.random(in: 0...7) * 24 * 60 * 60)
            }
        }
        #else
        // Production builds: no sample data created
        print("Production build: Sample data creation skipped")
        #endif
    }

    // M7.1.1: Changed to NSPersistentCloudKitContainer for CloudKit sync support
    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        // M7.1.1: Initialize with CloudKit-enabled container
        container = NSPersistentCloudKitContainer(name: "forager")
        
        // M7.1.1: Configure CloudKit container options
        if let description = container.persistentStoreDescriptions.first {
            // CRITICAL FIX: Force Development environment
            // The container options need to be set with proper environment
            let containerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.richhayn.forager"
            )
            
            // Set database scope to private (required for NSPersistentCloudKitContainer)
            description.cloudKitContainerOptions = containerOptions
            
            #if DEBUG
            // FORCE Development environment in Debug builds
            // This is the correct way to override the default Production environment
            description.setOption("Development" as NSObject,
                                forKey: "NSPersistentStoreCloudKitEnvironment")
            print("☁️ CloudKit sync enabled (DEVELOPMENT environment FORCED)")
            #else
            print("☁️ CloudKit sync enabled (Production environment)")
            #endif
            
            // M7.1.3: Enable automatic lightweight migration for schema changes
            description.setOption(true as NSNumber,
                                forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber,
                                forKey: NSInferMappingModelAutomaticallyOption)
            
            // Enable history tracking (required for CloudKit sync)
            description.setOption(true as NSNumber, 
                                forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications (observes CloudKit updates)
            description.setOption(true as NSNumber, 
                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // For in-memory testing (previews)
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
                print("🧪 In-memory store for testing")
            }
        }
        
        // Load persistent stores
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Core Data stack loaded successfully")
        })
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // M7.2.2: Set up observer to wait for initial CloudKit import before creating defaults
        if !inMemory {
            setupCloudKitImportObserver()
        }
    }
    
    // MARK: - One-Time Setup (ENHANCED with Step 4 Migration - UPDATED)
    /// M7.2.2: Observes CloudKit import events to ensure sync completes before creating defaults
    /// This prevents duplicate categories when Device B syncs from Device A
    private func setupCloudKitImportObserver() {
        // M7.2.2: Use UserDefaults to track if initial setup has been performed
        let setupKey = "M7.2.2_InitialSetupCompleted"
        
        // If already completed, skip
        guard !UserDefaults.standard.bool(forKey: setupKey) else {
            print("ℹ️ M7.2.2: Initial setup already completed, skipping observer")
            return
        }
        
        // Store observer reference and timeout work item
        var observer: NSObjectProtocol?
        var timeoutWorkItem: DispatchWorkItem?
        
        // M7.2.2: Helper to execute setup exactly once using serial queue
        let executeSetupOnce = {
            PersistenceController.setupQueue.async {
                // Check flag again inside serial queue (ensures only one execution)
                guard !UserDefaults.standard.bool(forKey: setupKey) else {
                    print("ℹ️ M7.2.2: Setup already completed, skipping duplicate call")
                    return
                }
                
                // Mark as completed FIRST (inside serial queue)
                UserDefaults.standard.set(true, forKey: setupKey)
                
                // Cancel timeout and remove observer
                timeoutWorkItem?.cancel()
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                
                // Now perform setup (guaranteed to run only once)
                self.performOneTimeSetup()
            }
        }
        
        // Create timeout work item
        timeoutWorkItem = DispatchWorkItem {
            print("ℹ️ M7.2.2: No CloudKit import detected after 3s, proceeding with setup...")
            executeSetupOnce()
        }
        
        // Set up observer
        observer = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            // Check if this is an import event
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event,
               event.type == .import {
                
                // Wait for first successful import before creating defaults
                if event.endDate != nil {
                    print("ℹ️ M7.2.2: Initial CloudKit import completed, proceeding with setup...")
                    executeSetupOnce()
                }
            }
        }
        
        // Schedule timeout on background queue (3 seconds)
        if let workItem = timeoutWorkItem {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 3.0, execute: workItem)
        }
    }
    
    /// Performs all setup operations in the correct order to prevent duplicates
    private func performOneTimeSetup() {
        container.performBackgroundTask { backgroundContext in
            // Step 1: Ensure categories exist first (only once)
            self.ensureCategoriesExist(in: backgroundContext)
            
            // Step 2: Migrate existing data to use category relationships
            self.migrateExistingData(in: backgroundContext)
            
            // Step 3: Migrate nil assignments to Uncategorized
            self.migrateToUncategorizedCategory(in: backgroundContext)
            
            // Step 4: Execute staples migration if needed
            self.executeStaplesMigrationIfNeeded(in: backgroundContext)
            
            // Step 5: M7.2.2 - REMOVED sample data creation
            // Users now start with clean slate (no pre-populated grocery items)
            // Sample data only exists in SwiftUI previews for development
            
            // Step 6: M7.1.3 - Execute Stage A migration (populate semantic keys)
            self.performStageAMigration(in: backgroundContext)
            
            // Save all changes at once
            do {
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("✅ One-time setup completed successfully")
                }
            } catch {
                print("❌ Setup failed: \(error)")
            }
        }
    }
    
    /// Ensures categories exist (called only once)
    private func ensureCategoriesExist(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let existingCategories = try context.fetch(request)
            if existingCategories.isEmpty {
                Category.createDefaultCategories(in: context)
                print("✅ Created default categories")
            } else {
                print("ℹ️ Categories already exist (\(existingCategories.count) found)")
            }
        } catch {
            print("❌ Error checking categories: \(error)")
            Category.createDefaultCategories(in: context)
        }
    }
    
    /// Migrates existing grocery items to use category relationships
    private func migrateExistingData(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
        request.predicate = NSPredicate(format: "categoryEntity == nil AND category != nil")
        
        do {
            let itemsToMigrate = try context.fetch(request)
            if !itemsToMigrate.isEmpty {
                print("🔄 Migrating \(itemsToMigrate.count) items to category relationships")
                //for item in itemsToMigrate {
                //    item.migrateToCategory(in: context)
                //}
            }
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
    
    /// Migrates nil ingredient template assignments to Uncategorized category
    private func migrateToUncategorizedCategory(in context: NSManagedObjectContext) {
        print("🔄 Starting migration to Uncategorized category...")
        Category.migrateNilAssignmentsToUncategorized(in: context)
    }
    
    /// NEW - Execute Step 4 staples migration if needed (ADDED)
    private func executeStaplesMigrationIfNeeded(in context: NSManagedObjectContext) {
        // Check if migration has already been completed
        guard !IngredientTemplate.isMigrationCompleted else {
            print("ℹ️ Step 4 staples migration already completed, skipping...")
            return
        }
        
        print("🚀 Executing Step 4 staples migration...")
        IngredientTemplate.migrateStaplesFromGroceryItems(in: context)
        
        // Validate migration
        let validation = IngredientTemplate.validateMigration(in: context)
        print(validation.report)
        
        if !validation.success {
            print("⚠️ Step 4 migration validation failed - manual review recommended")
        }
    }
    
    // MARK: - Background Operations
    /// Performs Core Data write operations on a background context to prevent UI blocking.
    func performWrite(_ block: @escaping (NSManagedObjectContext) -> Void, onError: ((Error) -> Void)? = nil) {
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(ctx)
            if ctx.hasChanges {
                do {
                    try ctx.save()
                } catch {
                    print("❌ Background save failed: \(error)")
                    DispatchQueue.main.async {
                        onError?(error)
                    }
                }
            }
        }
    }
}

// MARK: - Step 4 Migration Support Extension (ADDED)
extension PersistenceController {
    
    // MARK: - Step 4 Migration Support
    
    /// Execute one-time staples migration during app startup
    func executeMigrationIfNeeded() {
        // Check if migration has already been completed
        guard !IngredientTemplate.isMigrationCompleted else {
            print("ℹ️ Staples migration already completed, skipping...")
            return
        }
        
        print("🚀 Executing staples migration on app startup...")
        
        // Perform migration in background context
        container.performBackgroundTask { context in
            IngredientTemplate.migrateStaplesFromGroceryItems(in: context)
            
            // Validate migration
            let validation = IngredientTemplate.validateMigration(in: context)
            print(validation.report)
            
            if !validation.success {
                print("⚠️ Migration validation failed - manual review recommended")
            }
        }
    }
    
    // MARK: - Migration Testing (Development Only)
    
    #if DEBUG
    /// Reset migration status for testing purposes (DEBUG builds only)
    func resetMigrationForTesting() {
        UserDefaults.standard.removeObject(forKey: "StaplesMigrationCompleted")
        UserDefaults.standard.removeObject(forKey: "StaplesMigrationDate")
        print("🔄 Migration status reset for testing")
    }
    
    /// Get migration status report for debugging
    func getMigrationStatusReport() -> String {
        var report = "🔍 MIGRATION STATUS REPORT\n\n"
        
        if IngredientTemplate.isMigrationCompleted {
            report += "✅ Migration Status: COMPLETED\n"
            if let date = IngredientTemplate.migrationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                report += "📅 Completion Date: \(formatter.string(from: date))\n"
            }
        } else {
            report += "⏳ Migration Status: PENDING\n"
        }
        
        // Get current data counts
        let context = container.viewContext
        
        do {
            let stapleRequest: NSFetchRequest<GroceryItem> = GroceryItem.fetchRequest()
            stapleRequest.predicate = NSPredicate(format: "isStaple == YES")
            let staplesCount = try context.count(for: stapleRequest)
            
            let templateRequest: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
            templateRequest.predicate = NSPredicate(format: "isStaple == YES")
            let templatesCount = try context.count(for: templateRequest)
            
            report += "\n📊 Current Data:\n"
            report += "   GroceryItem staples: \(staplesCount)\n"
            report += "   IngredientTemplate staples: \(templatesCount)\n"
            
        } catch {
            report += "\n❌ Error fetching counts: \(error.localizedDescription)"
        }
        
        return report
    }
    #endif
}

// MARK: - M7.1.3 Phase 1.1 Part 2: Semantic Key Population
extension PersistenceController {
    
    /// M7.1.3: Populate semantic keys for existing Category entities
    /// Normalizes displayName to lowercase, trimmed format for semantic uniqueness
    private func populateCategorySemanticKeys(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        guard let categories = try? context.fetch(request) else { 
            print("⚠️ M7.1.3: Failed to fetch categories for population")
            return 
        }
        
        var populatedCount = 0
        for category in categories {
            // Use 'name' field (optional), not 'displayName' (computed property)
            guard let name = category.name, 
                  !name.isEmpty else { 
                print("⚠️ M7.1.3: Skipping category with nil/empty name")
                continue 
            }
            
            // Use helper function for normalization
            category.normalizedName = Category.normalizedName(from: name)
            category.updatedAt = Date()
            populatedCount += 1
        }
        
        print("✅ M7.1.3: Populated normalizedName for \(populatedCount) categories")
    }
    
    /// M7.1.3: Populate semantic keys for existing IngredientTemplate entities
    /// Normalizes name to canonical form for semantic uniqueness
    private func populateIngredientTemplateSemanticKeys(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<IngredientTemplate> = IngredientTemplate.fetchRequest()
        
        guard let templates = try? context.fetch(request) else {
            print("⚠️ M7.1.3: Failed to fetch templates for population")
            return
        }
        
        var populatedCount = 0
        for template in templates {
            guard let name = template.name,
                  !name.isEmpty else {
                print("⚠️ M7.1.3: Skipping template with nil/empty name")
                continue
            }
            
            // Use helper function for normalization
            template.canonicalName = IngredientTemplate.canonicalName(from: name)
            
            // Set dateCreated if missing (reusing existing field)
            if template.dateCreated == nil {
                template.dateCreated = Date()
            }
            
            template.updatedAt = Date()
            populatedCount += 1
        }
        
        print("✅ M7.1.3: Populated canonicalName for \(populatedCount) templates")
    }
    
    /// M7.1.3: Populate semantic keys for existing PlannedMeal entities
    /// Generates slotKey from date and mealType for semantic uniqueness
    private func populatePlannedMealSemanticKeys(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<PlannedMeal> = PlannedMeal.fetchRequest()
        
        guard let meals = try? context.fetch(request) else {
            print("⚠️ M7.1.3: Failed to fetch planned meals for population")
            return
        }
        
        var populatedCount = 0
        
        for meal in meals {
            guard let date = meal.date else {
                print("⚠️ M7.1.3: Skipping planned meal with nil date")
                continue
            }
            
            // Extract mealType from existing data or default to "meal"
            // TODO: In future, properly categorize meals by time of day
            let mealType = meal.mealType ?? "meal"
            
            // Generate slotKey using helper function
            meal.slotKey = PlannedMeal.generateSlotKey(date: date, mealType: mealType)
            meal.mealType = mealType
            
            // Set createdDate if missing (reusing existing field)
            if meal.createdDate == nil {
                meal.createdDate = Date()
            }
            
            populatedCount += 1
        }
        
        print("✅ M7.1.3: Populated slotKey for \(populatedCount) planned meals")
    }
    
    /// M7.1.3: Populate semantic keys for existing Recipe entities
    /// Normalizes title for duplicate detection (not prevention)
    /// Note: Recipes allow duplicates - titleKey only for showing user warnings
    private func populateRecipeSemanticKeys(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        
        guard let recipes = try? context.fetch(request) else {
            print("⚠️ M7.1.3: Failed to fetch recipes for population")
            return
        }
        
        var populatedCount = 0
        for recipe in recipes {
            guard let title = recipe.title,
                  !title.isEmpty else {
                print("⚠️ M7.1.3: Skipping recipe with nil/empty title")
                continue
            }
            
            // Use helper function for normalization
            recipe.titleKey = Recipe.titleKey(from: title)
            
            // Set dateCreated if missing (reusing existing field)
            if recipe.dateCreated == nil {
                recipe.dateCreated = Date()
            }
            
            populatedCount += 1
        }
        
        print("✅ M7.1.3: Populated titleKey for \(populatedCount) recipes")
    }
    
    // MARK: - M7.1.3 Stage A Migration Orchestration
    
    /// M7.1.3: Performs Stage A migration (populate semantic keys for existing data)
    /// This is a one-time migration that runs on first launch after schema update
    /// Uses UserDefaults to ensure idempotency (only runs once)
    private func performStageAMigration(in context: NSManagedObjectContext) {
        // Check if Stage A migration already completed
        let migrationKey = "M7.1.3_StageA_Migration_Completed"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("ℹ️ M7.1.3 Stage A: Migration already completed, skipping...")
            return
        }
        
        print("🚀 M7.1.3 Stage A: Starting semantic key population migration...")
        let startTime = Date()
        
        // Populate semantic keys for all 4 entities
        populateCategorySemanticKeys(in: context)
        populateIngredientTemplateSemanticKeys(in: context)
        populatePlannedMealSemanticKeys(in: context)
        populateRecipeSemanticKeys(in: context)
        
        // Save populated data
        do {
            if context.hasChanges {
                try context.save()
                print("✅ M7.1.3 Stage A: Successfully saved semantic keys")
            } else {
                print("ℹ️ M7.1.3 Stage A: No changes to save")
            }
        } catch {
            print("❌ M7.1.3 Stage A: Failed to save: \(error)")
            // Don't mark as complete if save failed
            return
        }
        
        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationKey)
        UserDefaults.standard.set(Date(), forKey: "M7.1.3_StageA_Migration_Date")
        
        let duration = Date().timeIntervalSince(startTime)
        print("✅ M7.1.3 Stage A: Migration completed in \(String(format: "%.2f", duration))s")
    }
}
