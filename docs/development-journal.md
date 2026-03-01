# Forager Development Journal

**Purpose**: A narrative chronicle of building Forager — capturing decisions, learning moments, AI tooling evolution, and the story behind the code. Unlike the technical insights log (quick-reference table) or learning notes (milestone summaries), this journal tells the *why* behind the *what*.

**Format**: Session-level entries in reverse chronological order. Each entry captures what happened, what decisions were made and why, what was learned about the tools and process, and what it means for the project's direction.

---

## Session 59 — March 1, 2026
**Milestone**: M10.6.1 — LLM Parser Protocol + Claude Adapter + Tests
**Focus**: Build the foundational layer for optional Claude API ingredient parsing
**Branch**: `feature/M10.6-claude-api-integration`

### What Happened

Set up M10.6 milestone (PRD audit, service check, branch, core docs) and implemented M10.6.1 — the protocol layer, Claude API adapter, mock, and 10 unit tests.

**M10.6.1** — Four files created:
1. **`LLMIngredientParser.swift`** — Protocol (`parseBatch`, `providerName`, `isConfigured`), `LLMParserResult` struct with `toParserResult()` bridge, `LLMParserError` enum with `isRetryable` for retry routing.
2. **`ClaudeIngredientParser.swift`** — Anthropic Messages API adapter using `tool_use` for structured output. Model: `claude-haiku-4-5-20251001`. Exponential backoff (1s, 2s, 4s) on 429/529, immediate throw on 401/5xx. Accepts injectable `URLSession` for testability.
3. **`MockLLMIngredientParser.swift`** — Test double with `stubbedResults`, `stubbedError`, call tracking.
4. **`ClaudeIngredientParserTests.swift`** — 10 tests: batch parse, empty input, single ingredient, multi-ingredient split, 401 no-retry, 429 retry+backoff, malformed response, validation (empty name), `toParserResult` bridge, request header verification.

All 10 tests pass. The `MockURLProtocol` pattern intercepts all network calls via `URLSessionConfiguration.ephemeral` — zero live API calls in tests.

**M10.6.2** — Three files touched:
1. **`KeychainHelper.swift`** — Added `saveLLMAPIKey`, `getLLMAPIKey`, `deleteLLMAPIKey` inside the enum body (private `read`/`write` require internal access).
2. **`LLMSettingsService.swift`** — `@MainActor` singleton with `@Published isEnabled` (UserDefaults-backed), Keychain API key CRUD, masked key display, `testConnection()` async method, `activeParser()` factory.
3. **`LLMSettingsServiceTests.swift`** — 9 tests covering toggle persistence, key save/retrieve/delete, whitespace trimming, empty key rejection, factory nil/configured states, connection test without key.

All 9 tests pass in 0.034s.

**M10.6.3** — One file modified:
- **`SettingsView.swift`** — Added `aiImportSection` between Display Options and Developer Tools. Toggle, SecureField API key entry, masked key display with Clear button, connection test with ProgressView spinner, status indicators (green checkmark / red X / gray circle), link to Anthropic console.

**M10.6.4** — Four files touched:
1. **`RecipeImportService.swift`** — Made `saveImport(from:)` and `replaceExistingRecipe(objectID:with:)` async. Added `tryLLMParsing()` helper that attempts LLM batch parsing before local pipeline, with silent fallback on any error. Extracted `persistAndFinish()` shared helper.
2. **`RecipeImportSheet.swift`** — Wrapped 3 call sites in `Task { await ... }`.
3. **`RecipeImportServiceLLMTests.swift`** — 5 tests: pipeline fallback when LLM disabled, template connection, uncategorized template IDs, replace existing recipe, empty ingredients.

All 24 M10.6 tests pass (10 + 9 + 5).

### Key Decisions

- **Separate protocol from `IngredientParser`**: The LLM contract is async + batch + network-dependent, fundamentally different from the sync + per-line + local `IngredientParser`. A shared protocol would force awkward wrappers on both sides. The `toParserResult()` bridge connects at the boundary.
- **`tool_use` for structured output**: Forces Claude to return JSON matching the tool schema, eliminating freeform text parsing. The tool definition specifies `name`, `quantity` (number|null), `unit` (string|null), `notes` (string|null).
- **Fixed 0.95 confidence**: LLM results get a constant confidence score since the model doesn't provide per-field confidence. This positions LLM above the NLP fallback (capped at 0.75) in the routing hierarchy.
- **`URLSession` injection**: The parser accepts a session parameter (defaulting to `.shared`) so tests can inject a mock-protocol session. No singletons, no test hooks needed.

### Learning

- Swift requires exhaustive catch blocks even when you "know" the error type — a typed `catch let error as X` still needs a fallback `catch` clause.
- `MockURLProtocol` with a static `requestHandler` closure is the cleanest iOS networking test pattern — no third-party mocking libraries needed.
- Exponential backoff tests take real wall-clock time when using `Task.sleep`. For 10 tests this is fine (~3s), but larger suites would benefit from an injectable clock.

### AI Tooling Observations

The session started with housekeeping (skill renames, CLAUDE.md audit) before pivoting to M10.6. The `/claude-md-management:claude-md-improver` audit was useful — identified 6 concrete improvements including stale test file counts and redundant sections. PRD audit caught that `KeychainHelper.read`/`write` are `private static`, which will matter for M10.6.2.

### What's Next

M10.6.2: KeychainHelper extension for LLM API key storage + LLMSettingsService + tests.

---

## Session 58 — February 28, 2026
**Milestone**: M10.8 Phase 2 — Fully Inline RecipeDetailView + Import Instructions Editing
**Focus**: Eliminate Edit Recipe modal, inline everything, TestFlight build 29
**Branch**: `feature/M10.8-inline-ingredient-editing`

### What Happened

Implemented M10.8 Phase 2 — making RecipeDetailView fully inline-editable and adding instruction editing to RecipeImportPreviewView. This is the natural extension of Phase 1 (which added tap-to-edit ingredients): if ingredients are already inline, instructions and metadata should be too. The Edit Recipe modal is now gone entirely.

Five changes in two files:
1. **Inline instruction editing** (RecipeDetailView) — bordered card per step matching the ingredient pattern. Tap to edit, submit/blur to save, long-press context menu to delete, "+ Add Step" button at bottom.
2. **Inline instruction editing** (RecipeImportPreviewView) — same visual pattern but writes to draft buffer instead of Core Data.
3. **Inline metadata editing** (RecipeDetailView) — tap-to-edit title, prep/cook time with `.numberPad`, servings row, always-visible favorite heart toggle.
4. **Edit Recipe modal removal** — deleted `showingEditSheet` state, sheet presentation, and menu item. EditRecipeView.swift left as dead code for future cleanup.
5. **Category picker height fix** — both views get `.presentationDetents([.medium, .large])` so users can drag the sheet taller.

Also ran the full TestFlight pipeline for build 29 (archive → upload → App Store Connect API → beta group → review submission). Build 28 was an oops — archived before committing the Phase 2 code. Caught it immediately and re-archived with build 29.

### Key Decisions

- **Three `@FocusState` properties for mutual exclusion**: `focusedIngredientId: UUID?`, `focusedStepIndex: Int?`, `focusedMetadata: MetadataFocus?`. SwiftUI only allows one focused field at a time, so moving focus between these automatically triggers `onChange` handlers that commit pending edits from the previous mode. No explicit state machine needed.
- **Vertical-axis TextField with `.submitLabel(.done)`**: `TextField("", text:, axis: .vertical)` wraps text naturally. The Done key fires `.onSubmit` instead of inserting a newline — perfect for multi-sentence instruction steps that still need a clean submit action.
- **Save-on-blur for metadata**: Each metadata field saves independently when focus leaves it, same pattern as ingredients. No "Save All" button needed — the recipe updates as you edit.

### Learning

- `@FocusState` is SwiftUI's built-in mutual exclusion mechanism. Multiple `@FocusState` properties across different types naturally enforce single-active-editor since only one field can hold keyboard focus at a time. The `onChange(of:)` handlers become the commit triggers.
- `TextField("", text:, axis: .vertical)` combined with `.submitLabel(.done)` is the right pattern for editable content that can wrap. Without `.submitLabel(.done)`, the return key inserts newlines and there's no submit action.
- Conditional view + `@FocusState` requires `.onAppear { focusedField = .value }` to reliably gain focus after the TextField view is inserted into the hierarchy. Setting focus before the view exists is a no-op.
- Always commit code changes before archiving. Build 28 was a wasted archive because the Phase 2 changes were still uncommitted. The `/archive` skill doesn't check for uncommitted changes — it should warn.

### AI Tooling Observations

Second session using the `/archive` skill. The full TestFlight pipeline (archive → upload → API polling → compliance → beta group → review submission) completed successfully for build 29. The JWT-based App Store Connect API automation saves significant time vs the Xcode Organizer GUI workflow.

One improvement needed: the archive skill should warn when there are uncommitted changes, since the archive only includes committed code. The build 28 mistake was entirely avoidable.

### What's Next

Manual testing of build 29 on device (inline instructions + metadata editing in both RecipeDetailView and import preview). Then merge M10.8 to main.

---

## Session 57 — February 28, 2026
**Milestone**: M10.8 Inline Ingredient Editing
**Focus**: Display/edit toggle for recipe ingredient rows
**Branch**: `feature/M10.8-inline-ingredient-editing`

### What Happened

Implemented M10.8 — porting the proven `RecipeImportPreviewView` display/edit toggle pattern to `EditRecipeView` and `CreateRecipeView`. This replaces always-visible TextFields with formatted read-only display (qty+unit in secondary color, parsed name bold in accent), where tapping a row opens an inline TextField for editing.

Two files changed, zero model/service changes, exactly as the PRD specified. The PRD audit confirmed every reference was accurate — entity properties, line numbers, service APIs, theme tokens all matched.

### Key Decisions

- **UUID-based tracking over index-based**: The import preview uses `editingIndex: Int?` because its ingredient list is static. Recipe views support drag-to-reorder and swipe-to-delete, so we use `editingIngredientId: UUID?` via `IngredientInput.id` to survive list mutations.
- **iOS 26 Text interpolation**: Used `Text("\(Text(a))\(Text(b))")` instead of the deprecated `Text + Text` pattern, clearing warnings that still exist in the import preview source.
- **No save-path changes needed**: The existing `saveRecipe()` already re-parses all ingredients with nil templates, so our `commitIngredientEdit()` provides earlier visual feedback without being a required step.

### Learning

- PRD-first workflow pays off: the M10.8 PRD was created earlier today and every reference checked out perfectly against the codebase. Zero surprises during implementation.
- The new Claude Code skills system (`/session-start`, `/service-check`, `/build`) streamlined the pre-development checks — ran the PRD audit and service check as part of the session startup flow rather than doing them ad hoc.
- `xcodebuild archive` works from CLI with `-destination 'generic/platform=iOS'` and defaults to Release config. Combined with the App Store Connect API for TestFlight distribution, the entire release pipeline can be scripted.
- Version bumping in pbxproj requires targeting only the app target's entries (first 2 of 6 `CURRENT_PROJECT_VERSION` occurrences) — test targets stay at `1`.

### AI Tooling Observations

First session using the new skills infrastructure (Session 56 created the skills). The `/session-start` skill loaded context docs efficiently. The PRD audit and service check were done manually this time (skills are `disable-model-invocation: true` for those), but the structured approach from having the skill definitions kept the process systematic. Also created a 12th skill (`/archive`) during this session — the skills system is proving easy to extend organically as workflow needs emerge.

### What's Next

Manual testing of the display/edit toggle in simulator, then PR. The RecipeImportPreviewView's `+` deprecation warnings should be addressed in a future cleanup pass. The `/archive` skill needs real-world testing when M7.7 (App Store Submission) begins — will need an App Store Connect API key for full TestFlight automation.

---

## Session 56 — February 28, 2026
**Milestone**: Claude Code Skills Infrastructure
**Focus**: Extract workflow procedures from CLAUDE.md into 11 custom skills
**Branch**: `main` (PR #54, squash merged)

### What Happened

Refactored the project's AI tooling configuration by extracting procedural workflow instructions from CLAUDE.md into Claude Code's custom skills system (`.claude/skills/`).

**The problem**: CLAUDE.md had grown to 518 lines — a mix of declarative rules (architecture, naming, code standards) and procedural instructions (how to commit, how to start a session, how to audit Core Data). All 518 lines loaded into every turn of every conversation, whether the session needed the git workflow or not.

**The solution**: Created 11 custom skills, each a self-contained SKILL.md with step-by-step instructions for a specific workflow. CLAUDE.md was slimmed to 388 lines of pure rules and references, with a skills table pointing to the procedures.

### Skills Created (by Priority)

- **P0 (every session)**: `/session-start`, `/forager-commit`, `/dev-journal`, `/milestone-complete`
- **P1 (most sessions)**: `/log-insight`, `/forager-pr`, `/core-data-audit`
- **P2 (as needed)**: `/service-check`, `/new-milestone`, `/build`, `/prd-audit`

### Key Design Decision: Declarative vs. Procedural Split

CLAUDE.md retained the *what* — architecture overview, naming rules, quality gates, code standards. Skills contain the *how* — step-by-step checklists, bash commands, file update procedures. This mirrors the distinction between a team's engineering handbook (always relevant) and its runbooks (relevant only when running a specific procedure).

### Context Savings Analysis

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| CLAUDE.md lines | 518 | 388 | -130 (25%) |
| CLAUDE.md bytes | 20,297 | 15,905 | -4,392 (21.6%) |
| Total knowledge base | 518 lines | 1,059 lines | +104% |

The total instructions doubled, but context cost per turn dropped 25%. Skills are lazy-loaded — `/forager-commit` (64 lines) only enters the context window when invoked. Over a 50-turn session, the always-loaded savings compound to ~55K tokens that never need processing.

### What Was Learned

1. **Skills are lazy-loaded, CLAUDE.md is not.** This is the fundamental insight. Moving procedures to skills doesn't just organize them — it changes *when* they consume context window budget.
2. **Separation of concerns applies to AI config too.** Declarative rules (always needed) vs. procedural runbooks (on-demand) is the same split you'd make in any well-structured system.
3. **The knowledge base can grow without growing cost.** By moving to on-demand loading, you can add more skills without increasing per-turn overhead.

---

## Session 55 — February 28, 2026
**Milestone**: M10.8 PRD + M10.3 Wrap-Up
**Focus**: Create PRD for inline ingredient editing, finalize M10.3 documentation
**Branch**: `main` (PRD commit) + `feature/M10.3-photo-import` (doc updates)

### What Happened

Two tasks in one session:

**1. M10.8 PRD — Inline Ingredient Editing**: Created a PRD for porting the `RecipeImportPreviewView` display/edit toggle pattern to `EditRecipeView` and `CreateRecipeView`. The import preview (built during M10.3) already has a polished tap-to-edit pattern with formatted display (qty+unit secondary, parsed name bold accent), `@FocusState`-driven keyboard management, and commit-on-exit re-parsing. The recipe editing views still use always-visible TextFields with no visual distinction between reading and editing. The PRD documents the exact state variables, rendering logic, and `.onChange` handlers needed — all proven patterns from the import preview, adapted to use UUID-based tracking instead of index-based (since recipe ingredient lists support reorder/delete).

**2. M10.3 Documentation Wrap-Up**: The M10.3 branch had a status inconsistency — `current-story.md` said "ACTIVE" while `next-prompt.md` and `roadmap.md` said "DEV COMPLETE." Aligned all 5 core docs to reflect M10.3 dev-complete status. Build verified clean on the branch.

### Key Decision: UUID vs Index Tracking

The import preview uses `@State editingIndex: Int?` because the ingredient list is read from `ImportDraftRecipe` and indices are stable. The recipe editing views use `IngredientInput.id: UUID` because the list supports reorder and swipe-to-delete — indices shift, UUIDs don't. This is the only architectural difference from the source pattern.

### What's Next

M10.3 is ready for PR creation and merge. After that: M10.4 (polish & integration) → M10.6 (Claude API) → M10.8 (inline editing).

---

## Session 54 — February 27, 2026
**Milestone**: M10.3.9 Category Assignment + Import UX Improvements
**Focus**: Rewrite CategoryAssignmentModal, inline categories in import preview, fix card heights
**Branch**: `feature/M10.3-photo-import`

### What Happened

Three UX improvements in one session:

**1. CategoryAssignmentModal rewrite (M10.3.9)**: Rewrote from a 520-line scroll list with NavigationLink pickers to a 280-line card-by-card stepper matching `IngredientReviewSheet`. Name editing with re-parsing + merge-on-rename. `.interactiveDismissDisabled()` on all 4 callers.

**2. Inline category assignment in import preview**: User pointed out the two-step flow (preview → save → category modal) was unnecessary friction. Moved category assignment directly into `RecipeImportPreviewView` — each ingredient row now has a compact `Menu` category dropdown. Pre-filled from template matches, user can override. On save, categories are applied to templates via post-save patch (`applyCategoryAssignmentsAndFinish`). CategoryAssignmentModal only appears if the user left some unassigned (graceful fallback). No service API changes needed.

**3. Fixed-height recipe list cards**: Recipe cards without timing data were shorter than cards with prep/cook pills. Fixed by always rendering the timing row — empty cards get an invisible spacer that matches pill height.

### Key Decision: Post-Save Category Patch

Rather than modifying `RecipeImportService.saveImport()` to accept category hints (which would change the API contract), categories are applied after save by matching template names. This keeps the service clean and maintains backward compatibility with all other callers. The `pendingCategoryAssignments` dictionary flows through the save pipeline as state on `RecipeImportSheet`, applied in `applyCategoryAssignmentsAndFinish()`.

### Insight: Inline Assignment as Library Growth Strategy

User noted: "categorization will become less burdensome over time as the library grows." This is exactly right — the inline category picker auto-fills from existing template matches. After a user categorizes "chicken breast" once, every future import that includes chicken breast will auto-fill "Deli & Meat". The M10.6 LLM integration will fill the gap for truly new ingredients.

### Continued: Full-Line Editing + Parsed Feedback

Two additional rounds of refinement driven by user testing:

**Full-line editing**: Initially implemented split editing (qty as static Text + name as TextField). User immediately flagged this — "I want the whole ingredient line to be editable." Single TextField for the entire line is the right UX: users fix OCR errors holistically, not component-by-component. The app's job is to parse the corrected line, not force the user to do the parsing mentally.

**Parsed name highlight**: After making lines fully editable, the user noticed the system's understanding was invisible — "I still want the line parsed and the ingredient highlighted." Added a secondary line below the TextField showing the parsed ingredient name in accent color with a dot separator before the category picker. This creates a feedback loop: edit → submit → see parsed name → confirm the system understood.

### USDA FoodData Research

User explored the idea of using USDA FoodData Central as a seed dictionary for ingredient categories. Pulled Foundation Foods samples via API — ~1,000 curated items with food groups that map well to Forager's 7 categories (e.g., "Vegetables and Vegetable Products" → "Fruits & Veg"). The mapping is feasible but implementation deferred — the inline category assignment + library growth pattern is the near-term solution.

---

## Session 53 — February 26, 2026
**Milestone**: M10.3 Photo/Image Import — Bug Fixes & Ingredient Matching Design
**Focus**: Fix 3 bugs found during manual testing, design import preview ingredient matching
**Branch**: `feature/M10.3-photo-import`

### What Happened

User testing on a flight surfaced three issues:

**1. Review binding bug**: The SectionHighlightView review step froze after editing the first classified line. Root cause: `PhotoImportPhase`'s custom `Equatable` returned `true` for all `.reviewing` states — SwiftUI's diff saw "no change" and skipped re-rendering when lines were modified. One-character fix: `return true` → `return false`.

**2. Save UX**: The big "Recipe Saved!" success screen was unnecessary and actually obscured the CategoryAssignmentModal that should appear for uncategorized ingredients. The user expected import to behave like manual entry — hit Save, optionally assign categories, done. Fix: removed the success view entirely, save now auto-dismisses. CategoryAssignmentModal appears first if there are uncategorized templates, then dismisses. State resets to `.idle` on dismiss to prevent stale state.

**3. Import ingredient categorization**: The `CategoryAssignmentModal` was wired up and the parsing pipeline ran on save, but the user never saw it working because the success view took over. With the success view removed, the flow now works as intended: save → category assignment (if needed) → dismiss.

Also fixed two small bugs from earlier testing: cold launch blank grocery list (HouseholdService timing — `loadCurrentHousehold()` was running before stores loaded) and "Templates" → "Ingredients" label in HouseholdView.

### Key Decision: Import Preview Ingredient Matching (M10.3.8)

User feedback: "we are not running the ingredient categorization step like what happens when a user manually enters in a recipe... matching it to the user's existing ingredient list would be helpful, that way the user knows what is already categorized."

This led to designing M10.3.8 — a preview-time enhancement where each imported ingredient line gets parsed and matched against the user's existing template database. The preview will show ✓/? /○ status indicators per ingredient (matching CreateRecipeView's pattern), so the user knows exactly what's new vs existing before hitting Save. Key constraint: preview is read-only, no templates created until save.

All infrastructure exists: `parseIngredient()` is fast (<0.05s), `searchTemplates()` is a simple fetch, and `IngredientStatus` enum already defines the three states. Just needs wiring in `RecipeImportPreviewView.ingredientsSection`.

### What Was Learned

Custom `Equatable` on `@State` enums is a footgun — if your `==` returns `true` when the actual data changed, SwiftUI silently stops updating. Either omit Equatable (SwiftUI handles it) or make it precise. Also: intermediate success screens that require user dismissal (like "Recipe Saved!" + "Done") break the flow when there's follow-up work (like category assignment). Just save and move on.

### Session 53b Update — M10.3.8 Implemented

Implemented M10.3.8 ingredient matching in `RecipeImportPreviewView.swift`. Added `@EnvironmentObject` for `IngredientParsingService` and `IngredientTemplateService`, a private `IngredientMatchInfo` struct, and a `computeIngredientMatches()` method that runs in `.task {}`. Each ingredient line gets parsed via the 3-tier hybrid parser, then the parsed name is matched against existing templates via `searchTemplates()`. The ingredient row now shows SF Symbol status icons (checkmark.circle.fill / questionmark.circle.fill / circle) instead of confidence dots when matches are available, plus a category label or status description below the ingredient text. A summary bar at the top of the ingredients section shows counts: "N matched · N need category · N new".

No new tests needed — this is view-layer glue connecting two already-tested services. M10.3 is now dev complete.

### What's Next

Continue manual testing with real photos, verify M10.3.8 ingredient matching display works as expected, then merge to main.

---

## Session 52 — February 26, 2026
**Milestone**: M10.3 Photo/Image Import
**Focus**: Add third recipe import source — camera scan and photo library via Vision.framework OCR
**Branch**: `feature/M10.3-photo-import`

### What Happened

Implemented M10.3 in a single focused session. Three new files created:
1. `ImageOCRService.swift` — Vision.framework VNRecognizeTextRequest wrapper producing `[OCRLine]` with real boundingBox data
2. `DocumentScannerView.swift` — UIViewControllerRepresentable for VNDocumentCameraViewController (multi-page scan support)
3. `PhotoImportView.swift` — Full local phase state machine: pick → process → review → preview

Modified `RecipeImportSheet` (`.photo` mode), `RecipeListView` (new menu button + sheet), `Info.plist` (`NSCameraUsageDescription`).

### Key Decisions and Why

**1. Single-pass implementation over sub-phase splits**: The plan broke PhotoImportView into M10.3.2 (entry points), M10.3.3 (review wiring), M10.3.4 (FM enhancement) — but all three live in one file following TextPasteImportView's proven pattern. Building them separately would create throwaway intermediate states.

**2. View-driven flow, not extractor**: Like TextPasteImportView, PhotoImportView manages its own local phase enum rather than fitting into the RecipeExtractor protocol. The split-screen review step (image alongside classified text) doesn't fit the extractor's `input → draft` contract. The local state machine pattern is clean and proven.

**3. Dual extraction path**: FM as primary with heuristic fallback mirrors M10.2. On FM-capable devices, OCR text goes to FoundationModelsExtractor first — if it produces a valid draft, the user skips the review step entirely. Only when FM fails/is unavailable does the heuristic classification → SectionHighlightView path activate. This gives the best UX on capable devices while maintaining full functionality everywhere.

**4. Image data for review via JPEG compression**: Rather than holding a UIImage in state (which doesn't conform to Equatable), the review phase stores `Data` from JPEG compression at 0.5 quality. This keeps the enum Equatable and reduces memory for large photos.

### What Was Learned

Vision.framework's coordinate system (bottom-left origin) requires explicit sort for reading order — observations come back in arbitrary order. PhotosPicker's out-of-process design is elegant — no permission needed for library access. VNDocumentCameraViewController returns already-processed images (deskewed, contrast-enhanced), so no preprocessing is needed before OCR.

### What's Next

Manual testing with real recipe photos is the critical next step — the code compiles and follows the proven TextPasteImportView pattern, but real-world OCR accuracy on cookbook photos, screenshots, and handwritten recipes needs validation. After that, M10.4 (Polish & Integration) or M10.6 (Claude API) depending on priority.

---

## Session 51 — February 26, 2026
**Milestone**: M10.6 PRD Creation
**Focus**: Formalize the LLM integration design into a standalone, implementation-ready PRD
**Branch**: `feature/M10.6-prd`

### Why This Session Happened

This was an impromptu planning session. The original plan was to move straight to M10.3 (Photo Import) now that M10.5's pipeline spike is merged. But the M10.5 spike produced a rich Section C in its PRD — a high-level LLM integration design covering protocol shape, OAuth research, provider comparison, prompt engineering, and cost analysis. That design was buried inside a spike document alongside FM evaluation data and 12 regex fix descriptions. If we'd started M10.6 implementation later by referencing Section C, we'd be working from a design embedded in the wrong document, mixed with irrelevant spike context.

The decision to extract a standalone M10.6 PRD now, while the spike findings are fresh, means the implementation session can start clean. The PRD is self-contained — no need to cross-reference the spike document during implementation.

### What Happened

Created `docs/prds/active/m10.6-claude-api-integration.md` — a 12-section, 766-line PRD with implementation-ready detail. This isn't a copy of Section C; it's an enriched design that adds concrete file paths, exact API request/response schemas, the full error-to-fallback matrix, Settings UI wireframes, test file inventory, and sub-phase breakdown.

### Key Decisions and Why

**1. Bypass, Not Tier**
The LLM acts as a pipeline **bypass** in `RecipeImportService.saveImport()`, not a 4th tier inside the hybrid router. When LLM is enabled and configured, it parses ALL ingredient lines in one batch API call and skips regex→ML→NLP entirely. On any failure, the full pipeline runs unchanged.

Why not a 4th tier: The existing `IngredientParser` protocol is sync + per-line. LLM is async + batch. Forcing `IngredientParser` to become async would cascade through `HybridIngredientParser`, `IngredientParsingService`, and 11+ call sites — a massive blast radius for what should be an optional enhancement. The bypass lives at the service layer (`RecipeImportService`), keeping the parsing infrastructure untouched.

**2. Separate Protocol: LLMIngredientParser**
Rather than extending `IngredientParser`, we introduce `LLMIngredientParser` with `parseBatch(_ lines:) async throws -> [LLMParserResult]`. The `toParserResult()` bridge method maps LLM output into the existing `ParserResult` type, so downstream code (Ingredient entity creation, telemetry) works identically regardless of which parser produced the result.

**3. FM Excluded from Fallback Chain**
The fallback chain is `LLM API → deterministic pipeline`. Foundation Models is intentionally **not** in this chain despite being "on-device AI." The M10.5 spike proved FM is unreliable for numeric extraction — it systematically converts grams to kilograms (a silent 1000x error), invents units for unitless items (`1 cucumber` → `unit=g`), and assigns wrong units (`4 slices bread` → `unit=clove`). FM may have a future role in soft tasks (category suggestion, template deduplication) but not for the one job this feature needs: accurate quantity parsing.

**4. Claude-Only for M10.6**
The PRD defines the `LLMIngredientParser` protocol to support multiple providers, but M10.6 only implements `ClaudeIngredientParser`. This is a deliberate "validate the pattern first" strategy. Adding GPT and Gemini adapters is trivial once the protocol, settings UI, and integration point are proven. Shipping Claude-only avoids the complexity of multi-provider testing and UI before we know if anyone uses the feature at all. GPT/Gemini deferred to M10.7+.

**5. Toggle OFF by Default, No Nudges**
The app is fully functional without LLM integration. The toggle is OFF by default. There are no setup banners, no "enhance your experience" prompts, no feature discovery nudges. If a user never opens Settings, they never know LLM integration exists. This is a strong philosophical position: the deterministic pipeline (92-94% accuracy) is the product. LLM is a power-user enhancement for the remaining ~7-8%.

**6. UserDefaults + Keychain, Not Core Data**
All LLM settings (`isLLMEnabled`, `selectedProvider`) go in UserDefaults. API keys go in iOS Keychain. This avoids a Core Data v7 migration entirely — no new entities, no schema change, no CloudKit sync complexity. The trade-off is that LLM settings don't sync across devices via CloudKit, but that's acceptable because API keys are personal (not household-shared in M10.6). Household key sharing is deferred to M10.6.x/M10.7 when we can evaluate whether CloudKit KV store or a Core Data entity is the right approach.

**7. API Keys as the Universal Auth Approach**
The M10.5 spike's OAuth research was a turning point. Anthropic explicitly banned third-party OAuth (Jan 2026 enforcement). OpenAI's OAuth is for ChatGPT actions calling your backend, not your app calling their API. Only Google Gemini supports proper OAuth, but with consent screen review friction that defeats the purpose. API keys are the only approach that works for all three providers. The UX mitigation — deep links to Console, `sk-ant-` prefix validation on paste, "Test Connection" button — turns a 5-minute setup into a 30-second setup.

### Process Observation: PRD-Before-Implementation

This is the second time we've done a "PRD extraction" session (the first was the M10 spike → M10 PRD back in session 23). The pattern is proving valuable: spike produces raw findings + rough design → separate session formalizes into implementation-ready PRD → implementation session starts clean. The spike document stays as a historical record of the exploration; the PRD is the actionable contract.

### What This Means for the Project
M10.6 is estimated at 8.5-12 hours across 5 sub-phases. It sits after M10.3 (Photo Import) and M10.4 (Polish) in the execution order — so the next session starts M10.3, and M10.6 implementation happens later with a ready PRD waiting. Zero Core Data schema changes means no migration risk.

---

## Session 50 — February 26, 2026
**Milestone**: M10.5.4 — Validation Corpus 2 + Confidence Routing Documentation
**Focus**: Build 50-recipe validation corpus, verify pipeline generalization, update docs
**Branch**: `feature/M10.5-spike-pipeline-fixes`

### What Happened
This session continued the M10.5 spike work by building a second 50-recipe corpus to validate that the pipeline fixes generalize beyond the original training data. The earlier part of this session (before context compaction) discovered and fixed a critical confidence routing issue where regex patterns with valid quantity extractions were being overridden by the ML parser.

### Confidence Routing Discovery (Session 49 continuation)
The biggest finding was that the hybrid parser's 0.90 confidence threshold was causing massive qty loss. Regex patterns for descriptive amounts returned 0.60 confidence, ranges returned 0.80-0.85, and standard quantities without units returned 0.75 — all below the threshold. The ML parser won with higher confidence but returned qty=nil for these patterns because it treats descriptive words like "bunch" and "dash" as unit names rather than quantities.

The fix was straightforward: raise confidence levels for all regex patterns that successfully extract a quantity above the 0.90 routing threshold. Descriptive amounts went from 0.60→0.95, ranges from 0.80-0.85→0.92-0.95, and standard patterns from 0.75→0.92. Also fixed a mixed fraction pattern gap where "2-1/2 cups" wasn't matched because the regex only accepted space separators between the whole number and fraction, not hyphens. Changed to `[-\s]+`.

Result: qty extraction jumped from 88.4% to 94.1% (448/476), and regex usage went from 65.5% to 92.9%.

### Corpus 2 — Validation Set
Built a second corpus of 50 recipes from TheMealDB API (no overlap with corpus 1) across the same 5 difficulty categories. Selected diverse cuisines (30+ including Algerian, Croatian, Filipino, Polish, Russian, Jamaican, Portuguese, Canadian) with ingredient counts ranging from 4 to 19.

### Validation Results
The key metric: **92.9% qty extraction on unseen data** vs 94.1% on corpus 1. Only 1.2% degradation means the regex patterns aren't overfitting. Messy category found only 47/~170 ingredients — expected, since prose defeats line-by-line classification. This is exactly the use case for M10.6 LLM integration.

Regex parser usage at 91.8%, confirming the confidence routing fix works consistently across both corpora.

---

## Session 49 — February 26, 2026
**Milestone**: M10.5.4 — Remaining Pipeline Gaps + PRD OAuth/Strategy Update
**Focus**: OAuth research findings, 3 additional pipeline fixes (descriptors, juice/zest, temperature metadata), PRD strategy updates
**Branch**: `feature/M10.5-spike-pipeline-fixes`

### What Happened
This session addressed the remaining pipeline gaps identified by the FM comparison test (33 lines where pipeline returned qty=nil but FM found a quantity). After analysis, ~12 were fixable with regex and ~21 were genuinely semantic (requiring LLM). Three targeted fixes were implemented.

The OAuth research was a turning point for the LLM integration strategy. Discovering that Anthropic explicitly banned third-party OAuth (with a specific Jan 2026 enforcement date) eliminated the "seamless sign-in" UX dream. OpenAI's OAuth is designed for ChatGPT actions (their app calling your backend), not for your app calling their API. Only Google Gemini supports proper OAuth, but the consent screen review process adds friction that defeats the purpose. The conclusion: API keys are the universal approach, and the UX mitigation (deep links, clipboard auto-detect, test connection) is the right investment.

### Pipeline Fixes Round 2
Three fixes were implemented, reducing FM-fixable gaps from 33 to 25:

**Fix 8 (Descriptive Amounts + Qualifiers)**: Added `bunch`, `sprinkling`, `squeeze` to the descriptor map and both regex patterns. Also expanded the qualifier pattern with `for dusting`, `for glazing`, `to serve`, `to garnish`, `for garnishing` — these are common recipe qualifiers that were being classified as unknown.

**Fix 9 (Juice/Zest Prefix Pattern)**: A new `tryPrefixQuantityPattern()` method handles the inverted structure where a descriptor comes before the quantity: `"Juice of 1/2 lemon"`. This pattern is common enough in British and international recipes to warrant dedicated handling.

**Fix 10 (Temperature Metadata)**: Updated the `metadataLabelPattern` to include `(?:\w+\s+)?temperature` so lines like `"Oil temperature: 350F / 175C"` are classified as metadata rather than ingredients.

### Key Decision: Pipeline Has Reached Its Ceiling
After 10 total fixes across 2 rounds, the pipeline is at ~88% qty extraction. The remaining 25 FM-fixable gaps are genuinely semantic — prose-embedded quantities, "X to serve" patterns, ambiguous multi-ingredients. No amount of regex will solve these. This validates the M10.6 LLM integration strategy: regex handles the structured 88%, LLM handles the semantic 12%.

### PRD Strategy Updates
The PRD was updated with OAuth findings (§4.4), household API key sharing (§4.10), future subscription model possibility (§4.11), and the remaining gaps analysis (§3.8). M10.6 was reframed as Claude-only with explicit emphasis that integration is optional.

---

## Session 48 — February 26, 2026
**Milestone**: M10.5 — Pipeline Accuracy Fixes + LLM Evaluation PRD
**Focus**: Spike PRD creation, Foundation Models evaluation writeup, 7 pipeline bug fixes, external LLM API architecture design
**Branch**: `feature/M10.2-text-paste-import` (spike artifacts) → `feature/M10.5-spike-pipeline-fixes` (pipeline fixes)

### What Happened
This session synthesized the findings from Sessions 46-47 (corpus testing, LLM review, FM evaluation) into a comprehensive spike PRD, then implemented the 7 pipeline bug fixes identified by the corpus review.

The FM comparison test (run on physical device with Apple Intelligence) showed FM achieves 78.7% quantity extraction vs the pipeline's 65.2% — a clear accuracy advantage. But the hallucination analysis killed the "FM as primary parser" strategy: systematic gram-to-kilogram conversions (250g → 0.25), invented units (cucumber → unit=g), and batch count mismatches (7/50 recipes) make FM unsuitable for numeric extraction. The pivot: FM for soft tasks (category suggestion, template dedup), external LLM APIs (Claude/GPT/Gemini) for high-accuracy parsing, deterministic pipeline as always-available offline fallback.

### Pipeline Bug Fixes
The corpus review's most impactful finding was that a single root cause — leading bullet/list prefixes (`"- "`, `"• "`, `"* "`) — accounts for ~70% of all 295 errors. Both the classifier and regex parser use `^`-anchored patterns that fail when a `-` character sits at position 0 instead of a digit. Stripping these prefixes before scoring/parsing (while preserving original text in output) was the foundational fix that unlocked improvements across all other patterns.

The remaining 6 fixes addressed specific pattern gaps: metric no-space (`400g`), unit-less count items (`2 eggs`), bare name ingredients (`celery`), unusual metadata (`Difficulty: Easy`), mixed fractions with hyphens (`2-1/2`), and parenthetical prep methods (`butter (softened)`). Each fix was independent after the bullet stripping foundation.

### Cascading Regex Bug Discovery
The initial implementation had a subtle regex character class bug: `[\.\):\s]` in the bullet stripping pattern treated ANY digit followed by a space as a numbered list. This caused `"2 cups flour"` to have its `"2 "` stripped, breaking the parse completely. The same `\s` inclusion existed in `numberedStepPattern`, where it caused lines like `"2 tbs vegetable oil"` (after bullet stripping) to trigger a -0.4 ingredient penalty. Both were fixed to `[\.\):]` (punctuation only).

### Corpus Results (Before → After)
| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Ingredients detected | 442 | 477 | +7.9% |
| Classification confidence | 0.520 | 0.641 | +23.3% |
| Parsing confidence | 0.932 | 0.984 | +5.6% |
| Regex parser usage | 18.3% | 79.8% | +61.5pp |

Per-category: clean 92→106, no-headers 50→77 (+54%), unusual-metadata 135→130, messy 33→51 (+55%), international 132→113. The no-headers and messy categories saw the biggest improvements — exactly the categories that had the most issues in the original review.

### External LLM API Architecture
Designed a clean architecture for external LLM integration: `LLMIngredientParser` protocol with provider adapters, user-owned API keys in iOS Keychain, Settings UI for opt-in, and a three-tier fallback chain (LLM API → on-device FM → deterministic pipeline). The key insight is that the user pays their own API costs directly (~$0.001/recipe with Claude Haiku) — no server-side proxy, no data collection, full privacy. This is the "bring your own key" model that respects user autonomy.

### Key Decisions
- **FM verdict: not a replacement, but an augmentation** — hallucinations are reproducible and systematic, not random errors that more prompting would fix. The gram-to-kg pattern alone is disqualifying for a grocery app where quantities must be exact.
- **Pipeline fixes still worth doing** — even with LLM APIs as the future primary parser, the deterministic pipeline serves as the offline fallback. Fixing 7 bugs that affect 295/442 lines makes the fallback path much stronger.
- **Claude API first (M10.6)** — among external LLMs, Claude's tool use provides the most reliable structured output for ingredient parsing. GPT and Gemini adapters are straightforward additions (M10.7+).
- **Spike artifacts preserved** — FM parser and comparison test committed as reference even though FM isn't the strategic direction. Future sessions may revisit if Apple improves the model.

### AI Tooling
- Opus 4.6 in explanatory mode — the comprehensive PRD writing benefited from the educational style, producing a document that explains both the "what" and the "why" for each design decision
- Plan mode → implementation execution worked well for a task with clear phases and dependencies

### What's Left
- M10.6: Claude API integration (estimated 8-12 hours)
- M10.7+: GPT/Gemini adapter expansion
- Corpus expansion from 50 to 250-500 recipes (deferred to after pipeline fixes settle)

---

## Session 46 — February 25, 2026
**Milestone**: M10.5 — Recipe Test Corpus & Accuracy Baseline
**Focus**: PRD creation, 50-recipe corpus generation, test harness build + first run
**Branch**: `feature/M10.2-text-paste-import` (tacked onto M10.2 branch)

### What Happened
After completing M10.2 and encountering parsing issues during real-world testing, pivoted to building a systematic accuracy measurement infrastructure. Created M10.5 PRD, generated a 50-recipe pilot corpus across 5 difficulty categories, built a test harness that runs the full two-stage pipeline (OCRLineClassifier → HybridIngredientParser), and produced the first accuracy baseline.

### Key Results (First Corpus Run)
- **50 recipes**, 1019 lines classified, 442 ingredients parsed, 0.359s total
- **Classification confidence avg: 0.520** — surprisingly low, biggest improvement opportunity
- **Parsing confidence avg: 0.932** — strong once a line is correctly identified as an ingredient
- **Parser usage**: ML 81.7%, regex 18.3%, NLP 0%
- **Messy category gap**: Only 33 ingredients detected vs 100-130 in structured categories — the classifier struggles with prose-embedded ingredients

### Key Decisions
- **Confirm-or-correct review model**: Pre-fill all predictions, human only marks errors. Same approach used by strangetom's 68,846-sample training set. Much faster than manual annotation from scratch.
- **TheMealDB as data source**: Every major recipe site (AllRecipes, NYT Cooking, etc.) blocks automated fetching. TheMealDB provides a free API with structured ingredient/measure pairs — we reformatted into 5 realistic text styles.
- **5 difficulty categories**: clean (standard headers + lists), no-headers (bare text), unusual-metadata (odd yield/time formats), messy (blog prose), international (metric + British). This covers the real-world formatting spectrum.
- **`#filePath`-based resource location**: Test finds corpus files relative to source path, avoiding 50+ pbxproj resource entries.
- **Two-file output**: JSON for programmatic analysis, markdown for human review. The markdown has per-recipe classification and parsing tables with "Correct? | Correction" columns.

### AI Tooling
- Third conversation window in the same day — context summary system worked well for continuity
- Parallel agent spawning for PRD creation and corpus generation saved significant time
- WebFetch limitations forced the TheMealDB pivot — a good example of tool constraints driving creative solutions

### What's Left
- ~~User review of corpus-review.md (2284 lines of predictions to verify)~~ — LLM-reviewed in Session 47
- M10.5.4: Correction ingestion after human review
- M10.5.5: Scale decision — expand from 50 to 250-500 based on pilot results

---

## Session 47 — February 25, 2026
**Milestone**: M10.5 — LLM Corpus Review + Pipeline Improvement Tracking
**Focus**: LLM review of 50-recipe corpus, systematic bug identification, Foundation Models integration design
**Branch**: `feature/M10.2-text-paste-import`

### What Happened
Used Claude Opus to review all 50 corpus recipes — 5 parallel agents (one per category) identified **295 errors** across classification and parsing. Generated `corpus-review-corrected.md` with all corrections marked. More importantly, distilled 295 individual errors into **7 systematic patterns** that explain the vast majority of failures.

### Corpus Review Results
- **~146 classification errors** — primarily: unit-less ingredients→instruction, bare names→unknown, unusual metadata→unknown, STEP headers→instruction
- **~149 parsing errors** — primarily: metric no-space (`400g`), `tbs`/`tablespoons` unrecognized, mixed fractions (`2-1/2`), prep methods in names
- **LLM review took ~12 minutes** vs estimated 3-4 hours for human review
- Generated `docs/test-corpus/corpus-review-corrected.md` (2286 lines, 295 corrections)

### 7 Systematic Pipeline Bugs Identified
1. **Metric no-space** (`400g`, `750ml`, `2L`) — ~120 parsing failures. Regex expects `\d+\s+unit`.
2. **Unit-less ingredients** (`1 egg`, `2 bay leaves`) — ~30 classification failures. No unit = defaults to instruction.
3. **Bare ingredient names** (`celery`, `sugar`, `passata`) — ~15 classification failures. No quantity = unknown.
4. **Unusual metadata** (`Difficulty:`, `Oven:`, `Active time:`) — ~47 classification failures. Limited keyword list.
5. **Unit abbreviations** (`tbs`, `tablespoons`) — ~15 parsing failures. Not in alias map.
6. **Mixed fractions** (`2-1/2`, `1-1/2`) — parsing failures. Hyphenated form not handled.
7. **Prep methods in names** (`(cubed)`, `(sliced)`, `minced`) — not stripped from ingredient names.

### Strategic Pivot: Universal LLM Backend
The corpus review naturally revealed that Foundation Models (already integrated in M10.2 for text paste) can handle classification AND parsing in a single pass — outperforming the 3-tier pipeline on every category. This led to a design discussion about making Foundation Models the primary ingredient processor for ALL input paths:
- Manual entry → LLM normalizes + suggests category
- URL import → LLM extracts + structures
- Text paste → LLM classifies + parses (already works via M10.2)
- Photo OCR → LLM processes OCR output
- Existing regex→ML→NLP pipeline becomes the offline/fallback path

### Key Decision
The 7 pipeline bugs above are **still worth fixing** — they serve the fallback path and improve the baseline. But the strategic direction is Foundation Models as the primary processor, with the existing pipeline as graceful degradation for devices without Apple Intelligence.

### AI Tooling
- 5 parallel review agents processed the full 50-recipe corpus simultaneously — a powerful pattern for batch analysis tasks
- LLM review found systematic patterns that individual recipe review would miss (aggregating ~120 metric-no-space failures across recipes)
- Context continuity across 3 conversation windows in a day worked well

---

## Session 45 — February 25, 2026
**Milestone**: M10.2 — Text Paste Import
**Focus**: Full M10.2 build — Foundation Models + heuristic fallback + SectionHighlightView + tests
**Branch**: `feature/M10.2-text-paste-import`

### What Happened
Built the complete M10.2 text paste import feature across two conversation windows — Foundation Models extractor, heuristic line classifier, text input UI, SectionHighlightView classification review, and 31 tests. All 6 sub-phases complete.

### Key Decisions
- **Foundation Models API discovery**: The PRD assumed `LanguageModelSession.isSupported` but the actual API is `SystemLanguageModel.default.isAvailable` with a detailed `.availability` enum. Discovered by reading the Swift interface files directly from the SDK.
- **Numbered step scoring bug**: Lines like "1. Mix ingredients" were scoring 0.6 as ingredient (startsWithNumber: +0.5, shortLine: +0.1) and only 0.5 as instruction (numberedStep: +0.5). Added a -0.4 ingredient penalty for numbered steps. This is a generalizable lesson about multi-category scorers — signals can double-count across categories.
- **Mode-aware RecipeImportSheet**: Rather than creating a separate sheet for text import, added an `ImportMode` enum (.url, .text) to the existing sheet. This shares the preview, duplicate detection, category assignment, and error handling flows.
- **SectionHighlightView as local phase**: Rather than adding states to the global `ImportJobState` machine, the classification review lives as a local `TextPastePhase` enum inside `TextPasteImportView`. This keeps the review step scoped to text paste only — it doesn't affect URL import flow at all.
- **Tap-to-cycle reclassification**: Users tap a line to cycle through types (ingredient → instruction → title → metadata → unknown). Simpler than a picker/dropdown for each line, and the color-coded badges give instant visual feedback.

### AI Tooling
- Claude Opus 4.6 in explanatory mode — the SDK interface file reading was particularly valuable for verifying the exact API surface before writing code. This prevented a PRD assumption from becoming a runtime bug.
- Second conversation window picked up seamlessly from context summary after the first ran out of context.

### What's Left
- Foundation Models testing on physical device (requires Pro hardware)
- PR merge to main

---

## Session 44 — February 25, 2026
**Milestone**: M10.9 — Repository Structure Cleanup
**Branch**: `chore/M10.9-repo-structure-cleanup`

### Repo Spring Cleaning

Executed the full M10.9 repo structure cleanup PRD — all 3 tiers in one session:

**Tier 3** (quick fixes): Removed duplicate docs/recipe-import-research.md, deleted dead MigrationTestHelper.swift + its SettingsView debug button, moved milestone5.0.1-name-decision-record.md to docs/architecture/.

**Tier 1** (Core Data models): Moved 36 Core Data entity files from project root to Models/ and converted to PBXFileSystemSynchronizedRootGroup. Root directory went from 46 items to 10. This was the biggest visual impact — the GitHub landing page no longer looks cluttered.

**Tier 2** (app source): Reorganized forager/'s 55 flat Swift files into subdirectories: App/, Theme/, Components/, Views/{Grocery,Recipes,Import,MealPlanning,Household,Settings,Search}/, Debug/. Converted from manual PBXGroup to PBXFileSystemSynchronizedRootGroup. Required a PBXFileSystemSynchronizedBuildFileExceptionSet to exclude Info.plist and entitlements from auto-sync's bundle copy (they're already handled by build settings).

### Key Learning: PBXFileSystemSynchronizedBuildFileExceptionSet

The first Tier 2 build failed with "Multiple commands produce Info.plist" — auto-sync wanted to copy Info.plist as a bundle resource while INFOPLIST_FILE was also processing it. The fix is a membershipExceptions list that excludes files already handled by build settings. Same applies to entitlements referenced by CODE_SIGN_ENTITLEMENTS.

All 3 source directories (forager/, Models/, Services/) now use auto-sync. Only foragerTests/ still uses manual PBXGroup.

---

## Session 43 — February 25, 2026
**Milestone**: M10.1.10 — Import bug fixes (validation limits + title extraction)
**Branch**: `feature/M10.1-url-import`

### Two Import Bugs from Real-World Testing

First real-world test of the new in-app browser against NYT Cooking revealed two issues:

1. **Validation limits too tight for imports**: The 100-character limit on `IngredientTemplate.name` was designed for manual entry, where users type short names. Imported recipes have verbose ingredients — NYT Cooking's carbonara includes "1 ounce (about ⅓ packed cup) grated pecorino Romano, plus additional for serving" — and after parsing, template names can inherit qualifiers that push past 100 chars. Increased to 250 for templates and 300 for recipe titles.

2. **JSON-LD `name` field is unreliable**: NYT Cooking puts just "Carbonara" in the JSON-LD structured data while the actual recipe title is "Spaghetti Carbonara". The full title was available in the HTML `og:title` meta tag. Added a post-extraction enhancement step that checks `og:title` and `<title>` tags — only upgrading when the metadata title is longer AND contains the JSON-LD name (prevents false replacements). Wired into all three extraction paths (JSON-LD, WKWebView, browser).

### Technical Notes

The title enhancement is a containment-based safety check: `og:title.localizedCaseInsensitiveContains(jsonLDTitle)` ensures we're enhancing an incomplete title, not replacing a genuinely different one. Common suffixes like " Recipe" and " - Site Name" are stripped before comparison. This handles the NYT pattern (JSON-LD "Carbonara" → og:title "Spaghetti Carbonara") without over-reaching.

---

## Session 42 — February 24, 2026
**Milestone**: M10.1.9–M10.1.10 — Share extension removal, in-app browser, categorization fix
**Branch**: `feature/M10.1-url-import`

### The Pivot

This session represents a significant UX pivot within M10.1. After completing the share extension (M10.1.7) in Session 41, testing revealed the UX was fundamentally poor — the share sheet flash-and-disappear pattern, combined with the app-switching handoff, felt janky. The user decided to rip it all out and replace with a Paprika-style in-app browser.

This is a textbook example of "technically correct, experientially wrong." The share extension *worked* — App Group handoff, URL scheme, scenePhase fallback, race condition handling — but the resulting user flow didn't meet the bar. The lesson: share extensions are great for content *creation* (posting, saving) but awkward for content *import* where the user needs to see results in the receiving app immediately.

### What Got Built

**M10.1.9 — Share Extension Removal**: Clean deletion of all share extension code. The ~28 pbxproj entries across 9 sections were the trickiest part. The `importService` stayed at app level because the browser needs it.

**M10.1.9 — In-App Browser**: `RecipeBrowserViewModel` manages a WKWebView via KVO observations (URL, title, loading, progress, canGoBack/Forward). The key insight: no settle delay needed. The headless `WKWebViewExtractor` needs 2 seconds for JS to inject JSON-LD, but the in-app browser's page is already rendered by the time the user taps "Import" — extraction is instant.

**M10.1.10 — Categorization Fix**: Found and fixed `categorizeIngredient()` returning phantom category names ("Meat & Seafood", "Dairy", "Pantry", "Other") that don't match seeded Category entity names. New templates now start uncategorized; `CategoryAssignmentModal` handles proper assignment. Also wired the modal into the import save flow — same pattern as CreateRecipeView.

### Architecture Decisions

- **In-app browser over share extension**: Better UX, simpler code (no IPC, no App Groups, no URL scheme), and the extraction reuses existing JSON-LD infrastructure
- **KVO over Combine for WKWebView**: WKWebView's properties are KVC-observable, not Combine publishers. KVO is the natural fit.
- **`@Observable` over `ObservableObject`**: The new macro is cleaner for pure state management — no `@Published` wrappers needed

---

## Session 41 — February 24, 2026
**Milestone**: M10.1.7–M10.1.8 — Share extension + error handling
**Branch**: `feature/M10.1-url-import`

### What Happened

**M10.1.7 — Share Extension + App Group**

Created the `ForagerShareExtension` Xcode target and implemented the full share-to-import handoff:

1. **ShareViewController** — Rewrote Xcode's `SLComposeServiceViewController` template into a minimal no-UI `UIViewController`. Extracts URL from `NSExtensionItem` attachments via `loadItem(forTypeIdentifier: UTType.url.identifier)`, writes to App Group `UserDefaults`, opens main app via `forager://import` URL scheme, completes request.

2. **Info.plist** — Switched from storyboard entry (`NSExtensionMainStoryboard`) to principal class (`NSExtensionPrincipalClass`). Tightened activation from `TRUEPREDICATE` (Apple rejects this) to `NSExtensionActivationSupportsWebURLWithMaxCount: 1` (URLs only).

3. **App Group entitlements** — Added `group.com.richhayn.forager` to both main app (`forager.entitlements`) and extension (`ForagerShareExtension.entitlements`). Added `CODE_SIGN_ENTITLEMENTS` to extension build settings.

4. **foragerApp.swift** — Lifted `RecipeImportService` from inline creation in RecipeListView to app-level `@StateObject` + `.environmentObject()`. Added `.onOpenURL` handler for `forager://import` scheme and `.onChange(of: scenePhase)` fallback. Both trigger `importService.checkForPendingImport()`.

5. **RecipeImportService** — Uncommented `checkForPendingImport()` stub: reads URL from App Group defaults, clears immediately, triggers `importFromURL()`.

**M10.1.8 — Error Handling + Edge Cases**

Implemented wireframe screen 5's type-specific error presentations:
- `ImportError` — `errorTitle` + `errorIcon` computed properties
- `RecipeImportService` — `checkUnsupportedSource()` for Pinterest/TikTok/Instagram fail-fast
- `RecipeImportSheet` — 4 error views via generic `errorLayout<Actions>()` template

### Design Decisions
- **No-UI extension**: Subclass `UIViewController` instead of `SLComposeServiceViewController` — the compose sheet is unnecessary for a URL-only handoff. User sees no extension UI at all.
- **Dual handoff paths**: `.onOpenURL` handles the happy path (extension opens app); `.onChange(of: scenePhase)` handles the fallback (URL stays in defaults until next activation).
- **Service lifted to app level**: `RecipeImportService` moved from inline creation in RecipeListView to `foragerApp` `@StateObject`, injected as `.environmentObject()`. Necessary so `.onOpenURL` at the app level can trigger imports.

### What Went Well
- Xcode target wizard handled all pbxproj complexity for the new extension target
- `PBXFileSystemSynchronizedRootGroup` on the extension directory means no manual file reference management
- Both targets build clean on first try after all changes

---

## Session 40 — February 24, 2026
**Milestone**: M10.1.1–M10.1.6 — Import models, extraction, orchestration, UI, detection
**Branch**: `feature/M10.1-url-import`

### What Happened

Starting M10 implementation — the biggest feature since M7 CloudKit.

**M10.1.1** lays the data model foundation for the entire import system: `ImportDraftRecipe`, `ImportField<T>`, `ImportConfidence`, `ImportFieldSource`, `ImportJobState`, `ImportError`, `RecipeExtractor` protocol, and utility parsers (ISO8601Duration, RecipeYield, HTMLEntity). All 4 files compiled clean on first try.

**M10.1.2** ports the spike's JSON-LD extraction and schema mapping into production. Two files created:
- `RecipeJSONLDExtractor.swift` — 3-tier HTML extraction strategy (ld+json → inline scripts → __NEXT_DATA__), implements `RecipeExtractor` protocol
- `SchemaRecipeMapper.swift` — maps schema.org/Recipe dict → `ImportDraftRecipe` with per-field `ImportField<T>` confidence wrappers

Key adaptation from spike: the spike's `MappingContext` returned diagnostic flags as a separate return value. Production inlines these flags to directly drive `ImportConfidence` levels (HowToSections → `.medium`, unusual yield → `.medium`). Also switched from unconditional entity decoding to guard-first with `HTMLEntityDecoder.containsEntities()`.

**Architecture decisions verified against codebase before coding:**
- Confirmed `RecipeFormData` at `RecipeFormModels.swift:98` has no import-specific fields — separate `ImportDraftRecipe` is the right call
- Confirmed `RecipeService.createRecipe()` at line 44 calls `save()` immediately — validates the need for a separate atomic `importRecipe()` method (M10.1.3)
- Confirmed `ParsingSource.import_` already exists in `ParsingTelemetryService.swift:31` — telemetry attribution ready
- Services/ uses `PBXFileSystemSynchronizedRootGroup` — just create files on disk, no pbxproj edits needed

**Key design choices (M10.1.1):**
1. `ImportField<T: Equatable>` generic wrapper — avoids repeating confidence/source/wasEdited for each field
2. `ImportConfidence: Int, Comparable` with raw values — enables sorting for UI dot colors and min() aggregation
3. `DuplicateResult` uses `NSManagedObjectID` not `Recipe` — reference semantics for Core Data objects
4. `ImportError.userMessage` computed property — every error case maps to a user-facing string (zero silent failures)
5. ISO8601DurationParser and RecipeYieldParser ported directly from spike with no changes needed

**Key design choices (M10.1.2):**
6. Confidence levels driven by parsing context — HowToSection nesting and unusual yield formats get `.medium` vs `.high`
7. `HTMLEntityDecoder.containsEntities()` guard-first pattern in instruction text cleaning
8. `filterIngredientHeaders()` strips section headers ("For the sauce:") from ingredient lists

Both M10.1.1 (4 files) and M10.1.2 (2 files) compile clean. BUILD SUCCEEDED on first try for both.

**M10.1.3** builds the import orchestrator — `RecipeImportService.swift`. This is the central coordinator: URL fetch → extraction → preview → atomic save.

Key verification: the PRD flagged a concern about `IngredientTemplateService.findOrCreateTemplate()` and `incrementUsage()` calling `context.save()` internally. Confirmed this is true (lines 437 and 474). Solution: **child context pattern** — create a child of viewContext, run all template/ingredient operations there (their saves push to parent in memory only), then call `viewContext.save()` exactly once to persist everything to disk atomically. If the save fails, `viewContext.rollback()` discards everything cleanly.

The orchestrator also implements the error collection pattern: extractors return `nil` ("not my format") or throw `ImportError` ("my format but failed"). The orchestrator keeps the last thrown error and shows it if all extractors pass; if no extractor claims the input, shows "No recipe found."

M10.1.3 (1 file) compiles clean. BUILD SUCCEEDED — 3 for 3 on first try across all sub-phases.

**M10.1.6** adds duplicate detection — exact sourceURL match via Core Data fetch predicate, plus fuzzy title match using Levenshtein distance (Wagner-Fischer algorithm, O(n) space). Integrated into `RecipeImportService.checkDuplicate(for:)`.

**M10.1.5** adds WKWebView fallback extractor for ~30% of recipe sites that inject JSON-LD via client-side JS. Uses `CheckedContinuation` to bridge `WKNavigationDelegate` callbacks to async/await. Key pattern: nil-check continuation before resuming to handle the race between didFinish+settle, timeout, and didFail code paths.

**M10.1.4** builds the import preview UI — 3 view files + RecipeListView integration:
- `RecipeImportSheet.swift` — entry point with URL input, state-driven content
- `RecipeImportPreviewView.swift` — extracted fields with confidence dots (green/amber/red/gray)
- `DuplicateResolutionSheet.swift` — modal dialog for duplicate resolution
- Manual pbxproj entries for all 3 files (PBXFileReference, PBXBuildFile, PBXGroup, PBXSourcesBuildPhase)
- Import button added to RecipeListView toolbar (square.and.arrow.down icon)

All sub-phases M10.1.1–M10.1.6 compile clean. 7 BUILD SUCCEEDED on first try, zero regressions.

**M10.1 View alignment to wireframes** (continued session): Rewrote all 3 import view files + added service layer method to align with wireframes:

1. **RecipeImportPreviewView.swift** — Major layout rewrite from simplified prototype to wireframe-accurate:
   - Per-ingredient bordered card rows with confidence dots + qty/name split (replaces numbered gray box)
   - Numbered instruction step circles with "Show all N steps" collapse (replaces full text block)
   - Compact metadata row with dot separators "N servings · N min prep · N min cook" (replaces separate sections)
   - Warning banner with `surfaceWarning` + `warningFG` border (replaces inline text)
   - Partial meta field cards with dashed borders for empty fields
   - Save moved to nav bar `.confirmationAction` toolbar (removed bottom save bar)

2. **DuplicateResolutionSheet.swift** — Added "Replace Existing" as third button, updated title "Similar Recipe Found", all buttons use `.bordered` style matching wireframe screen 4.

3. **RecipeImportSheet.swift** — Wired up `replaceExistingWithDraft()` → `importService.replaceExistingRecipe()`, hides parent Cancel when in `.needsReview` state.

4. **RecipeImportService.swift** — Added `replaceExistingRecipe(objectID:with:)` using child context pattern for atomic in-place update (preserves PlannedMeal references and CloudKit identity).

5. **ImportJobState** — Added `isReviewing` computed property for nav bar coordination.

BUILD SUCCEEDED with zero errors. All existing functionality preserved.

### Insights Logged
- Strategy pattern as Forager-wide convention (RecipeExtractor mirrors IngredientParser)
- ImportDraftRecipe separation rationale vs RecipeFormData
- ImportField<T: Equatable> generic wrapper design
- Confidence-from-context pattern (MappingContext flags → ImportConfidence levels)
- Guard-before-work pattern (containsEntities check before decode)
- Child context for atomic saves (template service saves internally)
- Orchestrator error collection pattern (nil vs throw semantics)
- CheckedContinuation multi-resume guard for WKWebView async bridge
- Manual PBXGroup friction for view files vs auto-detected Services/
- SwiftUI toolbar coordination: parent hides Cancel, child manages its own via `.toolbar`
- Child context `existingObject(with:)` for atomic in-place replace preserving object ID
- HTML wireframe CSS classes → SwiftUI component mapping (bordered HStack, Circle Text, StrokeStyle dash)

---

## Session 39 — February 24, 2026
**Milestone**: M10 Spike — Codex Round 2 Review Fixes
**Branch**: `spike/M10-import-prd-preparation`

### What Happened

A Codex architecture review of commit `966fb59` (the M10 spike output) identified 5 findings. All 5 were assessed as valid and fixed in this session.

**Finding 1 (High) — Draft-first persistence gap**: PRD §3.1 said "draft-first" but referenced `createRecipe()` which calls `save()` immediately. Fixed by adding an explicit **persistence contract invariant** to §3.1: "No `Recipe` entity exists in the view context before the user taps Save." Added integration test requirement: URL → preview → cancel → assert zero Recipe rows.

**Finding 2 (High) — BBC Good Food false positive**: `recipeFound: true` for BBC Good Food with only `imageURL: "Image"` — a non-recipe object in `__NEXT_DATA__` had `cookTime` + `prepTime`. Tightened `findObjectWithRecipeKeys()` to require `recipeIngredient` as mandatory key (not just any 2 of N keys). Eliminated the false positive with zero impact on legitimate extractions.

**Finding 3 (Medium) — extractionMethod always "none"**: The `extract(from:)` method set `ctx.extractionMethod` after strategy calls but returned the stale tuple from the strategy (which captured context before the method was set). Fixed by returning `(result.recipe, ctx)` instead of `result` for all 3 strategies.

**Finding 4 (Medium) — Computed metrics not in JSON**: `ExtractionReport`'s computed properties (fullExtractionCount, medianTime, etc.) weren't serialized by Codable's auto-synthesis. Added custom `encode(to:)` with `SummaryPayload` + `EdgeCaseCounts` structs, `ExtractionSuccessLevel` enum, and `classifySuccess()` method.

**Finding 5 (Low) — Test matrix placeholders**: Results Summary, Edge Case Catalog, and Failure Taxonomy sections had placeholder text. Filled all three with data from the regenerated report.

**Cascading number corrections**: Regenerated the extraction report after code fixes. Recipe count dropped from 13/28 to 12/28 (BBC false positive eliminated). All 12 are full extractions (0 partial). Updated all references across PRD, acceptance criteria, test matrix, insights log, and dev journal.

### Round 3 Review (same session)

Sent updated artifacts to Codex for re-review. All 5 original findings confirmed resolved. 4 new findings surfaced:

**Finding 1 (Medium) — Transaction semantics**: PRD claimed atomic save but `createRecipe()` and `parseAndConnectIngredients()` are two separate commits. Fixed by adding explicit implementation note to §3.1 requiring a new `importRecipe(from:ingredientTexts:)` method that creates Recipe + Ingredients + saves once. Updated §3.2 orchestrator diagram.

**Finding 2 (Medium) — "Dead URLs" number inconsistency**: PRD said "~7/28 (25%)" but actual data shows 16/28 failures. Replaced vague row with precise 3-row breakdown: "No extraction possible | 16/28 (57%)" split into "client-rendered WKWebView recoverable | ~8/28 (29%)" and "truly unrecoverable | ~3/28 (11%)" in both PRD and acceptance criteria.

**Finding 3 (Low) — `__NEXT_DATA__` recall risk**: Tightened `recipeIngredient` requirement could theoretically reject legitimate non-@type recipes. Added risk register entry with mitigation: build validation corpus of 10+ `__NEXT_DATA__` sites during M10.1.

**Finding 4 (Low) — CLI vs report classification mismatch**: `fieldsMissing` checked 6 fields while `classifySuccess()` checked 3 core fields — two competing classification systems. Created single source of truth via `ExtractedRecipe.successLevel` computed property, refactored `classifySuccess()` to delegate, updated CLI to use same classification.

### Key Decisions and Why

**Strict success classification**: Defined "full" as title + ingredients + instructions (the 3 core fields). Previously counted all 8 fields for full/partial. This is more meaningful because time fields and author are genuinely optional — a recipe without cookTime is still usable.

**Regenerate, don't patch**: After fixing extractor bugs, re-ran the full 28-site extraction instead of manually adjusting numbers. This ensures the report is a faithful snapshot of the code's actual behavior, not a hand-edited approximation.

### Deliverables Modified

| # | File | Change |
|---|------|--------|
| 1 | `RecipeJSONLDExtractor.swift` | Tightened `findObjectWithRecipeKeys()`, fixed `extractionMethod` attribution |
| 2 | `ExtractedRecipe.swift` | Added custom Codable, `ExtractionSuccessLevel`, `classifySuccess()` |
| 3 | `extraction-report.json` | Regenerated with all fixes |
| 4 | `m10-recipe-import.md` | PRD §3.1 persistence invariant, §2.x numbers corrected |
| 5 | `acceptance-criteria.md` | Spike findings summary + per-field rates corrected |
| 6 | `test-site-matrix.md` | All placeholder sections filled with spike data |
| 7 | `insights-log.md` | 4 Round 2 insights + 2 Round 3 insights + corrected stale numbers |
| 8 | `ExtractedRecipe.swift` | Round 3: Added `successLevel` computed property, single classification source of truth |
| 9 | `main.swift` | Round 3: CLI uses `successLevel` instead of `fieldsMissing` |

---

## Session 38 — February 24, 2026
**Milestone**: M8.4.1 Normalization Qualifier Reclassification
**Branch**: `feature/M8.4.1-normalization-qualifier-fix`

### What Happened

User testing found that "ground beef" was being normalized to just "beef" when entering recipe ingredients. The 3-tier parser (regex → ML → NLP) was correctly producing `name: "ground beef"`, but `IngredientTemplateService.normalize()` Phase 4 (`removeVariations()`) stripped "ground" as a qualifier word.

**Root cause**: The `removeVariations()` method maintained a flat list of 30+ qualifier words to strip, conflating two fundamentally different categories:
- **Identity qualifiers** (ground, fresh, frozen, dried, dark, whole, unsalted) — change WHAT an ingredient IS
- **Preparation qualifiers** (diced, chopped, sliced, minced) — describe what you DO to it

**Data-driven fix**: Instead of hand-curating an allowlist of compound ingredients, mined the strangetom training dataset (68,846 samples) for qualifier words labeled as NAME. Found 3,032 unique compounds — "ground" appears as NAME 838 times, "fresh" 4,523 times, "unsalted" 904 times. The data overwhelmingly shows these qualifiers are part of ingredient identity.

**Changes made**:
1. Reduced `removeVariations()` strip list from 30+ qualifiers to 9 pure preparation qualifiers (diced, chopped, sliced, minced, crushed, grated, shredded, halved, quartered)
2. Aligned `normalizePlural()` prefix stripping to match the same 9 qualifiers
3. Added compound `preferPlural` last-word check so "dried cranberries" stays plural
4. Added 15 new tests (identity preservation + preparation stripping + dedup)
5. Updated 3 existing tests to match new behavior

All 282 tests pass, 0 failures. Code review (5 parallel agents) found no blocking bugs.

### Key Decisions and Why

**Reclassify rather than allowlist**: The user correctly challenged the initial hand-curated `preservedCompounds` set approach — "how do you know you've gotten all of these compound ingredients?" The training data already encodes this knowledge. Reducing the strip list to only preparation qualifiers is more maintainable and complete than an ever-growing allowlist.

**Trust the parser, fix the normalizer**: The ML model was trained on 68,846 samples that label "ground" as NAME in "ground beef" contexts. The parser gets it right. The normalization layer was undoing correct parser output — a classic case of the bug being downstream from where symptoms appear.

**Only 9 preparation qualifiers survive**: The principle is simple — only strip qualifiers that describe a physical cutting/processing action. Everything else (freshness, quality, type, form) is an identity qualifier that changes the product for shopping purposes.

### What Was Learned

**Data beats hand-curation for normalization rules**: When you have 68,846 labeled training samples, use them to drive decisions. Mining the data for qualifier-as-NAME occurrences took minutes and provided conclusive evidence for the reclassification.

**Pipeline tracing is essential**: The bug symptom ("ground beef" → "beef") could have been in any of 5 places: regex parser, ML parser, NLP parser, template service normalization, or template dedup. Tracing the full pipeline identified the exact location (Phase 4 of normalize) without wasting time fixing the wrong layer.

### Deliverables

| # | File | Change |
|---|------|--------|
| 1 | `Services/IngredientTemplateService.swift` | Reduced qualifier strip list, aligned plural prefixes, added compound preferPlural |
| 2 | `foragerTests/Services/IngredientTemplateServiceTests.swift` | 15 new tests |
| 3 | `foragerTests/Services/IngredientTemplateNormalizationTests.swift` | 3 tests updated |
| 4 | `docs/prds/complete/m8.4.1-normalization-qualifier-reclassification.md` | PRD documenting change |

---

## Session 37 — February 24, 2026
**Milestone**: M10 Recipe Import PRD Preparation Spike
**Branch**: `spike/M10-import-prd-preparation`

### What Happened

Executed a comprehensive overnight spike to validate assumptions from the recipe import research doc before writing the formal PRD. The spike covered 5 work packages (WP1-WP5) plus a user-requested photo/OCR addition — all in one session.

**Work completed**:
1. **Test Site Matrix (WP2)**: Built a 28-URL matrix across 4 tiers: major sites (9), food blogs (9), challenging sources (6), and international sites (4). Each URL was a specific recipe page chosen to test different JSON-LD patterns.

2. **Swift CLI JSON-LD Extractor (WP1)**: Built a full Swift Package Manager CLI tool (`Tools/import-spike/`) with 6 source files: ExtractedRecipe models, ISO 8601 duration parser, yield parser, JSON-LD extractor (3 strategies), schema.org mapper, and a CLI main. Ran it against all 28 sites.

3. **Photo/OCR Extraction (WP8 — user addition)**: Added `ImageRecipeExtractor.swift` with Vision framework OCR + heuristic line classification + section-aware context boosting. Tested against a programmatically generated recipe image.

4. **Acceptance Criteria (WP4)**: Wrote data-backed targets for all 4 phases. Every percentage and latency target traces to a spike measurement.

5. **Wireframes (WP3)**: Created 7 phone-frame screens in HTML/CSS matching ForagerTheme design system: import preview, share extension, partial extraction, duplicate detection, error states, photo OCR result, and camera capture.

6. **PRD Draft (WP5)**: Wrote the formal M10 PRD incorporating all spike findings, Codex review responses, calibrated effort estimates (72-97h), and 7 wireframe references.

### Key Decisions and Why

**WKWebView is Phase 1, not Phase 2**: The research doc assumed ~90% JSON-LD coverage. The spike measured 43% via URLSession because ~30% of recipe sites use WordPress plugins that inject JSON-LD via client-side JavaScript. This single finding reshuffled the Phase 1 architecture — WKWebView fallback is now a sub-phase in Phase 1, not an optional enhancement.

**Three extraction strategies, not one**: The initial extractor only found `<script type="application/ld+json">` tags. Debugging failures revealed Marmiton embeds Recipe JSON in regular `<script>` blocks, and BBC Good Food buries it in `__NEXT_DATA__` Next.js payloads. Each strategy individually covers a small slice; together they reach 43% (estimated 75-80% with WKWebView).

**Extend RecipeFormData, don't replace it**: The Codex review suggested a dedicated `ImportDraftRecipe` model. The spike showed that all extracted fields map naturally to existing `RecipeFormData` fields. Adding optional confidence properties is simpler than building a parallel model hierarchy. The draft-first workflow already exists in create/edit flows.

**Section-aware OCR classification**: Pure line-by-line heuristics achieve ~80% accuracy on recipe text. Tracking section headers ("Ingredients:", "Instructions:") and applying that context to subsequent lines raises accuracy to ~90%+. This is a simple state machine that dramatically improves quality — worth the 20 extra lines of code.

### What Was Learned

**Spike-before-PRD is essential for external dependencies**: Three of the spike's most important findings (43% vs 90% extraction rate, 4 distinct JSON-LD patterns, WKWebView as Phase 1 requirement) would have caused expensive mid-implementation pivots if discovered during build. The 4-hour spike prevented at least 10 hours of wrong-direction work.

**Real-world JSON-LD is messy**: The research doc described clean schema.org patterns. The spike found: HTML entities in 25% of JSON-LD values, @graph wrappers in 18%, array @type fields in 11%, full URL @type in some sites, and HowToStep instruction objects in 39%. A production extractor needs all of these handled from day one.

**OCR is solved; classification is the challenge**: Vision framework OCR achieved 100% character accuracy on clean printed text. The entire complexity lies in figuring out what each line means — is "Mix in the flour" an ingredient or an instruction? Section-aware context is the key insight.

### Process Insight

This session used parallel Task agents extensively — launching wireframe creation, OCR spike, and acceptance criteria concurrently while the main thread handled sequential work. The total wall clock time was significantly less than the sum of individual task hours because independent work packages ran simultaneously.

### Deliverables Created

| # | File | Purpose |
|---|------|---------|
| 1 | `Tools/import-spike/Package.swift` | SPM package (6 source files) |
| 2 | `Tools/import-spike/Sources/ImportSpike/*.swift` (6 files) | CLI: JSON-LD extractor + OCR pipeline |
| 3 | `docs/import-research/test-site-matrix.md` | 28 URLs across 4 tiers |
| 4 | `docs/import-research/extraction-report.json` | Machine-readable results |
| 5 | `docs/import-research/acceptance-criteria.md` | Data-backed thresholds per phase |
| 6 | `docs/import-research/import-wireframes.html` | 7 phone-frame screens |
| 7 | `docs/prds/active/m10-recipe-import.md` | Formal PRD |

### Next Steps

M10 PRD is written and ready for review. Implementation order: M8.4 (ML parsing) first, then M10 (recipe import). M8.4's BiLSTM-CRF parser improves ingredient parsing quality for all three import modes simultaneously — it's the rising tide that lifts all boats.

---

## Session 36 — February 23, 2026
**Milestone**: Recipe Import Research Review
**Branch**: `main` (research/documentation)

### What Happened

Reviewed the recipe-import-research.md document against an external architecture review produced by Codex. The review identified 5 critical findings and 5 missing architecture elements. Evaluated each finding against the actual Forager codebase to determine which were valid, which were overstated, and what the review missed.

### Key Findings from Evaluation

**Valid and high-value**: (1) Preview flow persistence timing — `RecipeService.createRecipe()` saves immediately, so the research doc's code example would persist records before user confirmation. The existing create/edit views already use `RecipeFormData` as a draft, but the research doc's integration example skipped this pattern. (2) `RecipeFormData(from: Recipe)` doesn't exist — the research doc assumed an initializer that hasn't been built. (3) Multi-component recipe model gap — ingredient groups ("For the sauce:") are identified as a pain point but no v1 scoping decision was made.

**Partially valid**: Foundation Models share extension constraint was stated as absolute ("CANNOT run") when it should be qualified ("expected to exceed memory limits — validate with spike"). The Codex review correctly noted no compile-time unavailability annotations exist, but underweighted the practical ~1.2 GB vs 120 MB memory constraint.

**Overstated**: Legal section critique was stylistic rather than architectural. The research doc's legal treatment was already nuanced.

**Missed by Codex**: App Group container sharing for the share extension, CloudKit sync timing during import, `sourceURL` uniqueness not enforced in Core Data, and `OptimizedRecipeDataService` naming inconsistency.

### Process Insight

Running research docs through multiple AI reviewers (Claude for authoring, Codex for architecture review, Claude for meta-evaluation) creates a productive adversarial loop. Each model catches different things. The pattern: author → external review → meta-evaluation → targeted improvements is more effective than any single pass.

### Edits Applied to Research Doc

Applied 6 priority edits plus supporting changes:
1. **Fixed preview flow** — replaced `createRecipe()` code example with draft-first `RecipeFormData` workflow
2. **Added `RecipeFormData` gap note** — acknowledged `init(from:)` doesn't exist yet
3. **Softened Foundation Models constraint** — "CANNOT" → "expected to exceed memory limits, validate with spike"
4. **Added v1 scoping for ingredient groups** — explicit "flatten with labels" decision
5. **Added dedup strategy** (Decision 7) — `sourceURL` match + fuzzy title match
6. **Added share extension handoff** (Decision 8) — App Group shared container pattern
7. **Added Observability & Telemetry section** — KPIs and implementation approach
8. **Added Domain Policy Table** — explicit handling for 8 input source types
9. **Added Open Questions for PRD** — 8 product decisions needed before implementation
10. **Updated effort estimates** — 55-73h → 62-84h with buffer guidance
11. **Expanded legal section** — copyright vs ToS distinction, pre-launch review gates
12. **Updated executive summary and ToC** — reflects all changes

### Next Steps

Research doc is now post-review quality. Gap to A+/PRD-ready: prototype validation (build a JSON-LD extractor spike against top-20 sites), user research (which import method do Forager's actual users want most?), and acceptance criteria quantification.

---

## Session 35 — February 23, 2026
**Milestone**: Post-M8.4 bugfixes (parsing + CloudKit schema)
**Branch**: `main` (direct fixes)

### What Happened

User testing surfaced three issues: (1) "16oz baby carrots" failed to parse because the regex parser requires a space between quantity and unit, (2) editing "baby carrots" to fix it resulted in the template name being normalized to just "carrots" because "baby" was treated as a strippable qualifier, and (3) creating a household on a Release/TestFlight build failed with a CloudKit error because the `quickOption` field on `PlannedMeal` (added in Core Data v6) was never deployed to the CloudKit Production schema.

### Parsing Fixes

**Concatenated qty+unit**: Added a pre-processing step in `RegexIngredientParser.parse()` that inserts a space between trailing digits and leading letters at the start of input. `"16oz baby carrots"` → `"16 oz baby carrots"` before patterns run. This is cleaner than adding dedicated patterns for every concatenated format.

**"Baby" qualifier removal**: Removed "baby" from qualifier lists in both `normalizePlural()` and `removeVariations()`. In grocery context, "baby X" always denotes a distinct product (baby carrots, baby spinach, baby corn), unlike true size descriptors ("large eggs" → "eggs"). Added compound "baby X" entries to the `preferPlural` map for proper plural handling.

### CloudKit Schema Deployment

The `quickOption` field was added to `PlannedMeal` in v6 (M15.5) but the CloudKit Development schema was never updated because no `PlannedMeal` record was synced after the change. Used `initializeCloudKitSchema(options: [])` temporarily to force-push the complete v6 schema to Development, then deployed Development → Production via CloudKit Dashboard. This is a common gotcha documented in our own learning note 34 — schema fields only register when records with those fields actually sync.

### Household Shared Data UI

Fixed the Shared Data section on the household screen to show all 5 data types (recipes, lists, plans, categories, templates) — matching the Migration screen which already showed all 5.

### Key Takeaways

- **Pre-processing beats pattern proliferation**: One normalization step handles all concatenated qty+unit formats.
- **Food vocabulary ≠ generic vocabulary**: "baby" is a product qualifier in grocery context, not a size descriptor. The normalization pipeline needs domain awareness.
- **CloudKit schema requires active pushing**: Adding a field to Core Data doesn't automatically update CloudKit's schema. Must sync records or use `initializeCloudKitSchema()`.
- **267 tests** (259 existing + 8 new), 0 failures.

---

## Session 34 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 8-9: Continuous Learning + Integration Testing) — **M8.4 COMPLETE**
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Completed M8.4's final two phases. Phase 8 closed the ML feedback loop (correction export + retraining script). Phase 9 added 8 end-to-end integration tests and comprehensive milestone documentation. M8.4 is now fully complete after ~25 hours across 10 phases.

### Phase 8: Continuous Learning Pipeline

**Shared tokenizer extraction**: The tokenizer in `MLIngredientParser` was a 50-line method that only used a static punctuation set — completely stateless. Extracting it as a free function `foragerTokenize()` lets both `MLIngredientParser` (inference) and `ParsingTelemetryService` (export) share the exact same tokenization logic. This is critical for train/serve consistency.

**Synthetic reconstruction over raw input alignment**: Corrections carry corrected fields but not raw text. We reconstruct clean training tokens from corrected fields themselves — this produces *better* training data because the reconstructed form matches the model's training distribution.

**Fine-tune with oversampling**: 50 corrections in a 55k-sample training set is noise. Auto-oversampling up to 50x targets ~4.5% of merged set, with lower LR (0.0005) to prevent catastrophic forgetting.

### Phase 9: Integration Testing + Documentation

**8 end-to-end integration tests** covering the PRD scenarios: garlic (qty+unit), milk 2% (edge case), black pepper (fractions), cilantro (natural language), bananas (plural), bulk add (4 ingredients), recipe scaling (2x), and edit recipe (structured field preservation). All pass with the regex tier in tests — proving pipeline correctness is parser-independent.

**Learning note 38** chronicles the full ML parsing journey across all 10 phases. **CLAUDE.md** updated with parser architecture section (3-tier routing, key files, architecture rules). All 7 core docs updated for milestone completion.

### M8.4 Retrospective

Looking back at the full M8.4 milestone:
- **What worked**: Phased delivery with strict acceptance criteria at each gate. The tokenizer contract (TOKENIZER_SPEC.md) caught what would have been a silent train/serve mismatch in Phase 6. The DI infrastructure from M9.5 made the hybrid parser cleanly pluggable.
- **Surprise**: Pre-existing test failures (Phase 7.5) took significant unplanned time. Test suites drift silently when schema evolves without corresponding test updates.
- **Key insight**: The split architecture (CoreML emissions + Swift Viterbi) was forced by CoreML's CRF limitation but turned out to be beneficial — the Viterbi decoder is fully testable without CoreML dependencies.

### Test Results

259 total tests (251 + 8 Phase 9 integration), 0 failures. `** TEST SUCCEEDED **`.

---

## Session 33 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 7.5: Test Failure Fixes)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

After completing Phase 7 (correction instrumentation), a full test suite run revealed 14+ pre-existing test failures across 7 test classes. None were caused by Phase 7 changes — they accumulated silently as schema evolution, normalization behavior, and routing thresholds changed over several milestones without corresponding test updates.

### Root Causes Discovered

The failures fell into five categories, each teaching something about how test suites drift:

1. **Validation requirements added after tests written**: Recipe's `validateForInsert()` was extended to require non-empty `instructions`, IngredientTemplate to require `dateCreated`, and GroceryListItem's `displayText` was marked required at the Core Data model level. Tests that created these entities with minimal properties compiled fine but failed at `context.save()`.

2. **Intentional behavior changes not reflected in tests**: The `preferPlural` dictionary was added to `IngredientTemplateService` to normalize "eggs" → "eggs" (not "egg") for natural grocery naming. Four normalization tests still expected the old singular behavior.

3. **Threshold changes cascading to integration tests**: M8.4 changed hybrid parser routing from 2-tier (regex ≥0.8 → NLP) to 3-tier (regex ≥0.9 → ML ≥0.8 → NLP). Medium-confidence regex results that previously returned directly now route through ML, producing different output.

4. **Schema evolution leaving stale test data**: MigrationValidationTests had hardcoded property names (Recipe.name → title, Ingredient.quantity → numericValue) that no longer matched the current schema.

5. **Swift/Core Data type mismatch**: The `.xcdatamodeld` marks `displayText` as Non-Optional (required), but Swift codegen types it as `String?`. Code compiles with nil, but `context.save()` throws error 1570 at runtime — invisible until a test actually saves.

### Test Host App Crash Investigation

After fixing all 80 unit test assertions (0 failures), the test runner still exited with `** TEST FAILED **`. Three separate issues:

1. **Broken UI test target**: `foragerUITests` was in the test plan but contained only Xcode boilerplate with no configuration. Removed from `forager.xctestplan`.

2. **CloudKit mirroring on in-memory stores**: `NSPersistentCloudKitContainer` creates `NSCloudKitMirroringDelegate` for every store with `cloudKitContainerOptions`. In-memory test stores got mirroring delegates that fired fetch requests during teardown against disappearing contexts. Fixed by guarding `cloudKitContainerOptions` with `if !inMemory` in `createStoreDescription()`.

3. **Test host app rendering full UI**: The critical crash. When tests run, the app launches as test host. `prepare()` was short-circuiting with `isReady = true`, causing the full SwiftUI TabView to render — including views with `@FetchRequest` that tried to execute fetch requests against a context with no loaded stores. The fix: keep `isReady = false` in test mode so the app stays on `AppLoadingView` (a simple image + spinner). The full view hierarchy never renders.

Final result: 245 tests, 0 failures, `** TEST SUCCEEDED **`.

### Design Decisions

**Parser-agnostic assertions**: For HybridIngredientParser tests, rather than pinning assertions to regex-specific output, the tests now verify *pipeline correctness* (did we extract the ingredient name?) rather than *parser-specific output* (did regex return exactly 3.0 for "2-3 cloves garlic?"). This makes tests resilient to future routing changes.

**Minimal production changes**: Two surgical changes to `PersistenceController.swift` — both guarded by `#if DEBUG` or test-only code paths. All other fixes are test-only.

### What Was Learned

Two key discoveries:

1. **Core Data model-vs-Swift type mismatch**: `displayText` is required in the xcdatamodeld but `@NSManaged public var displayText: String?` in Swift. The compiler gives zero warning. Only the runtime save validates it. This class of bug is completely invisible during development and only surfaces in tests that exercise the full save path.

2. **Test host app lifecycle**: iOS unit tests launch the full app as a test host. The `@main` struct's `init()` and `body` all execute. If `isReady` flips to true, SwiftUI renders the complete view hierarchy including `@FetchRequest` controllers — against a context where stores were intentionally not loaded. The correct pattern is to detect `XCTestConfigurationFilePath` and keep the app on a minimal static screen.

---

## Session 32 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 7: Correction Instrumentation)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 7 closes the feedback loop between the ML parser and user behavior. The BiLSTM-CRF model from Phases 2-6 is accurate (98.5% token accuracy), but no parser is perfect for every input. When users edit parser output — renaming an ingredient, fixing a quantity, correcting a unit — those corrections are *exactly* the training data needed to improve the model.

This phase wired `ParsingTelemetryService.logCorrection()` into three production edit flows:

1. **EditRecipeView** — The primary correction source. When a user edits an existing recipe ingredient, `loadRecipeData()` now captures the original parsed values (name, quantity, unit, confidence) as `IngredientInput` fields. At save time, `completeSave()` uses `parseUnified()` (replacing the previous `parseToStructured()` call) to get both the structured entity fields and the parsed ingredient name, then compares original vs edited values. Any difference triggers a correction event.

2. **CreateRecipeView** — Same pattern for new recipes. When a user adds an ingredient (manually or via autocomplete), `originalFullText` is captured. If they edit the text before saving, the correction is logged.

3. **IngredientsView** — Template renames. Both the merge branch (user renames to an existing template name, triggering a merge) and the rename branch (simple name change) now log corrections. These are high-signal because the user is explicitly fixing parser categorization.

### Design Decisions

**Schema v3 with optional backward compat**: Added `parserUsed: String?` and `source: CorrectionSource?` to `ParsingCorrectionEvent`. Both are optional with nil defaults, so v2 JSON decodes fine — `JSONDecoder` silently skips missing optional keys. This is the same proven pattern from schema v1→v2.

**`CorrectionSource` is separate from `ParsingSource`**: Semantic distinction matters. `ParsingSource` tracks where parsing happened (recipe, grocery list, meal plan). `CorrectionSource` tracks where the correction happened (editing a recipe, renaming a template). A correction in `.editRecipe` may have originated from a `.recipeIngredient` parse.

**GroceryListDetailView skipped**: The plan initially included grocery list editing, but examination showed no item name editing exists in the UI — it's quick-add only. No correction flow to wire.

**v1 unlinked corrections**: All corrections use `originalEventId: nil` and `parserUsed: nil`. Linking corrections to their original parse events would require persisting the `parseEventId` on Core Data entities — a schema change deferred to a future phase.

### What Was Learned

The `parseUnified()` refactor from Phase 0c continues to pay dividends. By replacing `parseToStructured()` with `parseUnified()` in save flows, we get both `ParsedIngredient.name` (needed for correction comparison) and `StructuredQuantity` fields (needed for entity population) from a single parse. No double-parse.

The corpus gate display (50 corrections threshold) is a pragmatic guardrail. Retraining on < 50 corrections would likely overfit to a narrow distribution of user preferences rather than capture genuine parser errors.

### Metrics
- 6 new tests, all passing (25 total in telemetry suite)
- 8 files modified (service, models, 3 views, settings, tests, docs)
- Build succeeded first try — nil defaults preserved all existing callsites
- ~2 hours implementation time

---

## Session 31 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 6: Test Suite + Tokenizer Fix)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 6 creates the comprehensive test suite for the ML parser pipeline — and in doing so, uncovered real tokenizer bugs that were silently degrading model accuracy in production.

Two new test files were created:

1. **ViterbiDecoderTests.swift** (15 tests) — Pure algorithm tests using hand-crafted 3-label (A/B/C) emission matrices. These isolate individual Viterbi behaviors (start transitions, end transitions, backpointer correctness, tie-breaking) without needing the real CoreML model. All 15 passed immediately.

2. **MLIngredientParserTests.swift** (21 tests) — Integration tests requiring the CoreML model in the test bundle. Covers standard format regression, known regex failure cases the ML model should handle, fraction/unicode parsing, complex inputs (parentheticals, comma prep), confidence validation, parser attribution, tokenizer cross-validation, and performance benchmarks.

The integration tests initially had 8 failures, which split into two categories: **real tokenizer bugs** (3 failures from incorrect token splitting) and **model output assertion specificity** (2 failures from exact-match assertions on probabilistic outputs). The remaining 3 failures cascaded from the tokenizer bugs.

### Decisions Made and Why

**Context-aware punctuation splitting**: The tokenizer was incorrectly splitting `.` and `/` as standalone punctuation even when they appeared between digits. This turned `1/4` into `["1", "/", "4"]` and `14.5` into `["14", ".", "5"]` — completely wrong vocabulary IDs sent to the model. The fix checks digit context: only split `.` and `/` when NOT between digits. This matches the Python training tokenizer's behavior exactly.

**NFKD combining mark stripping**: NFKD normalization decomposes `ñ` into `n` + combining tilde (U+0303), but the combining mark was NOT being stripped. Python's `str.encode('ascii', 'ignore').decode('ascii')` drops these implicitly; Swift needs explicit `CharacterSet.nonBaseCharacters` filtering. Without this, `jalapeño` stayed as `jalapeño` rather than becoming `jalapeno`, causing vocabulary mismatches.

**Invariant-based ML assertions**: Tests for deterministic algorithms (Viterbi) use exact equality. Tests for ML model outputs use invariant assertions — `result.name.contains("flour")` rather than `result.name == "flour"`, `result.confidence > 0` rather than an exact threshold. The model has 95.4% sentence accuracy, meaning ~1 in 20 sentences may differ from human expectations. The hybrid router handles these cases in production.

**Manual timing over XCTest measure{}**: The `measure { }` block triggered CoreData infrastructure in the test process, causing `NSInvalidArgumentException`. Manual `CFAbsoluteTimeGetCurrent()` timing is more robust in this context and avoids the test infrastructure setup that conflicts with CoreData initialization during app bootstrap.

### AI Tooling Learnings

Cross-validation testing proved its worth dramatically. The 102 frozen test vectors from the Python training pipeline — a contract between training and inference — caught three tokenizer bugs on first run. Without these vectors, the model would have been receiving wrong vocabulary IDs in production, silently degrading from 98.5% token accuracy to something lower. The "cross-validate frozen contracts" pattern should be applied wherever training and inference systems are in different languages.

Context recovery from the previous session's compaction was again seamless. The summary preserved the Phase 6 task list, all prior architecture decisions, and the specific test specifications from the PRD.

### What It Means

Phase 6 closes the implementation loop on the ML parser. The tokenizer fix means the Swift inference pipeline now matches the Python training pipeline exactly — the model receives the same vocabulary IDs it was trained on. With 36 new tests (15 Viterbi + 21 ML integration) and 0.84ms/parse steady-state performance, the ML parser is thoroughly validated and production-ready.

Phases 0-6 represent the complete ML parser build: architecture → data → training → CoreML → runtime → integration → testing. The remaining phases (7-9) shift focus from building the parser to building the ecosystem around it — correction telemetry, continuous learning, and integration testing.

---

## Session 30 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 5: HybridIngredientParser Integration)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 5 integrates the ML parser into the production routing chain. This is the culmination of Phases 0-4 — the ML model is now live in the app, processing real ingredient text alongside regex and NLP.

The core change was rewriting `HybridIngredientParser.swift` from 2-tier (regex → NLP) to 3-tier (regex → ML → NLP) routing with winner-only attribution. The routing logic mirrors the PRD pseudocode almost exactly, with graceful degradation when the ML model is unavailable (`mlParser: IngredientParser? = nil`).

**Files changed**: 9 production files + 2 test files + 1 ADR document. Despite the breadth, each change was surgical — routing logic update, comment updates, warmup call, and test assertion fixes.

### Decisions Made and Why

**NLP gate at both < 0.5**: NLP is only consulted when BOTH regex and ML produce confidence below 0.5. This is conservative but intentional — NLP's confidence cap (0.75 from ADR 010) means it can never beat a decent ML result (0.5-0.8), so consulting it in the moderate band wastes time. The gate protects against NLP overriding ML on inputs where ML is simply less confident than usual but still correct.

**Winner-only attribution over "hybrid" label**: The old `"hybrid"` parserUsed value was a routing artifact — it said "regex won but we checked NLP too." For telemetry analysis, you want to know which parser to improve: group corrections by `parserUsed` and each group directly measures one parser's accuracy. `"hybrid"` would require additional metadata about consultation history.

**CoreML warmup in `foragerApp.init()`**: The static `sharedParser` lazily loads the CoreML model on first use. If that first use is during SwiftUI body evaluation (e.g., `extractCleanIngredientName` called from a view), the 100-500ms JIT compilation blocks the main thread. A one-line warmup dispatch during app init prevents this entirely.

### AI Tooling Learnings

Context recovery from session compaction was seamless. The summary preserved every detail needed to continue: PRD line numbers, file contents read in the previous session, the "yes, let's continue with phase 5" user intent, and the detailed routing pseudocode from the PRD. No ramp-up time was needed.

The build → test build verification (both SUCCEEDED) confirmed that changes across 11 files compile correctly together. SourceKit continued to report false positives about missing types — these are consistently unreliable in this project's `PBXFileSystemSynchronizedRootGroup` structure.

### What It Means

The ML parser is now live in the routing chain. Every `HybridIngredientParser()` instance — including the static `sharedParser` — now includes the ML tier by default. Phase 6 (tests) will validate that the routing works correctly with real model outputs, and that known regex failure cases are handled by the ML parser.

---

## Session 29 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 4: ViterbiDecoder + MLIngredientParser)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 4 implements the Swift runtime components that consume the CoreML model from Phase 3. Two new files:

1. **ViterbiDecoder.swift** (~70 lines) — Pure-Swift Viterbi algorithm ported from the Python reference. Standard forward pass with backpointers + backtrace, consuming all 3 CRF parameter sets (7×7 transitions + start + end vectors). The critical detail from Phase 3 was that `transitions.json` uses `label_names` as the key, not `labels` as the PRD pseudocode showed.

2. **MLIngredientParser.swift** (~300 lines) — Full pipeline: tokenize → vocabulary lookup → CoreML emissions → Viterbi decode → assemble result. Implements the `IngredientParser` protocol with failable `init?()` for graceful degradation when resources are unavailable.

The tokenizer follows the frozen TOKENIZER_SPEC.md contract exactly: NFKD normalize → lowercase → whitespace normalize → punctuation split → truncate to 64 tokens. Key subtlety: NFKD decomposes Unicode fractions (½ → "1⁄2" with U+2044 fraction slash), so the quantity parser handles both regular "/" and U+2044.

### Decisions Made and Why

**Simple per-label token collection for result assembly**: Rather than complex region-based grouping, tokens are collected by label type (QTY → quantity, UNIT → unit, NAME+MODIFIER → name, PREP+COMMENT → notes). This means connecting words like "and" labeled as OTHER between PREP tokens get dropped from notes (e.g., "peeled and diced" might become "peeled diced"). Accepted as v1 trade-off — the critical data (qty/unit/name) is correct, and the model may actually label "and" as PREP in context.

**Geometric mean for confidence**: Using `exp(mean(log(max_softmax_probs)))` rather than arithmetic mean. This is sensitive to ANY uncertain token — even one low-confidence prediction drags down the entire score. Better for routing decisions in the HybridIngredientParser.

**Unicode fraction slash handling**: Added explicit handling for U+2044 (FRACTION SLASH) in quantity parsing. After NFKD, ½ decomposes to "1⁄2" with this character, which is different from the regular "/" (U+002F). Without this, fraction quantities from Unicode input would silently fail to parse.

**Deferred UnitCanonicalizer extraction**: The PRD mentions extracting a shared unit standardizer as a Phase 4 sub-task. Deferred to Phase 5 integration work where all three parsers' unit maps will be reconciled. For now, MLIngredientParser has its own `standardizeUnit()` matching the same patterns.

### AI Tooling Learnings

Context recovery after session compaction worked smoothly. The summary preserved all critical details: file paths, architecture decisions, the `label_names` vs `labels` JSON key mismatch, and the pending CLAUDE.md update. The previous session's interrupted documentation work (insights log + journal) was picked up and completed before moving to new code.

The CLAUDE.md update to make insights/journal updates MANDATORY was committed first, reinforcing the behavioral rule going forward. This kind of process improvement — encoding session learnings into durable instructions — is one of the most valuable uses of the CLAUDE.md file.

### What It Means

Phase 4 is the last "pure implementation" phase. From Phase 5 onward, it's integration and testing. The ML parser is now a complete `IngredientParser` implementation that can be slotted into the HybridIngredientParser routing chain. Build succeeds with both new files auto-detected by Xcode's `PBXFileSystemSynchronizedRootGroup`.

---

## Session 28 — February 22, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 3: CoreML Conversion + Viterbi Parity Gate)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 3 converted the trained BiLSTM-CRF model into a CoreML `.mlpackage` and verified Viterbi parity — the critical gate between Python training and Swift runtime.

**CoreML Conversion:**

Wrote `convert_to_coreml.py` (283 lines) that extracts the BiLSTM emission scorer from the full BiLSTM-CRF model. The key insight: `pack_padded_sequence` (used in training for batched variable-length inputs) cannot convert to CoreML, but for single-sequence inference (batch_size=1 with no padding), dropping packing produces identical results — max diff was literally 0.0.

The conversion used coremltools 9.0 with `RangeDim(1, 64)` for variable-length input sequences. Torch 2.8.0 is newer than the officially tested 2.7.0, but conversion succeeded without issues. Final model: 5.15 MB, FLOAT32, iOS 18 minimum deployment.

**Viterbi Parity Gate (the big one):**

The Python reference Viterbi decoder matches pytorch-crf's decode output with 100.0000% parity — 8,030/8,030 tokens across 1,000 test samples, zero disagreements. This is actually expected: the Viterbi algorithm is deterministic given identical inputs, and with emission differences at 4.77e-06, no argmax decisions are flipped.

The end-to-end check (CoreML emissions + Python Viterbi vs full PyTorch CRF) also achieved 100% parity on 100 samples.

**Xcode Integration:**

Added three files to the project: `.mlpackage` in Sources (Xcode auto-generates `IngredientTaggerEmissions` prediction class), `transitions.json` and `vocabulary.json` in Copy Bundle Resources. Build succeeded clean. Verified all resources present in the app bundle.

### Decisions Made

1. **FLOAT32 over FLOAT16**: Used full FLOAT32 precision for maximum emission parity. FLOAT16 would halve model size but increase emission differences, potentially causing label prediction differences at decision boundaries. At 5.15 MB, size is not a concern.

2. **iOS 18 minimum deployment target**: Matches the app's current iOS 26 deployment target with headroom. No iOS 18-specific features used by the CoreML model itself.

3. **MLModel/ directory for JSON resources**: Created `forager/MLModel/` to group ML-related resources separate from other app files. The `.mlpackage` stays at top level for Xcode to auto-generate the prediction class.

### AI Tooling Learnings

The entire Phase 3 was completed in a single session — about 2 hours including documentation. The conversion script ran end-to-end on first attempt with no debugging needed. This continues the pattern from Phase 2: when the PRD specs are thorough (12 review passes), implementation is smooth.

The coremltools scikit-learn compatibility warning and Torch version warning were both non-issues — these are advisory, not errors. Good to know for future ML work.

### What It Means

The "can we get it to iOS?" question is now answered. The CoreML model produces identical predictions to the Python model (100% Viterbi parity), fits in the bundle at 5.15 MB, and Xcode generates the prediction class automatically. Phase 4 is the transition from Python to Swift: implementing `ViterbiDecoder.swift` and `MLIngredientParser.swift` that consume these resources at runtime.

---

## Session 27 — February 21, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 2: Model Architecture & Training)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

Phase 2 of M8.4 — the core ML training phase. Wrote `train_model.py` (340 lines) and trained a BiLSTM-CRF sequence labeler that exceeded all acceptance criteria on first attempt.

**The Training Pipeline:**

The script implements a complete training pipeline: vocabulary building (min_freq=2 → 5,372 words), `IngredientTagger(nn.Module)` with embedding → BiLSTM → dropout → linear → CRF architecture, sorted-batch collation with `pack_padded_sequence`, gradient clipping at 5.0, and early stopping with patience=5. The CRF layer from `pytorch-crf` handles both training loss (negative log-likelihood) and inference (Viterbi decoding).

**Architecture Decisions:**

Hidden dim was bumped from the PRD's 128 to 256 during implementation — the larger hidden state provides more capacity for the BiLSTM to capture ingredient patterns, and the model still comes in at 5.2 MB (well under the 10 MB budget). Dropout was also increased from 0.3 to 0.5, which proved prescient: the train/val loss gap at stopping was only 0.03 (0.17 vs 0.20), suggesting dropout effectively controlled overfitting.

**Results:**

All targets exceeded comfortably:
- Token accuracy: 98.49% (target ≥96%)
- Sentence accuracy: 95.40% (target ≥92%)
- QTY F1: 0.9968, UNIT F1: 0.9939, NAME F1: 0.9869 (all target ≥0.90)
- MODIFIER F1: 0.9261 — the weakest label due to severe class imbalance (only 1.1% of tokens)
- Model size: 5.2 MB (target <10 MB)

Training took ~39 minutes on Apple Silicon MPS (Metal Performance Shaders). Early stopping found the best model at epoch 21/30, stopping at epoch 26.

**CRF Transition Patterns:**

The learned CRF transition matrix is interpretable and matches ingredient grammar: QTY→UNIT has the highest forward weight (1.28), NAME→NAME self-transitions (1.32) capture multi-word ingredient names, and PREP→PREP/COMMENT→COMMENT model multi-word phrases. Start transitions favor QTY (0.59), reflecting that most ingredients begin with quantities.

### Debugging Notes

Two notable issues during the session:

1. **Em dash encoding mismatch**: `update_model_card()` used `--` in replacement keys but MODEL_CARD.md uses Unicode `—` (U+2014). Replacements silently failed. Fixed by using `\u2014` escape in Python code.

2. **Python stdout buffering**: Training output wasn't visible when run as a background task. Python buffers stdout when not connected to a terminal. Fixed by rerunning with `python -u` flag.

### AI Tooling Learnings

Running a ~39-minute training job inside Claude Code required some workflow adjustment — the initial attempt used background execution which obscured output due to Python's stdout buffering. Running in foreground with `-u` flag gave real-time epoch-by-epoch visibility. The model trained successfully on first attempt with no hyperparameter tuning needed, which speaks to the quality of the Phase 1 dataset preparation.

### What It Means

The hardest "will this work?" question of M8.4 is now answered definitively: yes. The model exceeds all targets and the CRF transition patterns show it has learned real ingredient grammar. Phase 3 (CoreML conversion) is the next critical gate — extracting the BiLSTM emission scorer into a `.mlpackage` and verifying Viterbi parity between Python and Swift implementations.

---

## Session 26 — February 21, 2026
**Milestone**: M8.4 ML-Powered Parsing (Phase 0+1: Contract Lock + Dataset Preparation)
**Branch**: `feature/M8.4-ml-parsing`

### What Happened

The first implementation session of M8.4, covering two phases in a single session. Phase 0 locked all contracts (architecture, tokenizer spec, model card), and Phase 1 built the complete dataset preparation pipeline.

**Phase 0 — Contract Lock (3 deliverables):**

1. **Architecture locked**: Word-only BiLSTM v1 — no character features. The decision came from PRD review passes 1-11: char-level features add CoreML conversion complexity for marginal accuracy gain on ingredient vocabulary where words are already distinctive ("cups", "tsp", "garlic").

2. **Tokenizer spec frozen**: `TOKENIZER_SPEC.md` with 100 test vectors covering NFKD normalization, case folding, punctuation splitting, and compound word preservation. The critical NFKD vs NFD distinction (Session 24 insight) was baked into the contract.

3. **Single-parse refactor**: `parseCore()` became the single telemetry entry point, and `parseUnified()` returns both `ParsedIngredient` + `StructuredQuantity` from one `parser.parse()` call. This eliminated redundant parsing across 3 view files and IngredientParsingService itself — critical prep for when ML inference enters the pipeline.

**Phase 1 — Dataset Preparation (1 deliverable):**

4. **`prepare_dataset.py`**: Full pipeline converting strangetom's SQLite (81,316 rows) to Forager's JSONL format. Key steps: fraction decoding (3-pass `re.sub` for mixed/prefixed/simple fractions), 13→7 label mapping, deduplication by sentence (removed 12,470 = 15.3%), validation, statistics computation, stratified 80/10/10 splitting by source.

Final dataset: 68,846 unique samples → 55,076 train / 6,885 val / 6,885 test. Zero data leakage verified between splits.

### Decisions Made

1. **strangetom only, not NYT**: The PRD originally mentioned merging NYT (180k) + strangetom. In practice, strangetom already includes NYT-sourced data among its 5 sources. Using strangetom's unified labeling avoids cross-dataset label alignment issues.

2. **Deduplicate before splitting**: 15% of strangetom is duplicate sentences. Without dedup, identical sentences would appear in both training and test sets, inflating evaluation metrics. Standard ML hygiene, but the duplicate rate was higher than expected.

3. **Coarse labels over fine-grained**: Mapping 13 strangetom labels to 7 Forager labels (QTY, UNIT, NAME, MODIFIER, PREP, COMMENT, OTHER) loses some granularity (B_NAME_TOK vs I_NAME_TOK distinction) but matches what Forager actually needs for structured ingredient display. The mapping is a dict, not regex, so it's auditable.

4. **Fraction decoding at dataset time**: strangetom's `#num$den` notation must be decoded to decimals before training, since production text won't contain these encoding artifacts. The 3-pass `re.sub` approach handles mixed fractions, embedded ranges, and suffixed tokens cleanly.

### Research and Planning Approach

This was a "build exactly what the PRD says" session — the 11 review passes from Session 24 had already resolved all ambiguities. The only discovery was the deduplication rate being higher than anticipated (15% vs the implicit assumption of unique data).

### AI Tooling Learnings

**PRD review investment pays off immediately.** Zero implementation surprises — every edge case (fraction encoding, label mapping, deduplication, split leakage) was already spec'd. The single-parse refactor was identified in PRD review pass 1 (finding: "double-parsing per ingredient") and executed cleanly because the scope and rationale were pre-documented.

### What It Means

M8.4's foundation is solid: contracts locked, dataset ready, pipeline validated. Phase 2 (model training) is pure Python ML work — `train_model.py` with BiLSTM-CRF, early stopping, evaluation metrics. No Swift changes needed. The training targets are clear: ≥96% token accuracy, ≥92% sentence accuracy, ≥0.90 per-class F1 on QTY/UNIT/NAME.

Next session: M8.4 Phase 2 (model architecture and training).

---

## Session 25 — February 21, 2026
**Milestone**: M8.4 ML-Powered Parsing (Recipe Import Research & Validation)
**Branch**: `main` (research session, no code changes)

### What Happened

A focused research session validating that M8.4's BiLSTM-CRF parser investment pays forward to Forager's future recipe import feature. Updated `recipe-import-research.md` with three new sections synthesized from competitive research, M8.4 PRD analysis, and Forager codebase review.

**Three sections added:**

1. **M8.4 Architecture Validation for Recipe Import** — confirmed that M8.4 directly supports recipe import with zero new plumbing. Key validation: all three import paths (URL, text paste, photo) converge at `parseAndConnectIngredients()`, which automatically benefits from the ML parser tier. Documented 7 implementation pitfalls with severity ratings and mitigations.

2. **Competitive Parsing Quality & User Complaints** — deep dive into how competitors handle ingredient parsing. Mapped 10 specific failure patterns (unicode fractions, range quantities, unmeasured amounts, product variants, multi-word units, compound names, ingredient groups, inline prep, word-number quantities) to M8.4's coverage. Used Mealie's open GitHub issues as a cautionary tale — re-parsing destroys user edits, silent API failures, database interference with parser.

3. **AI-Assisted Import Strategy** — recommended layered extraction architecture using Foundation Models for document-level understanding + BiLSTM-CRF for token-level extraction. Key finding: Foundation Models CANNOT run in Share Extensions (120MB limit vs 1.2GB model), which reinforces minimal share extension architecture. Hardware availability analysis: ~60-70% of iOS 26 users have Apple Intelligence support.

### Decisions Made

1. **Foundation Models + BiLSTM-CRF are complementary, not competing** — LLM for "what is this text?" (section detection), ML for "what does each token mean?" (ingredient parsing). No competitor uses both layers.

2. **Share Extension must be minimal** — the 120MB memory limit rules out Foundation Models in the extension. URL extraction only, AI processing in main app.

3. **Mealie's re-parse data loss is the anti-pattern** — Forager's correction instrumentation (M8.4 Phase 7) explicitly avoids this by logging corrections separately from parse results.

### Research and Planning Approach

Conducted parallel web searches across 4 categories: BiLSTM-CRF benchmarks, competitive parsing complaints, Foundation Models limitations, and strangetom dataset accuracy. Cross-referenced findings against the M8.4 PRD to verify all pitfalls were captured.

The strangetom model accuracy data (95.27% sentence / 98.10% word on 81k sentences) was confirmed directly from the project documentation. BiLSTM-CRF typically exceeds pure CRF by 1-3% on sequence labeling tasks, supporting the 96%+ target in the M8.4 PRD.

Pestle's competitive position was clarified: on-device ML optimized for social media captions (~0.1s), now adding Apple Intelligence for broader website support. Their developer explicitly chose on-device ML over ChatGPT for speed, privacy, and control — the same philosophy as Forager.

### AI Tooling Learnings

**Parallel web search is essential for research sessions.** Running 4+ searches simultaneously and synthesizing results produces a much richer picture than sequential searching. The competitive parsing quality section would have been thin without cross-referencing Mealie GitHub issues, Pestle TechCrunch coverage, and NYT tagger edge case documentation in the same pass.

### What It Means

M8.4 is validated as a foundational investment — not just a parsing improvement, but the core of Forager's future recipe import quality. The research document now serves as a reference for future PRD writing, with specific evidence for architectural decisions.

Next session: M8.4 Phase 0+1 (contract lock + dataset preparation). Create `feature/M8.4-ml-parsing` branch.

---

## Session 24 — February 21, 2026
**Milestone**: M8.4 ML-Powered Parsing (Planning — 11 review passes)
**Branch**: `main` (planning session, no code changes)

### What Happened

This was a pure planning session — no code written, but arguably more valuable than a coding session. The M8.4 PRD went through **eleven review passes** (8 external via Codex, 3 internal) producing **60 findings** across 3 severity levels. Every finding was triaged and integrated.

**Pass 1 (Codex, 11 findings)** caught architectural gaps: Viterbi decoder missing start/end transition handling, model spec inconsistent about char features, double-parsing per ingredient, correction instrumentation not wired, main-thread ML risk.

**Pass 2 (Codex, 6 findings)** caught contract and migration gaps introduced by the pass 1 fixes: `parseEventId` doesn't exist on entities, background dispatch conflated with sync parsers, `"hybrid"` vs winner-only attribution conflict, schema v3 not planned.

**Pass 3 (Codex, 5 findings)** caught precision gaps in the corrections system: per-parser correction rate underspecified without linkage, acceptance criterion conflicts with existing test assertions, stale CRF text in Section 2, `source` field doesn't exist on correction model.

**Pass 4 (Internal, 12 findings)** was a full code cross-reference audit — reading every referenced source file and verifying claims. Biggest discoveries: the double-parse pattern exists in 5 call sites (not just 1), 11 production `parseIngredient()` callers generate zero telemetry, strangetom has 13 labels (not 12), session hour estimates didn't add up to phase estimates, and the static `sharedParser` implicitly gets the ML parser through default init parameters.

**Pass 5 (Codex, 3 findings)** caught the `ParsingSource` vs `CorrectionSource` typing mismatch (parse-context enum reused for edit-flow context), a Section 3.3 contradiction ("Modified" vs "NOT modified"), and per-parser rate source bias needing denominator guardrails.

**Pass 6 (Codex, 2 findings)** was the final convergence pass: winner-only test update scope was too narrow ("2 assertions" when there are actually 3 across 2 test files), and legacy `"hybrid"` telemetry values from prior app versions need a handling strategy. Zero high-severity findings — the PRD converged.

**Pass 7 (External Codex, 3 findings)** caught: Phase 7b `logCorrection()` example included `parserUsed` but was missing the `source` parameter (medium), stale "18-24h" estimate at line 188 (low), and Section 3.3 "No file changes required" self-contradictory wording (low).

**Pass 8 (Internal, 3 findings)** cross-referenced PRD against ADRs and future milestones: ADR 010 still documents `"hybrid"` attribution but Phase 5 switches to winner-only without mentioning the ADR update (medium), `HybridIngredientParser.parserName = "hybrid"` becomes orphaned after winner-only but PRD didn't address it (medium), and `docs/roadmap.md` had stale "18-24h" estimates in 4 places (medium). Also performed a tech debt assessment against M9.5-full, M9.3, M6, and M10 — no conflicts found.

**Pass 9 (External Codex, 2 findings)** caught: `parserName` removal conflicts with the `IngredientParser` protocol contract which requires `parserName: String { get }` on all conforming types (medium), and the header review-count arithmetic was confusing (low). Fixed by retaining `parserName = "hybrid"` for protocol conformance and simplifying the header format.

**Pass 10 (External Codex + Internal consistency sweep, 3 findings)** caught: M9.3 rationale was stale — referenced "called on main thread" which is no longer accurate after M9.5-partial made parsers injectable (low-medium), Section 3.4 "no changes needed" wording was misleading after Phase 7 added correction instrumentation (low). The internal consistency sweep found duplicate "7b" sub-section labels in Phase 7 — two different sub-sections both labeled "#### 7b:". Fixed by demoting the second to an unnumbered bold subsection.

**Pass 11 (Internal principal mobile engineer review, 10 findings)** was a deep technical review from a senior iOS/CoreML engineering perspective. Key findings: tokenizer padding spec contradicted RangeDim dynamic input shapes (should be no padding, not right-pad), Swift NFKD normalization requires `applyingTransform` (not `decomposedStringWithCanonicalMapping`), missing `runEmissionModel` implementation sketch for MLMultiArray stride-based access, unit canonicalization duplicated across parsers needs extraction, CoreML first-prediction warmup latency (100-500ms JIT compilation on first load), silent model load failure needs `#if DEBUG` logging, memory estimate too low (runtime ~8-10MB not <5MB), test structure should split into 3 files, model presence guard test needed, and 4 CoreML platform risks added.

### Decisions Made

1. **Phase 0 feasibility gate**: Dedicated contract-locking phase before any ML implementation. Tokenizer spec, architecture lock, single-parse refactor, Viterbi parity criteria, governance artifacts. Worth the schedule impact for reduced downstream risk.

2. **Word-only architecture for v1**: No char CNN/LSTM features. Simplicity wins — strangetom CRF achieves 95.25% without them.

3. **Single-parse refactor expanded to all call sites (Phase 0c)**: Internal review found 5 double-parse sites (not just `parseAndConnectIngredients`) and 11 `parseIngredient()` callers with zero telemetry. Phase 0c now covers the full scope.

4. **Correction instrumentation as its own feature (Phase 7)**: User elevated this from "part of continuous learning" to a dedicated phase.

5. **Unlinked corrections for v1**: Corrections logged with `originalEventId: nil`. Per-parser rates scoped to attributable subset (CreateRecipeView where `parserUsed` is in memory), with denominator guardrails (N ≥ 20) and unattributable share always displayed.

6. **Winner-only parser attribution**: `parserUsed` reports the winning parser (`regex`/`ml`/`nlp`). Explicit Phase 5 sub-steps for code change, comment updates, and 2 test assertion updates.

7. **Dedicated `CorrectionSource` enum**: `ParsingSource` is parse-context oriented (`.recipeIngredient`, `.groceryListItem`). Corrections need an edit-flow oriented enum (`.editRecipe`, `.createRecipe`, `.groceryListEdit`, `.templateRename`). Reusing `ParsingSource` would conflate two different dimensions.

8. **Schema v3 includes both `parserUsed` and `source`**: Backward-compatible via optional Codable fields.

9. **Phase 7 sub-section reordering**: 7a = schema v3 changes, 7b = edit flow wiring, 7c = corpus gate. The wiring depends on the new `logCorrection()` parameters, so schema changes must come first.

10. **NLP intentionally excluded from moderate-confidence band**: When regex is [0.5, 0.9) and ML is [0.5, 0.8), NLP is not consulted. ML is expected to outperform NLP in this range. Documented as intentional design choice, revisitable during threshold calibration.

### Phase-by-Phase Breakdown (Why Each Phase Exists)

**Phase 0: Feasibility + Contract Lock (2-3h)** — Principal engineering review found that contract ambiguity creates silent quality regressions. Locking contracts here saves 3-5x in debugging time later. Includes the expanded single-parse refactor (5 call sites + 11 telemetry gaps).

**Phase 1: Dataset Preparation (3-4h)** — The ML model needs training data. strangetom (81k) + NYT (180k) provide ~120-150k labeled ingredient sentences — enough to train without waiting for user corrections. Convert SQLite + CSV → unified JSONL with 13→7 label mapping.

**Phase 2: Model Architecture & Training (4-5h)** — Build the BiLSTM-CRF. Right architecture for the job: small (2-5MB), fast (<5ms), proven on this exact domain. Target: ≥96% token, ≥92% sentence accuracy, ≥0.90 F1 per key class.

**Phase 3: CoreML Conversion (2-3h)** — CRF layers can't convert to CoreML, so we split: BiLSTM → `.mlpackage`, CRF params → JSON, Viterbi → Swift. Hard parity gate (≥99.9% token agreement) blocks Phase 4.

**Phase 4: MLIngredientParser Implementation (3-4h)** — Wrap CoreML model in Swift behind the `IngredientParser` protocol. Tokenize → CoreML emissions → Viterbi decode → `ParserResult`. Route ML-produced units through shared canonicalization pipeline.

**Phase 5: HybridIngredientParser Integration (2-3h)** — Slot ML parser into the routing chain (regex ≥0.9 → ML ≥0.8 → NLP if both <0.5). Switch to winner-only attribution. Add background dispatch for bulk operations. The architecture was designed for this since M8.3.

**Phase 6: Test Suite (2-3h)** — Prove the ML parser handles the 6 known failure cases from Section 1. Prove zero regressions on 204 existing tests. Performance validation (<5ms per parse).

**Phase 7: Correction Instrumentation (2-3h)** — `logCorrection()` exists but is never called from production code. Wire it into 4 edit flows. Schema v3 adds `parserUsed` + `CorrectionSource` to correction events. Creates the data foundation for model improvement.

**Phase 8: Continuous Learning Pipeline (2h)** — Connect corrections to the training pipeline. Manual in v1 (developer exports + retrains locally), but the plumbing makes it repeatable.

**Phase 9: Integration Testing & Documentation (1-2h)** — End-to-end validation across 8 integration scenarios. Update all project documentation.

### Research and Planning Approach

The eight-pass review workflow followed a clear pattern of diminishing severity:

| Pass | Agent | Findings | Severity Profile | Character |
|------|-------|----------|-----------------|-----------|
| 1 | Codex | 11 | 5 high, 4 med, 2 low | Architecture gaps |
| 2 | Codex | 6 | 2 high, 3 med, 1 low | Contract/migration gaps |
| 3 | Codex | 5 | 1 high, 3 med, 1 low | Precision gaps in corrections |
| 4 | Internal | 12 | 2 high, 5 med, 5 low | Code cross-reference audit |
| 5 | Codex | 3 | 0 high, 1 med, 2 low | Typing/consistency cleanup |
| 6 | Codex | 2 | 0 high, 1 med, 1 low | Test scope + legacy data |
| 7 | Codex | 3 | 0 high, 1 med, 2 low | Example code + stale estimates |
| 8 | Internal | 3 | 0 high, 3 med, 0 low | ADR sync + orphaned code + roadmap staleness |
| 9 | Codex | 2 | 0 high, 1 med, 1 low | Protocol contract + header arithmetic |
| 10 | Codex+Internal | 3 | 0 high, 1 med, 2 low | Stale rationale + misleading wording + duplicate labels |
| 11 | Internal (PME) | 10 | 1 high, 7 med, 2 low | CoreML platform risks + implementation sketches |

Key observations:
- **Each pass found genuinely new things** — no repeated findings across 11 passes. This validates the multi-pass approach.
- **Severity decreased monotonically** — high-count dropped from 5 → 2 → 1 → 2 → 0 → 0 → 0 → 0 → 0 → 0 then **1 high resurfaced in pass 11** (PME review found CI testing gap). The PRD converged by pass 6 for consistency issues, but a fresh perspective (principal engineer framing) found a new class of issues.
- **The internal review (pass 4) found the highest single-pass count** — 12 findings — because it actually read the source files and cross-referenced claims. The PME review (pass 11) found the second-highest (10 findings) by applying platform-specific engineering expertise.
- **The PME review was the most implementation-enriching pass** — it added concrete code sketches (`runEmissionModel`, warmup strategy, debug logging), platform risk mitigations, and test structure improvements. Previous passes focused on spec correctness; pass 11 focused on implementation readiness.
- **The double-parse expansion was the biggest scope change** — going from 1 call site to 5 + 11 telemetry gaps. This only surfaced by reading the actual code, not the PRD.

### AI Tooling Learnings

**Five-pass review with diminishing severity is the convergence signal — but fresh perspectives reset it.** When high-severity findings drop to zero and remaining findings are typing/consistency level, the document has converged *for that review framing*. Pass 11's principal mobile engineer review found a new high-severity finding (CI testing gap) because it applied a different lens than consistency checking.

**External review + internal code audit + domain expert review are three distinct review types.** Codex reviews the PRD's internal logic and consistency. The internal code audit reads actual source files and verifies claims. The PME review applies platform engineering expertise (CoreML memory, thread safety, bundle lifecycle) that neither of the other types would surface.

**Semantic type design surfaces in late passes.** The `ParsingSource` vs `CorrectionSource` distinction only became visible in pass 5, after the correction system was fully specified. You can't review type design until the use cases are concrete. This argues for iterative review over single-pass review, even for type definitions.

**PRD surgery scales to 60+ edits.** This session made ~80 targeted edits across 11 passes to a 1500-line document. Every edit preserved surrounding context. No full rewrites. The final grep checks confirmed zero stale references across all dimensions checked.

**Implementation sketches in PRDs reduce ambiguity dramatically.** Pass 11 added concrete code for `runEmissionModel`, CoreML warmup, and debug logging. These sketches eliminate the "I'll figure it out during implementation" gap that causes surprises. A 10-line code sample is worth a paragraph of prose.

### What It Means

M8.4 has been hardened through 11 review passes producing 60 findings, all integrated. The PRD grew from ~885 lines to ~1500 lines — the additional content is acceptance criteria, provenance rules, concurrency boundaries, phase sub-steps, implementation sketches, platform risk mitigations, and review documentation. This is spec weight that prevents implementation weight.

Passes 7-8 caught important integration gaps (missing parameter in example code, ADR contradiction, orphaned property). Passes 9-10 caught protocol contract conflicts and stale rationale. Pass 11 (principal mobile engineer review) was qualitatively different — instead of finding consistency issues, it found CoreML platform risks (warmup latency, MLMultiArray type variance, RangeDim CPU fallback, silent model load failure) and added concrete implementation guidance (code sketches, test structure, memory estimates).

The plan is 10 phases across 6 sessions (23-32h). Phase 0 front-loads risk reduction. Phases 1-4 are the core ML pipeline. Phase 5 is integration. Phase 6 is testing. Phases 7-8 are the correction data plumbing. Phase 9 is wrap-up.

Next session: Phase 0 + Phase 1 (contract lock + dataset preparation). Create `feature/M8.4-ml-parsing` branch.

---

## Session 23 — February 21, 2026
**Milestone**: M9.5-partial: Parser Dependency Injection
**Branch**: `feature/M9.5-parser-di`

### What Happened

Executed the M9.5-partial plan from the previous session — the last prerequisite before M8.4 ML-Powered Parsing. The plan was detailed enough that execution was largely mechanical: 6 phases (A–F) across 3 implementation steps plus PRD corrections.

**Step 1–2: PRD Corrections.** Audited both the M9 and M8.4 PRDs before touching code. Found 7 corrections needed: wrong caller reference (foragerApp.swift should be MigrationDebugView.swift), Phase D overestimated (45→15 min), missing Mocks/ directory creation, and — most importantly — the M8.4 PRD hardcoded `MLIngredientParser` as a concrete type where it should use the `IngredientParser` protocol for testability. All fixed before any implementation work.

**Phases A–B: Core DI.** Converted `HybridIngredientParser` from hardcoded sub-parser construction to injectable init parameters (`regexParser: IngredientParser = RegexIngredientParser()`, `nlpParser: IngredientParser = NLPIngredientParser()`, `regexConfidenceThreshold: Float = 0.8`). Same pattern for `IngredientParsingService` — added `parser: IngredientParser = HybridIngredientParser()` parameter. Zero call sites changed. The static `extractCleanIngredientName()` keeps its own `sharedParser` — it's a pure text utility that doesn't need DI.

**Phase C: Mock + Tests.** Created `MockIngredientParser` with call tracking (`parseCalls: [String]`) and preset result injection. Wrote 8 routing tests that exercise the confidence-based routing logic with mock sub-parsers — verifying that high-confidence regex (≥0.8) skips NLP, low-confidence falls back, custom thresholds change the boundary, etc. Also created the `foragerTests/Mocks/` directory with manual pbxproj registration.

**Phase D–E: Verification.** Full test suite: 127 passing (unchanged from before), 8 new routing tests passing, plus 1 new integration test showing mock injection through the full DI chain. 5 pre-existing failures unchanged (4 normalization + 1 migration — these predate M9.5). Phase E added optional DI to `QuantityMigrationService` — backward compatible, not M8.4-blocking.

**Phase F: Build + Docs.** Clean build verified (zero warnings). All 7 core documentation files updated.

### Decisions Made

1. **Protocol-typed stored properties**: `private let regexParser: IngredientParser` (not `RegexIngredientParser`). This is what enables mock injection — you can't pass a `MockIngredientParser` to a stored property typed as `RegexIngredientParser`. The default parameter handles the production case.

2. **Static-to-instance for threshold**: `regexConfidenceThreshold` was `private static let`. Making it an instance property means M8.4 can raise it from 0.8 → 0.9 at construction time rather than editing a source constant. Small change, big flexibility.

3. **Call tracking over protocol spy**: The mock records `parseCalls: [String]` for verification. This enables negative assertions ("NLP should NOT be called when regex is confident") which are the most valuable routing tests. A simple pattern that covers the important cases.

4. **Phase E kept optional**: `QuantityMigrationService` is a legacy M3 migration debug tool. The DI addition is clean code but not M8.4-blocking. Included it since it was 15 minutes of work.

### AI Tooling Learnings

The previous session's deep planning paid off dramatically. The 6-phase plan mapped every file, every line number, every call site — so this session was pure execution with no research. The context window was spent on code, not exploration. This validates the "plan in one session, execute in the next" pattern for milestones that touch many files.

The pbxproj manual registration (creating PBXGroup entries, PBXFileReference, PBXBuildFile, and build phase entries) is still the trickiest part of adding test files. Having the group IDs and build phase IDs cached in MEMORY.md made it reliable.

### What It Means

All three M8.4 prerequisites are complete: zero-warning build (M9.0), centralized parser name extraction (M9.1.2), and injectable parser construction (M9.5-partial). M8.4 can now add the ML parser as a simple `mlParser: IngredientParser? = nil` parameter to `HybridIngredientParser.init()` — no architectural restructuring needed. The routing tests established in M9.5 will serve as a template for M8.4's own routing tests (regex → ML → NLP fallback chain).

Test count: 155 across 8 test files (was 146 across 7).

---

## Session 22 — February 21, 2026
**Milestone**: M9.1.2 wrap-up + M9.5-partial planning
**Branch**: `feature/M9.1.2-centralize-extract-clean-name` (PR pending)

### What Happened

Picked up M9.1.2 from the previous session where the core centralization was done and a merge-comparison normalization fix was committed. The remaining work was cleanup: removed 3 blocks of `#if DEBUG` print statements from `AddIngredientsToListView.swift` that were leftover from debugging the normalization fix. Verified clean build (zero warnings).

The main work this session was a deep architecture analysis for M9.5-partial (Parser Dependency Injection) — the next prerequisite before M8.4 ML parsing. This involved reading every file that touches `IngredientParsingService` (11 instantiation sites), mapping the dependency graph, cross-referencing with the M8.4 PRD's expectations, and identifying conflicts between the two PRDs.

### Decisions Made

1. **M9.5-partial scope**: Only parser DI (HybridIngredientParser + IngredientParsingService injectable constructors, mock parser, routing tests). Full-app DI (views, PersistenceController.shared, ServiceFactory) deferred to M9.5-full. This is the minimum needed for M8.4 — adding more would delay the ML parser without proportional benefit.

2. **Default parameter pattern over DI container**: Swift default parameters (`parser: IngredientParser = HybridIngredientParser()`) give us testability with zero blast radius. All 11 existing call sites compile unchanged. No ServiceFactory, no protocol witnesses, no Environment keys. The "thin DI" pattern is the right tool for a 4-hour task.

3. **Static method stays static**: `extractCleanIngredientName()` keeps its own `sharedParser` rather than converting to an instance method. Converting would require all 7 call sites to hold an IngredientParsingService instance — but those call sites (views) don't always have the Core Data context needed to construct one. The static method is a pure text utility; it doesn't need DI.

4. **M8.4 Phase 5 adjustment identified**: The M8.4 PRD's Phase 5 code hardcodes `MLIngredientParser` in `HybridIngredientParser.init()`. After M9.5-partial, this should instead pass it as an init parameter. Documented in PRD cross-reference so the M8.4 session doesn't re-hardcode.

5. **Threshold injectability**: Making `regexConfidenceThreshold` an init parameter prepares for M8.4 raising it from 0.8 → 0.9. One parameter change at construction time vs editing a private constant.

### AI Tooling Learnings

Used a parallel exploration agent to deep-dive the parser architecture while editing files in the main context. The agent read 20 files, mapped 11 instantiation sites, 6 dependent services, and 5 test files — work that would have been tedious in the main conversation and would have consumed significant context. The resulting report was comprehensive enough to write the full M9.5-partial PRD section without additional research.

Cross-referencing two PRDs (M9 and M8.4) before planning revealed a conflict that would have been a session-wasting surprise during implementation. The M8.4 Phase 5 code sample directly contradicts the DI approach M9.5 is supposed to establish. Catching this during planning — not implementation — is exactly why the "audit PRDs before implementation" rule exists.

### What It Means

M9.1.2 is ready to PR and merge. The M9.5-partial plan is detailed enough to execute mechanically in one session (~4h). The key architectural insight is that Forager's parser architecture was *already designed* for extensibility (M8.3 protocol abstraction, M7.5 service-level init injection) — M9.5-partial just extends that pattern one more level by making the sub-parser constructors injectable. The blast radius is small because Swift default parameters make the change backward-compatible at every call site.

After M9.5-partial, M8.4 becomes a pure feature addition: create the ML parser, pass it as a parameter, update routing. No architectural restructuring needed.

---

## Session 21 — February 21, 2026
**Milestone**: M9.1.2 Centralize `extractCleanIngredientName`
**Branch**: `feature/M9.1.2-centralize-extract-clean-name`

### What Happened

Executed a clean refactoring milestone: two diverging private `extractCleanIngredientName(from:)` implementations in view files (AddIngredientsToListView with 40 lines and 5 call sites, MealPlanDetailView with 18 lines and 1 call site) were replaced by a single `static` method on `IngredientParsingService` that delegates to the `HybridIngredientParser`.

The key insight from the planning phase was that these view-layer functions were manually reimplementing what the parser already does — and doing it worse. The MealPlanDetailView version was notably weaker: no qualifier stripping ("salt to taste" → "Salt To Taste" instead of "Salt"), fewer unit patterns (missing unicode fractions, descriptive amounts). Meanwhile, `HybridIngredientParser.parse()` already handles 7 regex pattern categories + NLP fallback.

The implementation was straightforward: add a `static let sharedParser = HybridIngredientParser()` on `IngredientParsingService`, write a 10-line static method that delegates to it, update 6 call sites across two views, delete ~58 lines of hand-rolled regex. Added 12 unit tests covering standard measurements, fractions, unicode, count units, parentheticals, qualifiers, edge cases. All pass.

### Decisions Made

1. **Static method over instance method**: The call sites in views don't hold an `IngredientParsingService` instance (it requires Core Data context). A `static` method avoids requiring DI injection for what's a pure text-to-text utility.

2. **Shared parser as `static let`**: Swift guarantees `static let` is initialized lazily and atomically. `HybridIngredientParser` holds only `let` properties and `parse()` creates no shared mutable state — thread-safe by construction.

3. **Capitalized fallback for empty names**: If the parser returns an empty name (very short unrecognizable input), we fall back to `trimmed.capitalized` rather than empty string. This preserves the convention all call sites expect.

4. **No qualifier stripping concern**: The old AddIngredientsToListView stripped 13 qualifier words inline (large, fresh, chopped, etc.). The parser doesn't strip leading adjectives, but `findOrCreateTemplate(name:)` runs `normalize()` Phase 4 which handles these. The stripping still happens, just in the right layer.

### AI Tooling Learnings

The planning phase (done in a prior session) was thorough — line numbers, call site inventory, thread safety verification, behavioral change analysis. This made implementation mechanical: follow the plan, verify each step. Total implementation time was well under the 1.5h estimate. The plan's explicit note about `normalize()` handling qualifier stripping prevented me from trying to add that logic to the new static method.

### What It Means

This is the kind of cleanup that prevents silent divergence: two implementations that started the same but drifted apart over time, producing different results for the same input. The MealPlanDetailView bulk-add was creating junk templates that would accumulate in the database. Now all name extraction goes through one path, and any future parser improvements (M8.4 ML parser) automatically propagate to all call sites.

---

## Session 20 — February 21, 2026
**Milestone**: M9.0.1 Recipe Picker Scalability Fix — IN PROGRESS
**Branch**: `feature/M9.0.1-recipe-picker-fix`

### What Happened

Started with manual testing after M9.0 and spotted the first real UX regression from M15: the recipe picker on the meal plan detail view was a tiny `Menu` popover capped at 20 recipes with no search. This worked fine with 2 test recipes but would be unusable with a real recipe collection. Created M9.0.1 as a bug fix milestone.

First attempt went wrong. I wired up the existing `RecipePickerSheet` (built in M4.2, never connected after M15) as a modal sheet — tap "Choose Recipe" → full sheet slides up with search. Technically correct but missed the user's actual intent: they wanted an **inline text box directly in the day card** where you type and results appear below, no modal at all. The pre-M15 design had exactly this pattern and M15 lost it.

Second attempt got it right: each unplanned day card now has a TextField with magnifying glass icon and "Search recipes…" placeholder. As you type, up to 5 matching recipes appear directly below with name, ingredient count, and servings. Tap a result to add it — search clears, keyboard dismisses, day card shows the recipe. Quick-select pills (Eating Out, Leftovers, etc.) remain below the search field. The Swap flow on already-planned days still uses RecipePickerSheet as a modal since there's no search field visible on planned cards.

Also did a documentation cleanup pass — ChatGPT Codex had flagged stale content across README.md, roadmap.md, and project-index.md (M7 still showing "IN PROGRESS", M15 still "ACTIVE", unchecked success criteria, stale PRD paths). All three files updated and committed.

### Decisions Made

1. **Inline search over modal sheet**: The user was very clear — "I wanted a text box inline in the day" not "a popup for the user to interact with." This is the right call for a quick-access pattern: choosing a recipe for a day should be as fast as typing 2-3 characters and tapping a result. A modal adds two extra taps (open sheet, close sheet) for something that should be friction-free.

2. **`@FocusState<Date?>` for multi-field tracking**: With 7 day cards potentially visible, each with its own TextField, I needed to track which field is active. Using `@FocusState private var focusedSearchDate: Date?` with `.focused($focusedSearchDate, equals: date)` was the clean solution — SwiftUI handles the mutual exclusion automatically. No manual state synchronization needed.

3. **Keep RecipePickerSheet for Swap**: The swap flow is fundamentally different — you're on an already-planned day card that shows the recipe, not a search field. A modal sheet makes sense here because you're explicitly choosing to change something, not doing the initial quick-add.

4. **Default servings on inline add**: The inline picker adds recipes with their default serving count. No per-recipe servings adjuster inline — that would bloat the card. The full RecipePickerSheet (used for swap) still has the servings adjuster for when you want precision.

### AI Tooling Learnings

This session had a clear "wrong first attempt" that illustrates a persistent failure mode: **Claude defaults to the technically clean solution (reuse existing component) over the UX-correct solution (match the user's mental model)**. The RecipePickerSheet was *right there*, already built, with full search and servings adjustment. Wiring it up was elegant engineering. But it wasn't what the user wanted — they wanted something simpler and more integrated.

The correction took one message from the user and about 15 minutes to implement. The lesson: when the user describes an interaction ("type in the inline box"), implement that interaction literally. Don't optimize for code reuse at the expense of the described UX.

Also: ChatGPT Codex's doc review was genuinely useful. It caught 4 real staleness issues that I should have caught during M15/M9.0 milestone completion. The "update all core docs after milestone" rule works, but the update quality depends on actually checking cross-references, not just updating the most obvious sections.

### Where This Leaves The Project

M9.0.1 is on a feature branch with 4 commits, build succeeds, ready for manual testing. The inline search needs real-device testing to verify:
- TextField focus behavior across multiple visible day cards
- Keyboard interaction (dismiss on selection, auto-focus on tap)
- Search result layout when cards have varying content heights
- Performance with 50+ recipes in the filter

---

## Session 19 — February 21, 2026
**Milestone**: M9.0 Warning Resolution → COMPLETE
**Branches**: `chore/prd-folder-cleanup` → merged (PR #40), `feature/M9.0-warning-resolution` → open (PR #41)

### What Happened

Two cleanup tasks today, both foundational work before the M9 technical debt milestones begin in earnest.

**PRD Folder Cleanup** came first — the `prds/` directory had accumulated clutter. M7.5 and M15 PRDs were still sitting in `active/` or the root despite both milestones being complete. Moved 15 files total: completed M15 and M7.5 docs into `complete/` (with M15's 8 implementation plans in a new `complete/plans/` subfolder), and upcoming M9/M6/M7.x docs into `active/`. The tricky part was updating 19 stale cross-references across 10 documentation files — every file that linked to a PRD path needed fixing. This is the kind of work that's easy to get 90% right and have the last 10% haunt you for weeks.

**M9.0 Warning Resolution** was the main event: take the codebase from 18 compiler warnings to zero. The M9 PRD had a Phase 0 section with a warning list, but it was written before M15 shipped — meaning it was stale. Did a fresh `xcodebuild clean build`, compared actual warnings to the PRD's list, and rewrote Phase 0 with the real data. This PRD audit step added maybe 10 minutes but saved confusion later.

The most interesting fix was the CloudKit `discoverUserIdentity` deprecation. Apple deprecated it in iOS 17 with *no replacement*. The API was already broken in practice — `nameComponents` returned nil for the current user since iOS 16. Our code had a 57-line continuation-based wrapper around this dead API, with fallback paths that were actually the only paths that ever executed. Replacing all of that with a 2-line `container.userRecordID()` call was a satisfying deletion.

The remaining 16 warnings were mechanical: unused variables, unnecessary `await` on same-actor calls, non-exhaustive switches, and a redundant type cast. The batch took about 30 minutes.

### Decisions Made

1. **PRD folder cleanup first, M9.0 code second**: The user made this call, and it was right. Doing the folder moves on main before branching for M9.0 meant the M9.0 branch started with a clean directory structure. Otherwise we'd have had conflicting path changes to resolve.

2. **Update M9 PRD before implementing**: Another user directive. Rather than treating the stale PRD as a rough guide and just fixing whatever warnings the build showed, we updated Phase 0 to be the actual source of truth. Future sessions that reference M9.0 will find accurate data.

3. **Remove deprecated APIs, don't replace them**: For `discoverUserIdentity`, there's no modern equivalent. The app already collected display names during household creation (user types their name), and the deprecated API was just a pre-fill that never worked. Clean deletion was the right call.

### AI Tooling Learnings

This session had a useful process correction. I started reading source files to begin M9.0 code changes immediately, and the user redirected me twice: first to update the PRD, then to do the folder cleanup as a separate branch. Both redirections improved the outcome.

The pattern: **Claude defaults to "go build" mode when given a plan, but the user often sees sequencing improvements that aren't in the plan.** The plan said "Part 1: warnings, Part 2: cleanup" — the user flipped the order and added a PRD-update step. This is where the human-AI collaboration works best: AI handles the execution depth, human handles the strategic sequencing.

Also notable: the insights logging rule in CLAUDE.md works as intended. I added 3 insights during the session and the user still had to remind me about the development journal. The system of rules enforces consistency, but only for the rules that actually exist. Need to make sure the journal habit is as ingrained as the insights one.

### Where This Leaves The Project

M9.0 is the first of three M9-prereqs milestones:
- **M9.0**: Warning resolution ✅ (this session)
- **M9.1.2**: Centralize `extractCleanIngredientName` (next)
- **M9.5-partial**: Parser dependency injection

After those three, the codebase is ready for M8.4's ML parser integration — the big feature milestone. The zero-warning baseline matters because M8.4 will introduce CoreML and new model files; we need to be able to spot *new* warnings immediately rather than hunting through a pile of pre-existing noise.

---

## Session 18 — February 20, 2026
**Milestone**: M7.5 Architecture Hardening → COMPLETE
**Branch**: `feature/M7.5-service-ownership` → merged to main

### What Happened

Wrapped up M7.5 today. This was the "make the architecture match the vision" milestone — after M15's massive visual rewrite touched nearly every view in the app, M7.5 went through and enforced the service layer pattern everywhere. Three phases: move all Core Data saves into services, convert complex views to enum-based navigation routing, and add tests + polish.

The interesting story isn't the work itself — it's how fast it went.

### The Reordering Decision That Paid Off

The original roadmap had M7.5 (architecture hardening) happening *before* M15 (UX design system). The logic was: clean up the architecture first, then build the new UI on a solid foundation.

I flipped that order. M15 went first because:
1. The app needed to look and feel right for TestFlight testers — architecture debt is invisible to users
2. The visual refresh would rewrite most views anyway, so cleaning up architecture *before* a rewrite was wasted effort
3. Building the design system (mockups → PRD → implementation) would naturally simplify the code as views got rewritten from scratch

The PRD estimated M7.5 at 14-19 hours. Actual: ~5 hours. The reason is exactly what I hoped — M15's rewrite had already eliminated most of the direct `context.save()` calls and simplified navigation patterns. By the time M7.5 started, the "35 direct saves eliminated from 13 views" was mostly just moving existing clean code into service methods, not refactoring spaghetti.

**Lesson**: When two milestones have a dependency that goes both ways, sequence the one that *reduces scope* of the other. M15 reduced M7.5's scope dramatically. The reverse wouldn't have been true.

### AI Tooling: The Documentation Workflow

This session highlighted something I've been refining over the past few weeks: using Claude Code for documentation management at milestone boundaries. The workflow:

1. Complete the code work on a feature branch
2. Ask Claude to update all 7 core docs simultaneously (current-story, next-prompt, roadmap, requirements, project-index, insights-log, development-journal)
3. Claude reads all 5, understands the cross-references, and updates them consistently
4. Commit the doc update, create the PR, merge

This works *much* better than updating docs manually because the 5 files reference each other heavily. Changing a milestone status in one file without updating the others creates contradictions that confuse future sessions. Having Claude do all 5 at once keeps them synchronized.

The catch: Claude caught me not logging an insight I'd shared verbally. The CLAUDE.md rule says "whenever you share a technical insight, log it to insights-log.md" — and I'd set that rule specifically to prevent insights from evaporating between sessions. The system works, but only if I let it enforce the rules consistently.

### Where This Leaves The Project

M7.5 merged. Main is clean. The execution order going forward:

- **M9-prereqs** (9h) — Warning resolution, centralize `extractCleanIngredientName`, parser dependency injection. These are cleanup tasks that make the codebase ready for the ML parser.
- **M8.4** (18-24h) — The big one: ML-powered ingredient parsing using BiLSTM-CRF trained on 260k open-source sentences.
- **M7.7** (3-5h) — App Store submission, timed after ML parser is in for best first impression.

The app has been on TestFlight since December with real users. The next visible improvement they'll see is M8.4's parsing accuracy jump — going from regex+NLP (~95%) to ML (~98%+). Everything between now and then is foundation work.

---

## Project Arc — The Story So Far

*A retrospective summary covering August 2025 through February 2026, ~220 hours of development.*

### The Beginning: Learning iOS by Building (Aug-Oct 2025, M1-M3.5)

Forager started as a learning project — build a real iOS app to learn Swift, SwiftUI, and Core Data. The first milestone (M1, grocery list management) took 32 hours and covered the fundamentals: Core Data entities, SwiftUI views, drag-and-drop, the whole iOS development stack from zero.

What made it unusual from the start was the decision to use Claude Code as a development partner rather than just a code generator. Every session started with reading project documentation. Every milestone had a structured plan. Every commit followed a naming convention. This discipline paid compound interest as the project grew — by M7, the documentation was rich enough that Claude could understand the full architecture and make informed suggestions rather than guessing.

### The Structured Quantity Breakthrough (Oct 2025, M3)

M3 was where the app's data model got serious. Instead of storing "2 cups flour" as a string, the system parsed it into structured fields (numericValue: 2.0, standardUnit: "cup", name: "flour"). This enabled recipe scaling, quantity consolidation (two recipes calling for butter → one grocery item with combined amount), and unit conversion.

The parsing pipeline that emerged here — regex fast path for common patterns, NLP fallback for edge cases — became the foundation for everything that followed. M8's hybrid parser architecture, M8.4's planned ML parser, and the template normalization system all build on the structured quantity model.

### CloudKit: The Hardest Technical Challenge (Dec 2025-Jan 2026, M7)

M7 was humbling. CloudKit sync and household sharing took ~55 hours across multiple sub-milestones. The key moments:

- **The Architecture Pivot (M7.1.3)**: Started with a shared zone approach, discovered it wouldn't work for the use case, pivoted to attach-then-share with dual persistent stores. This was a "read the PRD first" learning moment — the original plan had assumptions that didn't hold.
- **Public Link Sharing (M7.2.2)**: iOS 18's `UICloudSharingController` was broken (radar filed). Built a custom public-link sharing flow as a workaround. This became ADR 009.
- **The Schema Deploy Incident (M7.6.8)**: Deployed to CloudKit Production without first creating a CKShare in Development. The `cloudkit.share` record type was missing from Production, breaking all sharing. Lesson: CloudKit schema is append-only and lazy — you must exercise every code path in Development before deploying.

CloudKit taught me that platform integration work has an irreducible complexity that no amount of planning eliminates. You have to build, hit the walls, and adapt.

### The Design System Bet (Feb 2026, M15)

M15 was the largest single milestone (~50-65 hours). The approach was unconventional: design the entire app's visual language in HTML/CSS mockups first, then implement in SwiftUI.

**Why HTML mockups?** Because iterating on visual design in SwiftUI is slow — you're fighting the compiler, simulators, and preview rendering. HTML in a browser is instant. The `frontend-design` Claude Code plugin provided structured design critique that caught issues like font size proliferation, insufficient contrast ratios, and inconsistent component patterns before any Swift was written.

This produced 16 phone-frame mockups covering every screen and state (empty states, search, edit mode, loading/error, celebrations, swipe actions). The mockups became the specification — the PRD references them by section number, and a Swift file → mockup mapping table tells developers exactly which mockup to implement.

The gamble was that the time spent on mockups would be recovered during implementation. It was — M15's SwiftUI implementation went smoothly because every design decision was already made. And as noted above, it also reduced M7.5's scope by ~10 hours.

### How AI Tooling Evolved

The relationship with Claude Code changed significantly over 6 months:

**Early (M1-M3)**: Used Claude primarily for code generation — "write a SwiftUI view that does X." The documentation discipline was basic: learning notes after each milestone.

**Middle (M4-M7)**: Started using Claude for architectural reasoning — "here are two approaches to CloudKit sync, which has better trade-offs?" The session startup checklist emerged here, after a session where Claude created a duplicate service because it hadn't read the existing codebase first.

**Current (M8-M15)**: Claude is now a full development partner. The mandatory 4-document startup sequence, the 5-core-doc update rule, the insights log, the PRD audit before implementation — these are all systems that emerged from specific failures and were codified in CLAUDE.md. The CLAUDE.md file itself is a living document that encodes the project's accumulated wisdom about how to work effectively.

**Key meta-insight**: The value of AI tooling compounds with project documentation quality. A well-documented project gets dramatically better AI assistance because the context is richer and more accurate. The investment in documentation isn't just for human readers — it's infrastructure for AI collaboration.

---

*This journal is maintained during every development session. New entries are added at the top.*
