# Recipe Import Acceptance Criteria

**Date**: February 24, 2026
**Based on**: JSON-LD extraction spike (28 sites, 4 tiers)
**Status**: Data-backed targets from spike results

---

## Spike Findings Summary

| Metric | Spike Result | Notes |
|--------|-------------|-------|
| Total sites tested | 28 | Across 4 tiers (major, blogs, challenging, international) |
| JSON-LD present (any form) | 19/28 (68%) | Includes standard ld+json tags and embedded JSON |
| Recipe extractable (URLSession) | 13/28 (46%) | Standard ld+json + inline scripts + __NEXT_DATA__ |
| Full extraction (all core fields) | 9/28 (32%) | Title, ingredients, instructions, prep/cook time, servings all present |
| Partial extraction | 4/28 (14%) | 1-2 fields missing (typically prepTime or cookTime) |
| Client-rendered JSON-LD | ~8/28 (29%) | WordPress blogs requiring JS rendering to access Recipe data |
| Dead URLs / no structured data | ~7/28 (25%) | 404s, social media, markdown, sites without schema.org |
| Median extraction time | 150ms | Fetch + parse combined |
| @graph wrappers encountered | 5/28 (18%) | Recipe nested in @graph array |
| HowToStep instructions | 11/28 (39%) | Most extracted sites use structured instruction format |
| HTML entities in JSON-LD | 7/28 (25%) | Requires entity decoding before JSON parsing |

### Why 46% ≠ 90%

The research doc's "~90%+ of major recipe sites have JSON-LD" is correct — most sites DO embed JSON-LD for Google Rich Results. However, ~30% of those sites render JSON-LD via client-side JavaScript (WordPress recipe plugins like WPRM inject the `<script type="application/ld+json">` tag after page load). `URLSession` only gets server-rendered HTML, missing these entirely.

**Implication**: Phase 1 must include a `WKWebView` fallback path that renders the page with JavaScript before extracting JSON-LD. This raises the extraction rate from ~46% to an estimated ~75-80%.

---

## Phase 1: URL Import — Acceptance Criteria

### P1-AC1: Extraction Success Rate

| Metric | Target | Rationale |
|--------|--------|-----------|
| Recipe extraction rate (Tier 1 sites) | ≥ 80% | Spike achieved 56% (5/9) without WKWebView; adding WKWebView fallback should reach 80%+ |
| Recipe extraction rate (Tier 2 blogs) | ≥ 70% | Blog platforms with WPRM/Tasty plugins should mostly work with WKWebView |
| Recipe extraction rate (all tiers) | ≥ 65% | Weighted across tiers including known-impossible sources |
| Full extraction rate (all core fields) | ≥ 50% | Spike: 32% without WKWebView; target with WKWebView is 50%+ |
| Graceful failure rate | 100% | Every failed extraction must show a user-facing message explaining what happened |

### P1-AC2: Per-Field Extraction Targets

Based on spike results for successfully extracted recipes:

| Field | Target Extraction Rate | Spike Actual | Notes |
|-------|----------------------|--------------|-------|
| Title | 100% | 100% (13/13) | Always present in Recipe JSON-LD |
| Ingredients | 100% | 100% (13/13) | recipeIngredient is the core field |
| Instructions | ≥ 95% | 100% (13/13) | Occasionally missing on partial extractions |
| Prep time | ≥ 75% | 69% (9/13) | ISO 8601 parsing; some sites omit |
| Cook time | ≥ 70% | 62% (8/13) | More commonly omitted than prepTime |
| Servings | ≥ 85% | 85% (11/13) | Various formats handled by yield parser |
| Image URL | ≥ 90% | 92% (12/13) | Nearly always present |
| Author | ≥ 80% | 85% (11/13) | Present in most JSON-LD |

### P1-AC3: Latency Targets

| Metric | Target | Spike Measurement |
|--------|--------|-------------------|
| Median extraction time (URLSession path) | < 500ms | 150ms median (spike) |
| P95 extraction time (URLSession path) | < 3s | 1.7s P95 (spike) |
| WKWebView fallback path | < 5s | Not measured in spike |
| End-to-end (fetch → preview shown) | < 3s (URLSession), < 8s (WKWebView) | Estimate based on spike + rendering overhead |

### P1-AC4: Error Handling

| Scenario | Expected Behavior | Pass Criteria |
|----------|-------------------|---------------|
| No JSON-LD found | Fall through to WKWebView, then heuristic | Message: "Attempting alternative extraction..." |
| Paywall detected (402/403) | Show partial extraction if available | Message: "This recipe may be behind a paywall..." |
| Network failure | Retry once, then show error | Message: "Unable to reach site. Check your connection." |
| Malformed JSON-LD | Log issue, continue to next strategy | Silent fallback, no crash |
| No recipe on page | Clear feedback | Message: "No recipe found on this page" |
| Multiple recipes on page | Extract first, note in preview | "Found X recipes — showing the first one" |
| Duplicate detection | Check sourceURL + fuzzy title | "Similar recipe found — import as new or replace?" |

### P1-AC5: Edge Case Coverage

Based on spike edge case frequencies:

| Edge Case | Frequency | Required Handling |
|-----------|-----------|-------------------|
| @graph wrapper nesting | 18% (5/28) | Recursive search through @graph arrays |
| Array @type (e.g., ["Recipe", "CreativeWork"]) | 11% (3/28) | Check array contains "Recipe" |
| HowToStep structured instructions | 39% (11/28) | Map to numbered step text |
| HowToSection nested instructions | 4% (1/28) | Flatten with section headers |
| HTML entities in JSON-LD | 25% (7/28) | Full entity decoding before parse |
| Unusual recipeYield formats | 14% (4/28) | Parse "6-8 servings", "Makes 12", etc. |
| Ingredient group headers | Unknown (0 in spike) | Filter "For the sauce:" style headers |

### P1-AC6: UX Flow Completion

| Flow | Acceptance Criteria |
|------|-------------------|
| Happy path (URL → preview → save) | Complete in < 4 taps from Share Sheet |
| Share extension | Accepts URL, hands off to main app within 2s |
| Import preview | Shows all extracted fields with edit capability |
| Partial extraction | Missing fields clearly indicated, editable |
| Cancel flow | No data persisted, clean return to previous screen |
| Post-save | Recipe appears in recipe list, ingredients connected to templates |

---

## Phase 2: Text Paste Import — Acceptance Criteria

| Metric | Target | How Measured |
|--------|--------|-------------|
| Ingredient detection accuracy | ≥ 85% of ingredient lines correctly identified | Test corpus of 50 pasted recipes |
| Section detection accuracy | ≥ 80% (title, ingredients, instructions, metadata) | Same test corpus |
| Foundation Models extraction quality | ≥ 90% when available (iPhone 15 Pro+) | Compare against manual extraction |
| Heuristic fallback quality | ≥ 70% on devices without Apple Intelligence | Test on non-Pro hardware |
| Latency (Foundation Models) | < 5s from paste to preview | Timer in import flow |
| Latency (heuristic) | < 1s from paste to preview | Timer in import flow |

---

## Phase 3: Photo/Image Import — Acceptance Criteria

| Metric | Target | How Measured |
|--------|--------|-------------|
| OCR accuracy (clean printed text) | ≥ 95% character accuracy | Test corpus of 20 cookbook photos |
| OCR accuracy (handwritten, neat) | ≥ 80% character accuracy | Test corpus of 10 handwritten recipes |
| End-to-end accuracy (OCR → structure) | ≥ 75% correct field extraction | Combined OCR + section detection |
| Latency (scan → preview) | < 8s | Timer including VNDocumentCamera + processing |

---

## Phase 4: Polish & Integration — Acceptance Criteria

| Metric | Target |
|--------|--------|
| Import history tracks all imports | 100% of imports logged with status |
| Household import sharing works | URL shared by member A visible to member B within CloudKit sync window |
| No regressions in existing recipe CRUD | All 267 existing tests pass |
| Performance targets maintained | All operations within CLAUDE.md performance targets |

---

## Cross-Phase Quality Gates

| Gate | Requirement |
|------|-------------|
| Zero silent failures | Every extraction failure must produce a user-visible message |
| Cancel-after-preview rate | < 25% (high cancel = poor extraction quality) |
| Post-import correction rate | < 3 fields corrected per import on average |
| Import → grocery integration | Imported ingredients connect to IngredientTemplate within 1 parse cycle |
| No data loss | Draft-first workflow: no Recipe entities created until user confirms |
| Accessibility | All import screens meet WCAG AA contrast (≥ 4.5:1 text, ≥ 3:1 UI) |
