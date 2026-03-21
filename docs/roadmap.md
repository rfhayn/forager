# Forager - Development Roadmap

**Last Updated**: March 21, 2026
**Current Phase**: Launch prep — M9.26 → M10.6.5 → M9.28 → M9.29 → M7.7 (~8-15h to App Store)
**Recently Completed**: M9.15.3 ✅ (returning user detection, 6s discovery) | M9.24 ✅ | M9.27 ✅ | M17.1 ✅
**Post-Launch**: M10.4 → M6 → M9 remaining → M11+

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

---

## Launch Path (Remaining ~10-18h)

| Milestone | Description | Est. Hours | Status |
|-----------|-------------|------------|--------|
| M9.24 | *Current sprint task* | TBD | ACTIVE |
| M9.15.3 | *Current sprint task* | TBD | READY |
| M9.26 | *Current sprint task* | TBD | READY |
| M10.6.5 | Claude API docs & verification | 1-2h | READY |
| M9.28 | *Current sprint task* | TBD | READY |
| M9.29 | *Current sprint task* | TBD | READY |
| M7.7 | App Store Submission & Public Presence | 3-5h | QUEUED |

**M7.7 sub-phases**: Landing page, GitHub README, App Store listing, submission

---

## Post-Launch Priorities

| Milestone | Description | Est. Hours |
|-----------|-------------|------------|
| M10.4 | Recipe Import Polish & Integration | 11-16h |
| M6 | Testing Foundation & AI Augmentation | 12-18h |
| M9 (remaining) | Technical Debt & Optimization | ~120h |
| M11 | Analytics & Insights | 8-12h |
| M16.3 | MCP Server Polish | 1-2h |
| M12-M14 | Health, Budget, AI Assistant | 30-45h |

**Feature Ideas (Backlog):**
- M10.7: Alternative Ingredient Splitting ("X or Y" parsing) — 3-4h

---

## Timeline Summary

- **Total completed**: ~295 hours across 40+ milestones
- **Remaining to App Store**: ~10-18 hours
- **Post-launch backlog**: ~180-210 hours
- **267 unit tests**, 19 test files
- **Build 58** on TestFlight, ML parser live, zero warnings
