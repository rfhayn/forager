# forager

A smart iOS grocery and meal planning app that turns shopping from a chore into an efficient, personalized experience -- with store-layout optimization, recipe scaling, household collaboration, and intelligent ingredient parsing.

**Pure Swift. No external dependencies. Built with SwiftUI, Core Data, and CloudKit.**

[![TestFlight Beta](https://img.shields.io/badge/TestFlight-Join%20Beta-blue)](https://testflight.apple.com/join/zwFHTpDs)
[![iOS 26+](https://img.shields.io/badge/iOS-26%2B-black)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6-orange)](https://swift.org)

---

## Try It

Join the public beta on TestFlight: **[testflight.apple.com/join/zwFHTpDs](https://testflight.apple.com/join/zwFHTpDs)**

---

## Features

### Grocery Management
- **Store-layout optimized lists** -- organize items by your actual shopping path with custom drag-and-drop category ordering
- **Store-aware shopping** -- assign preferred stores to ingredients, group grocery items by store
- **Smart consolidation** -- merge duplicates intelligently ("1 cup milk" + "2 cups milk" = "3 cups milk")
- **Unit conversion** -- automatic conversion between compatible units (cups/tbsp/tsp, lbs/oz)

### Recipe Catalog
- **Multi-source import** -- import recipes from URLs, pasted text, or photos (OCR)
- **Recipe scaling** -- adjust servings from 0.25x to 4x with kitchen-friendly fractions
- **Smart autocomplete** -- parse-then-search ingredient entry with fuzzy matching and template alignment
- **Grid and list views** -- browse recipes as image cards or a compact list

### Meal Planning
- **Calendar-based planning** -- assign recipes to specific days with an intuitive interface
- **Bulk grocery generation** -- one-tap "Add All to Shopping List" from any meal plan
- **Servings adjustment** -- per-recipe scaling when adding to grocery lists
- **Completion tracking** -- mark meals as completed with visual feedback

### Household Collaboration
- **CloudKit sync** -- multi-device sync with < 5s latency
- **Shared households** -- create a household, invite members via shareable link, share all data automatically
- **Dual-store architecture** -- private store for personal data, shared store for household data
- **Full lifecycle** -- create, invite, join, leave, rejoin, remove members, delete households

### Intelligent Parsing
- **3-tier hybrid parser** -- regex fast path (< 0.05s) + ML model (BiLSTM-CRF) + NLP fallback
- **98%+ accuracy** -- 7 regex pattern categories covering unicode fractions, ranges, parentheticals, compound phrases, qualifiers, and descriptive amounts
- **Optional AI enhancement** -- Claude API integration for edge cases (user provides own API key, off by default)
- **Template normalization** -- 4-phase pipeline prevents "Butter"/"butter"/"BUTTER" duplication
- **Auto-merge** -- adding the same ingredient from multiple recipes merges quantities automatically

---

## Architecture

### Technology Stack
| Layer | Technology |
|-------|-----------|
| UI | SwiftUI with `@FetchRequest` for live updates |
| Persistence | Core Data (13 entities, schema v11) |
| Cloud | CloudKit via `NSPersistentCloudKitContainer` |
| Parsing | Regex + BiLSTM-CRF (CoreML) + Apple NaturalLanguage |
| Testing | XCTest (531 unit tests) |
| Distribution | TestFlight + App Store Connect |

### Key Patterns

**Dual-store CloudKit architecture** -- two persistent stores (`forager.sqlite` for private, `forager_shared.sqlite` for shared) backed by separate CloudKit databases. Data scope is determined by a `DataScope` enum (`.personal` vs `.household`), and a `ManagedObjectFactory` automatically assigns objects to the correct store.

**3-tier hybrid parser with confidence routing** -- `IngredientParser` protocol with three implementations: `RegexIngredientParser` (fast, handles 90%+ of inputs), `MLIngredientParser` (BiLSTM-CRF CoreML model), and `NLPIngredientParser` (Apple NaturalLanguage fallback). `HybridIngredientParser` routes based on confidence thresholds.

**Service layer standard** -- all Core Data writes go through service objects. Views never call `context.save()` directly. Factory enforcement (ADR 014) ensures all household-scoped entities use `ManagedObjectFactory.make()`.

**Template-based normalization** -- `IngredientTemplate` is the single source of truth for ingredient names. A 4-phase normalization pipeline and `findOrCreateTemplate` ensure deduplication across all entry points.

### Core Data Model (13 Entities)

| Domain | Entities |
|--------|----------|
| Grocery | `WeeklyList`, `GroceryListItem`, `GroceryItem`, `Category`, `Store` |
| Recipe | `Recipe`, `Ingredient`, `IngredientTemplate` |
| Meal Planning | `MealPlan`, `PlannedMeal` |
| Household | `Household`, `HouseholdMember` |
| Settings | `UserPreferences` |

---

## Performance

| Metric | Target | Achieved |
|--------|--------|----------|
| Query performance | < 0.1s | < 0.1s |
| Search | < 0.2s | < 0.15s |
| Ingredient parsing | < 0.05s | < 0.03s |
| Recipe scaling | < 0.5s | < 0.4s |
| Consolidation analysis | < 0.5s | < 0.3s |
| CloudKit sync | < 5s | < 5s |
| UI responsiveness | 60fps | 60fps |
| Parsing accuracy | 98%+ | 98%+ |

---

## Development

forager has been built incrementally across ~345 hours with high planning accuracy. Each milestone follows a one-branch, one-PR, one-squash-commit workflow.

### Completed Milestones

| Milestone | Description |
|-----------|-------------|
| **M1** | Professional Grocery Management |
| **M2** | Recipe Integration & Autocomplete |
| **M3** | Structured Quantities & Scaling |
| **M3.5** | Foundation Validation & Testing |
| **M4** | Meal Planning & Grocery Integration |
| **M5.0** | App Renaming & TestFlight |
| **M7.0-7.1** | App Store Prerequisites & CloudKit Foundation |
| **M7.2** | Household Shared Zone Architecture |
| **M7.3-7.4** | Household Management & UI Polish |
| **M7.5** | Architecture Hardening (Service Layer) |
| **M7.6** | Pre-Launch Prep & External TestFlight |
| **M8** | Hybrid NLP Parser & Intelligence |
| **M8.4** | ML-Powered Parsing (BiLSTM-CRF) |
| **M9.x** | Tech Debt, Bug Fixes, Security Hardening |
| **M10** | Recipe Import (URL, Text, Photo/OCR) |
| **M10.6** | Claude API Integration |
| **M15** | UX Design System & Liquid Glass |
| **M16** | Parsing Test Harness & ML Retraining |
| **M18** | Store-Aware Shopping (Schema v11) |
| **FUI-1** | Dashboard, Navigation, Recipe UI |
| **M19** | Pre-Launch Factory Enforcement |

### Documentation

| Resource | Description |
|----------|-------------|
| [current-story.md](docs/current-story.md) | Active development status |
| [requirements.md](docs/requirements.md) | Functional requirements with traceability |
| [project-index.md](docs/project-index.md) | Central navigation hub |
| [architecture/](docs/architecture/) | 14 Architecture Decision Records |

---

## Privacy

All data stored in your personal iCloud account. No third-party servers, no tracking, no analytics. Optional AI parsing sends only ingredient text to Anthropic's API using your own key.

[Privacy Policy](https://rfhayn.github.io/forager/privacy.html) | [Support](https://github.com/rfhayn/forager/issues)

---

## License

All rights reserved. Copyright 2025-2026 Rich Hayn.

---

**~345 hours** of development | **531** unit tests | **14** ADRs | **13** Core Data entities
