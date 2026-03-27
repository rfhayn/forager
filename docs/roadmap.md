# Forager - Development Roadmap

**Last Updated**: March 27, 2026
**Current Phase**: M16.9 (ML retraining) active | Launch path: M18 → M10.4 → M9.28 → M7.7
**Total Completed**: ~320 hours across 40+ milestones
**Build**: 90 on TestFlight

---

## Pre-Launch Path (~22-32h remaining)

| Milestone | Description | Est. Hours | Status |
|-----------|-------------|------------|--------|
| **M16.9** | ML model retraining (harness data → BiLSTM-CRF v2) | 14-20h | ACTIVE |
| **M16.9.6** | Port harness parser fixes to app | 2-3h | PLANNED |
| **M18** | Store-aware shopping (preferred store per template, grouped lists) | 12-18h | PLANNED |
| **M10.4** | Recipe attribution, image cache, legal gates (revised scope) | 4-5h | PLANNED |
| **M9.28** | Strip diagnostic logging for production | 1-2h | PLANNED |
| **M7.7** | App Store submission (screenshots, metadata, listing) | 3-5h | PLANNED |

**M18 Store-Aware Shopping** (from beta tester feedback — Joe):
- Store entity + preferredStore on IngredientTemplate (Core Data schema change)
- Grocery list grouped by store with color indicators
- 2 phases, 12-18h estimated
- PRD: `docs/prds/active/m18-store-aware-shopping.md`

**M10.4 revised scope** (was 11-16h, now 4-5h):
- M10.4.5a: `imageURL` on Recipe entity (schema v11) — 1-1.5h
- M10.4.5b: Source attribution UI + disk image cache — 2-2.5h
- M10.4.5c: Legal review gates (scraping disclaimer, attribution) — 1h
- Dropped: Import history (M10.4.1), household sharing (already works), telemetry dashboard (M16 harness), perf optimization (done in M16), regression testing (M16 harness)

---

## Post-Launch Priorities

| Milestone | Description | Est. Hours |
|-----------|-------------|------------|
| **M6** | Testing foundation & AI augmentation | 12-18h |
| **M10.7** | Alternative ingredient splitting ("X or Y" parsing) | 3-4h |
| **M11** | Analytics & insights | 8-12h |
| **M9** (remaining) | Technical debt & optimization | ~120h |
| **M16.3** | MCP Server polish | 1-2h |
| **M12-M14** | Health, budget, AI assistant | 30-45h |

---

## Active: M16.9 — ML Model Retraining

| Sub | Description | Status |
|-----|-------------|--------|
| M16.9.1 | Harness data converter (field→token alignment) | COMPLETE |
| M16.9.2 | Data accumulation + quality review | COMPLETE |
| M16.9.3 | Full retrain (combined dataset + vocab rebuild) | ACTIVE |
| M16.9.4 | A/B model comparison + regression check | READY |
| M16.9.5 | Deploy retrained model to app + validate | READY |
| M16.9.6 | Port parser fixes to app + validate | READY |

---

## Recently Completed

| Milestone | Description | Date |
|-----------|-------------|------|
| M16 | Parsing Test Harness — 9 runs, ~20 bugs fixed, 1,440 training entries | Mar 2026 |
| M9.35.3 | Leading comma display fix | Mar 2026 |
| M9.35.2 | Confidence routing + IEEE 754 float conversion | Mar 2026 |
| M9.34 | First import guide walkthrough | Mar 2026 |
| M9.33 | AI multi-ingredient splitting | Mar 2026 |
| M9.32 | Grocery item name cleanup | Mar 2026 |
| M9.31 | CKShare acceptance resilience | Mar 2026 |
| M9.30 | Household invitation security | Mar 2026 |
| M9.29 | Claude/AI branding cleanup | Mar 2026 |
| M9.27 | First launch walkthrough redesign | Mar 2026 |
| M9.26 | Launch prep bug fixes (rounds 2-4) | Mar 2026 |
| M9.25/25.1 | Glass card UI unification | Mar 2026 |
| M9.24 | Member device import store routing | Mar 2026 |
| M9.15.3 | Returning user detection after reinstall | Mar 2026 |
| M17.1 | Doc slimming + PRD archival | Mar 2026 |
| M10.6.5 | Claude API documentation | Mar 2026 |

---

## All Completed Milestones (~320h)

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
| M9.24 | Member Device Import Store Routing | 0.5h | Mar 2026 |
| M9.15.3 | Returning User Detection After Reinstall | ~1h | Mar 2026 |
| M9.25/25.1 | Glass Card UI Unification | ~1h | Mar 2026 |
| M9.26 | Launch Prep Bug Fixes (rounds 2-4) | ~4h | Mar 2026 |
| M9.27 | First Launch Walkthrough Redesign | ~4h | Mar 2026 |
| M9.29 | Claude/AI Branding Cleanup | ~0.5h | Mar 2026 |
| M9.30 | Household Invitation Security | ~3h | Mar 2026 |
| M9.31 | CKShare Acceptance Resilience | ~1h | Mar 2026 |
| M9.32 | Grocery Item Name Cleanup | ~1h | Mar 2026 |
| M9.33 | AI Multi-Ingredient Splitting | ~3h | Mar 2026 |
| M9.34 | First Import Guide Walkthrough | ~2h | Mar 2026 |
| M9.35.2 | Parsing: Confidence Fix + Float Conversion | ~1h | Mar 2026 |
| M9.35.3 | Leading Comma Display Fix | <0.5h | Mar 2026 |
| M10.3 | Photo/Image Import | ~25h | Mar 2026 |
| M10.5 | Pipeline Accuracy + LLM Evaluation | ~4h | Feb 2026 |
| M10.6 | Claude API Integration (M10.6.1-10) | ~22h | Mar 2026 |
| M10.6.5 | Claude API Documentation | ~1h | Mar 2026 |
| M15 | UX Design System & Visual Refresh | ~60h | Feb-Mar 2026 |
| M16 | Parsing Test Harness (CLI tool + 3 ralph loops) | ~5h | Mar 2026 |
| M16.1-16.2 | Knowledge MCP Server | ~6h | Mar 2026 |
| M17.1 | Doc Slimming + PRD Archival | ~1h | Mar 2026 |

---

## Timeline Summary

- **Total completed**: ~320 hours across 40+ milestones
- **Pre-launch remaining**: ~22-32 hours (M16.9 active, then M18 → M10.4 → M9.28 → M7.7)
- **Post-launch backlog**: ~163-202 hours
- **Build 90** on TestFlight, ML parser live, zero warnings
