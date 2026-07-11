# Deferred work

Intentionally-deferred engineering items — extracted here so they survive
outside session memory and surface during future planning. Add new items as
they're deferred; remove them when shipped.

## Recipe entity fields — `description`, `cuisine`, `category`
**Deferred; extraction already done.** The import pipeline (`ImportDraftRecipe`)
already extracts `description`, `cuisine`, and `category`, but they are dropped
in `toRecipeFormData()` at save time and never persisted.

- **Why deferred:** schema v11 (M18) only added `imageURL` and `author` (legal
  attribution). The rest add user value but weren't needed for launch.
- **To ship:** append-only migration adding the optional String attributes, then
  wire them through `RecipeImportService.saveImport()` (~line 182). **No new
  extraction work needed** — the values are already available in
  `ImportDraftRecipe`. Natural fit for a "recipe detail" redesign.

---
*Seeded from auto-memory during the 2026-07-10 memory sweep.*
