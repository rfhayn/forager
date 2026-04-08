# Spec: Store-Aware Shopping

## Overview

Store preference system that layers on top of existing category-based grocery organization, enabling users who shop at multiple stores (e.g., Costco, Heinen's, Target) to assign preferred stores to ingredient templates and view grocery lists grouped by store. The feature is invisible by default -- zero store UI until the user creates their first store. Store preferences are household-shared.

## Requirements

- REQ-001: The system MUST support a Store entity (schema v11) with name, hex color, sortOrder, householdKey, and household relationship, created via ManagedObjectFactory as a HouseholdScoped entity.
  - Scenario: Given a user creates a store "Costco" with blue color, When the store saves, Then a Store entity exists with name="Costco", color="#0000FF", sortOrder based on creation order, and correct householdKey.

- REQ-002: The system MUST support assigning a preferred store to IngredientTemplate entities via an optional preferredStore relationship.
  - Scenario: Given the user assigns "Costco" as the preferred store for "Paper Towels", When a recipe adds "Paper Towels" to a grocery list, Then the GroceryListItem snapshot captures store=Costco.

- REQ-003: The system MUST snapshot the template's preferred store onto GroceryListItem at creation time, following the same pattern as category snapshotting -- the snapshot does NOT auto-update if the template preference changes later.
  - Scenario: Given "Milk" has preferredStore="Heinen's", When the user adds milk to a list, Then GroceryListItem.store is set to "Heinen's"; When the user later changes milk's preferred store to "Target", Then the existing grocery list item still shows "Heinen's".

- REQ-004: The system MUST provide a "Group by Store" toggle in the grocery list toolbar that switches between category grouping (default) and store grouping.
  - Scenario: Given a grocery list with items from 3 stores, When the user taps "Group by Store", Then items reorganize into store sections with color-coded headers; items with no store appear in an "Unassigned" section.

- REQ-005: The system MUST support nested grouping in store view: Store sections contain Category sub-sections contain items.
  - Scenario: Given 10 items across 2 stores and 4 categories, When viewing in store grouping mode, Then items appear as Store > Category > Items hierarchy (e.g., "Costco > Produce > Bananas").

- REQ-006: The system MUST provide a Manage Stores view (accessible from Settings) for creating, editing, reordering, and deleting stores with color picker and suggested store name chips.
  - Scenario: Given the user opens Settings > Stores, When they tap Add Store, Then a form appears with a name field, color picker, and suggested chips ("Costco", "Walmart", "Target", etc.); the new store appears in the reorderable list.

- REQ-007: The system MUST display store color dots as visual indicators on grocery list items when a store is assigned.
  - Scenario: Given "Paper Towels" is assigned to Costco (blue), When the item appears in the grocery list, Then a small blue color dot appears next to the item name.

- REQ-008: The system MUST support store deletion with reassignment -- deleting a store offers to reassign its items to another store or leave them unassigned.
  - Scenario: Given "Target" has 5 items assigned, When the owner deletes Target and chooses to reassign to "Walmart", Then all 5 GroceryListItems and their IngredientTemplates update to Walmart.

- REQ-009: The system MUST be invisible by default -- zero stores means zero store UI. No store-related controls appear until the user creates their first store.
  - Scenario: Given a user with zero stores, When they view a grocery list, Then no "Group by Store" toggle appears, no color dots show, and no store section appears in Settings.

- REQ-010: The system MUST use resolveStore(for:targetList:) for cross-store CloudKit safety when adding items, mirroring the resolveCategory() pattern.
  - Scenario: Given a member device receives a grocery item with a store reference from the owner's zone, When the item is processed, Then resolveStore safely resolves the store reference across CloudKit stores without crashing.

## Implementation Notes

- Store entity added in schema v11 (lightweight migration from v10, append-only, CloudKit safe)
- Store is HouseholdScoped: uses ManagedObjectFactory.make(), has householdKey + household relationship
- StoreService provides CRUD, assignment, query, and cross-store resolution
- GroceryListItemService modified to snapshot store in all 3 creation paths (addItem, addIngredients batch, addStaples)
- Fetch index: byStoreSortOrder on (sortOrder ASC, name ASC)
- Feature origin: Beta tester feedback -- categories express *what* you buy, stores express *where* you buy
- M18 is ACTIVE with all 6 sub-milestones complete, pending PR merge
