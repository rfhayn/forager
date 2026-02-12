import Foundation
import CoreData

/// Simple performance-optimized service for Recipe data operations
/// Starts with basic functionality, relationships to be added later
class OptimizedRecipeDataService: ObservableObject {
    private let context: NSManagedObjectContext
    
    // Performance tracking
    @Published var lastFetchDuration: TimeInterval = 0
    @Published var isPerformanceOptimal: Bool = true
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Basic Recipe Fetching
    
    /// Fetch recipes with basic performance optimization
    func fetchRecipes(limit: Int = 50) -> [Recipe] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        
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
    func fetchRecipe(id: UUID) -> Recipe? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let request: NSFetchRequest<Recipe> = Recipe.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
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
