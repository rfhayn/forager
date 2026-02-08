# Next Implementation Prompt

**Last Updated**: February 8, 2026
**For Milestone**: M7.6 - External TestFlight
**Status**: READY TO START
**Prerequisite**: Merge M8.3 PR to main first
**PRD**: TBD

---

## **M7.6: EXTERNAL TESTFLIGHT**

### **Goal**
Prepare and submit the app for External TestFlight testing. This involves App Store Connect configuration, build submission, and beta review.

### **Prerequisites**
- M8.3 merged to main ✅
- All parsing improvements integrated
- Clean build with no errors

### **Key Files for Context**

```
Services/Parsing/                    # M8.3 hybrid parser architecture
Services/IngredientParsingService.swift  # Public API (unchanged from M8.3)
Services/ParsingTelemetryService.swift   # Telemetry with parserUsed field
```

### **Pre-Launch Roadmap**

| Task | Status | Est. Hours |
|------|--------|------------|
| M8.1: Parsing Resilience & Telemetry | ✅ COMPLETE | ~3h |
| M8.3: Hybrid NLP Parser | ✅ COMPLETE | ~11h |
| **M7.6: External TestFlight** | 🚀 NEXT | 2-3h |
| M7.7: App Store Submission | 📋 PLANNED | 2-3h |

---

**Version**: February 8, 2026 - M7.6 Ready
**Dependencies**: M8.3 complete, all parsing improvements integrated
