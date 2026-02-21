# forager

A smart iOS grocery and meal planning app that turns shopping from a chore into an efficient, personalized experience — with store-layout optimization, recipe scaling, household collaboration, and intelligent ingredient parsing.

**Pure Swift. No external dependencies. Built with SwiftUI, Core Data, and CloudKit.**

---

## Features

### Grocery Management
- **Store-layout optimized lists** — Organize items by your actual shopping path with custom drag-and-drop category ordering
- **Staple items** — Auto-populate recurring essentials to every new list
- **Smart consolidation** — Merge duplicates intelligently ("1 cup milk" + "2 cups milk" = "3 cups milk")
- **Unit conversion** — Automatic conversion between compatible units (cups/tbsp/tsp, lbs/oz)

### Recipe Catalog
- **Full CRUD operations** — Create, browse, search, edit, and delete recipes
- **Recipe scaling** — Adjust servings from 0.25x to 4x with kitchen-friendly fractions (1.5 → "1 1/2")
- **Smart autocomplete** — Parse-then-search ingredient entry with fuzzy matching and template alignment
- **Usage tracking** — Track recipe popularity with usage counts and dates

### Meal Planning
- **Calendar-based planning** — Assign recipes to specific days with an intuitive grid interface
- **Bulk grocery generation** — One-tap "Add All to Shopping List" from any meal plan
- **Servings adjustment** — Per-recipe scaling when adding to grocery lists
- **Completion tracking** — Mark meals as completed with visual feedback

### Household Collaboration
- **CloudKit sync** — Multi-device sync with < 5s latency
- **Shared households** — Create a household, invite members via shareable link, share all data automatically
- **Dual-store architecture** — Private store for personal data, shared store for household data
- **Full lifecycle** — Create, invite, join, leave, rejoin, remove members, delete households

### Intelligent Parsing
- **Hybrid parser** — Regex fast path (< 0.05s) + NLP fallback for complex inputs
- **98%+ accuracy** — 7 regex pattern categories covering unicode fractions, ranges, parentheticals, compound phrases, qualifiers, and descriptive amounts
- **Template normalization** — 4-phase pipeline (case, plural, abbreviation, variation) prevents "Butter"/"butter"/"BUTTER" duplication
- **Confidence tracking** — Yellow badges flag low-confidence parses for user review
- **Auto-merge** — Adding the same ingredient from multiple recipes merges quantities automatically

---

## Getting Started

### Requirements
- iOS 26+
- Xcode 26.0+
- macOS 26.0+

### Installation

```bash
git clone https://github.com/rfhayn/forager.git
cd forager
open forager.xcodeproj
```

Press **Cmd+R** in Xcode to build and run. No package managers, no dependency installs — it's pure Swift.

---

## Architecture

### Technology Stack
| Layer | Technology |
|-------|-----------|
| UI | SwiftUI with `@FetchRequest` for live updates |
| Persistence | Core Data (10 entities, 6 model versions) |
| Cloud | CloudKit via `NSPersistentCloudKitContainer` |
| Parsing | Regex + Apple NaturalLanguage (NLTagger) |
| Testing | XCTest (146+ unit tests) |
| Distribution | TestFlight + App Store Connect |

### Key Patterns

**Dual-store CloudKit architecture** — Two persistent stores (`forager.sqlite` for private, `forager_shared.sqlite` for shared) backed by separate CloudKit databases. Data scope is determined by a `DataScope` enum (`.personal` vs `.household`), and a `ManagedObjectFactory` automatically assigns objects to the correct store.

**Hybrid parser with confidence routing** — `IngredientParser` protocol with three implementations: `RegexIngredientParser` (fast, handles 85% of inputs), `NLPIngredientParser` (Apple NaturalLanguage fallback), and `HybridIngredientParser` (router). If regex confidence < 0.8, NLP gets consulted. Whichever parser returns higher confidence wins.

**Service layer standard** — All Core Data writes go through service objects (`HouseholdService`, `MealPlanService`, `OptimizedRecipeDataService`, etc.). Views never call `context.save()` directly.

**Template-based normalization** — `IngredientTemplate` is the single source of truth for ingredient names. A 4-phase normalization pipeline and `findOrCreateTemplate` ensure deduplication across all entry points.

### Project Structure

```
forager/
├── forager.xcodeproj
├── forager/                     # Main app source
│   ├── foragerApp.swift         # App entry point + loading screen
│   ├── SceneDelegate.swift      # CloudKit share handling
│   ├── Assets.xcassets/         # App icon, launch assets
│   └── forager.xcdatamodeld/    # Core Data model (v1-v6)
├── Services/                    # Service layer
│   ├── Persistence/             # Core Data + CloudKit infrastructure
│   │   ├── PersistenceController.swift
│   │   ├── DataScope.swift
│   │   ├── ManagedObjectFactory.swift
│   │   ├── CategoryDeduplicator.swift
│   │   └── ...
│   ├── Parsing/                 # Hybrid ingredient parser
│   │   ├── IngredientParser.swift       # Protocol
│   │   ├── RegexIngredientParser.swift  # Fast path (~650 lines)
│   │   ├── NLPIngredientParser.swift    # NLP fallback (~310 lines)
│   │   └── HybridIngredientParser.swift # Router (~60 lines)
│   ├── HouseholdService.swift
│   ├── MealPlanService.swift
│   ├── IngredientParsingService.swift   # Public API
│   ├── UnitConversionService.swift
│   ├── RecipeScalingService.swift
│   └── ...
├── foragerTests/                # Unit tests (146+)
├── docs/                        # Project documentation
│   ├── current-story.md         # Active development status
│   ├── roadmap.md               # Milestone tracking
│   ├── requirements.md          # 234 functional requirements
│   ├── learning-notes/          # 37 implementation journey notes
│   ├── architecture/            # 12 Architecture Decision Records
│   └── prds/                    # Product Requirements Documents
└── CLAUDE.md                    # AI assistant instructions
```

### Core Data Model (10 Entities)

| Domain | Entities |
|--------|----------|
| Grocery | `WeeklyList`, `GroceryListItem`, `Category` |
| Recipe | `Recipe`, `Ingredient`, `IngredientTemplate` |
| Meal Planning | `MealPlan`, `PlannedMeal` |
| Household | `Household`, `HouseholdMember` |
| Settings | `UserPreferences` |

---

## Performance

All targets met or exceeded across ~190 hours of development:

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

## Development Journey

forager has been built incrementally across ~190 hours with 89% planning accuracy. Each milestone follows a one-branch, one-PR, one-squash-commit workflow.

### Completed Milestones

| Milestone | Description | Hours | Date |
|-----------|-------------|-------|------|
| **M1** | Professional Grocery Management | 32h | Aug 2025 |
| **M2** | Recipe Integration & Autocomplete | 16.5h | Sep-Oct 2025 |
| **M3** | Structured Quantities & Scaling | 10.5h | Oct 2025 |
| **M3.5** | Foundation Validation & Testing | 8.5h | Oct 2025 |
| **M4** | Meal Planning & Grocery Integration | 19.25h | Nov 2025 |
| **M5.0** | App Renaming & TestFlight | 6h | Dec 2025 |
| **M7.0** | App Store Prerequisites | 3h | Dec 2025 |
| **M7.1** | CloudKit Sync Foundation | 10.5h | Dec 2025 |
| **M7.2** | Household Shared Zone Architecture | ~25h | Dec 2025-Feb 2026 |
| **M7.3** | Household Management & Error Handling | ~6h | Jan-Feb 2026 |
| **M7.4** | UI Polish (Apple Music-style nav) | ~4h | Feb 2026 |
| **M8** | Hybrid NLP Parser & Parsing Intelligence | ~17h | Feb 2026 |
| **M7.6** | Pre-Launch Prep & Schema Cleanup | ~9.5h | Feb 2026 |
| **M15** | UX Design System & Visual Refresh | ~50h | Feb 2026 |

### Current

M15 complete on `feature/M15-ux-design-system` — pending merge to main, then TestFlight build 11 (v1.2).

### Planned

| Milestone | Description | Est. Hours |
|-----------|-------------|------------|
| **M7.5** | Architecture Hardening | 14-19h |
| **M9-prereqs** | Warning Resolution, Centralize Extract, Parser DI | 9h |
| **M8.4** | ML-Powered Parsing (CoreML BiLSTM-CRF) | 18-24h |
| **M7.7** | App Store Submission & Landing Page | 3-5h |
| **M6** | Testing Foundation & CI/CD | 20-30h |
| **M9** | Technical Debt & Optimization | ~120h |
| **M10+** | Analytics, Health, Budget, AI, Collaboration | 48-72h |

---

## Documentation

This project maintains comprehensive documentation tracking the full development journey:

| Resource | Description |
|----------|-------------|
| [current-story.md](docs/current-story.md) | Active development status |
| [roadmap.md](docs/roadmap.md) | Milestone tracking and execution order |
| [requirements.md](docs/requirements.md) | 234 functional requirements with traceability |
| [project-index.md](docs/project-index.md) | Central navigation hub |
| [learning-notes/](docs/learning-notes/) | 37 implementation journey notes |
| [architecture/](docs/architecture/) | 12 Architecture Decision Records |
| [prds/](docs/prds/) | Product Requirements Documents |
| [insights-log.md](docs/insights-log.md) | Technical insights triage inbox |

---

## License

This project is available under the MIT License.

---

**~190 hours** of development | **89%** planning accuracy | **146+** unit tests | **234** tracked requirements | **37** learning notes | **12** ADRs | **Zero** technical debt
