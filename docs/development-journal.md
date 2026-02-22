# Forager Development Journal

**Purpose**: A narrative chronicle of building Forager — capturing decisions, learning moments, AI tooling evolution, and the story behind the code. Unlike the technical insights log (quick-reference table) or learning notes (milestone summaries), this journal tells the *why* behind the *what*.

**Format**: Session-level entries in reverse chronological order. Each entry captures what happened, what decisions were made and why, what was learned about the tools and process, and what it means for the project's direction.

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
