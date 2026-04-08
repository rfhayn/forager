# Spec: Recipes

## Overview

Recipe management including manual creation/editing, multi-source import (URL, text paste, camera/OCR), ingredient parsing with template alignment, recipe scaling, favorites, usage tracking, hero images, source attribution, and one-tap grocery list generation. Recipes are the content backbone of the app, feeding into meal planning and grocery list workflows.

## Requirements

- REQ-001: The system MUST provide a recipe catalog view with search across name, ingredients, tags, and instructions, plus filtering by favorites and recents.
  - Scenario: Given 50 recipes in the catalog, When the user searches "chicken", Then all recipes containing "chicken" in title, ingredients, tags, or instructions appear in results within 0.2 seconds.

- REQ-002: The system MUST support full recipe CRUD with title, ingredients, instructions, prep time, cook time, servings, tags, and notes.
  - Scenario: Given the user taps "New Recipe", When they fill in title, add 5 ingredients via parse-then-autocomplete, enter instructions, and tap Save, Then a Recipe entity is created with all fields persisted and ingredients linked to IngredientTemplates.

- REQ-003: The system MUST import recipes from URLs by extracting structured data from JSON-LD (including @graph wrappers, array @type, HowToStep instructions, and __NEXT_DATA__ payloads), with WKWebView fallback for client-rendered pages.
  - Scenario: Given a user pastes a URL from allrecipes.com, When the import runs, Then JSON-LD extraction pulls title, ingredients, instructions, prep/cook times, servings, image URL, and author within 2 seconds.

- REQ-004: The system MUST import recipes from pasted plain text using Foundation Models (iPhone 15 Pro+ / iPad M1+) with heuristic fallback on older devices.
  - Scenario: Given a user pastes a recipe from a message, When the system processes the text, Then Foundation Models (or heuristic fallback) classify lines into title, ingredients, and instructions with 90%+ accuracy.

- REQ-005: The system MUST import recipes from camera photos using VNRecognizeTextRequest OCR with section-aware classification.
  - Scenario: Given a user photographs a cookbook page, When OCR processes the image, Then text is recognized with 100% confidence on clean printed text, and section headers boost classification accuracy to 90%+.

- REQ-006: The system MUST use a draft-first import workflow where no Recipe entity exists until the user taps Save, with full preview and editing capability before persistence.
  - Scenario: Given a URL extraction completes, When the user reviews the ImportDraftRecipe preview, Then they can edit any field before saving; cancelling creates zero entities in Core Data.

- REQ-007: The system MUST persist imageURL and author on the Recipe entity (schema v11) for source attribution and future image display.
  - Scenario: Given a recipe imported from a URL with an image and author, When the user saves the import, Then Recipe.imageURL and Recipe.author are populated and the detail view shows a hero image via AsyncImage and author attribution.

- REQ-008: The system MUST support recipe scaling from 0.25x to 4x with kitchen-friendly fraction display (e.g., 1.5 displays as "1 1/2") and non-destructive preview.
  - Scenario: Given a recipe serving 4 with "2 cups flour", When the user scales to 8 servings (2x), Then the preview shows "4 cups flour" without modifying the original recipe.

- REQ-009: The system MUST add recipe ingredients to a grocery list in one tap with category preservation and template alignment.
  - Scenario: Given a recipe with 8 ingredients, When the user taps "Add to List" and selects a weekly list, Then all 8 ingredients are added as GroceryListItems with correct categories inherited from their IngredientTemplates.

- REQ-010: The system MUST provide parse-then-autocomplete for ingredient entry using fuzzy matching against existing IngredientTemplates.
  - Scenario: Given the user types "chick" in the ingredient field, When autocomplete activates, Then suggestions "Chicken breast", "Chicken thigh", "Chickpeas" appear within 0.1 seconds from the template database.

- REQ-011: The system MUST support a grid/list toggle for the recipe catalog, where grid mode shows image cards using Recipe.imageURL.
  - Scenario: Given the user is in list mode viewing recipes, When they tap the grid toggle, Then recipes display as image cards in a grid layout using AsyncImage for hero images.

- REQ-012: The system MUST track recipe usage (usageCount, lastUsed) and support favorite toggling for quick access.
  - Scenario: Given a recipe is added to a meal plan, When the assignment saves, Then Recipe.usageCount increments and Recipe.lastUsed updates to the current date.

- REQ-013: The system MUST validate imported recipes through the same RecipeFormData.validate() gate as manual creation: title at least 3 characters, servings 1-99, at least 1 ingredient, instructions non-empty.
  - Scenario: Given an import extraction returns a recipe with an empty title, When the user views the preview, Then the Save button is disabled until the user provides a valid title.

## Implementation Notes

- Import architecture uses the strategy pattern: RecipeExtractor protocol with JSONLDExtractor, WKWebViewRecipeExtractor, FoundationModelsExtractor, HeuristicTextExtractor, and OCRExtractor implementations
- ImportDraftRecipe is an in-memory struct that maps to RecipeFormData at save time via toRecipeFormData()
- RecipeImportService.importRecipe() provides atomic save: create Recipe, parse ingredients, single context.save()
- Import history stored in UserDefaults (100-entry cap), not Core Data
- Optional LLM parsing (see ingredient-parsing spec) bypasses the deterministic pipeline during import save
- Deferred fields: description, cuisine, and category are extracted for preview but not persisted (no entity properties yet)
