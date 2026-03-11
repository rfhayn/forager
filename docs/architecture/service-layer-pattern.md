# Service Layer Pattern - Forager Architecture Standard

**Status**: ACTIVE - Standard for all M7.5+ development
**Created**: January 13, 2026
**Context**: M7.5 Architecture Hardening - Service Ownership of Saves
**Research Sources**: Industry best practices validated January 2026

---

## 🎯 Purpose

This document defines the **Service Layer Pattern** for Forager, establishing how services should be structured, how they handle errors, and how views interact with them. This pattern provides:

1. **Centralized write paths** - All Core Data saves go through services
2. **Consistent error handling** - Standardized @Published error pattern
3. **Testability** - Services are mockable and unit-testable
4. **Maintainability** - Clear separation of concerns

---

## 📚 Research Validation

This pattern is based on industry best practices from:

### **Service Layer Architecture**
- [App architecture basics in SwiftUI Part 4: Services](https://www.cocoawithlove.com/blog/separated-services-layer.html)
  - **Key insight**: "A Services-layer is...the single best app architectural addition you can make, after the basic Model-View separation already implicit in SwiftUI"
  - Services separate Model from side effects and external dependencies
  - Protocol-based abstraction enables testing and flexibility

### **Repository Pattern with MVVM**
- [Modern MVVM + Repository Pattern in SwiftUI](https://medium.com/@gauravios/modern-mvvm-repository-pattern-in-swiftui-eca4f78fc2f5)
- [Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui)
  - **Key insight**: Repositories serve as "stateless gateways providing access to a single data service"
  - Error handling via `@Published var errorMessage: String?`
  - Services should be UI-independent for reusability

### **Single Responsibility Principle**
- [SOLID Principles in iOS Development](https://medium.com/@quasaryy/solid-principles-in-the-context-of-ios-development-e1bf8bf40e16)
  - Each service should have one well-defined responsibility
  - Delegate network/persistence to separate service classes
  - Avoid mixing UI, business logic, and data handling

---

## 🏗️ Service Structure

### **Standard Service Template**

```swift
import Foundation
import CoreData

/// Service for managing [Entity] operations
/// Handles CRUD operations and business logic for [Entity]
@MainActor
class [Entity]Service: ObservableObject {

    // MARK: - Properties

    private let viewContext: NSManagedObjectContext
    private let persistence: PersistenceController

    /// Published error message for view display
    @Published var errorMessage: String?

    /// Published loading state
    @Published var isLoading: Bool = false

    // MARK: - Initialization

    init(context: NSManagedObjectContext, persistence: PersistenceController = .shared) {
        self.viewContext = context
        self.persistence = persistence
    }

    // MARK: - Public API (Intent-Style Methods)

    /// Creates a new [entity] with the provided data
    /// - Parameters:
    ///   - param1: Description
    ///   - param2: Description
    /// - Returns: The created entity, or nil if creation failed
    func create[Entity](param1: Type1, param2: Type2) -> Entity? {
        clearError()
        isLoading = true
        defer { isLoading = false }

        let context = persistence.newBackgroundContext(for: .userEdit)

        do {
            // 1. Create entity using repository pattern
            let entity = [Entity]Repository.getOrCreate(
                // ... parameters
                in: context
            )

            // 2. Set properties
            entity.property1 = param1
            entity.property2 = param2

            // 3. Save context
            try context.save()

            print("✅ [Entity] created: \(entity.id)")
            return entity

        } catch {
            handleError("Failed to create [entity]", error: error)
            return nil
        }
    }

    /// Updates an existing [entity]
    /// - Parameters:
    ///   - entity: The entity to update
    ///   - param1: Updated value
    func update[Entity](_ entity: Entity, param1: Type1) {
        clearError()

        do {
            entity.property1 = param1
            try viewContext.save()
            print("✅ [Entity] updated: \(entity.id)")
        } catch {
            handleError("Failed to update [entity]", error: error)
        }
    }

    /// Deletes an [entity]
    /// - Parameter entity: The entity to delete
    func delete[Entity](_ entity: Entity) {
        clearError()

        viewContext.delete(entity)

        do {
            try viewContext.save()
            print("✅ [Entity] deleted: \(entity.id)")
        } catch {
            handleError("Failed to delete [entity]", error: error)
            viewContext.rollback()
        }
    }

    // MARK: - Error Handling

    /// Clears any existing error message
    private func clearError() {
        errorMessage = nil
    }

    /// Handles and publishes error messages
    /// - Parameters:
    ///   - message: User-friendly error message
    ///   - error: The underlying error
    private func handleError(_ message: String, error: Error) {
        errorMessage = message
        print("❌ \(message): \(error)")
    }
}
```

---

## 📋 Service Granularity Guidelines

### **Rule: One Service Per Entity Type (with exceptions)**

**Default Pattern - Entity-Specific Services:**
```swift
RecipeService          // Manages Recipe CRUD
IngredientTemplateService  // Manages IngredientTemplate CRUD
CategoryService        // Manages Category CRUD
```

**Exception - Parent-Child Relationships:**

When entities have tight parent-child relationships (like WeeklyList → GroceryListItem), use **Aggregate Services**:

```swift
/// Service managing WeeklyList and its GroceryListItems
/// Child items are tightly coupled to parent list lifecycle
class WeeklyListService: ObservableObject {

    // MARK: - WeeklyList Operations

    func createList(name: String) -> WeeklyList? { ... }
    func deleteList(_ list: WeeklyList) { ... }

    // MARK: - GroceryListItem Operations

    func addItem(to list: WeeklyList, name: String) -> GroceryListItem? { ... }
    func removeItem(_ item: GroceryListItem, from list: WeeklyList) { ... }
    func toggleItemChecked(_ item: GroceryListItem) { ... }
}
```

**Rationale from Research:**
- **Single Responsibility**: Each service focuses on one domain aggregate
- **Service Oriented Architecture**: Services should be responsible for "specific types of models and operations under these models"
- **Practical**: Prevents coordination overhead between services

---

## 🎯 Decision Matrix: When to Split vs Combine

| Scenario | Pattern | Example |
|----------|---------|---------|
| **Independent entities** | Separate services | `RecipeService`, `MealPlanService` |
| **Parent-child lifecycle** | Aggregate service | `WeeklyListService` (List + Items) |
| **Shared business logic** | Aggregate service | `MealPlanService` (Plan + PlannedMeals) |
| **Independent lifecycles** | Separate services | `IngredientTemplateService` (used by many entities) |

**When in doubt**: Start with one service per entity. Split only when complexity demands it.

---

## ⚠️ Error Handling Standard

### **Required Pattern: @Published errorMessage**

All services MUST implement this error handling pattern:

```swift
@MainActor
class SomeService: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private func clearError() {
        errorMessage = nil
    }

    private func handleError(_ message: String, error: Error) {
        errorMessage = message
        print("❌ \(message): \(error)")
    }
}
```

### **View Integration Pattern**

Views display errors using this standard approach:

```swift
struct SomeView: View {
    @EnvironmentObject var service: SomeService

    var body: some View {
        VStack {
            // Main content

            // Error display
            if let error = service.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            // Loading state
            if service.isLoading {
                ProgressView()
            }
        }
    }
}
```

---

## 🔄 Context Management

### **Background Context Pattern**

For write operations, prefer background contexts:

```swift
func createEntity() -> Entity? {
    let context = persistence.newBackgroundContext(for: .userEdit)

    do {
        let entity = Entity(context: context)
        // ... configure entity
        try context.save()
        return entity
    } catch {
        handleError("Failed to create entity", error: error)
        return nil
    }
}
```

### **ViewContext Usage**

Use `viewContext` only for:
- Simple updates to existing objects
- UI-driven changes that need immediate feedback
- Operations that don't block UI

```swift
func toggleItemChecked(_ item: GroceryListItem) {
    item.isChecked.toggle()

    do {
        try viewContext.save()
    } catch {
        handleError("Failed to update item", error: error)
        viewContext.rollback()
    }
}
```

### Store Assignment Pattern (ADR 014)
Services that create HouseholdScoped entities (`WeeklyList`, `Recipe`, `PlannedMeal`, `MealPlan`, `Category`, `IngredientTemplate`) MUST accept a `ManagedObjectFactory` and use `factory.make()` for creation. Add a `var factory: ManagedObjectFactory?` property and fall back to direct creation only when factory is nil (tests/previews).

---

## 📏 Existing Service Examples

### **Good Example: HouseholdService**

```swift
@MainActor
class HouseholdService: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var currentHousehold: Household?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func createHousehold(name: String, ownerName: String) async throws -> Household {
        // ... implementation with try/catch
        try viewContext.save()
        return household
    }
}
```

✅ **What's good:**
- Proper error handling with `@Published var errorMessage`
- Intent-style method names (`createHousehold`)
- Saves handled internally
- Clear responsibility (household management)

### **Good Example: MealPlanService**

```swift
class MealPlanService: ObservableObject {
    @Published var lastError: Error?

    func createMealPlan(startDate: Date? = nil) -> MealPlan? {
        // ... creates plan
        try context.save()
        return plan
    }

    func addRecipe(to plan: MealPlan, recipe: Recipe, date: Date) {
        // ... adds recipe to plan
        try context.save()
    }
}
```

✅ **What's good:**
- Aggregate service pattern (MealPlan + PlannedMeals)
- All writes go through service
- Logical grouping of operations

---

## ❌ Anti-Patterns to Avoid

### **1. Views Calling save() Directly**

```swift
// ❌ BAD
Button("Save") {
    ingredient.name = name
    try? viewContext.save()  // View owns persistence
}

// ✅ GOOD
Button("Save") {
    ingredientService.createTemplate(name: name, category: category)
}
```

### **2. Service Methods That Don't Save**

```swift
// ❌ BAD - Caller must remember to save
func createTemplate(name: String) -> IngredientTemplate {
    let template = IngredientTemplate(context: context)
    template.displayName = name
    return template  // No save! Caller must do it
}

// ✅ GOOD - Service owns the save
func createTemplate(name: String) -> IngredientTemplate? {
    let template = IngredientTemplate(context: context)
    template.displayName = name

    do {
        try context.save()
        return template
    } catch {
        handleError("Failed to create template", error: error)
        return nil
    }
}
```

### **3. Scattered Error Handling**

```swift
// ❌ BAD - Inconsistent error handling
func createA() {
    try? context.save()  // Silent failure
}

func createB() {
    do {
        try context.save()
    } catch {
        print("Error: \(error)")  // Console only
    }
}

// ✅ GOOD - Consistent pattern
func createA() {
    do {
        try context.save()
    } catch {
        handleError("Failed to create A", error: error)
    }
}

func createB() {
    do {
        try context.save()
    } catch {
        handleError("Failed to create B", error: error)
    }
}
```

---

## 🧪 Testing Benefits

This pattern enables true unit testing:

```swift
class MockRecipeService: RecipeService {
    var createRecipeCalled = false
    var mockError: String?

    override func createRecipe(title: String) -> Recipe? {
        createRecipeCalled = true

        if let error = mockError {
            errorMessage = error
            return nil
        }

        return Recipe(context: viewContext)
    }
}

// In tests
func testRecipeCreationError() {
    let mockService = MockRecipeService()
    mockService.mockError = "Test error"

    let result = mockService.createRecipe(title: "Test")

    XCTAssertNil(result)
    XCTAssertEqual(mockService.errorMessage, "Test error")
}
```

---

## 📊 M7.5 Implementation Checklist

When implementing M7.5 Phase 1, use this checklist for each service:

### **Creating New Service**

- [ ] Create `[Entity]Service.swift` in `Services/` folder
- [ ] Implement `@Published var errorMessage: String?`
- [ ] Implement `@Published var isLoading: Bool = false`
- [ ] Add `private func clearError()`
- [ ] Add `private func handleError(_ message: String, error: Error)`
- [ ] Implement intent-style methods (create, update, delete)
- [ ] All methods handle saves internally
- [ ] Use background context for writes where appropriate
- [ ] Add to `foragerApp.swift` `.environmentObject()`

### **Refactoring Views**

- [ ] Add `@EnvironmentObject var service: [Entity]Service`
- [ ] Replace all `try? viewContext.save()` with service calls
- [ ] Replace all `try viewContext.save()` with service calls
- [ ] Add error display using `service.errorMessage`
- [ ] Add loading indicator using `service.isLoading`
- [ ] Test all user flows work identically

### **Verification**

- [ ] No `viewContext.save()` calls remain in view
- [ ] All writes go through service
- [ ] Error handling consistent
- [ ] Build succeeds
- [ ] All features work

---

## 🔗 Related Documents

- [M7.5 PRD](../prds/complete/m7.5-architecture-hardening-ux-service-cleanup.md) - Full implementation plan
- [ADR 008: Shared Zone Architecture](008-shared-zone-architecture.md) - Dual-store context
- [session-startup-checklist.md](../session-startup-checklist.md) - Reference during sessions

---

## 📝 Research Sources

This pattern is validated by industry best practices:

- [App architecture basics in SwiftUI Part 4: Services](https://www.cocoawithlove.com/blog/separated-services-layer.html) - Service layer separation
- [Modern MVVM + Repository Pattern in SwiftUI](https://medium.com/@gauravios/modern-mvvm-repository-pattern-in-swiftui-eca4f78fc2f5) - Repository pattern
- [Implementing MVVM, Repository & Service Pattern with SwiftUI](https://medium.com/@mkaakati/implementing-mvvm-with-swiftui-2b2c56c9a2cf) - MVVM + Services
- [Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui) - Clean architecture principles
- [SOLID Principles in iOS Development](https://medium.com/@quasaryy/solid-principles-in-the-context-of-ios-development-e1bf8bf40e16) - Single Responsibility

---

**Status**: ACTIVE - Use this pattern for all M7.5+ development
**Version**: 1.0
**Last Updated**: January 13, 2026
