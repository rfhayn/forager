import Foundation
import CoreData

/// Simple performance-optimized service for Recipe data operations
/// Starts with basic functionality, relationships to be added later
class OptimizedRecipeDataService: ObservableObject {
    private let context: NSManagedObjectContext

    // M10.6.18: Household key for scoping fetches (ADR 013)
    var householdKeyProvider: (() -> String?)?

    // Performance tracking
    @Published var lastFetchDuration: TimeInterval = 0
    @Published var isPerformanceOptimal: Bool = true

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // M10.6.18: Build householdKey predicate for scoped fetches (ADR 013)
    private func householdKeyPredicate() -> NSPredicate {
        if let key = householdKeyProvider?() {
            return NSPredicate(format: "householdKey == %@", key)
        } else {
            return NSPredicate(format: "householdKey == nil")
        }
    }

    // MARK: - Basic Recipe Fetching

    /// Fetch recipes with basic performance optimization
    /// M10.6.18: Scoped by householdKey (ADR 013)
    func fetchRecipes(limit: Int = 50) -> [Recipe] {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = householdKeyPredicate()

        // Basic performance optimization
        request.fetchLimit = limit
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Recipe.lastUsed, ascending: false),
            NSSortDescriptor(keyPath: \Recipe.usageCount, ascending: false)
        ]

        do {
            let recipes = try context.fetch(request)

            // Track performance
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.lastFetchDuration = duration
            self.isPerformanceOptimal = duration < 0.1

            return recipes
        } catch {
            #if DEBUG
            print("Error fetching recipes: \(error)")
            #endif
            return []
        }
    }

    // MARK: - Single Recipe Fetch

    /// Fetch single recipe by ID
    /// M10.6.18: Scoped by householdKey (ADR 013)
    func fetchRecipe(id: UUID) -> Recipe? {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "id == %@", id as CVarArg),
            householdKeyPredicate()
        ])

        do {
            let recipes = try context.fetch(request)

            // Track performance
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.lastFetchDuration = duration
            self.isPerformanceOptimal = duration < 0.1

            return recipes.first
        } catch {
            #if DEBUG
            print("Error fetching recipe: \(error)")
            #endif
            return nil
        }
    }
    
    // MARK: - Performance Validation
    
    /// Basic performance validation
    func validatePerformance() -> Bool {
        // Test basic fetch performance
        let _ = fetchRecipes(limit: 10)
        return isPerformanceOptimal
    }
}
