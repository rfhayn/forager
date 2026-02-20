# Learning Note 36: Core Data Runtime Pitfalls

**Milestone**: M15 — UX Design System & Testing Bug Fixes
**Date**: February 20, 2026
**Scope**: Save timing, rollback state, template deduplication, display field semantics

---

## Context

M15 testing revealed five Core Data runtime behaviors that compile cleanly but produce incorrect results at runtime. Unlike schema or migration issues (covered in LN 31), these are runtime data-integrity problems — the database structure is correct, but the code that reads/writes it has subtle ordering or semantic bugs.

---

## 1. Async Save + Synchronous Dismiss = Unreachable Errors

When using `performWrite` (async background context), calling `dismiss()` synchronously after the write call makes `onError` unreachable — the view is gone before the error callback fires.

```swift
// BUG: dismiss() runs before onError can fire
performWrite { context in
    // ... mutate ...
} onError: { error in
    errorMessage = error.localizedDescription  // View already dismissed!
    showingError = true
}
dismiss()  // Runs immediately, before async write completes
```

**Fix**: Move `dismiss()` into the `onSuccess` callback. Errors can then still be shown to the user.

```swift
performWrite { context in
    // ... mutate ...
} onSuccess: {
    dismiss()  // Only after confirmed save
} onError: { error in
    errorMessage = error.localizedDescription
    showingError = true
}
```

---

## 2. Incomplete Rollback on Save Failure

When reverting a failed `viewContext.save()`, you must capture ALL original values before mutation — not just the primary field.

```swift
// BUG: only captures isCompleted, not dateCompleted
item.isCompleted.toggle()
item.dateCompleted = item.isCompleted ? Date() : nil

do {
    try viewContext.save()
} catch {
    item.isCompleted.toggle()  // Reverted
    // item.dateCompleted is now nil — LOST the original date!
}
```

**Fix**: Capture all mutable fields before mutation:

```swift
let wasCompleted = item.isCompleted
let originalDate = item.dateCompleted

item.isCompleted.toggle()
item.dateCompleted = item.isCompleted ? Date() : nil

do {
    try viewContext.save()
} catch {
    item.isCompleted = wasCompleted
    item.dateCompleted = originalDate
}
```

**Pattern**: Before any multi-field mutation with a save that could fail, create a snapshot of all fields you're about to change.

---

## 3. Template Deduplication Requires Two Passes

Template deduplication that only normalizes names can create new collisions that it doesn't detect.

**Pass 1** (rename): `normalizePlural()` changes "Strawberry" → "strawberries" and "strawberries" → "strawberries". Two templates now have the same name.

**Pass 2** (merge): Group by `canonicalName`, find duplicates, merge usage data and relationships into one survivor, delete the rest.

The original `migrateExistingTemplates()` only did Pass 1. It renamed templates but never checked if two now collide.

Additionally, `canonicalName` (simple lowercase) had diverged from `normalize()` (4-phase pipeline). Templates created at different times could have matching display names but different canonicals — invisible to dedup.

**Fix**: Always sync `canonicalName = normalize(name).lowercased()` and run the merge pass after renaming.

```swift
// After normalization pass:
let allTemplates = try context.fetch(IngredientTemplate.fetchRequest())
let grouped = Dictionary(grouping: allTemplates, by: { $0.canonicalName ?? "" })
for (_, duplicates) in grouped where duplicates.count > 1 {
    let survivor = duplicates.first!
    for dupe in duplicates.dropFirst() {
        // Merge relationships and usage data to survivor
        // Delete dupe
    }
}
```

---

## 4. Display Field vs Identity Field Semantics

`GroceryListItem.name` serves double duty as both a display field and an identity/matching field. When these semantics diverge, things break.

**Original pattern**: `name` stored the template name ("garlic"). A separate `displayText` column held the full text ("2 cloves garlic"). Removal of redundant display was planned.

**After removing displayText duplication**: `name` must now contain the full ingredient text ("2 cloves garlic") for the quantity to be visible. But template matching code still expected `name` to hold just the ingredient name ("garlic").

**Fix**: Use `name` for display (full text with quantity), and derive a `cleanName` variable for matching:

```swift
// Display: item.name = "2 cloves garlic"
// Matching: use parsed name from IngredientParsingService
let parsed = parsingService.parseIngredient(text: item.name ?? "")
let cleanName = parsed.name  // "garlic"
```

**Principle**: When a field serves multiple purposes, either split it into two fields or clearly document which code path uses which interpretation.

---

## 5. EditRecipeView Must Mirror CreateRecipeView

When `EditRecipeView.completeSave()` deletes and recreates `Ingredient` entities (the standard edit pattern), any fields not explicitly set are zero/nil — unlike updates where existing values persist.

```swift
// CREATE path (CreateRecipeView) — sets everything:
ingredient.name = parsed.displayName
ingredient.displayText = structured.displayText
ingredient.numericValue = structured.numericValue ?? 0.0
ingredient.standardUnit = structured.standardUnit
ingredient.isParseable = structured.isParseable
ingredient.parseConfidence = structured.parseConfidence

// EDIT path (EditRecipeView) — was missing structured fields:
ingredient.name = parsed.displayName
// Everything else = 0/nil!  Quantities vanish after editing.
```

**Fix**: Copy the full field-setting block from `CreateRecipeView` to `EditRecipeView`. These two paths must remain in sync.

**Prevention**: Extract a shared `configureIngredient(from:)` method on Ingredient or a service so both paths call the same code. (Planned for M9 service layer cleanup.)

---

## Summary

| Pitfall | Data Impact | Detection |
|---------|-------------|-----------|
| Async save + sync dismiss | Errors silently swallowed | Trigger a save error — alert never appears |
| Incomplete rollback | Field values permanently lost | Toggle + fail save + check field state |
| Single-pass dedup | Duplicate templates persist | Query `GROUP BY canonicalName HAVING COUNT > 1` |
| Display/identity field confusion | Quantities invisible or matching broken | Add ingredient from recipe → check grocery list display |
| Edit not mirroring create | Structured fields zeroed after edit | Edit recipe → verify quantities survive |

---

**Promoted from**: Insights Log entries — CoreData/AsyncDismiss (Feb 18), CoreData/RollbackState (Feb 18), CoreData/TemplateDuplication (Feb 20), CoreData/GroceryItemName (Feb 20), SwiftUI/EditRecipe (Feb 20)
