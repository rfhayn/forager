# Forager

An iOS app that transforms grocery shopping from a time-consuming chore into an efficient, personalized experience through smart automation, custom store layouts, and intelligent meal planning.

## 🎯 Project Status

**Current Phase**: M7.2.2 - Member Invitation & Acceptance Testing  
**Development Time**: ~119.5 hours across 11 major milestones  
**Planning Accuracy**: 89% average  
**Technical Debt**: Zero ✅  

**GitHub Project**: [View Project Board](https://github.com/users/rfhayn/projects/1)

## Features

### Core Functionality
- **Smart Grocery Lists**: Auto-generate weekly shopping lists from your regular staples
- **Custom Store Layout**: Organize items by your actual shopping path for maximum efficiency
- **Recipe Management**: Build and maintain a personal recipe collection with usage tracking
- **Calendar Meal Planning**: Plan meals across multiple weeks with an intuitive calendar interface
- **Intelligent Categories**: Create unlimited custom categories with personalized drag-and-drop ordering
- **Real-time Search**: Instant search across all items and recipes

### Advanced Features
- **Meal Plan Integration**: Assign recipes to specific days and bulk-add all ingredients to your shopping list
- **Recipe Source Tracking**: See which recipes contributed ingredients to your shopping list
- **Recipe Scaling**: Adjust servings with automatic ingredient quantity conversion and kitchen-friendly fractions
- **Quantity Consolidation**: Intelligently merge duplicate items (e.g., "1 cup milk" + "2 cups milk" = "3 cups milk")
- **Unit Conversion**: Automatic conversion between compatible units (cups ↔ tablespoons ↔ teaspoons, pounds ↔ ounces)
- **Recipe Usage Analytics**: Track recipe usage patterns with automatic counting and dating
- **Meal Completion Tracking**: Mark meals as completed with visual feedback
- **Performance Optimized**: Sub-500ms response times with Core Data optimization
- **CloudKit Sync**: Multi-device sync with household sharing (M7 - In Progress)

### Intelligent Automation
- **Parse-Then-Autocomplete**: Smart ingredient entry with fuzzy matching and template alignment
- **Ingredient Normalization**: Automatic deduplication (e.g., "Butter", "butter", "BUTTER" → "butter")
- **Template System**: Single source of truth for ingredients prevents duplication across recipes
- **Smart Consolidation**: Reduce list redundancy by 30-50% through intelligent merging

## Screenshots

*Coming soon - Screenshots of the main tabs and key features*

## Getting Started

### Requirements
- iOS 18.5+
- Xcode 15.0+
- macOS Sonoma 14.0+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/rfhayn/forager.git
cd forager
```

2. Open the project in Xcode:
```bash
open forager.xcodeproj
```

3. Build and run:
   - Select your target device or simulator
   - Press ⌘+R to build and run
   - The app launches ready for use

## App Structure

The app consists of six main tabs:

- **Lists**: View and manage weekly grocery lists with smart consolidation and recipe source tracking
- **Ingredients**: Browse and manage ingredient templates for recipe creation
- **Recipes**: Browse and manage your recipe collection with search, scaling, and usage analytics
- **Meal Planning**: Calendar-based meal planning with recipe assignments and bulk grocery list generation
- **Categories**: Manage custom categories with drag-and-drop ordering
- **Settings**: User preferences, household management, display options, and help documentation

## Architecture

### Technology Stack
- **SwiftUI** for modern, declarative UI
- **Core Data** for local data persistence with performance optimization
- **CloudKit** for multi-device sync and household sharing (M7 - In Progress)
- **NSPersistentCloudKitContainer** with dual-store architecture (private + shared)

### Data Model
- 10-entity Core Data model supporting recipes, ingredients, meal planning, custom categories, and households
- Performance-optimized queries with compound indexes
- Template-based ingredient normalization to prevent duplication
- Structured quantity system enabling scaling and consolidation
- Meal planning with date-based recipe assignments
- Many-to-many relationships for recipe source tracking
- Household-scoped data for family collaboration

**Core Entities:**
- WeeklyList, GroceryListItem, Category
- Recipe, Ingredient, IngredientTemplate
- MealPlan, PlannedMeal, UserPreferences
- Household, HouseholdMember

### Performance
- **Sub-millisecond response times** for most operations
- **Background processing** for non-blocking UI operations
- **Memory efficient** relationship handling
- **Validated performance targets**: All operations < 0.5s maintained across 119+ hours of development

## Development Status

### Completed Milestones (~119.5 hours)

**M1: Professional Grocery Management** ✅ (32 hours - August 2025)
- Custom store-layout optimization with drag-and-drop categories
- Staple item system with auto-population
- Professional iOS UI with Core Data architecture
- Sub-0.1s query performance

**M2: Recipe Integration** ✅ (16.5 hours - Sept-Oct 2025)
- Complete recipe catalog with CRUD operations
- Recipe-to-grocery integration with intelligent templating
- Recipe ingredient autocomplete with fuzzy matching
- Enhanced search across name, ingredients, tags, instructions

**M3: Structured Quantity Management** ✅ (10.5 hours - October 2025)
- Recipe scaling with kitchen-friendly fractions (0.25x-4x)
- Intelligent quantity consolidation (30-50% list reduction)
- Unit conversion system (volume and weight)
- Visual indicators for parseable vs. unparseable quantities

**M3.5: Foundation Validation** ✅ (8.5 hours - October 2025)
- Comprehensive validation and test infrastructure
- 75+ computed properties for data integrity
- Automated validation test suite (6 test suites, 100% pass rate)
- Performance validation (all operations < 0.5s)

**M4: Meal Planning & Enhanced Grocery Integration** ✅ (19.25 hours - Oct-Nov 2025)
- **M4.1**: Settings infrastructure with user preferences (1.5h)
- **M4.2**: Calendar-based meal planning with recipe assignment (4h)
- **M4.3.1**: Recipe source tracking with many-to-many relationships (3.5h)
- **M4.3.2**: Scaled recipe to shopping list with servings adjustment (1.25h)
- **M4.3.3**: Bulk add from meal plan with progress tracking (2.5h)
- **M4.3.4**: Meal completion tracking with visual feedback (1h)
- **M4.3.5**: Ingredient normalization (4 phases, 5.5h)

**M5.0: App Renaming & TestFlight Deployment** ✅ (6 hours - December 2025)
- Complete app rename from "GroceryRecipeManager" to "Forager"
- Professional app icon design (green sprout, grocery-themed)
- Bundle identifier migration (com.richhayn.forager)
- Apple Developer Program enrollment and App Store Connect configuration
- CloudKit production entitlements
- Internal TestFlight deployment with multi-tester beta program

**M7.0: App Store Prerequisites** ✅ (3 hours - December 2025)
- Privacy policy creation and hosting on GitHub Pages
- In-app privacy link implementation with SafariView
- App Privacy questionnaire completion
- Display name disambiguation

**M7.1: CloudKit Sync Foundation** ✅ (10.5 hours - December 2025)
- CloudKit container setup and schema validation (10 entities)
- CloudKitSyncMonitor service for real-time sync tracking
- Multi-device sync debugging (4 hours):
  - Fixed production schema lock
  - Solved duplicate categories race condition
  - Implemented serial queue synchronization
  - Removed sample data from production
- Perfect bi-directional sync < 5s latency

**M7.2.1: Household Setup Foundation** ✅ (1.25 hours - December 2025)
- Household and HouseholdMember Core Data entities
- HouseholdService singleton for household management
- CreateHouseholdSheet professional UI
- Settings integration for household management

**M7.2.3: CloudKit Hardening & Shared Data Architecture** ✅ (12.25 hours - Dec 2025-Jan 2026)
- External validation by ChatGPT ("Gold Standard") and Gemini ("Production-ready")
- Phase 0: Core Data Model v2 with household relationships (2h)
- Phase 1: Persistence decomposition into focused services (5h)
- Phase 2: Scope-based store assignment infrastructure (3.75h)
  - DataScope enum, HouseholdScoped protocol
  - ManagedObjectFactory with automatic store assignment
  - Manual Core Data property files (6 entities)
- Phase 3.8: CategoryDeduplicator with self-healing sync (1h)
- Phase 4: Attach-then-share migration with UI (3.5h)
  - PreHouseholdDataMigrationSheet
  - **Critical fix**: Added missing context.save() after container.share()
  - Validated 61 items migrated to CloudKit shared zone

### In Progress

**M7.2.2: Member Invitation & Acceptance** 🔄 (11-12 hours so far)
- Jan 9: Public link sharing implementation (~8h)
  - Bypassed UICloudSharingController (broken on iOS 18.x)
  - Successfully sent invitations via ShareSheet
- Jan 10: Bug fixes from physical device testing (~3-4h)
  - Fixed display name extraction (CloudKit ID hiding)
  - Extended sync retry from 3s → 30s (CloudKit propagation)
  - Integrated auto-member creation
  - Added restart alert for edge cases
- Status: Bug fixes committed, ready for Device B retest

### Planned Features

**M7: CloudKit Sync & External TestFlight** (Remaining: ~8-15 hours)
- M7.3: Conflict Resolution & Error Handling (4-6h)
- M7.4: Sync UI & Polish (3-4h)
- M7.5: Architecture Hardening - UX/Service Cleanup (8-12h)
- M7.6: External TestFlight Deployment (2-3h)
- M7.7: Public Beta Program (2-3h)

**M6: Testing Foundation & AI Augmentation** (12-18 hours)
- Human-written test baseline (50%+ service coverage)
- AI test reviewer operational on every PR via GitHub Actions
- Testing standards documentation and CI/CD pipeline
- Semantic coverage gap detection foundation

**M8: Ingredient Parsing Intelligence** (13-16 hours core, +15-20h optional ML)
- M8.1: Parsing Resilience & Telemetry (3-4h)
- M8.2: Telemetry Analysis & Strategy (2h)
- M8.3: Hybrid NLP Parser (8-10h) - Target: 95% → 98%+ accuracy
- M8.4: ML-Powered Parsing (15-20h, optional) - Target: 98% → 99.5%+ accuracy

**M9: Technical Debt & Codebase Optimization** (135-165 hours)
- Phase 1: Quick Wins (20-25h)
- Phase 2: Architecture & Structure (40-50h)
- Phase 3: Performance & Data Model (60-70h)
- Phase 4: Quality & Standards (15-20h)
- Impact: ~2,000 lines removed, 50-80% performance improvement

**M10-M14: Advanced Intelligence Platform** (60-90 hours)
- **M10**: Analytics & Insights dashboard (8-12h)
- **M11**: Health & Nutrition tracking (10-15h)
- **M12**: Budget intelligence (10-15h)
- **M13**: AI-powered recipe assistant (10-15h)
- **M14**: Advanced collaboration features (10-15h)

## Project Structure

```
forager/
├── forager.xcodeproj          # Xcode project
├── forager/                    # Main source code
│   ├── Views/                  # SwiftUI views
│   ├── Services/               # Data services
│   │   ├── Persistence/        # Core Data + CloudKit
│   │   ├── HouseholdService.swift
│   │   ├── MealPlanService.swift
│   │   └── ...
│   └── forager.xcdatamodeld/   # Core Data model
├── foragerTests/               # Unit tests
├── foragerUITests/             # UI tests
├── docs/                       # Comprehensive documentation
│   ├── requirements.md         # All functional requirements
│   ├── roadmap.md              # Milestone timeline & tracking
│   ├── current-story.md        # Active development status
│   ├── project-index.md        # Documentation navigation hub
│   ├── learning-notes/         # Implementation journey (22+ notes)
│   ├── architecture/           # Architecture Decision Records (8 ADRs)
│   ├── m7-docs/                # M7 CloudKit implementation docs
│   └── prds/                   # Product Requirements Documents
└── Tools/                      # Development tools
    └── AITestReview/           # AI test review CLI (M6)
```

## Documentation

This project maintains extensive documentation tracking the complete development journey:

- **[requirements.md](docs/requirements.md)** - All functional requirements with traceability to implementation
- **[roadmap.md](docs/roadmap.md)** - Milestone sequence, timelines, and completion tracking
- **[current-story.md](docs/current-story.md)** - Current active development status
- **[project-index.md](docs/project-index.md)** - Central navigation hub for all documentation
- **[learning-notes/](docs/learning-notes/)** - 22+ detailed implementation notes for each milestone
- **[architecture/](docs/architecture/)** - 8 Architecture Decision Records (ADRs)
- **[m7-docs/](docs/m7-docs/)** - CloudKit implementation documentation
- **[prds/](docs/prds/)** - Product Requirements Documents for complex features

**GitHub Project Management**:
- **[Issues](https://github.com/rfhayn/forager/issues)** - 11 issues with 380+ granular tasks
- **[Milestones](https://github.com/rfhayn/forager/milestones)** - 6 milestones grouping related work
- **[Project Board](https://github.com/users/rfhayn/projects/1)** - Kanban-style visual progress tracking

## Contributing

This is a personal learning project focused on iOS development skills and best practices. The extensive documentation in the `docs/` folder tracks the complete development journey, architectural decisions, and lessons learned.

### Development Approach
- **Incremental Development**: Features built in small, validated phases
- **Performance First**: All features maintain strict performance standards (<0.5s)
- **User Experience Focus**: Native iOS patterns and accessibility compliance
- **Quality Assurance**: Comprehensive validation and testing after each phase
- **Documentation-Driven**: Every decision and pattern documented for future reference

### Planning Accuracy
- **89% average accuracy** across completed milestones (M1-M7.2.3)
- **100% build success rate** (zero breaking changes)
- **Phase-based planning** with 45-90 minute increments
- **Proven patterns** reused across milestones for velocity

## Technical Highlights

### Performance Engineering
- N+1 query prevention with batch relationship fetching
- Indexed Core Data queries for instant search results (<0.1s)
- Background operations preventing UI blocking
- Optimized parsing service (<0.03s for quantity parsing)
- Consolidation analysis <0.3s for 50+ items

### User Experience Innovation
- Revolutionary custom store layout optimization
- Drag-and-drop category personalization
- Recipe source tracking with tappable navigation
- Progress overlays for long-running operations
- Visual feedback throughout (checkmarks, strikethrough, scale indicators)

### Architecture Excellence
- Service-oriented architecture with clear separation of concerns
- Template-based normalization preventing data duplication
- Structured quantity system enabling advanced features
- Scalable data model supporting future intelligence platform
- Dual-store CloudKit architecture (private + shared)
- Household-scoped data with automatic store assignment
- Performance monitoring and validation systems
- Comprehensive computed properties for data integrity

### Code Quality
- **Zero technical debt** maintained across 119+ hours
- Consistent naming conventions (M#.#.# hierarchy)
- Comprehensive inline documentation explaining "why" not "what"
- Function header comments for all methods
- MARK comments for logical section organization

## Performance Metrics

All targets met or exceeded across 119+ hours of development:

| Metric | Target | Achieved | Status |
|--------|--------|----------|--------|
| Query performance | < 0.1s | < 0.1s | ✅ Met |
| Search performance | < 0.2s | < 0.15s | ✅ Exceeded |
| Autocomplete | < 0.1s | < 0.08s | ✅ Exceeded |
| Parsing | < 0.05s | < 0.03s | ✅ Exceeded |
| Recipe scaling | < 0.5s | < 0.4s | ✅ Exceeded |
| Consolidation analysis | < 0.5s | < 0.3s | ✅ Exceeded |
| Merge execution | < 1s | < 0.8s | ✅ Exceeded |
| UI responsiveness | 60fps | 60fps | ✅ Met |
| CloudKit sync | < 5s | < 5s | ✅ Met |

## Learning Journey

This project represents a comprehensive learning journey in iOS development, including:

- **Core Data**: Advanced features including relationships, migrations, performance optimization
- **CloudKit**: NSPersistentCloudKitContainer, dual-store architecture, shared zones, CKShare
- **SwiftUI**: Modern declarative UI with complex state management patterns
- **Architecture**: Service layer design, data model planning, scalability considerations
- **Performance**: Query optimization, background processing, memory management
- **UX Design**: Native iOS patterns, accessibility, visual feedback systems
- **Project Management**: Phase-based planning, accurate estimation, documentation practices
- **Multi-Device Sync**: Race condition prevention, conflict resolution patterns

## License

This project is available under the MIT License.

## Contact

For questions about the project or iOS development approaches used, please open an issue or check the comprehensive documentation in the `docs/` folder.

---

**Project Stats:**
- 🕐 119.5+ hours of development across 11 major milestones
- 📊 89% planning accuracy with phase-based approach
- ✅ 100% build success rate (zero breaking changes)
- 🚀 100% performance targets met or exceeded
- 📚 Comprehensive documentation tracking every decision
- 🔧 380+ granular tasks tracked across GitHub Issues
- 📋 22+ learning notes documenting implementation journey
- 🏗️ 8 Architecture Decision Records (ADRs)
- 🎯 Zero technical debt maintained

*Transform your grocery shopping experience with intelligent automation and personalized organization.*
