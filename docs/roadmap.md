# Forager - Development Roadmap

**Last Updated**: March 28, 2026
**Current Phase**: M18 ACTIVE (store-aware shopping + recipe attribution) | Launch path: M18 → M9.28 → M7.7
**Recently Completed**: M16.9 ✅ | M16 ✅ | M9.35.3 ✅ | M9.35.2 ✅ | M9.34 ✅ | M9.33 ✅ | M9.32 ✅
**Post-Launch**: M6 → M9 remaining → M11+

---

## Completed Milestones (~295h)

| Milestone | Description | Hours | Date |
|-----------|-------------|-------|------|
| M1 | Grocery Management | 32h | Aug 2025 |
| M2 | Recipe Integration | 16.5h | Sep-Oct 2025 |
| M3 | Structured Quantity Management | 10.5h | Oct 2025 |
| M3.5 | Foundation Validation & Testing | 8.5h | Oct 2025 |
| M4.1 | Settings Infrastructure | 1.5h | Oct 2025 |
| M4.2 | Calendar-Based Meal Planning | 4h | Nov 2025 |
| M4.3.1 | Recipe Source Tracking | 3.5h | Nov 2025 |
| M4.3.2 | Scaled Recipe to List | 1.25h | Nov 2025 |
| M4.3.3 | Bulk Add from Meal Plan | 2.5h | Nov 2025 |
| M4.3.4 | Meal Completion Tracking | 1h | Nov 2025 |
| M4.3.5 | Ingredient Normalization | 5.5h | Nov 2025 |
| M5.0 | App Renaming & TestFlight | 6h | Dec 2025 |
| M7.0 | App Store Prerequisites | 3h | Dec 2025 |
| M7.1 | CloudKit Sync Foundation | 6.5h | Dec 2025 |
| M7.1-debug | CloudKit Multi-Device Debugging | 4h | Dec 2025 |
| M7.2.1 | Household Setup | 1.25h | Dec 2025 |
| M7.2.2 | Member Invitation & Leave Flow | ~25h | Jan-Feb 2026 |
| M7.2.3 | CloudKit Hardening & Shared Data | 12.25h | Jan 2026 |
| M7.3 | Household Management & Error Handling | ~6h | Feb 2026 |
| M7.4 | UI Polish & Pre-Launch Fixes | ~4h | Feb 2026 |
| M7.5 | Architecture Hardening | ~5h | Feb 2026 |
| M7.6 | Pre-Launch Prep & TestFlight | ~12h | Feb 2026 |
| M8.1 | Parsing Resilience & Telemetry | ~3h | Feb 2026 |
| M8.3 | Hybrid NLP Parser | ~11h | Feb 2026 |
| M8.3.1 | Template Hygiene & Badge Fix | ~3h | Feb 2026 |
| M8.3.2 | Auto-Merge Grocery Quantities | ~3h | Feb 2026 |
| M8.4 | ML-Powered Parsing (BiLSTM-CRF) | ~25h | Feb 2026 |
| M8.4.1 | Normalization Qualifier Reclassification | ~2h | Feb 2026 |
| M9.0 | Warning Resolution | <1h | Feb 2026 |
| M9.1.2 | Centralize extractCleanIngredientName | ~2h | Feb 2026 |
| M9.5-partial | Parser Dependency Injection | ~3h | Feb 2026 |
| M9.13 | ManagedObjectFactory Enforcement | ~3h | Mar 2026 |
| M9.16 | Unified GroceryListItemService | ~4h | Mar 2026 |
| M9.25/25.1 | UI Fixes | ~1h | Mar 2026 |
| M9.27 | First Launch Walkthrough Redesign | ~4h | Mar 2026 |
| M10.3 | Photo/Image Import | ~25h | Mar 2026 |
| M10.5 | Pipeline Accuracy + LLM Evaluation | ~4h | Feb 2026 |
| M10.6 | Claude API Integration (M10.6.1-10) | ~22h | Mar 2026 |
| M15 | UX Design System & Visual Refresh | ~60h | Feb-Mar 2026 |
| M16.1-16.2 | Knowledge MCP Server | ~6h | Mar 2026 |
| M9.35.2 | Parsing: Confidence Fix + Float Conversion | ~1h | Mar 2026 |
| M9.35.3 | Leading Comma Display Fix | <0.5h | Mar 2026 |
| M16 | Parsing Test Harness (CLI tool + 3 ralph loops) | ~5h | Mar 2026 |
| M16.9 | ML Model Retraining (BiLSTM-CRF v2 + parser fixes) | ~15h | Mar 2026 |
| M17.1 | Doc Slimming + PRD Archival | ~1h | Mar 2026 |

---

## Launch Path (~11-18h remaining)

| Milestone | Description | Est. Hours | Status |
|-----------|-------------|------------|--------|
| **M18** | Store-aware shopping + recipe attribution (combined schema v11) | 7-10h | ACTIVE |
| **M9.28** | Strip diagnostic logging for production | 1-2h | PLANNED |
| **M7.7** | App Store submission (screenshots, metadata, listing) | 3-5h | PLANNED |

**M18 combined scope**: Store entity + preferredStore on IngredientTemplate + store snapshot on GroceryListItem + Recipe.imageURL/author. Single v10→v11 migration. M10.4 attribution schema absorbed. PRD: `docs/prds/active/m18-store-aware-shopping.md`

---

## Post-Launch Priorities

| Milestone | Description | Est. Hours |
|-----------|-------------|------------|
| M10.4 | Recipe import polish (history, telemetry — schema done in M18) | 6-8h |
| M6 | Testing Foundation & AI Augmentation | 12-18h |
| M9 (remaining) | Technical Debt & Optimization | ~120h |
| M11 | Analytics & Insights | 8-12h |
| M16.3 | MCP Server Polish | 1-2h |
| M12-M14 | Health, Budget, AI Assistant | 30-45h |

**Future considerations**:
- Recipe description, cuisine, category on Recipe entity — deferred to future milestone
- Recipe image rendering from imageURL — deferred to future milestone
- M10.7: Alternative Ingredient Splitting — 3-4h

---

## Timeline Summary

- **Total completed**: ~320 hours across 40+ milestones
- **Remaining to App Store**: ~11-18 hours
- **Post-launch backlog**: ~160-200 hours
- **Build 91** on TestFlight, ML parser v2 live, zero warnings
