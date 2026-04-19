import Foundation
import CoreData

/// Service for Category CRUD operations. Owns the user-facing custom-category
/// creation path. Views never call context.save() directly — they route through
/// this service.
///
/// Routes through ManagedObjectFactory for correct store assignment (ADR 014)
/// and scopes dedup fetch by householdKey (ADR 013).
@MainActor
class CategoryService: ObservableObject {

    // MARK: - Errors

    enum CategoryError: Error, LocalizedError {
        case duplicateName
        case factoryUnavailable
        case factoryError(Error)
        case saveFailed(Error)
        case fetchFailed(Error)

        var errorDescription: String? {
            switch self {
            case .duplicateName:
                return "A category with this name already exists."
            case .factoryUnavailable:
                return "Internal error: factory not available."
            case .factoryError(let underlying):
                return "Failed to create category: \(underlying.localizedDescription)"
            case .saveFailed(let underlying):
                return "Failed to save category: \(underlying.localizedDescription)"
            case .fetchFailed(let underlying):
                return "Failed to check for existing categories: \(underlying.localizedDescription)"
            }
        }
    }

    // MARK: - Properties

    private let viewContext: NSManagedObjectContext
    private let householdService: HouseholdService

    // Factory injection mirrors WeeklyListService / MealPlanService (ADR 014).
    private(set) var factory: ManagedObjectFactory!

    @Published var errorMessage: String?

    // MARK: - Initialization

    init(context: NSManagedObjectContext, householdService: HouseholdService) {
        self.viewContext = context
        self.householdService = householdService
    }

    /// One-time factory injection at app startup (ADR 014).
    func configure(factory: ManagedObjectFactory) {
        self.factory = factory
    }

    // MARK: - Public API

    /// Creates a user-defined custom Category, scoped to the current household.
    /// Encapsulates: dedup check (scoped by householdKey), factory get-or-create,
    /// sortOrder assignment (max-of-current-scope + 1), color/id/isDefault/dateCreated
    /// assignment, and the save. Views call this and map the Result to their UI.
    func createCustomCategory(displayName: String, color: String) -> Result<Category, CategoryError> {
        clearError()

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Dedup — scoped by householdKey (ADR 013).
        let dupRequest: NSFetchRequest<Category> = Category.fetchRequest()
        if let key = householdService.currentHouseholdKey {
            dupRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == %@", trimmedName, key)
        } else {
            dupRequest.predicate = NSPredicate(format: "name ==[c] %@ AND householdKey == nil", trimmedName)
        }
        do {
            if !(try viewContext.fetch(dupRequest)).isEmpty {
                let err = CategoryError.duplicateName
                errorMessage = err.errorDescription
                return .failure(err)
            }
        } catch {
            let err = CategoryError.fetchFailed(error)
            errorMessage = err.errorDescription
            return .failure(err)
        }

        // Factory (correct store assignment, ADR 014).
        guard let factory = factory else {
            let err = CategoryError.factoryUnavailable
            errorMessage = err.errorDescription
            return .failure(err)
        }

        guard let newCategory = CategoryRepository.getOrCreate(
            displayName: trimmedName,
            in: viewContext,
            factory: factory
        ) else {
            let err = CategoryError.factoryError(NSError(
                domain: "CategoryService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "CategoryRepository.getOrCreate returned nil"]
            ))
            errorMessage = err.errorDescription
            return .failure(err)
        }

        newCategory.id = UUID()
        newCategory.color = color
        newCategory.isDefault = false
        newCategory.dateCreated = Date()

        // sortOrder = max-of-current-scope + 1 (scoped by householdKey).
        let sortRequest: NSFetchRequest<Category> = Category.fetchRequest()
        if let key = householdService.currentHouseholdKey {
            sortRequest.predicate = NSPredicate(format: "householdKey == %@", key)
        } else {
            sortRequest.predicate = NSPredicate(format: "householdKey == nil")
        }
        let maxSortOrder = (try? viewContext.fetch(sortRequest).map(\.sortOrder).max()) ?? 5
        newCategory.sortOrder = maxSortOrder + 1

        // Save.
        do {
            try viewContext.save()
            #if DEBUG
            print("✅ CategoryService: created custom category '\(trimmedName)'")
            #endif
            return .success(newCategory)
        } catch {
            let err = CategoryError.saveFailed(error)
            errorMessage = err.errorDescription
            viewContext.rollback()
            return .failure(err)
        }
    }

    // MARK: - Error helpers

    private func clearError() {
        errorMessage = nil
    }
}
