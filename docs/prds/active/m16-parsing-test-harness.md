# PRD: Parsing Test Harness — Automated Recipe Parsing Evaluation Pipeline

**Milestone**: M16 (new)
**Status**: DRAFT
**Author**: Claude Code
**Date**: 2026-03-26

---

## Problem Statement

Testing ingredient parsing quality requires building the app, importing recipes on a physical device, and visually inspecting each ingredient. This is:
- **Slow**: ~2 min per recipe × 50 recipes = 100+ min per test cycle
- **Manual**: requires someone at a device to spot issues
- **Non-reproducible**: no structured comparison between runs
- **Blind to AI vs local differences**: can't easily compare what the local parser got vs what Claude API would return

The entire extraction and parsing stack is Foundation-only Swift — no Core Data, no UIKit — making it fully portable to a CLI tool.

## Solution

A standalone CLI tool (`ParsingHarness`) that automates the full cycle:

**Discover → Fetch → Extract → Parse (local + AI) → Compare → Report → Fix → Commit → Repeat**

Runs as `swift run ParsingHarness` from the terminal. No simulator. No device. Results in seconds for local parsing, minutes when including AI. Designed to run in a ralph loop for automated fix-rebuild-retest cycles.

### Critical Design Principle: Copy Then Refine

The harness **copies** the app's parsing files (not symlinks). This means:
- The harness starts with the **exact same code** the app uses
- Fixes are made to the harness copies during ralph loop iterations
- The app's `Services/Parsing/` files stay untouched during experimentation
- Once the harness reaches target quality, a **separate milestone** ports validated fixes back to the main app
- This is safer — experimental changes don't affect the shipping app

**Workflow**:
1. **M16**: Build harness, copy parsing files, run ralph loops, refine parsing in harness copies
2. **Future milestone**: Port validated fixes from `Tools/ParsingTestHarness/Sources/Parsing/` back to `Services/Parsing/`, rebuild app, ship to TestFlight

### Issue Tracking

A running log is maintained at `Tools/ParsingTestHarness/Results/issue-log.md`:
- Each loop records: what issues were found, what code was changed, what improved
- Format: timestamped entries with before/after metrics
- This log becomes the source for porting fixes back to the app later

### Commit Cadence

After each ralph loop iteration (run → fix → verify improvement):
1. `/forager-commit` with the harness fixes made in that iteration
2. Commit message references the issue-log entry
3. This creates a clean git history of incremental parsing improvements in the harness

---

## Detailed Process — Step by Step

### Step 1: Recipe Selection (RecipeDiscovery)

**What happens**: The harness selects 50 recipe URLs to test.

**Sources** (in priority order):
- `Results/previous-urls.json` — URLs from the last run (for reuse)
- `Data/recipe-urls.json` — curated seed list (~200 URLs to bootstrap)
- **Dynamic discovery** — fetch fresh URLs from recipe site sitemaps when seed list runs low

**Selection logic**:
1. Load `previous-urls.json` (if exists) → randomly pick **40%** (20 URLs) for reuse
2. Load `recipe-urls.json` → randomly pick **60%** (30 URLs) that weren't in the reuse set
3. Combine → 50 URLs total, tagged as `reuse` or `new`
4. Shuffle order (so site-specific rate limiting is naturally distributed)

**Broken link recovery**: The harness must always deliver the target count (default 50). When URLs fail (HTTP errors, no JSON-LD, timeout):
1. Log the failed URL and reason
2. Mark it as `broken` in `recipe-urls.json` (so it's never picked again)
3. Pull a replacement URL from the seed list (excluding already-selected and broken URLs)
4. Retry until target count is reached or seed list is exhausted
5. If seed list runs low (<20 remaining healthy URLs), warn: "Seed list running thin — add more URLs"

This ensures every run processes the full 50 recipes regardless of how many links have gone stale.

**Dynamic URL discovery** (keeps the pool fresh across loops):

When the seed list drops below a healthy threshold (e.g., <50 unused healthy URLs), the harness automatically replenishes by crawling recipe site sitemaps:

1. Maintain a list of **sitemap URLs** for known recipe sites in `Data/sitemap-sources.json`:
   ```json
   [
     {"site": "allrecipes", "sitemap": "https://www.allrecipes.com/sitemap.xml"},
     {"site": "budgetbytes", "sitemap": "https://www.budgetbytes.com/post-sitemap.xml"},
     {"site": "simplyrecipes", "sitemap": "https://www.simplyrecipes.com/sitemap.xml"}
   ]
   ```
2. Fetch the sitemap XML, parse `<url><loc>` entries
3. Filter for recipe-looking URLs (contain `/recipe/` or `/recipes/` in path)
4. Randomly sample N new URLs, add to `recipe-urls.json`
5. Mark URLs as `discovered` (vs `curated`) for tracking

This means the harness can run indefinitely — as links break, fresh ones are discovered from sitemaps. Each loop naturally mixes in new recipes alongside reused ones, continuously testing the parsers against novel input.

**Why reuse matters**: After fixing a parser bug, you need to retest the SAME recipes that triggered it. The 40/60 split ensures regression coverage while also testing against fresh data.

**CLI overrides**:
- `--count 50` — total recipes (default 50)
- `--reuse 40` — reuse percentage (default 40%)
- `--rerun-last` — 100% reuse (exact same URLs as last run)
- `--urls "url1,url2"` — test specific URLs only

**Output**: Array of `{url, source: "reuse"|"new", siteTag, status}` written to stdout as progress.

---

### Step 2: Fetch & Extract (reuses import-spike code)

**What happens**: For each URL, fetch the HTML and extract recipe data via JSON-LD.

**Process per URL**:
1. `URLSession` GET with mobile User-Agent, 15s timeout
2. Pass HTML to `RecipeJSONLDExtractor.extract()` (3-tier strategy: standard ld+json → inline scripts → `__NEXT_DATA__`)
3. Map to `ExtractedRecipe` via `SchemaRecipeMapper`
4. Extract `recipe.ingredients` — the raw ingredient text strings (typically 8-20 per recipe)
5. Wait 2 seconds before next URL (rate limiting)

**Error handling** (feeds into recipe selection — broken URLs trigger replacement):
- HTTP 403/429 (blocked): log, mark URL as broken in seed list, pull replacement
- No JSON-LD found: log, mark as broken, pull replacement
- JSON-LD found but no Recipe: log with details, mark as broken, pull replacement
- Timeout: retry once; if still fails, mark as broken, pull replacement
- Replacement URLs come from unused portion of seed list
- Goal: always achieve target recipe count (default 50)

**Code reuse**: These files are copied from `Tools/import-spike/`:
- `RecipeJSONLDExtractor.swift`
- `SchemaRecipeMapper.swift`
- `ExtractedRecipe.swift`
- `ISO8601DurationParser.swift`

**Output per recipe**: `{url, title, ingredientTexts: [String], extractionMethod, extractionTimeMs, issues}`

**Expected**: ~48/50 recipes extract successfully (96% based on import-spike testing).

---

### Step 3: Parse — Local Parsers

**What happens**: Every extracted ingredient string is parsed by ALL local parsers independently.

**Process per ingredient string**:
1. **Preprocess**: `IngredientPreprocessor.sanitize(text)` — strips prices, HTML entities, footnotes, leading commas, etc.
2. **Regex parse**: `RegexIngredientParser().parse(sanitized)` → `ParserResult` with confidence
3. **NLP parse**: `NLPIngredientParser().parse(sanitized)` → `ParserResult` with confidence (capped 0.75)
4. **Hybrid parse**: `HybridIngredientParser(mlParser: nil).parse(sanitized)` → `ParserResult` (this is what the app actually uses — routes between regex ≥0.9 and NLP fallback)

**Why run all three independently?** The hybrid router picks ONE, but seeing all three tells you:
- Is regex failing on something NLP handles? (routing issue)
- Is NLP giving a better result than regex but confidence thresholds prevent it from being used?
- Where does confidence drop? (indicates parser struggling)

**Stored per ingredient**:
```json
{
  "raw": "6 Tablespoons butter, melted",
  "sanitized": "6 Tablespoons butter, melted",
  "regex": {"name": "butter", "quantity": 6.0, "unit": "tbsp", "notes": "melted", "confidence": 0.95},
  "nlp": {"name": "butter", "quantity": 6.0, "unit": "tbsp", "notes": "melted", "confidence": 0.75},
  "hybrid": {"name": "butter", "quantity": 6.0, "unit": "tbsp", "notes": "melted", "confidence": 0.95, "parserUsed": "regex"}
}
```

**Code reuse**: Copied from `Services/Parsing/` (9 files). Edits to these harness copies are picked up on next `swift build`. Once validated, fixes are ported back to the app in a separate milestone.

---

### Step 4: Parse — Claude API

**What happens**: The same ingredient strings are sent to the Claude API for comparison parsing.

**Prerequisites**: `ANTHROPIC_API_KEY` environment variable must be set. If not set, this step is **skipped entirely** with a warning — the harness still produces a useful local-only report.

**Process per recipe** (batch, not per-ingredient):
1. Collect all ingredient strings for the recipe
2. Call `ClaudeIngredientParser.parseBatch(ingredients:, apiKey:)` — sends one API request per recipe
3. Parse returns: name, quantity, unit, notes for each ingredient
4. If batch count doesn't match input count (known edge case), fall back to individual parsing

**Rate limiting**: The Claude API has rate limits. With ~50 recipes averaging 12 ingredients each (~600 ingredients total), batching by recipe means ~50 API calls. At ~1 second per call, this adds ~2 minutes to the run.

**Stored per ingredient**:
```json
{
  "ai": {"name": "butter", "quantity": 6.0, "unit": "tbsp", "notes": "melted", "provider": "claude"}
}
```

**Cost estimate**: ~600 ingredients × ~100 tokens each ≈ 60K input tokens + 30K output tokens per run. At current Claude pricing, this is roughly $0.10-0.20 per run.

---

### Step 5: Compare & Evaluate

**What happens**: Side-by-side comparison of local vs AI results, with automated issue detection.

**Comparison logic per ingredient**:
1. Compare hybrid result vs AI result on each field:
   - **name**: exact match after lowercasing + trimming
   - **quantity**: numeric match within 0.01 tolerance (handles float precision)
   - **unit**: normalized match (e.g., "tbsp" == "tablespoon")
   - **notes**: fuzzy match (contains check, since AI may phrase differently)
2. Classify the disagreement:
   - `agreement` — both match
   - `local_likely_wrong` — AI result looks more reasonable (e.g., local has "(, melted)" but AI has "melted")
   - `ai_likely_wrong` — local result looks more reasonable
   - `both_wrong` — neither looks correct
   - `ambiguous` — can't determine which is better

**Pattern detection**: Group issues by pattern to identify systemic problems:
- "leading comma in qualifier" (7 occurrences)
- "word merge in name" (3 occurrences)
- "price not stripped" (2 occurrences)
- "unit not normalized" (5 occurrences)

**Regression detection**: If `baseline.json` exists, compare current run against it:
- New failures that weren't in baseline → REGRESSION
- Fixed issues that were in baseline → IMPROVEMENT
- Net score change

---

### Step 6: Report Generation

**What happens**: Produces both human-readable output (stderr) and machine-readable JSON (stdout).

**Human-readable summary** (printed to terminal):
```
═══════════════════════════════════════════════════════
PARSING HARNESS REPORT — Run 2026-03-26T14:30:00
═══════════════════════════════════════════════════════
Recipes:           48/50 extracted (2 blocked)
Ingredients:       487 total
Reuse:             20 recipes (40%), 30 new (60%)

LOCAL PARSING:
  Avg confidence:  0.89
  Router:          regex 78% | nlp 22%
  Preprocessor fixes: 34 ingredients modified

AI PARSING:
  Processed:       487/487
  Batch success:   48/48 recipes

COMPARISON:
  Agreement:       453/487 (93%)
  Local likely wrong: 22
  AI likely wrong:    8
  Ambiguous:          4

TOP ISSUES (local parser):
  1. Leading comma in qualifier    ×7  (e.g., "(, melted)")
  2. Unit not normalized           ×5  (e.g., "Tablespoons" → should be "tbsp")
  3. Word merge in name            ×3  (e.g., "butteror")
  4. Quantity range not parsed      ×2  (e.g., "1-2 tsp")

REGRESSIONS vs baseline: 0
IMPROVEMENTS vs baseline: 3
═══════════════════════════════════════════════════════
```

**JSON output**: Full structured data (see Output Format in architecture section).

---

### Step 7: Persist Results

**What happens**: Save everything for future comparison and reuse.

**Files written**:
- `Results/run-{timestamp}.json` — complete run data (recipes, ingredients, all parse results, comparison)
- `Results/previous-urls.json` — URL list for next run's reuse pool
- `Results/baseline.json` — only when `--update-baseline` flag is passed

**Retention**: Keep last 10 run files, auto-delete older ones.

---

## Ralph Loop Workflow

This is how Claude Code operates the harness in a ralph loop:

```
┌─────────────────────────────────────────────────┐
│  1. RUN HARNESS                                  │
│     swift run --package-path                     │
│       Tools/ParsingTestHarness ParsingHarness    │
│     → produces report with issues                │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  2. READ REPORT                                  │
│     Parse the JSON output                        │
│     Identify top issues by frequency             │
│     Check for regressions                        │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  3. FIX CODE                                     │
│     Edit Tools/ParsingTestHarness/Sources/       │
│       Parsing/*.swift (harness copies)           │
│     Log what was changed in issue-log.md         │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  4. RETEST (same recipes)                        │
│     swift run ... ParsingHarness --rerun-last    │
│     → compare: did fixes improve? regressions?   │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  5. COMMIT (after verified improvement)          │
│     /forager-commit with fix description         │
│     Update issue-log.md with results             │
│     Update development-journal.md                │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  6. (OPTIONAL) REBUILD APP                       │
│     Only after porting fixes to app in a         │
│     separate future milestone                    │
└─────────────────┬───────────────────────────────┘
                  ↓
┌─────────────────────────────────────────────────┐
│  7. NEW RUN (fresh recipes)                      │
│     swift run ... ParsingHarness                 │
│     → 40% reuse + 60% new recipes                │
│     → loop back to step 2                        │
└─────────────────────────────────────────────────┘
```

### Commit Strategy

Each loop iteration that produces a verified fix gets its own commit:
- `M16.7: Fix <specific issue> in <parser>` — imperative mood, milestone prefix
- The commit includes changes to `Tools/ParsingTestHarness/Sources/Parsing/*.swift` (harness copies only)
- Also includes the updated `issue-log.md` entry
- Multiple small commits > one big commit — easier to review when porting back to app
- The app's `Services/Parsing/` files are NOT touched during harness work

---

## API Key Handling

The Claude API key is required for AI parsing comparison. Two options for providing it:

**Option A — Export in terminal** (recommended):
```bash
export ANTHROPIC_API_KEY=sk-ant-api03-...
swift run --package-path Tools/ParsingTestHarness ParsingHarness
```

**Option B — Inline per command**:
```bash
ANTHROPIC_API_KEY=sk-ant-api03-... swift run --package-path Tools/ParsingTestHarness ParsingHarness
```

**If not set**: The harness runs local-only parsing and notes "AI parsing skipped — ANTHROPIC_API_KEY not set" in the report. Still produces a useful report for local parser evaluation.

---

## File Structure

```
Tools/ParsingTestHarness/
├── Package.swift
├── Sources/
│   ├── Extraction/              # Copied from Tools/import-spike/
│   │   ├── RecipeJSONLDExtractor.swift
│   │   ├── SchemaRecipeMapper.swift
│   │   ├── ExtractedRecipe.swift
│   │   └── ISO8601DurationParser.swift
│   ├── Parsing/                 # Copied from Services/Parsing/ (refined in harness)
│   │   ├── IngredientParser.swift
│   │   ├── RegexIngredientParser.swift
│   │   ├── NLPIngredientParser.swift
│   │   ├── HybridIngredientParser.swift
│   │   ├── IngredientPreprocessor.swift
│   │   ├── IngredientTokenizer.swift
│   │   ├── ViterbiDecoder.swift
│   │   ├── LLMIngredientParser.swift
│   │   └── ClaudeIngredientParser.swift
│   ├── Harness/                 # New code
│   │   ├── main.swift
│   │   ├── RecipeDiscovery.swift       # URL selection + broken link recovery
│   │   ├── SitemapCrawler.swift        # Dynamic URL discovery from sitemaps
│   │   ├── RecipeFetcher.swift
│   │   ├── ParsingEvaluator.swift
│   │   ├── ResultComparer.swift
│   │   ├── ResultStore.swift
│   │   └── ReportGenerator.swift
│   └── Stubs/
│       └── DebugLogServiceStub.swift
├── Data/
│   ├── recipe-urls.json         # ~200 curated seed URLs (grows via discovery)
│   ├── sitemap-sources.json     # Sitemap URLs for dynamic discovery
│   └── unit-normalization.json  # unit synonym map for comparison
├── Results/                     # gitignored, persisted between runs
└── run-harness.sh               # ralph loop entry point
```

---

## Seed URL List Coverage

~200 URLs across recipe site tiers:

| Tier | Sites | URLs | Characteristics |
|------|-------|------|----------------|
| 1 (high traffic) | AllRecipes, Food Network, Tastes Better from Scratch | ~50 | Standard JSON-LD, well-structured |
| 2 (popular blogs) | Pinch of Yum, RecipeTinEats, Budget Bytes, Simply Recipes, Serious Eats | ~60 | WordPress plugins, price annotations, footnotes |
| 3 (niche) | Maangchi, Just One Cookbook, Cookie and Kate, Half Baked Harvest | ~50 | International ingredients, unusual formats |
| 4 (edge cases) | NYT Cooking, Bon Appetit, King Arthur, various Next.js sites | ~40 | Paywalls, SSR, unusual JSON-LD nesting |

---

## Milestone Setup

This is **M16: Parsing Test Harness**. Use `/forager-new-milestone` to create:
- Branch: `feature/M16-parsing-test-harness`
- Update `docs/current-story.md` and `docs/next-prompt.md`
- PRD saved to `docs/prds/m16-parsing-test-harness.md`

Sub-milestones:
- **M16.1**: Package scaffold, symlinks, compilation
- **M16.2**: Recipe fetch + extract pipeline
- **M16.3**: Local parsing integration
- **M16.4**: AI parsing integration
- **M16.5**: Comparison, reporting, result storage
- **M16.6**: CLI, ralph loop, seed URL curation
- **M16.7+**: Each ralph loop fix iteration

---

## Implementation Steps

### Phase 1 (M16.1): Package scaffold + file copies
- Create directory structure
- Write Package.swift
- Copy all 13 source files (9 from `Services/Parsing/` + 4 from `Tools/import-spike/`)
- Write DebugLogServiceStub (no-op for `#if DEBUG` references)
- Verify `swift build` compiles

### Phase 2 (M16.2): Recipe fetch + extract pipeline
- RecipeDiscovery.swift (URL selection logic)
- RecipeFetcher.swift (HTTP fetch + JSON-LD extraction, reusing import-spike code patterns)
- Verify: fetch 5 URLs, extract ingredients

### Phase 3 (M16.3): Local parsing
- ParsingEvaluator.swift (run regex/NLP/hybrid on each ingredient)
- Verify: parse extracted ingredients, output structured results

### Phase 4 (M16.4): AI parsing
- Add Claude API batching to ParsingEvaluator
- Handle missing API key gracefully
- Verify: parse same ingredients via API, compare

### Phase 5 (M16.5): Comparison + reporting
- ResultComparer.swift (side-by-side analysis, pattern detection)
- ReportGenerator.swift (human + JSON output)
- ResultStore.swift (persist runs, manage reuse list, baseline comparison)

### Phase 6 (M16.6): CLI + ralph loop
- main.swift (argument parsing, orchestration)
- run-harness.sh (wrapper script)
- Curate seed URL list (200 URLs)
- End-to-end verification with full 50-recipe run

---

## Issue Log Format

`Tools/ParsingTestHarness/Results/issue-log.md`:

```markdown
## Loop 1 — 2026-03-26T14:30

### Run Summary
- Recipes: 48/50 | Ingredients: 487 | Agreement: 93%

### Issues Found
1. **Leading comma in qualifier** (×7) — e.g., "(, melted)" in RecipeTinEats, TBTFS
2. **Unit not normalized** (×5) — "Tablespoons" staying as-is instead of "tbsp"

### Fixes Applied
1. `IngredientPreprocessor.swift:149` — already fixed in M9.35.3 (display path),
   but raw parser output still has it → fix in `RegexIngredientParser.tryQualifierPattern()`
2. `RegexIngredientParser.swift:445` — added "Tablespoons" to unit normalization map

### Results After Fix
- Agreement: 93% → 95.5% (+2.5%)
- Regressions: 0
- Commit: `M16.7: Fix qualifier comma stripping and unit normalization`

---
## Loop 2 — 2026-03-26T15:15
...
```

---

## Success Criteria

1. `swift run ParsingHarness --count 5` completes in <30 seconds (local only)
2. Full 50-recipe run completes in <5 minutes (local) or <8 minutes (with AI)
3. Report clearly identifies parsing issues with examples
4. `--rerun-last` produces reproducible results
5. Editing harness copies → `swift build` picks up changes immediately
6. Ralph loop cycle works: run → identify issues → fix → retest → verify improvement → commit
7. Issue log tracks every finding and fix for audit trail
