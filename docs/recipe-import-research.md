# Recipe Import Research

**Date**: February 21, 2026
**Status**: Research Complete — Ready for PRD
**Scope**: URL import, text paste, photo/image import
**For**: Future Forager feature (post-M8.4)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Forager's Existing Architecture](#foragers-existing-architecture)
3. [URL Import (JSON-LD / Schema.org)](#url-import)
4. [Text Paste Import](#text-paste-import)
5. [Photo / Image Import](#photo--image-import)
6. [Competitive Landscape](#competitive-landscape)
7. [User Pain Points Across Apps](#user-pain-points)
8. [Forager Differentiators](#forager-differentiators)
9. [Recommended Implementation Plan](#recommended-implementation-plan)
10. [Key Technical Decisions](#key-technical-decisions)
11. [M8.4 Architecture Validation for Recipe Import](#m84-architecture-validation-for-recipe-import)
12. [Competitive Parsing Quality & User Complaints](#competitive-parsing-quality--user-complaints)
13. [AI-Assisted Import Strategy](#ai-assisted-import-strategy)
14. [Sources & References](#sources--references)

---

## Executive Summary

Recipe importing is table-stakes for competitive recipe apps. The market has shifted from schema.org-only extraction (2020-2023) to AI-powered multi-modal import (2024-2026). Key findings:

- **JSON-LD extraction** requires zero dependencies (pure Foundation regex + JSONSerialization) and covers ~90%+ of major recipe sites
- **Apple Foundation Models `@Generable`** (iOS 26) is the breakthrough for text and photo import — constrained structured output, on-device, offline, no API costs
- **No app does fully automatic photo import well** — semi-automated (Mela-style) is the gold standard
- **Share extension is table stakes** — Mela, AnyList, and Pestle all have one
- **Forager's existing architecture is well-positioned** — `sourceURL`, `RecipeService`, `IngredientParsingService.parseAndConnectIngredients()`, and `RecipeFormData` already form the integration surface

---

## Forager's Existing Architecture

### Already Have (No Changes Needed)

| Component | Location | Relevance |
|-----------|----------|-----------|
| `Recipe.sourceURL` | `Recipe+CoreDataProperties.swift` | Stores source URL for imported recipes |
| `RecipeService.createRecipe()` | `Services/RecipeService.swift` | Accepts title, servings, prepTime, cookTime, instructions, sourceURL |
| `RecipeService.addIngredient(to:parsed:name:)` | `Services/RecipeService.swift` | Convenience for parse→service pipeline |
| `IngredientParsingService.parseAndConnectIngredients()` | `Services/IngredientParsingService.swift` | Bulk import: takes Recipe + string array, creates Ingredient entities, connects templates |
| `RecipeFormData` / `IngredientInput` | `Services/RecipeFormModels.swift` | Preview/edit model — can serve as import preview |
| `IngredientParsingService.extractCleanIngredientName()` | `Services/IngredientParsingService.swift` | Static method for clean name extraction |
| `parseConfidence` field | `Ingredient+CoreDataProperties.swift` | Already tracks extraction confidence per ingredient |
| `HybridIngredientParser` | `Services/Parsing/` | Regex fast path + NLP fallback, protocol-based |

### Key Integration Points

```swift
// 1. Create recipe from imported data
let recipe = recipeService.createRecipe(
    title: imported.title,
    servings: Int16(imported.servings),
    prepTime: Int16(imported.prepTime),
    cookTime: Int16(imported.cookTime),
    instructions: imported.instructions,
    sourceURL: imported.sourceURL
)

// 2. Bulk-add ingredients through parsing pipeline
let ingredients = parsingService.parseAndConnectIngredients(
    for: recipe,
    ingredientTexts: imported.ingredientStrings
)

// 3. Preview before save using existing form model
let formData = RecipeFormData(from: recipe)
```

### What's New (Needs Building)

- **Recipe import service** — orchestrates fetch → extract → preview → save
- **JSON-LD extractor** — parses schema.org/Recipe from HTML
- **Share extension** — iOS app extension for Safari Share Sheet
- **Import preview UI** — shows extracted recipe before committing
- **Text/photo import views** — paste or camera input surfaces
- **Foundation Models integration** — `@Generable` structs for AI extraction

---

## URL Import

### How It Works

1. User shares or pastes a recipe URL
2. App fetches HTML content
3. Extract JSON-LD `<script type="application/ld+json">` blocks
4. Parse schema.org/Recipe object
5. Map to Forager's data model
6. Show preview → user confirms → save

### JSON-LD Extraction (Zero Dependencies)

~90%+ of major recipe sites embed JSON-LD for SEO (Google Rich Results). This is the primary extraction path.

```swift
// 1. Find JSON-LD script tags
let pattern = #"<script[^>]*type\s*=\s*"application/ld\+json"[^>]*>(.*?)</script>"#
let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)

// 2. Parse JSON
let jsonObject = try JSONSerialization.jsonObject(with: data)

// 3. Find Recipe in @graph or top-level
// Handle: direct Recipe, @graph array, nested types
```

### Schema.org/Recipe → Forager Mapping

| Schema.org Field | Forager Field | Notes |
|-----------------|---------------|-------|
| `name` | `Recipe.title` | Direct map |
| `recipeIngredient` | Array of strings → `parseAndConnectIngredients()` | Already have the pipeline |
| `recipeInstructions` | `Recipe.instructions` | May be string, array, or HowToStep/HowToSection |
| `prepTime` | `Recipe.prepTime` | ISO 8601 duration (PT30M → 30) |
| `cookTime` | `Recipe.cookTime` | ISO 8601 duration |
| `recipeYield` | `Recipe.servings` | Formats vary: "4", "4 servings", "Makes 12" |
| `image` | Future: `Recipe.imageData` | URL string or array — need to fetch separately |
| `url` / source | `Recipe.sourceURL` | Already exists in model |

### Edge Cases to Handle

- **@graph wrappers**: Some sites put Recipe inside `{"@graph": [...]}` — must unwrap
- **Array @type**: `"@type": ["Recipe", "CreativeWork"]` — check if array contains "Recipe"
- **HowToSection nesting**: Instructions may be nested sections (e.g., "For the sauce", "For the filling") — flatten or preserve structure
- **recipeYield formats**: "4", "4 servings", "Makes 12 cookies", "6-8" — need robust parsing
- **HTML entities in JSON-LD**: Some sites include `&amp;`, `&#39;` etc. in JSON-LD strings
- **Multiple Recipe objects**: Some pages have multiple recipes — need selection UI or take first
- **Missing fields**: Graceful degradation when prepTime, cookTime, or servings are absent

### Fallback: HTML Heuristic Parsing

When JSON-LD is absent (~10% of sites), fall back to:
1. Look for microdata (`itemtype="http://schema.org/Recipe"` with `itemprop` attributes)
2. Look for common CSS class patterns (`.recipe-ingredients`, `.wprm-recipe`, etc.)
3. WordPress recipe plugins (WPRM, Tasty, etc.) generate predictable HTML structures
4. **Last resort**: Foundation Models `@Generable` on extracted text content

### Legal Considerations

- **JSON-LD extraction is safe** — data is intentionally published for search engines (Google, Bing)
- **Recipe ingredient lists are not copyrightable** (Publications International v. Meredith Corp)
- **Single-fetch on user action** with proper User-Agent is clean — no scraping at scale
- **Respect robots.txt** as best practice, though user-initiated single fetches are generally fine
- **Don't cache/redistribute** recipe content beyond the user's personal collection

### Estimated Effort: 15-20 hours

---

## Text Paste Import

### How It Works

1. User pastes unstructured recipe text (from email, notes, message, etc.)
2. App analyzes text to identify sections (title, ingredients, instructions, metadata)
3. Extract structured data from each section
4. Show preview → user confirms → save

### Primary Approach: Foundation Models `@Generable` (iOS 26+)

Apple's on-device LLM with constrained structured output is the breakthrough here.

```swift
import FoundationModels

@Generable
struct ImportedRecipe {
    @Guide("The recipe title")
    var title: String

    @Guide("Number of servings")
    var servings: Int

    @Guide("Prep time in minutes")
    var prepTime: Int

    @Guide("Cook time in minutes")
    var cookTime: Int

    @Guide("List of ingredients with quantities")
    var ingredients: [String]

    @Guide("Step-by-step cooking instructions")
    var instructions: String
}

// Usage
let session = LanguageModelSession()
let result = try await session.respond(
    to: "Extract the recipe from this text: \(pastedText)",
    generating: ImportedRecipe.self
)
```

**Advantages:**
- On-device, offline, no API costs
- Constrained output — always returns valid structured data
- 2-5 second latency
- Privacy-preserving

**Limitations:**
- Requires Apple Intelligence hardware (iPhone 15 Pro+ / M1+)
- Need fallback for older devices

### Fallback: Heuristic Section Detection

For devices without Apple Intelligence:

```
Line scoring approach:
- Starts with number/fraction + contains unit word → ingredient (0.8)
- Starts with verb (preheat, mix, stir, bake) → instruction (0.7)
- Short line with time/temp pattern → metadata (0.6)
- Contains "serves", "yield", "makes" → servings (0.9)
- First non-empty line or line with Title Case → title candidate (0.5)
```

Signals for ingredient detection:
- Contains known unit (cup, tbsp, oz, lb, g, ml, etc.)
- Starts with numeric value or fraction
- Matches `quantity unit ingredient` pattern
- Short-to-medium line length (vs. instruction paragraphs)

Signals for instruction detection:
- Starts with imperative verb
- Longer line length
- Contains temperature references (350°F, 180°C)
- Contains time references (10 minutes, 1 hour)
- Numbered or bulleted list items

### Estimated Effort: 12-16 hours

---

## Photo / Image Import

### How It Works

1. User photographs a cookbook page or recipe card (or selects from photo library)
2. `VNDocumentCameraViewController` handles scanning with edge detection
3. `VNRecognizeTextRequest` performs OCR on the scanned image
4. Text is processed through the same extraction pipeline as text paste
5. Show preview → user edits/confirms → save

### OCR Pipeline

```swift
// 1. Document scanner
let scanner = VNDocumentCameraViewController()
scanner.delegate = self

// 2. OCR on scanned pages
let request = VNRecognizeTextRequest { request, error in
    guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
    let text = observations.compactMap { $0.topCandidates(1).first?.string }
}
request.recognitionLevel = .accurate
request.usesLanguageCorrection = true

// 3. Process extracted text through text paste pipeline
```

### Accuracy Expectations

| Content Type | Accuracy | Notes |
|-------------|----------|-------|
| Clean printed text | 98-99% | Excellent with `.accurate` mode |
| Magazine/cookbook pages | 95-98% | Good, may struggle with unusual fonts |
| Handwritten (neat) | 80-90% | Usable but needs review |
| Handwritten (cursive) | 60-80% | Often needs significant editing |
| Multi-column layouts | Variable | May need column detection logic |

### Semi-Automated Approach (Mela-Style — Gold Standard)

No app does fully automatic photo import reliably. The best approach:

1. **OCR extracts text blocks** with bounding box positions
2. **Display text overlaid on image** so user can see what was detected
3. **User assigns sections**: tap text blocks to label as "ingredient", "instruction", "title"
4. **Or use AI to pre-assign** and let user confirm/correct

This is more work than fully-automatic but far more reliable. Users accept the trade-off because the alternative (manual typing) is much worse.

### Foundation Models Enhancement

For iOS 26+ devices, after OCR extracts raw text:
1. Send OCR text through `@Generable` extraction (same as text paste)
2. AI handles section detection, quantity normalization, instruction ordering
3. Show preview with confidence indicators
4. User confirms or edits

### Estimated Effort: 20-25 hours

---

## Competitive Landscape

### App Comparison Matrix

| App | URL | Share Ext. | Photo/OCR | Social Video | Browser Ext. | AI/ML | Price |
|-----|-----|-----------|-----------|-------------|-------------|-------|-------|
| **Paprika** | Built-in browser | Safari only | No | No | Bookmarklet | No | $4.99 one-time |
| **Mela** | In-app + share | Yes (rich preview) | Yes | Yes (YT/IG/TT) | No | OCR + video | $5.99 one-time |
| **Crouton** | Clipboard detect | No | Yes (AI camera) | No | No | AI photo scan | $8.99/yr |
| **AnyList** | In-app + share | Yes | No | No | Chrome/FF/Safari/Edge | No | Freemium (5 free) |
| **CookBook** | In-app | Limited | Yes (free OCR) | Yes (IG/TT/FB) | No | AI scanner (2024) | Freemium |
| **Pestle** | Share ext. | Yes | No | Yes (IG/TT) | No | On-device ML + Apple Intelligence | $2.99/mo or $39.99 lifetime |
| **Recipe Keeper** | In-app | No | Yes (OCR + PDF) | No | No | OCR | One-time |

### Market Tiers

| Tier | Apps | Approach |
|------|------|----------|
| **AI-first** (2024+) | Pestle, Crouton | On-device ML, ~0.1s extraction, privacy-first |
| **Multi-modal** | Mela, CookBook | OCR + video + schema.org, broadest input support |
| **Traditional** | Paprika, AnyList | Schema.org/JSON-LD only, reliable but limited |

### Detailed App Analysis

#### Paprika Recipe Manager
- **Signature feature**: Built-in browser with one-tap "Download" button
- **Fallback**: Clipboard toolbar for manual field-by-field copy/paste when auto-extraction fails
- **Strengths**: Gold standard for web extraction reliability, 4.5-4.9 stars
- **Weaknesses**: Dated UI, no photo/OCR, no social media, no AI layer
- **UX flow**: Open Paprika → browse in-app → tap Download → recipe saved

#### Mela
- **Signature feature**: Share extension with rich preview (shows parsed recipe before saving)
- **Import breadth**: URL, share extension, clipboard detection, plain text, photo/OCR, social video (YT/IG/TT), bulk import from Paprika
- **Strengths**: MacStories "best-in-class" for web importing, elegant design
- **Weaknesses**: Apple ecosystem only, occasional failures on non-standard layouts
- **UX flow**: Safari → Share → Mela → see preview → tap Save

#### Crouton
- **Signature feature**: AI-powered camera scan of cookbook/magazine pages
- **Import pattern**: Clipboard-first (copy URL → open app → popup offers import)
- **Strengths**: Apple Design Award winner, timer detection in recipe steps
- **Weaknesses**: AI scan struggles with multi-component recipes, no share extension
- **UX flow**: Copy URL → open Crouton → "Import?" popup → one tap

#### AnyList
- **Signature feature**: Browser extensions for Chrome, Firefox, Safari, Edge (desktop)
- **Strengths**: Cross-browser desktop support (unique), grocery list integration
- **Weaknesses**: 5-recipe free limit, inconsistent on non-schema.org sites
- **UX flow**: Click browser extension → recipe extracted → syncs to app

#### Pestle
- **Signature feature**: On-device ML for social media video caption extraction (~0.1s)
- **Philosophy**: Explicitly chose on-device ML over ChatGPT for speed, privacy, control
- **Apple Intelligence**: iOS 26+ integration for broader website extraction
- **Strengths**: 4.7/5 stars, fastest extraction, full Apple ecosystem
- **Weaknesses**: No photo/OCR, occasional reliability reports, no Android
- **UX flow**: Share TikTok/IG link → Pestle → AI extracts → recipe saved instantly

#### CookBook (Recipe Keeper)
- **Signature feature**: Free OCR tool (unique — most apps paywall OCR)
- **Recent additions**: AI scanner, social media import (late 2024)
- **Weaknesses**: Inconsistent extraction — "sometimes working perfectly and sometimes missing almost all major parts"
- **Lesson**: Unreliable extraction is worse than no extraction

#### Recipe Keeper
- **Signature feature**: Handwriting OCR (including cursive, "only a couple of small errors")
- **Strengths**: Cross-platform (iOS, Android, Windows, Mac), one-time purchase
- **Weaknesses**: Web clipper less robust than Paprika, no social video

### Import Method Adoption

| Method | Apps Supporting | Status |
|--------|----------------|--------|
| Web URL import | All 7 | Table stakes |
| Share extension | Mela, AnyList, Pestle | Emerging standard |
| Clipboard URL detection | Mela, Crouton | Convenient but less discoverable |
| Photo/OCR scan | Mela, Crouton, CookBook, Recipe Keeper | Growing rapidly (2024-2025) |
| Social media video | Mela, CookBook, Pestle | The frontier — high user demand |
| Built-in browser | Paprika, Mela | Legacy pattern |
| Browser extensions (desktop) | Paprika (bookmarklet), AnyList | AnyList leads |
| Bulk import from other apps | Mela, Pestle, AnyList, Crouton | Important for switching users |

### Three Dominant UX Patterns

1. **Share Sheet flow** (Mela, AnyList, Pestle): Find recipe in Safari → Share → select app → preview → Save. Fastest path from discovery to save.

2. **Clipboard detection flow** (Crouton, Mela): Copy URL → switch to app → app detects URL → import prompt → one tap. Fewer taps but triggers iOS clipboard permission toast.

3. **Built-in browser flow** (Paprika): Open app → browse in-app → tap Download. More isolated but gives app maximum extraction control.

### How Apps Handle Import Failures

- **Paprika**: Clipboard toolbar for manual field-by-field copy/paste (best fallback UX)
- **Mela**: Preview before saving — user sees what's missing and can edit
- **AnyList**: Falls back to manual copy/paste, documentation acknowledges limitations
- **CookBook**: Inconsistent — sometimes succeeds, sometimes fails silently (worst pattern)
- **General**: Most allow post-import editing but few provide clear guidance on partial failures

---

## User Pain Points

### Top Complaints Across All Recipe Apps

1. **Inconsistent extraction quality** — #1 frustration. Works on major sites (Allrecipes, Food Network), fails on blogs and personal sites. CookBook's review captures it: "sometimes working perfectly and sometimes missing almost all major parts."

2. **Paywalled recipe sites** — NYT Cooking, Bon Appetit, Cook's Illustrated. Paprika handles these better than most; others largely fail. Growing problem as more sites add paywalls.

3. **Recipe blog bloat** — "Life story" preambles frustrate users. Apps that extract just the recipe (especially via share extensions that never show the blog) are strongly preferred. WordPress recipe plugins (WPRM, Tasty) generate JSON-LD that bypasses this entirely.

4. **Social media recipes without text** — TikTok/Instagram recipes that are purely video (no caption text) remain unsolvable. Only recipes with ingredient lists in video descriptions can be extracted.

5. **Multi-component recipes** — Recipes with sub-recipes ("For the sauce", "For the filling") import as flat lists, losing logical grouping. No app handles this well.

6. **Lost metadata on cross-app import** — Date saved, source URLs, images lost when switching apps.

7. **Photo/OCR accuracy** — Improving but still requires manual cleanup. Multi-column layouts, inline images, and unusual handwriting remain challenging.

### Sites That Commonly Fail

- Paywalled sites (NYT Cooking, Cook's Illustrated, Bon Appetit premium)
- Personal blogs without schema.org markup
- Pinterest pins (link to images, not structured recipes)
- Social media posts without text descriptions
- PDF recipes and scanned cookbook pages
- Sites with aggressive ad/popup overlays

### Features Users Wish Existed

- Universal import that works on every site (perennial wish)
- Unit conversion during import (imperial ↔ metric)
- Smart deduplication when same recipe imported from multiple sources
- Nutritional information extraction
- PDF and screenshot recipe storage when URLs aren't available
- Direct links to saved recipe collections (fewer taps)
- Better measurement handling (cups-to-tablespoons, not decimal fractions)

---

## Forager Differentiators

Based on Forager's existing architecture, these are unique advantages no competitor offers:

### 1. Household Import Queue
Leverage CloudKit household architecture for a shared "recipe inbox" — any household member can share a URL and others see it pending for review. No competitor has multi-user import workflows.

### 2. Grocery Integration at Import Time
At the moment of import, offer "Add missing ingredients to your grocery list" or "You already have 4 of these 12 ingredients" based on `IngredientTemplate` matching. Bridges recipe collection and actual cooking.

### 3. Transparent Confidence Scoring
`parseConfidence` already exists in the data model. Show users: "High confidence — all fields extracted" vs. "Medium confidence — instructions may be incomplete, please review." No competitor does this.

### 4. Reliability-First Graceful Degradation
Multi-layer extraction: JSON-LD → microdata → heuristic HTML → Foundation Models AI → manual entry. At each layer, clearly show users what was auto-populated vs. what needs review. Addresses the #1 pain point (inconsistent extraction).

### 5. Existing Parsing Pipeline
`HybridIngredientParser` with regex fast path + NLP fallback is already production-tested. Imported ingredient strings flow directly through `parseAndConnectIngredients()` → template matching → structured quantities. No new parsing infrastructure needed.

### 6. Post-Import Intelligence
After import, Forager can immediately:
- Match ingredients to existing templates (dedup "butter" / "Butter" / "unsalted butter")
- Calculate scaling factors
- Identify consolidation opportunities across recipes
- Connect to meal planning

---

## Recommended Implementation Plan

### Phase 1: URL Import (15-20 hours) — Highest Value, Lowest Effort

**Why first**: Covers the most common use case (saving recipes from the web), requires zero AI/ML infrastructure, and leverages existing services heavily.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| JSON-LD extractor | 4-5h | `RecipeJSONLDExtractor` — pure Foundation |
| Schema.org → Forager mapper | 3-4h | `SchemaRecipeMapper` with ISO 8601 duration parsing |
| Import preview UI | 4-5h | `RecipeImportPreviewView` using `RecipeFormData` |
| Share extension | 3-4h | Safari Share Sheet → extract → preview → save |
| Error handling & edge cases | 2-3h | Fallback flows, partial extraction UI |

### Phase 2: Text Paste Import (12-16 hours)

**Why second**: Builds on Phase 1's preview UI and adds Foundation Models integration that Phase 3 also needs.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Text input UI | 2-3h | Paste/type multiline text view |
| Foundation Models `@Generable` | 4-5h | `ImportedRecipe` struct with guided extraction |
| Heuristic fallback | 3-4h | Line scoring for non-AI devices |
| Section detection UI | 2-3h | Highlight detected sections, allow correction |
| Testing & refinement | 1-2h | Edge cases, Unicode, multi-language |

### Phase 3: Photo/Image Import (20-25 hours)

**Why third**: Most complex, benefits from Foundation Models work in Phase 2.

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Document scanner integration | 3-4h | `VNDocumentCameraViewController` wrapper |
| OCR pipeline | 4-5h | `VNRecognizeTextRequest` with text block positioning |
| Semi-automated section assignment | 5-6h | Mela-style UI — text overlaid on image, user assigns sections |
| AI-assisted extraction | 4-5h | OCR text → Foundation Models → structured recipe |
| Photo library picker | 2-3h | Select existing photos for OCR |
| Testing & refinement | 2-3h | Various cookbook formats, handwriting |

### Phase 4: Polish & Integration (8-12 hours)

| Sub-phase | Hours | Deliverable |
|-----------|-------|-------------|
| Import history/queue | 3-4h | Track imported recipes, retry failed imports |
| Household import sharing | 2-3h | Share import queue with household members |
| Duplicate detection | 2-3h | Check if recipe already exists before importing |
| Performance optimization | 1-2h | Caching, background processing |

### Total: 55-73 hours across 4 phases

---

## Key Technical Decisions

### Decision 1: Share Extension Architecture
**Options**:
- **Minimal extension** — extract URL, hand off to main app for processing
- **Full extraction in extension** — parse JSON-LD in extension, show preview, save to shared container

**Recommendation**: Minimal extension first. Share extensions have memory limits (120MB) and short execution time. Extract URL + basic metadata in extension, deep processing in main app.

### Decision 2: Foundation Models Dependency
**Options**:
- **Require Apple Intelligence** — text/photo import only on iPhone 15 Pro+ / M1+
- **AI-enhanced with fallback** — use Foundation Models when available, heuristic fallback otherwise
- **Heuristic only** — no AI dependency, works everywhere

**Recommendation**: AI-enhanced with fallback. Foundation Models dramatically improves quality but ~40% of users may not have compatible hardware. Heuristic fallback ensures universal availability.

### Decision 3: Image Storage
**Options**:
- **Store recipe images in Core Data** — as `Binary Data` with "Allows External Storage"
- **Store in app's documents directory** — file path reference in Core Data
- **Don't store images** — link to source URL only

**Recommendation**: Store in documents directory with Core Data path reference. Core Data binary storage adds complexity with CloudKit sync. URL-only breaks when sites change. File storage with CloudKit Assets is the best balance.

### Decision 4: Import Preview UX
**Options**:
- **Reuse RecipeFormData** — existing edit form becomes import preview
- **Dedicated import preview** — purpose-built UI showing extraction confidence
- **Save-then-edit** — import immediately, user edits after

**Recommendation**: Dedicated import preview that maps to `RecipeFormData` for editing. Shows confidence indicators, highlights auto-detected vs. needs-review fields. Mela's preview-before-save approach is the proven pattern.

### Decision 5: Extraction Architecture
**Options**:
- **Monolithic service** — single `RecipeImportService` handles all extraction
- **Strategy pattern** — `RecipeExtractor` protocol with `JSONLDExtractor`, `HeuristicExtractor`, `AIExtractor` implementations
- **Pipeline** — chain extractors, each enriching a partial result

**Recommendation**: Strategy pattern with fallback chain. Mirrors `HybridIngredientParser`'s proven architecture. Each extractor returns a result with confidence; router picks the best or falls through to the next.

### Decision 6: HTML Fetching
**Options**:
- **URLSession directly** — simple, built-in
- **WKWebView** — renders JavaScript, handles dynamic content
- **Headless rendering** — more complex but handles SPAs

**Recommendation**: URLSession first. Most recipe sites server-render their JSON-LD for SEO. WKWebView fallback only if JavaScript-rendered content becomes a significant failure case.

---

## M8.4 Architecture Validation for Recipe Import

**Finding: M8.4 is well-validated and directly supports recipe import.**

M8.4's BiLSTM-CRF sequence labeler is not just an ingredient parsing improvement — it's the foundation for robust recipe import. Every imported recipe runs its `recipeIngredient` strings through the same parsing pipeline, and M8.4 dramatically improves that pipeline's accuracy on the exact edge cases that imported recipes surface most often.

### Validation Points

| Claim | Evidence | Source |
|-------|----------|--------|
| BiLSTM-CRF achieves 95-98% token accuracy | strangetom CRF achieves 95.27% sentence / 98.10% word accuracy on 81k sentences. BiLSTM emission scoring with CRF decoding typically exceeds pure CRF by 1-3% on sequence labeling tasks. | [strangetom/ingredient-parser](https://github.com/strangetom/ingredient-parser), [Huang et al. 2015](https://arxiv.org/abs/1508.01991) |
| Training data sufficient — no cold start | strangetom (81k) + NYT (180k, with overlap) = ~120-150k unique sentences after dedup. BiLSTM-CRF models converge well at 50k+ for domain-specific tasks. | M8.4 PRD Phase 1 |
| Model fits in app bundle | BiLSTM emission scorer targets 2-5MB. Word-only embeddings (128-dim, ~8k vocab) + 2-layer BiLSTM (256-dim) + linear projection = well under 5MB with float16 quantization. | M8.4 PRD Phase 3 |
| Inference speed < 5ms | CoreML BiLSTM inference on modern iPhones (A15+) runs in 1-3ms for short sequences. Viterbi decoding adds <0.5ms for 7-label, <64-token sequences. Total well under 5ms budget. | CoreML hardware acceleration on Neural Engine |
| 7-label set covers schema.org patterns | `recipeIngredient` is free-form text. The labels QTY/UNIT/NAME/MODIFIER/PREP/COMMENT/OTHER cover all observed patterns including qualifiers ("to taste"), modifiers ("fresh"), and prep instructions ("diced"). | strangetom label analysis, M8.4 PRD Section 2 |
| Zero new plumbing for import | `parseAndConnectIngredients()` already accepts `[String]` and runs each through `HybridIngredientParser`. After M8.4, this automatically includes the ML tier — imported ingredient strings benefit without a single line of import-specific code. | `IngredientParsingService.swift` |
| Confidence routing provides graceful degradation | Regex (≥0.9) → ML (≥0.8) → NLP fallback. If ML model is unavailable (bundle missing, init failure), routing falls through to existing regex + NLP behavior. Import never fails silently. | M8.4 PRD Phase 5 |

### Why This Matters for Import Specifically

Imported recipes present harder parsing challenges than manually typed ingredients:

1. **Format diversity** — different recipe sites format ingredient strings differently ("1 cup flour", "flour, 1 cup", "1C flour")
2. **schema.org isn't standardized** — `recipeIngredient` accepts any free-form text; some sites include prep instructions inline ("2 cups flour, sifted and measured")
3. **Multi-language ingredients** — imported recipes may include non-English ingredient names alongside English measurements
4. **Unusual units** — "1 bunch cilantro", "3 cloves garlic", "1 stick butter" — all fail regex but are well-represented in the strangetom training data

M8.4's BiLSTM-CRF handles all of these because it learned from 81k+ real-world ingredient strings spanning 5 recipe sources (NYT, BBC, cookstr, allrecipes, tastecooking).

### Pitfalls to Document

These are the specific technical risks that M8.4 implementation must address, especially as they affect recipe import quality:

#### 1. Tokenizer Parity (Risk: HIGH)

The Python training tokenizer MUST match the Swift runtime tokenizer exactly. Misalignment causes silent prediction failures — tokens map to wrong vocabulary IDs, producing nonsense label sequences with deceptively high confidence.

**Mitigation**: Phase 0b locks a frozen `TOKENIZER_SPEC.md` with 100-sentence test vectors. Swift tokenizer must pass all 100 vectors before any model integration proceeds.

**Import impact**: Imported ingredient strings are more diverse than manually typed ones (unusual Unicode, HTML entity residue, varying whitespace). The tokenizer must handle all of these identically in both environments.

#### 2. CRF Parameter Export (Risk: HIGH)

Must export `start_transitions` (1x7) AND `end_transitions` (1x7) alongside the 7x7 transition matrix. Omitting either produces different label sequences than the full PyTorch CRF for some inputs, even when emission scores match perfectly.

**Mitigation**: Phase 0d defines a hard parity gate — Swift Viterbi decode must match Python CRF decode on 1000 held-out samples with >=99.9% token agreement. The gate blocks Phase 4 implementation until passed.

#### 3. Unit Canonicalization Shared Path (Risk: MEDIUM)

The ML parser must route extracted unit strings through the same `canonicalizeUnit()` pipeline as the regex parser (e.g., "cups" → "cup", "tbsp" → "tbsp"). Without this, downstream services (`UnitConversionService`, `QuantityMergeService`, `GroceryMergeService`) receive inconsistent units and produce wrong results.

**Import impact**: Imported recipes add ingredients to grocery lists via `AddIngredientsToListView` → `GroceryMergeService`. If ML-parsed units don't match regex-parsed units, identical ingredients won't merge ("2 cups flour" + "1 cup flour" should become "3 cups flour", not two separate items).

#### 4. ML Confidence Calibration (Risk: MEDIUM)

The initial 0.8 confidence threshold for ML acceptance is a heuristic. The threshold determines how often ML results are used vs. falling through to NLP. Too high = ML rarely used. Too low = low-quality ML results accepted.

**Mitigation**: Phase 5 includes an offline calibration pass: run all 3 parsers on 500 held-out samples, measure accuracy by confidence band, and adjust thresholds based on observed accuracy curves.

**Import impact**: Imported ingredients tend to have more varied formats than manually typed ones, which may shift the optimal confidence threshold. Calibration should include a representative sample of schema.org ingredient strings.

#### 5. Schema.org Ingredient Format Variation (Risk: MEDIUM)

`recipeIngredient` in schema.org accepts three formats:
- **Free-form text** (most common): `"2 cups all-purpose flour"`
- **Structured PropertyValue** (rare): `{"@type": "PropertyValue", "value": "2", "unitText": "cups"}`
- **Ingredient group headers** (not in spec but common): `"For the sauce:"`, `"Dressing:"` — these are not ingredients but section headers mixed into the ingredient array

**Import impact**: The JSON-LD extractor must strip group headers before feeding strings to the parser. Otherwise, "For the sauce:" gets parsed as an ingredient named "sauce" with no quantity. This is a pre-parser concern (import service responsibility), not a parser concern.

#### 6. Double-Parsing Pattern (Risk: LOW — being fixed)

Current code calls both `parseIngredient()` and `parseToStructured()` on the same text at 5 call sites. Phase 0c of M8.4 refactors this to a single parse. However, new import code must not re-introduce the pattern — each imported ingredient string should flow through the parser exactly once.

**Mitigation**: The import service should call `parseAndConnectIngredients()` (which handles the full pipeline) rather than calling parse methods directly.

#### 7. OCR Error Propagation (Risk: LOW for v1)

If photo import feeds OCR text into the BiLSTM-CRF parser, OCR errors compound with parsing errors. For example, OCR might read "½" as "1/2" or "V2", and "tbsp" as "tbs p" — each requiring different parser handling.

**Import impact**: Photo import is Phase 3 of the import plan (20-25 hours, lowest priority). By then, M8.4 will be live and we can evaluate ML parser robustness on OCR-quality text. Foundation Models can serve as an OCR error correction layer before parsing.

### Architecture Alignment Summary

```
Recipe Import Pipeline (future):

URL Import:    HTML fetch → JSON-LD extract → recipeIngredient[] → M8.4 parser → preview
                                                                    ↑
Text Paste:    Foundation Models @Generable → ingredients[] ─────────┤
                                                                    ↑
Photo Import:  VisionKit OCR → Foundation Models cleanup → text[] ──┘
                                                                    ↓
                                              parseAndConnectIngredients()
                                                                    ↓
                                              Template matching + structured quantities
                                                                    ↓
                                              Import preview UI (with confidence indicators)
                                                                    ↓
                                              User confirms → RecipeService.createRecipe()
```

All three import paths converge at the same point: an array of ingredient strings flowing through `parseAndConnectIngredients()`. M8.4 improves this shared bottleneck, benefiting all import modes simultaneously.

---

## Competitive Parsing Quality & User Complaints

### Real-World Parsing Failures Users Complain About

These are the specific ingredient parsing failures documented across competitor apps, open-source tools, and user communities. Each maps to how Forager's M8.4 parser handles (or will handle) it.

| Failure Pattern | Example | Who Suffers | M8.4 Coverage |
|----------------|---------|-------------|---------------|
| Unicode fractions | `½ cup flour`, `¼ tsp salt` | All regex parsers | strangetom includes Unicode fractions; regex already handles (M8.3) |
| Range quantities | `2-3 cups flour`, `1 to 2 cloves` | NYT tagger, AnyList | strangetom training data includes ranges; regex handles some (M8.3) |
| Unmeasured amounts | `salt to taste`, `a pinch of cayenne` | All parsers | COMMENT label captures qualifiers; regex has partial support |
| Parenthetical prep | `2 cups flour (sifted)` | Paprika, CookBook | PREP/COMMENT labels separate parentheticals from NAME |
| Product variants | `milk 2%`, `tomatoes 14.5 oz can` | Forager regex (false positive) | NAME_VAR label in strangetom → mapped to NAME in Forager |
| Multi-word units | `3 cloves garlic`, `2 bunches parsley` | Regex parsers generally | UNIT label learned from context, not a fixed unit list |
| Compound names | `all-purpose flour`, `cream of tartar` | Simple regex splits | B_NAME_TOK + I_NAME_TOK → merged NAME in Forager mapping |
| Ingredient groups | `For the sauce:`, `Filling:` | All importers (flatten or lose) | Not a parser problem — must be handled at import extraction layer |
| Inline prep instructions | `2 cups diced tomatoes, drained` | CookBook, basic parsers | PREP label separates prep from NAME |
| Word-number quantities | `one and a half cups`, `twelve eggs` | Most regex parsers | strangetom includes word numbers; regex has partial support (M8.3) |

### How Competitors Approach Parsing (Deep Dive)

| App | Method | Parsing Quality | Known Weaknesses | Source |
|-----|--------|----------------|------------------|--------|
| **Paprika** | Rule-based heuristics | Good for standard formats | Struggles with unconventional formats; no ML; requires "Reader Mode" toggle for some sites; parser changelog shows continuous minor fixes | [Paprika iOS changelog](https://paprikaapp.zendesk.com/hc/en-us/articles/115004481294) |
| **Mela** | Schema.org + ML fallback (v1.1) | Very good (MacStories "best-in-class") | Proprietary model, no published accuracy metrics; occasional failures on non-standard layouts | [MacStories review](https://www.macstories.net/reviews/mela-an-elegant-and-innovative-recipe-and-cooking-app-for-iphone-ipad-and-mac/) |
| **Pestle** | On-device ML (~0.1s) | Excellent for social media | Optimized for video captions/social media, not typed ingredients; "nine times out of ten" accuracy claim; uses Apple Intelligence for broader website support on iOS 26+ | [TechCrunch](https://techcrunch.com/2024/07/08/pestles-app-can-now-save-recipes-from-reels-using-on-device-ai/), [9to5Mac](https://9to5mac.com/2024/11/23/indie-app-spotlight-pestle/) |
| **NYT CRF** | CRF (ingredient-phrase-tagger) | Good baseline | Static model (no retraining); 180k examples; hand-crafted features; known edge case failures with non-American units ("clove", "bushel", "pinch") | [NYT GitHub](https://github.com/nytimes/ingredient-phrase-tagger), [mtlynch fork](https://mtlynch.io/resurrecting-1/) |
| **strangetom** | CRF (pycrfsuite) | 95.27% sentence / 98.10% word | Requires hand-crafted feature engineering; CRF can't learn features automatically like BiLSTM | [strangetom docs](https://ingredient-parser.readthedocs.io/en/latest/explanation/index.html) |
| **AnyList** | Schema.org extraction only | Works when structured data exists | Fails on ~87% of sites lacking structured data; falls back to manual copy/paste | [AnyList help](https://help.anylist.com/articles/feature-overview-recipe-import/) |
| **CookBook** | AI scanner (2024) | Inconsistent | "Sometimes working perfectly, sometimes missing almost all major parts"; unreliable extraction worse than no extraction | User reviews, competitive analysis |
| **Mealie** | CRF + OpenAI API option | Good (open source) | Data loss when re-parsing edited ingredients ([#5336](https://github.com/mealie-recipes/mealie/issues/5336)); ingredient changes not saved before parsing ([#3793](https://github.com/mealie-recipes/mealie/issues/3793)); OpenAI parser fails silently ([#4829](https://github.com/mealie-recipes/mealie/issues/4829)); parser ignores "cup" units when food in database ([#5399](https://github.com/mealie-recipes/mealie/issues/5399)) | [Mealie GitHub issues](https://github.com/mealie-recipes/mealie/issues) |

### Mealie: A Cautionary Tale for Parser UX

Mealie's open-source recipe manager provides the most transparent view of parsing pain points, with multiple GitHub issues documenting real user frustration:

1. **Data loss on re-parse** ([#5336](https://github.com/mealie-recipes/mealie/issues/5336)) — Users edit parsed ingredients, then clicking "Parse" again destroys their edits by re-parsing from original text. This is the worst outcome: user corrections lost.

2. **Save-before-parse requirement** ([#3793](https://github.com/mealie-recipes/mealie/issues/3793), [#2532](https://github.com/mealie-recipes/mealie/issues/2532)) — After importing a recipe and making changes, users must save first, then re-enter edit mode before they can safely use the parser. Unintuitive workflow creates frustration.

3. **Silent API failures** ([#4829](https://github.com/mealie-recipes/mealie/issues/4829)) — The OpenAI ingredient parser fails with no error reported and no ingredients displayed. Users are left confused.

4. **Database interference** ([#5399](https://github.com/mealie-recipes/mealie/issues/5399)) — When an ingredient exists in the food database, the parser ignores unit information ("cup") because it matches the food name first.

**Lesson for Forager**: M8.4's correction instrumentation (Phase 7) addresses the data loss problem — corrections are logged but never override the source text. The confidence-based preview pattern prevents silent failures. And the parser → template pipeline (parse first, template match second) avoids the database interference pattern.

### M8.4's Competitive Advantages

| Advantage | What It Means | Competitors That Lack It |
|-----------|--------------|--------------------------|
| **BiLSTM-CRF > pure CRF** | Learns features automatically — no hand-crafted feature engineering. Adapts to new patterns without manual rule additions. | NYT tagger (static CRF), strangetom (CRF), Paprika (regex) |
| **Continuous learning pipeline** (Phase 7-8) | User corrections feed into retraining. Model improves over time from real usage. No competitor offers this. | All competitors |
| **Transparent confidence scoring** | `parseConfidence` on every ingredient. Users see what was confidently parsed vs. needs review. No competitor exposes per-ingredient confidence. | All competitors |
| **3-tier routing** | Regex (microseconds) → ML (milliseconds) → NLP (milliseconds). Provides robustness no single-method app can match. Graceful degradation if any tier fails. | Pestle (ML only), Paprika (regex only), NYT (CRF only) |
| **On-device, offline, no API costs** | CoreML model in app bundle. Works in airplane mode. No API rate limits or costs. No data leaves device. | Mealie (optional OpenAI API), CookBook (cloud AI) |
| **Training data transparency** | Open-source datasets (strangetom MIT, NYT Apache 2.0). Model card documents training metadata. Reproducible. | Mela (proprietary), Pestle (proprietary) |

---

## AI-Assisted Import Strategy

### Recommended Architecture: Layered Extraction with Confidence Routing

The recipe import pipeline should layer multiple extraction strategies, each with different strengths, connected by confidence-based routing — the same pattern proven by `HybridIngredientParser`.

```
                    ┌─────────────────────────┐
                    │     Input Source         │
                    └────────┬────────────────┘
                             │
              ┌──────────────┼──────────────────┐
              ▼              ▼                   ▼
        URL Import     Text Paste          Photo Import
              │              │                   │
              ▼              ▼                   ▼
       JSON-LD extract  Foundation Models   VisionKit OCR
       (schema.org)     @Generable          (VNRecognizeTextRequest)
              │              │                   │
              │              │                   ▼
              │              │             Foundation Models
              │              │             (OCR error correction)
              │              │                   │
              └──────────────┼───────────────────┘
                             │
                             ▼
                   recipeIngredient[]
                             │
                             ▼
               ┌─────────────────────────┐
               │  M8.4 BiLSTM-CRF Parser │
               │  (via parseAndConnect   │
               │   Ingredients())        │
               └────────┬────────────────┘
                        │
                        ▼
              Import Preview UI
              (with per-ingredient
               confidence indicators)
                        │
                        ▼
              User confirms → Save
```

### Parser Selection by Input Source

| Input Source | Primary Parser | Fallback | Why |
|-------------|---------------|----------|-----|
| schema.org JSON-LD ingredients | M8.4 BiLSTM-CRF (via HybridIngredientParser) | Regex fast path (≥0.9 confidence) | Well-structured text but format varies by site; speed matters for batch import |
| Pasted recipe text (unstructured) | Foundation Models `@Generable` (section detection + ingredient extraction) | Heuristic line scoring (for non-AI devices) | Ambiguous sections need semantic understanding to separate ingredients from instructions |
| Photo OCR output | Foundation Models (fix OCR errors + extract) → M8.4 parser (per ingredient) | BiLSTM-CRF directly on raw OCR text | LLM can correct OCR mistakes ("1/2" misread as "V2") before structured parsing |
| Social media caption | Foundation Models `@Generable` | BiLSTM-CRF on raw caption | Informal language, emoji, abbreviations need semantic understanding |
| Manual typed ingredient | Regex → BiLSTM-CRF → NLP (existing HybridIngredientParser routing) | N/A — full pipeline runs | Standard format, latency-critical (<10ms), existing pipeline handles perfectly |

### Key Findings About Foundation Models `@Generable`

Based on research into Apple's Foundation Models framework (iOS 26+):

| Property | Value | Source |
|----------|-------|--------|
| Model size in memory | ~1.2 GB (loaded) | [Apple ML Research](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates) |
| Parameter count | ~3 billion | [Apple Newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/) |
| Latency | 50-200ms for short prompts; 2-5s for complex extraction | [WWDC25 Session 286](https://developer.apple.com/videos/play/wwdc2025/286/) |
| Hardware requirement | iPhone 15 Pro+ / M1+ (Apple Intelligence required) | [Apple Developer Documentation](https://developer.apple.com/documentation/FoundationModels) |
| Constrained output | `@Generable` macro + `@Guide` annotations guarantee valid structured output | [WWDC25 Session 301](https://developer.apple.com/videos/play/wwdc2025/301/) |
| Offline capability | Fully on-device, no network required | [Apple Developer Documentation](https://developer.apple.com/documentation/FoundationModels) |
| Install base coverage | ~60-70% of active iOS 26+ devices (iPhone 15 Pro+ / M1+) | Estimated from Apple hardware sales data |

#### Share Extension Constraint (CRITICAL)

**Foundation Models CANNOT run in a Share Extension.** iOS Share Extensions are limited to ~120 MB of memory. The Foundation Models framework loads a ~1.2 GB model into memory — 10x the extension limit. This means:

- **Share Extension**: Can only extract URL + basic metadata, then hand off to main app
- **Main App**: Does all Foundation Models processing (text paste, photo OCR, complex extraction)
- **Implication**: The "share → instant preview" UX (like Mela) must be achieved via JSON-LD extraction in the extension (lightweight, no AI) or by launching the main app for AI-powered extraction

This constraint reinforces the recommended minimal share extension architecture from Section 10, Decision 1.

#### When Foundation Models vs. BiLSTM-CRF

| Scenario | Best Tool | Why |
|----------|-----------|-----|
| Individual ingredient line ("2 cups flour") | BiLSTM-CRF (<5ms) | Fast, accurate, purpose-built for this exact task |
| Batch of 15 ingredient lines from JSON-LD | BiLSTM-CRF (<75ms total) | Each line is well-formatted; speed matters |
| Unstructured text block (pasted recipe) | Foundation Models (2-5s) | Need semantic understanding to identify which lines are ingredients vs. instructions vs. metadata |
| OCR output with errors | Foundation Models → BiLSTM-CRF | LLM corrects OCR errors, then parser extracts structure |
| Social media caption with emoji/slang | Foundation Models (2-5s) | Informal language needs semantic reasoning |
| Recipe with ingredient group headers | Foundation Models (section detection) → BiLSTM-CRF (per ingredient) | LLM identifies "For the sauce:" as a header; parser handles each ingredient |

**Key insight**: Foundation Models and BiLSTM-CRF are complementary, not competing. Foundation Models excels at **document-level understanding** (what is this text? which parts are ingredients?). BiLSTM-CRF excels at **token-level extraction** (given an ingredient line, what is the quantity? unit? name?). The ideal pipeline uses Foundation Models for section detection and BiLSTM-CRF for ingredient parsing.

### Forager-Unique Differentiators for Import

These differentiators come from Forager's existing architecture and cannot be replicated by competitors without rebuilding their infrastructure:

#### 1. Household Import Queue

CloudKit household architecture enables a shared "recipe inbox" — any household member can share a URL and others see it pending for review. Implementation: create an `ImportRequest` Core Data entity in the shared store with URL, status, and submitter fields. CloudKit syncs it automatically.

**No competitor has multi-user import workflows.** Mela, Paprika, and Pestle are all single-user. AnyList has household lists but not shared import queues.

#### 2. Grocery Integration at Import

At the moment of import, Forager can show: "You already have 4 of these 12 ingredients" or "Add 8 missing ingredients to your grocery list." This works because:
- `parseAndConnectIngredients()` creates `IngredientTemplate` links for every parsed ingredient
- `IngredientTemplate` is the single source of truth — shared across recipes and grocery lists
- Template matching happens automatically during parsing (no extra work)

**No competitor bridges recipe import and grocery shopping this directly.**

#### 3. Transparent Confidence

`parseConfidence` exists on every `Ingredient` entity. The import preview can show:
- Green indicator: high confidence (≥0.8) — all fields extracted correctly
- Amber indicator: medium confidence (0.5-0.8) — some fields may need review
- Red indicator: low confidence (<0.5) — user should verify this ingredient

**No competitor exposes per-ingredient parsing confidence.** Users either trust the import entirely or don't.

#### 4. Continuous Learning from Import Corrections

M8.4 Phase 7 wires correction logging into edit flows. When users fix a mis-parsed imported ingredient:
1. Correction logged with before/after values
2. Phase 8 exports corrections as BIO-tagged training data
3. Retraining improves the model for similar patterns in future imports

**This creates a flywheel**: more imports → more corrections → better parser → fewer corrections needed. No competitor has this feedback loop.

#### 5. Graceful Degradation — Never Fails Silently

The multi-layer extraction pipeline ensures something always works:

| Layer | Failure Mode | Fallback |
|-------|-------------|----------|
| JSON-LD extraction | No structured data on page | HTML heuristic parsing |
| HTML heuristic | Unusual page structure | Foundation Models `@Generable` |
| Foundation Models | Device doesn't support Apple Intelligence | Heuristic line scoring |
| BiLSTM-CRF parsing | Model init fails (file missing) | Regex → NLP fallback |
| Regex parsing | Non-standard format | NLP fallback |
| All parsing | Very low confidence | Show raw text for manual editing |

**At every layer, the user sees what was auto-populated vs. what needs review.** This directly addresses the #1 user complaint across all recipe apps: inconsistent extraction quality.

### Hardware Availability Strategy

| Device Tier | % of Users (est.) | Import Capability |
|------------|-------------------|-------------------|
| iPhone 15 Pro+ / M1+ (Apple Intelligence) | ~60-70% | Full pipeline: JSON-LD + Foundation Models + BiLSTM-CRF |
| iPhone 15 / 14 Pro / A16+ (no Apple Intelligence) | ~20-25% | JSON-LD + BiLSTM-CRF + heuristic line scoring (no LLM) |
| Older devices (A14/A15 non-Pro) | ~10-15% | JSON-LD + regex/NLP parsing + heuristic fallback |

**Forager's iOS 26 deployment target** means all users have modern hardware. The question is only whether they have Apple Intelligence support. The BiLSTM-CRF parser (M8.4) works on all devices — it's a CoreML model, not a Foundation Models feature. Foundation Models only adds value for unstructured text and photo import, where the ~60-70% coverage is acceptable because heuristic fallbacks exist.

---

## Sources & References

### Technical
- [Schema.org/Recipe specification](https://schema.org/Recipe)
- [Google Rich Results for Recipes](https://developers.google.com/search/docs/appearance/structured-data/recipe)
- [Apple Foundation Models documentation](https://developer.apple.com/documentation/foundationmodels)
- [Apple Vision framework — VNRecognizeTextRequest](https://developer.apple.com/documentation/vision/vnrecognizetextrequest)
- [Apple VNDocumentCameraViewController](https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller)
- [recipe-scrapers Python library](https://github.com/hhursev/recipe-scrapers) — 611 supported sites, architecture reference

### Legal
- Publications International v. Meredith Corp — recipe ingredient lists not copyrightable
- JSON-LD is intentionally published for search engines — extraction is expected use

### Competitive
- [Paprika User Guide](https://www.paprikaapp.com/help/ios/)
- [Mela MacStories Review](https://www.macstories.net/reviews/mela-an-elegant-and-innovative-recipe-and-cooking-app-for-iphone-ipad-and-mac/)
- [Mela Video Import — MacStories](https://www.macstories.net/reviews/mela-1-6-adds-web-search-engine-and-recipe-import-from-youtube-instagram-and-tiktok-videos/)
- [Crouton MacStories Review](https://www.macstories.net/reviews/crouton-review-an-elegant-modern-recipe-manager-and-cooking-aid/)
- [Pestle on-device AI — TechCrunch](https://techcrunch.com/2024/07/08/pestles-app-can-now-save-recipes-from-reels-using-on-device-ai/)
- [Pestle TikTok support — TechCrunch](https://techcrunch.com/2024/11/25/pestle-recipe-app-can-now-save-dishes-from-tiktok/)
- [Pestle Indie App Spotlight — 9to5Mac](https://9to5mac.com/2024/11/23/indie-app-spotlight-pestle/)
- [AnyList Recipe Import Help](https://help.anylist.com/articles/feature-overview-recipe-import/)
- [CookBook Official Site](https://cookbookmanager.com/)
- [Recipe Keeper Review](https://kowalskimountain.com/recipe-keeper-app-review/)

### M8.4 Architecture & ML Parsing
- [strangetom/ingredient-parser](https://github.com/strangetom/ingredient-parser) — 81k sentences, 13 labels, 95.27% sentence accuracy, MIT License
- [strangetom Model Guide](https://ingredient-parser.readthedocs.io/en/latest/explanation/index.html) — CRF model architecture and accuracy metrics
- [NYT ingredient-phrase-tagger](https://github.com/nytimes/ingredient-phrase-tagger) — 180k examples, Apache 2.0 License
- [Huang et al. "Bidirectional LSTM-CRF Models for Sequence Tagging" (2015)](https://arxiv.org/abs/1508.01991) — foundational BiLSTM-CRF paper
- [mtlynch fork — Resurrecting the NYT tagger](https://mtlynch.io/resurrecting-1/) — edge cases and customization challenges
- [Mealie ingredient parser issues](https://github.com/mealie-recipes/mealie/issues?q=ingredient+parser) — data loss, silent failures, re-parse UX problems
- [Mealie October 2024 Survey — Q12](https://docs.mealie.io/news/surveys/2024-october/q12/) — user feedback on import quality

### Apple Foundation Models
- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/FoundationModels)
- [Meet the Foundation Models framework — WWDC25](https://developer.apple.com/videos/play/wwdc2025/286/)
- [Deep dive into the Foundation Models framework — WWDC25](https://developer.apple.com/videos/play/wwdc2025/301/)
- [Apple Foundation Models Framework — Apple Newsroom](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- [Apple ML Research — Foundation Models 2025 Updates](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates)
- [Foundation Models Limitations — Natasha The Robot](https://www.natashatherobot.com/p/apple-foundation-models)
- [10 Best Practices for Foundation Models — Datawizz](https://datawizz.ai/blog/apple-foundations-models-framework-10-best-practices-for-developing-ai-apps)
- [iOS Share Extension Memory Limits — Igor Kulman](https://blog.kulman.sk/dealing-with-memory-limits-in-app-extensions/) — 120MB limit documentation

### Competitive Parsing (Updated Feb 2026)
- [Pestle — TechCrunch (Reels)](https://techcrunch.com/2024/07/08/pestles-app-can-now-save-recipes-from-reels-using-on-device-ai/) — on-device AI, ~0.1s extraction
- [Pestle — TechCrunch (TikTok)](https://techcrunch.com/2024/11/25/pestle-recipe-app-can-now-save-dishes-from-tiktok/) — TikTok caption parsing
- [Pestle — 9to5Mac Indie Spotlight](https://9to5mac.com/2024/11/23/indie-app-spotlight-pestle/) — "nine times out of ten" accuracy
- [Paprika iOS changelog](https://paprikaapp.zendesk.com/hc/en-us/articles/115004481294-What-s-New-on-iOS-Paprika-3) — continuous parser fixes
- [12 Best Recipe Apps 2026 — RecipeOne](https://www.recipeone.app/blog/best-recipe-manager-apps) — comprehensive comparison
- [Flavor365 — Top 5 Social Recipe Apps Reviewed](https://flavor365.com/we-tested-the-top-5-social-recipe-apps/) — Pestle accuracy claims

---

*Research conducted February 21, 2026 using web search, competitive analysis, and Forager codebase review.*
*Sections 11-13 added February 21, 2026: M8.4 validation, competitive parsing deep dive, and AI-assisted import strategy.*
