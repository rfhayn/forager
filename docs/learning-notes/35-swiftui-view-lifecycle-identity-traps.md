# Learning Note 35: SwiftUI View Lifecycle & Identity Traps

**Milestone**: M15 — UX Design System
**Date**: February 20, 2026
**Scope**: View identity, @FetchRequest limitations, environment scoping, animation guards

---

## Context

M15's comprehensive UI refresh touched nearly every view in the app. Six non-obvious SwiftUI behaviors surfaced that can cause crashes, infinite loops, or silent data staleness. These are "traps" in the sense that the code compiles cleanly and may even work in simple cases, but fails under specific conditions.

---

## 1. `.id()` + `.onAppear` Mutation = Infinite Loop

Setting `.id(stateVar)` on a view and then mutating `stateVar` in `.onAppear` creates an infinite loop:

1. SwiftUI renders the view with `id = X`
2. `.onAppear` fires, sets `stateVar` to `Y`
3. SwiftUI treats `id = Y` as a **new view** — destroys the old one, creates a new one
4. `.onAppear` fires again on the new view
5. Repeat forever → crash or freeze

```swift
// CRASH: infinite recreation loop
@State private var refreshToken = UUID()

SomeView()
    .id(refreshToken)
    .onAppear { refreshToken = UUID() }  // Never do this
```

**Fix**: If you need to force a view refresh, use `viewContext.refreshAllObjects()` or a `@State` toggle that doesn't feed into `.id()`. Only use `.id()` with values controlled by the **parent**, not the view itself.

---

## 2. `@FetchRequest` Is Blind to Relationship Changes

`@FetchRequest` observes direct attribute changes on its entity but does NOT re-trigger for changes that propagate through relationships.

Example: `GroceryListItem` has `categoryName` that's derived from display logic involving `ingredientTemplate?.category`. When you recategorize a template, the item's effective category changes — but the item entity itself is untouched. SwiftUI sees no change, so the fetch request doesn't re-fire.

```swift
// This fetch request won't update when related template changes:
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \GroceryListItem.sortOrder, ascending: true)]
) var items: FetchedResults<GroceryListItem>
```

**Fix**: Call `viewContext.refreshAllObjects()` on `.onAppear` or in response to a known mutation event. This forces Core Data to re-fault all objects, making relationship-derived values re-evaluate on next access.

**Caveat**: `refreshAllObjects()` has a performance cost — it invalidates the entire object graph cache. Use it surgically (on view appearance after a known mutation), not on every render.

---

## 3. `@Environment` Properties Are Per-Struct Scoped

`@Environment(\.accessibilityReduceMotion)` must be declared on the specific `struct` that uses it — not a parent struct in the same file.

When `RecipeListView.swift` contains both `RecipeListView` and `RecipeDetailView` as separate structs, adding `reduceMotion` only to `RecipeListView` causes "cannot find in scope" when `RecipeDetailView` references it.

```swift
// FILE: RecipeListView.swift

struct RecipeListView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion  // Only visible HERE
    var body: some View { ... }
}

struct RecipeDetailView: View {
    // @Environment(\.accessibilityReduceMotion) var reduceMotion  // MUST declare separately
    var body: some View {
        // reduceMotion  // ERROR: "cannot find in scope"
    }
}
```

Each struct is a separate scope. This applies to all `@Environment`, `@EnvironmentObject`, and `@State` properties.

---

## 4. Async Task Re-Loading on View Extraction

When extracting a view from a parent (e.g., `SettingsView` → `HouseholdView`), async data that was loaded in the parent's `.task` must be re-loaded in the child's own `.task`.

Don't assume the parent passes down pre-loaded state. The child view may be navigated to independently (via deep link, notification, or Settings row tap).

```swift
// HouseholdView must load its own data
struct HouseholdView: View {
    @State private var members: [HouseholdMember] = []

    var body: some View {
        List(members) { ... }
            .task { await loadHouseholdData() }  // Don't rely on parent
    }
}
```

---

## 5. `@ScaledMetric` for Zero-Effort Dynamic Type

`@ScaledMetric(relativeTo:)` makes fixed-size UI elements respect Dynamic Type with no additional code:

```swift
// Before: fixed size, ignores Dynamic Type
var size: CGFloat = 56

// After: scales with user's text size preference
@ScaledMetric private var size: CGFloat = 56
```

The `relativeTo:` parameter ties scaling to a specific text style so the element scales proportionally to nearby text. Applied in Forager to `ForagerProgressRing` (56pt ring) and `MealPlanSummaryCard` day circles (22pt).

---

## 6. Animation Guard Pattern for Reduce Motion

The correct pattern for respecting `accessibilityReduceMotion`:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Decorative animations: nil = instant, no animation
withAnimation(reduceMotion ? nil : .spring(response: 0.35)) {
    showContent = true
}

// State-change animations: brief crossfade so user sees something happened
withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.35)) {
    isExpanded.toggle()
}
```

Passing `nil` as the animation parameter makes the state change instant. For state changes where some visual feedback is needed for UX clarity, `.easeInOut(duration: 0.15)` is fast enough to not trigger motion sensitivity but visible enough to confirm the action.

Applied across 10 view structs in M15.7.

---

## Summary

| Trap | Severity | Symptom | Fix |
|------|----------|---------|-----|
| `.id()` + `.onAppear` mutation | Critical | Infinite loop / crash | Don't mutate `.id()` source in `.onAppear` |
| `@FetchRequest` relationship blindness | High | Stale UI after relationship changes | `refreshAllObjects()` on appearance |
| `@Environment` per-struct scope | Medium | Compile error in sibling struct | Declare on each struct that uses it |
| Missing async task on extraction | Medium | Empty data in extracted view | Each view loads its own data |
| `@ScaledMetric` | Low (opportunity) | Fixed sizes ignore Dynamic Type | Replace `var` with `@ScaledMetric` |
| Animation reduce motion guard | Medium | Accessibility violation | `nil` for decorative, brief ease for state |

---

**Promoted from**: Insights Log entries — SwiftUI/ViewIdentity (Feb 20), CoreData/FetchRequest (Feb 20), SwiftUI/Accessibility (Feb 17), SwiftUI/ViewExtraction (Feb 17), SwiftUI/Animation (Feb 17)
