# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M8.4 ML-Powered Parsing (23-32h across 6 sessions)
**Status**: M9.5-partial ✅ **COMPLETE** | M8.4 📋 **NEXT** | All prerequisites done
**Branch**: `main` → create `feature/M8.4-ml-parsing` when starting

---

## **NEXT: M8.4 ML-Powered Parsing**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (execution-ready — 12 review passes, 60 findings + priority validation)

### Key Architecture Decisions (from research + 11 review passes)
- **CRF cannot convert to CoreML** — split into 3 components:
  1. BiLSTM emission scorer → CoreML `.mlpackage`
  2. CRF parameters → `crf_params.json` (7×7 transition matrix + 1×7 start transitions + 1×7 end transitions)
  3. Viterbi decoder → Pure Swift (~40 lines)
- **strangetom dataset is SQLite** — 81k rows, **13** token-level labels → mapped to 7 Forager labels
- **Winner-only parser attribution** — `parserUsed` reports `regex`/`ml`/`nlp`, never `"hybrid"`. HybridIngredientParser is a router, not a parser.
- **Parsers stay synchronous** — background dispatch owned by service/callsite layers, not parsers
- **CorrectionSource enum** (edit-flow oriented) — `.editRecipe`, `.createRecipe`, `.groceryListEdit`, `.templateRename` — distinct from ParsingSource (parse-context oriented)
- **Unlinked corrections for v1** — no `parseEventId` persistence; correction linkage deferred to v2 with Option A/B
- **Provenance rules** — only CreateRecipeView corrections are attributable (parserUsed in memory); other flows are unattributable
- **Denominator guardrails** — per-parser correction rates shown only when N ≥ 20 attributable corrections

### Session 4: Phase 0+1 — Contract Lock + Dataset Prep (5-7h)
```
Branch: feature/M8.4-ml-parsing
```
**Phase 0 (Feasibility + Contract Lock)**:
1. Lock architecture: word-only v1 (no char features)
2. Write `TOKENIZER_SPEC.md` + 100-sentence test vectors
3. Single-parse refactor: 5 double-parse call sites + 11 zero-telemetry `parseIngredient()` callers (see PRD Phase 0c tables)
4. Write model card template + license attribution docs
5. Document Viterbi parity gate criteria

**Phase 1 (Dataset Preparation)**:
6. Set up `tools/ml-training/` directory structure
7. Download strangetom SQLite
8. Write `prepare_dataset.py`:
   - Load strangetom SQLite table `en` (columns: id, source, sentence, tokens, labels)
   - Decode fraction notation (`1#1$2` = 1.5, `3$4` = 0.75)
   - Map 13 strangetom labels → 7 Forager labels (QTY/UNIT/NAME/MODIFIER/PREP/COMMENT/OTHER)
   - 80/10/10 split → JSONL output
9. Validate dataset (spot-check, statistics, split integrity)

### Session 5: Phase 2 — Model Training (4-5h)
- Write `train_model.py`: word-only BiLSTM-CRF, training loop
- Train and evaluate (token/sentence accuracy, per-class F1 for QTY/UNIT/NAME)
- Export checkpoint + CRF params (7×7 transitions + 1×7 start + 1×7 end) + vocabulary
- Fill in model card with training metadata

### Session 6: Phases 3+4 — CoreML Export + Swift Implementation (5-7h)
- Extract BiLSTM emission scorer → `.mlpackage` via coremltools (word-only, single input)
- Export ALL CRF parameters (transitions + start_transitions + end_transitions)
- **Viterbi parity gate**: single unambiguous metric + denominator + threshold (see PRD)
- Implement `ViterbiDecoder.swift` (~40 lines, with start/end transitions)
- Implement `MLIngredientParser.swift` (CoreML emissions → Viterbi → unit canonicalization → ParserResult)
- Cross-validate tokenizer against Phase 0b test vectors

### Session 7: Phases 5+6 — Integration + Test Suite (4-6h)
- Add `mlParser: IngredientParser?` to HybridIngredientParser init (slot prepared by M9.5-partial)
- Update routing: regex ≥0.9 → ML ≥0.8 → NLP fallback
- **Winner-only attribution**: update 3 `"hybrid"` assertions across 2 test files (HybridParserRoutingTests lines 100, 124 + HybridIngredientParserTests line 45)
- Static `sharedParser` lazy CoreML loading — lazy atomic init, <5MB memory
- Background dispatch for bulk operations (≥5 ingredients) at service/callsite level
- Offline threshold calibration pass
- 20+ test cases covering known failures, regression, routing, performance

### Session 8: Phases 7+8 — Corrections + Continuous Learning (4-5h)
- **Phase 7a**: Telemetry schema v3 — add `parserUsed: String?` + `source: CorrectionSource?` to `ParsingCorrectionEvent` (backward-compatible optional Codable fields)
- **Phase 7b**: Wire `logCorrection()` into edit flows with `CorrectionSource` enum + provenance rules
- **Phase 7c**: Corpus gate (≥50 corrections, unlinked OK)
- **Phase 8**: BIO export method on ParsingTelemetryService + retraining script
- Handle legacy `"hybrid"` telemetry values in historical reports

### Session 9: Phase 9 — Integration Testing + Documentation (1-2h)
- Integration testing (8 end-to-end scenarios)
- Core doc updates (all 7 core files)

---

## **AFTER M8.4: M7.7 → M6 → M9 → M10+**

### M7.7: App Store Submission (3-5h)
- Beta landing page, README update, App Store listing, submission
- **PRD**: `docs/prds/active/m7.7-app-store-submission.md`

### M6: Testing Foundation (20-30h)
- 50%+ test coverage on critical services
- Known test infrastructure issues documented in M6 PRD (Issues 1-4)
- **PRD**: `docs/prds/active/milestone-6-testing-foundation-ai-augmentation.md`

### M9 Remaining (~120h)
- **PRD**: `docs/prds/active/m9-technical-debt-codebase-optimization.md`

---

**Dependencies**: M9.0 ✅, M9.1.2 ✅, M9.5-partial ✅, M7.5 ✅, TestFlight live (build 10, v1.1)
**M8.4 PRD**: Execution-ready after 12 review passes (60 findings + priority validation, zero high-severity by pass 6). Split CRF architecture, 13-label dataset, winner-only attribution, CorrectionSource enum, provenance rules, denominator guardrails, CoreML platform risks, warmup strategy, 3-file test structure. Pass 12 validated Must Do vs Nice To Have priority tiers — all critical items already hard-gated.
