## ADDED Requirements

### Requirement: Import persist-and-finish preserves updated-in-place entities

`RecipeImportService.persistAndFinish` SHALL expose an optional `preserveUpdated: Set<NSManagedObject>` parameter identifying entities whose pending edits MUST survive the cross-store-safety `refresh(mergeChanges: false)` loop. The refresh loop SHALL exclude any object whose `objectID` matches an `objectID` in `preserveUpdated`. Comparison is by `objectID`, not object identity, because the caller may pass a child-context reference while the refresh iterates viewContext's updatedObjects (different NSManagedObject instances sharing the same objectID after child→parent propagation).

`replaceExistingRecipe` SHALL pass `preserveUpdated: [recipe]` so the user's new title, instructions, prep/cook time, servings, sourceURL, tags, imageURL, and author survive the save. `saveImport` SHALL use the default empty set because it inserts a new recipe (the `!obj.isInserted` clause already excludes inserted objects from the refresh).

#### Scenario: Replace-existing-recipe preserves field edits

- **WHEN** `RecipeImportService.replaceExistingRecipe(objectID:with:)` is invoked with a draft whose title differs from the existing recipe's title
- **THEN** after save, the recipe's title matches the draft's title (previously: the refresh loop discarded pending edits, reverting the recipe to its pre-edit state)

#### Scenario: Replace-existing-recipe preserves new ingredient set

- **WHEN** `replaceExistingRecipe` is invoked with a draft containing different ingredients than the existing recipe
- **THEN** after save, the recipe's `ingredients` relationship contains exactly the new draft ingredients (the old ingredients were deleted in the child context and the new ones inserted)

#### Scenario: Save-import remains unchanged

- **WHEN** `RecipeImportService.saveImport(from:)` is invoked
- **THEN** `persistAndFinish` is called with the default empty `preserveUpdated` set, AND the cross-store-safety refresh loop still runs on all pre-existing updated objects (preserving the M9.23 fix for 134040 validation errors), AND the new recipe is inserted and saved correctly

#### Scenario: Refresh loop preserves non-matching updated objects

- **WHEN** `persistAndFinish` runs the refresh loop with a non-empty `preserveUpdated` set
- **THEN** objects whose `objectID` is NOT in the `preserveUpdated` set are still refreshed with `mergeChanges: false` (maintaining the cross-store validation fix from M9.23)
