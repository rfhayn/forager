# Next Implementation Prompt

**Last Updated**: January 2, 2026  
**For Milestone**: M7.2.3 - CloudKit Hardening & Shared Data Architecture  
**Status**: 🚀 **PHASE 2.6 READY - Infrastructure Complete**  
**Estimated Duration**: 2-3 hours (Phase 2.6)

---

## ✅ **PHASES 0-2.5 COMPLETE** (Jan 2, 2026)

**Completed Work**:
- ✅ Phase 0: Core Data Model v2 with household relationships (2h)
- ✅ Phase 2.1: DataScope enum & HouseholdScoped protocol (20min)
- ✅ Phase 2.2: HouseholdScopeProvider @MainActor service (15min)
- ✅ Phase 2.3: ManagedObjectFactory with generic create() (20min)
- ✅ Phase 2.4: Environment injection in foragerApp.swift (10min)
- ✅ Phase 2.5: Protocol activation & manual Core Data files (1.75h)

**Current State**:
- ✅ Build successful (0 errors)
- ✅ All infrastructure complete and activated
- ✅ 12 manual Core Data files created (6 entities × 2 files)
- ✅ Protocol conformances enforced
- ⚠️ **Factory exists but nothing uses it yet**
- ⚠️ **Design challenge: Background context pattern needed**

**What's Next**: Phase 2.6 - Update Creation Points (2-3 hours)

---

## 🚨 **CRITICAL DESIGN CHALLENGE - READ FIRST**

### **The Problem**

Most entity creation happens in background contexts via:
```swift
PersistenceController.performWrite { context in
    let recipe = Recipe(context: context)
    // ... configure recipe
}
```

**But our factory requires**:
1. `HouseholdScopeProvider` (from @Environment)
2. `@MainActor` isolation
3. Access to current scope state

**This doesn't work in background contexts** because:
- ❌ No access to @Environment values
- ❌ Background thread ≠ @MainActor
- ❌ Can't pass ObservableObject across threads

### **Potential Solutions to Explore**

**Option A: Pass ObjectID explicitly**
```swift
// On main thread
let scopeObjectID = scopeProvider.currentHouseholdObjectID

// In background context
PersistenceController.performWrite { context in
    let factory = ManagedObjectFactory(householdObjectID: scopeObjectID)
    let recipe = factory.create(Recipe.self, in: context)
}
```
**Pros**: Simple, thread-safe  
**Cons**: Couples creation to household knowledge

---

**Option B: Extend PersistenceController.performWrite**
```swift
// New method
func performWrite(
    scope: DataScope,
    _ block: @escaping (NSManagedObjectContext, ManagedObjectFactory) -> Void
) {
    performWrite { context in
        let factory = ManagedObjectFactory(scope: scope)
        block(context, factory)
    }
}
```
**Pros**: Clean API, encapsulates pattern  
**Cons**: Duplicates performWrite logic

---

**Option C: Factory per context**
```swift
extension NSManagedObjectContext {
    func createEntity<T: NSManagedObject>(
        _ type: T.Type,
        scope: DataScope
    ) -> T {
        let factory = ManagedObjectFactory(scope: scope)
        return factory.create(type, in: self)
    }
}
```
**Pros**: Context-aware, discoverable  
**Cons**: Scope still needs to be passed

---

**Option D: Main thread creation only**
```swift
// Only create on main thread with view context
// Use factory directly with @Environment
let recipe = factory.create(Recipe.self, in: viewContext)
```
**Pros**: Simple, uses infrastructure as-is  
**Cons**: Blocks UI, not scalable for bulk operations

---

### **Recommended Approach: Start with Option D, Evolve to A**

1. **Phase 2.6a**: Update 1-2 simple view-based creation points
   - Use factory directly in views with viewContext
   - Validate household relationships work
   - **Duration**: 30-45 minutes

2. **Phase 2.6b**: Prototype background pattern
   - Implement Option A for one background case
   - Test with performWrite
   - **Duration**: 45-60 minutes

3. **Phase 2.6c**: Decide on final pattern
   - Based on 2.6b results
   - Update remaining creation points
   - **Duration**: 45-60 minutes

---

## 📋 **PHASE 2.6a: SIMPLE VIEW-BASED CREATION** (30-45 min)

### **Goal**: Validate factory works in simplest case first

**Target**: WeeklyListsView (creates lists on main thread)

**Current Code** (WeeklyListsView.swift):
```swift
private func createList() {
    let newList = WeeklyList(context: viewContext)
    newList.id = UUID()
    newList.name = "Week of \(formatDate(Date()))"
    newList.dateCreated = Date()
    // ... etc
}
```

**Updated Code** (with factory):
```swift
@Environment(\.managedObjectContext) private var viewContext
@Environment(ManagedObjectFactory.self) private var factory  // ADD THIS

private func createList() {
    let newList = factory.create(WeeklyList.self, in: viewContext)  // USE FACTORY
    newList.id = UUID()
    newList.name = "Week of \(formatDate(Date()))"
    newList.dateCreated = Date()
    // household relationship automatically set by factory!
    
    do {
        try viewContext.save()
    } catch {
        print("Error creating list: \(error)")
    }
}
```

**Validation Steps**:
1. Launch app
2. Create a new weekly list
3. In debugger, check: `po newList.household`
4. Should be nil (personal scope) OR set (if household scope active)
5. Verify app doesn't crash

**Success Criteria**:
- ✅ List creates successfully
- ✅ Factory called without errors
- ✅ Household relationship matches current scope
- ✅ No performance degradation

---

## 📋 **PHASE 2.6b: BACKGROUND CONTEXT PATTERN** (45-60 min)

### **Goal**: Establish pattern for background creation

**Target**: DefaultSeeder.swift (creates default categories in background)

**Current Code** (DefaultSeeder.swift):
```swift
persistence.performWrite { context in
    let category = Category(context: context)
    category.id = UUID()
    category.name = "Produce"
    // ...
}
```

**Option A Implementation** (pass ObjectID):
```swift
// 1. Add method to HouseholdScopeProvider
extension HouseholdScopeProvider {
    var currentHouseholdObjectID: NSManagedObjectID? {
        guard case .household(let objectID) = currentScope else {
            return nil
        }
        return objectID
    }
}

// 2. Update DefaultSeeder
func seedDefaultCategories(
    householdObjectID: NSManagedObjectID? = nil
) {
    persistence.performWrite { context in
        let scope: DataScope = if let hhID = householdObjectID {
            .household(hhID)
        } else {
            .personal
        }
        
        let factory = ManagedObjectFactory(scope: scope)
        let category = factory.create(Category.self, in: context)
        category.id = UUID()
        category.name = "Produce"
        // household set automatically!
    }
}
```

**Validation Steps**:
1. Delete app, reinstall (triggers seeding)
2. Check default categories have household = nil (personal scope)
3. Create household, delete app, reinstall
4. Check default categories have household set (household scope)

**Success Criteria**:
- ✅ Seeding works in both scopes
- ✅ No threading issues
- ✅ Clean, maintainable pattern

---

## 📋 **PHASE 2.6c: FINALIZE PATTERN** (45-60 min)

### **Goal**: Update remaining creation points

**Targets** (in order of complexity):
1. RecipeListView - creating recipes (view context)
2. IngredientsView - creating ingredients (view context)  
3. MealPlanListView - creating meal plans (view context)
4. IngredientTemplateService - background operations

**Pattern to Apply**:
- **View contexts**: Use factory directly with @Environment
- **Background contexts**: Pass householdObjectID explicitly

**Validation**: 
After each update:
1. Test the creation flow
2. Verify household relationship
3. Ensure no crashes or performance issues

---

## 🎯 **AFTER PHASE 2.6 COMPLETE**

### **Git Workflow**:
```bash
# Commit Phase 2.6 work
git add forager/WeeklyListsView.swift
git add Services/DefaultSeeder.swift
git add Services/Persistence/HouseholdScopeProvider.swift
git add forager/RecipeListView.swift
# ... other updated files

git commit -m "M7.2.3 Phase 2.6: Update creation points to use ManagedObjectFactory

✅ Completed:
- Updated WeeklyListsView to use factory (view context)
- Updated DefaultSeeder with background context pattern
- Established householdObjectID passing pattern
- Updated 4 additional creation points

🏗️ Pattern Established:
- View contexts: Use factory via @Environment
- Background contexts: Pass householdObjectID explicitly
- Thread-safe, maintainable approach

✅ Validation:
- All creation flows tested
- Household relationships set correctly
- No performance degradation
- Zero crashes or errors

📊 Metrics:
- Estimated: 2-3h
- Actual: [X]h

🎯 Next: Phase 4 - Attach-then-share migration (3-4h)"

git push origin feature/M7.2.3-prep-phase
```

### **Update Documentation**:
1. Mark Phase 2.6 ✅ COMPLETE in `current-story.md`
2. Update progress: 52% → 68% (10.25h → 13.25h)
3. Create learning note about background context pattern
4. Update `next-prompt.md` for Phase 4

### **Begin Phase 4** (if time permits):
- Read PRD v2.2 Phase 4 section
- Implement attach-then-share migration UI
- Expected duration: 3-4 hours

---

## 📚 **KEY REFERENCES**

**PRD v2.2 FINAL**: `docs/prds/m7.2.3-cloudkit-hardening-household-repositories.md`
- Lines 425-582: Phase 2 (Scope-based store assignment) ← **READ THIS**
- Lines 583-741: Phase 4 (Attach-then-share migration)
- Lines 1511-1564: Version history & polish integrations

**Existing Code to Study**:
- `Services/Persistence/ManagedObjectFactory.swift` - How factory works
- `Services/Persistence/HouseholdScopeProvider.swift` - Scope management
- `Services/PersistenceController.swift` - Background context usage
- `forager/WeeklyListsView.swift` - Simple creation example

**Key Concepts**:
- **Thread safety**: ObjectID is thread-safe, ObservableObject is not
- **@MainActor isolation**: Environment values only on main thread
- **Background contexts**: Need explicit scope passing
- **Factory pattern**: Centralizes household assignment logic

---

## 🚨 **CRITICAL REMINDERS**

1. **Start simple** - Get view context working before background
2. **Test incrementally** - Validate after each creation point update
3. **Document the pattern** - Future developers need to understand approach
4. **Don't over-engineer** - If Option A works, don't complicate further
5. **Household can be nil** - Personal scope is valid and expected

---

## 💭 **DESIGN DECISIONS TO MAKE**

Before starting Phase 2.6, decide:

1. **Do we need background creation right away?**
   - Could defer to Phase 5 if view context works
   - Most user actions happen on main thread anyway

2. **What's the acceptable API?**
   - Passing ObjectID feels explicit and safe
   - Worth the extra parameter?

3. **Should we update ALL creation points now?**
   - Or just enough to validate the pattern?
   - Can always update more later

**Recommendation**: Start with 2-3 creation points, establish pattern, evaluate before updating all.

---

**Version**: January 2, 2026 - Phase 2.6 Ready  
**Status**: 🚀 Infrastructure complete, creation points next  
**Progress**: 52% complete (10.25h / 19.5h)  
**Design Challenge**: Background context pattern (Options A-D outlined above)
