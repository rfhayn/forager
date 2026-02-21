# Next Implementation Prompt

**Last Updated**: February 21, 2026
**For Milestone**: M8.4 ML-Powered Parsing (18-24h across 4 sessions)
**Status**: M9.5-partial ✅ **COMPLETE** | M8.4 📋 **NEXT** | All prerequisites done
**Branch**: `main` → create `feature/M8.4-ml-parsing` when starting

---

## **NEXT: M8.4 ML-Powered Parsing**

**PRD**: `docs/prds/active/m8.4-ml-powered-parsing.md` (updated Feb 21 with research findings)

### Key Architecture Decision (from research)
- **CRF cannot convert to CoreML** — split into 3 components:
  1. BiLSTM emission scorer → CoreML `.mlpackage`
  2. CRF transition matrix → `transitions.json` (7×7 float array)
  3. Viterbi decoder → Pure Swift (~30 lines)
- **strangetom dataset is SQLite** (not CSV) — 81k rows, 12 token-level labels → map to 7 Forager labels
- **strangetom includes NYT data** — dedup required, expect ~120-150k unique sentences

### Session 4: Phases 1+2 — Dataset Prep + Model Training (4h)
```
Branch: feature/M8.4-ml-parsing
```
1. Set up `tools/ml-training/` directory structure
2. Download strangetom SQLite + NYT CSV
3. Write `prepare_dataset.py`:
   - Load strangetom SQLite table `en` (columns: id, source, sentence, tokens, labels)
   - Decode fraction notation (`1#1$2` = 1.5, `3$4` = 0.75)
   - Map 12 strangetom labels → 7 Forager labels (QTY/UNIT/NAME/MODIFIER/PREP/COMMENT/OTHER)
   - Dedup NYT overlap (strangetom source="nyt")
   - 80/10/10 split → JSONL output
4. Write `train_model.py`: BiLSTM-CRF, export checkpoint + transitions.json + vocabulary.json
5. Train and evaluate

### Session 5: Phases 3+4 — CoreML Export + Swift Implementation (4h)
- Extract BiLSTM emission scorer → `.mlpackage` via coremltools
- Export transition matrix as JSON
- Implement `ViterbiDecoder.swift` (~30 lines)
- Implement `MLIngredientParser.swift` (CoreML emissions → Viterbi → ParserResult)
- Cross-validate tokenizer (Python ↔ Swift must match exactly)

### Session 6: Phases 5+6 — Integration + Test Suite (4h)
- Add `mlParser: IngredientParser?` to HybridIngredientParser init (slot prepared by M9.5-partial)
- Update routing: regex ≥0.9 → ML ≥0.8 → NLP fallback
- 20+ test cases covering known failures, regression, routing, performance

### Session 7: Phases 7+8 — Continuous Learning + Documentation (3h)
- BIO export method on ParsingTelemetryService
- Retraining script
- Integration testing (8 end-to-end scenarios)
- Core doc updates

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
**M8.4 PRD**: Updated Feb 21 with concrete dataset schemas, split CRF architecture, and label mapping
