# M6: Testing Foundation & AI Augmentation - PRD

**Project**: Grocery & Recipe Manager iOS App
**Milestone**: M6
**Status**: 🚀 READY (Deferred after M7)
**Version**: 2.1
**Created**: November 26, 2025
**Updated**: January 13, 2026 (Execution order clarified)
**Dependencies**: M7 complete (CloudKit sync, household sharing, external beta)
**Execution Plan**: M7 → M6 → M8 → M9

---

## ⏸️ Execution Order Change

> **Note**: Originally planned after M5, M6 was strategically deferred to execute after M7 completes.
>
> **Why?** This sequencing provides:
> - ✅ External beta proves app stable before investing in testing infrastructure
> - ✅ Test coverage in place BEFORE M8 parsing improvements (13-16h) and M9 refactoring (135-173h)
> - ✅ AI test reviewer learns patterns from M8 implementation
> - ✅ CI/CD established before external users depend on stability
>
> **Original Plan**: M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9
> **Revised Plan**: M1 → M2 → M3 → M4 → M5 → M7 → **M6** → M8 → M9
>
> The content below remains unchanged - this is the complete PRD ready to execute after M7.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Strategic Context](#strategic-context)
3. [User Personas](#user-personas)
4. [Goals & Success Criteria](#goals--success-criteria)
5. [Phase Breakdown](#phase-breakdown)
6. [Technical Requirements](#technical-requirements)
7. [Risks & Mitigations](#risks--mitigations)
8. [Timeline & Estimation](#timeline--estimation)
9. [Integration Points](#integration-points)
10. [Future Vision](#future-vision)
11. [Appendix](#appendix)

---

## Executive Summary

### What is M6?

M6 establishes a **dual-track testing foundation** that combines traditional manual test writing with AI-augmented test review. This milestone delivers both immediate value (working test coverage for critical app functionality) and strategic value (operational AI test reviewer that evolves alongside the codebase).

### Why This Approach?

Traditional testing approaches either:
- **All Manual**: Sustainable short-term but doesn't scale with complexity
- **All Automated**: Requires massive upfront investment with delayed ROI

M6 takes a **pragmatic hybrid approach**:
1. Write essential baseline tests manually (M6.1)
2. Activate AI test reviewer to augment future development (M6.2)
3. Establish standards that enable AI to learn patterns (M6.3)
4. Create foundation for autonomous testing evolution (Future)

### Key Outcomes

By the end of M6, you will have:
- ✅ 50%+ test coverage on critical services
- ✅ AI test reviewer operational on every PR
- ✅ Testing standards documented for consistency
- ✅ Foundation for gap detection and test generation
- ✅ CI/CD pipeline with automated test execution

---

## Strategic Context

### The Testing Challenge

After M1-M5, the app has:
- **8 Core Data entities** with complex relationships
- **6+ service classes** with business logic
- **15+ ViewModels** with state management
- **20+ user flows** spanning multiple screens
- **CloudKit sync** adding distributed system complexity

**Without automated testing:**
- Every feature change risks regression
- Refactoring becomes dangerous
- CloudKit conflicts are hard to validate
- Performance regressions go unnoticed

### The AI Opportunity

You've already built the foundation in `Tools/AITestReview`:
- Swift CLI that analyzes diffs
- OpenAI integration for test suggestions
- Structured prompt with domain context
- Safety kill switch (ENABLE_AI_TEST_REVIEW)

**M6 makes this operational** and establishes patterns for it to learn from.

### Connection to Long-Term Vision

This milestone implements **Phase 1-2** of the [Agentic Test Strategy PRD](milestone-6-agentic-test-strategy.md):

**✅ Phase 1**: Human-Written Test Baseline (M6.1)  
**✅ Phase 2**: Advisory AI Test Reviewer (M6.2)  
**🔄 Phase 3**: Semantic Coverage Gap Detector (Future M6.5)  
**⏳ Phase 4**: Test Skeleton Generator (Future milestone)  
**⏳ Phase 5**: Agentic Test Author (Long-term vision)

---

## User Personas

### Primary: Core App Developer (Rich, Claude)
- **Wants fast feedback** about missing tests during development
- **Wants domain-aware insights** specific to staples, recipes, grocery lists, meal planning, CloudKit sync, and usage tracking
- **Wants actionable test cases** in Given/When/Then format that can be implemented immediately
- **Wants consistent review quality** across all PRs without noise or irrelevant suggestions
- **Values AI augmentation** that enhances (not replaces) human judgment and domain expertise

### Secondary: Future Contributors
- **Needs clarity** on expected test structure and project-specific patterns
- **Benefits from automated review** to maintain quality standards without deep domain knowledge
- **Learns testing conventions** quickly from AI suggestions and documented patterns
- **Understands project architecture** through comprehensive test coverage as living documentation

---

## Goals & Success Criteria

### Primary Goals

1. **Establish Baseline Coverage**
   - Core Data entities validated
   - Service layer tested
   - Critical workflows protected

2. **Activate AI Test Review**
   - Operational on every PR
   - Generates useful suggestions
   - Integrated into developer workflow

3. **Create Testing Standards**
   - Documented patterns
   - Repeatable structure
   - Foundation for AI learning

### Success Criteria

#### M6.1: Human Test Baseline
- [ ] 50%+ code coverage on service layer
- [ ] All Core Data entities have basic tests
- [ ] 5+ critical workflows have happy path tests
- [ ] Zero flaky tests
- [ ] Test suite runs in < 30 seconds
- [ ] No test pollution (tests don't affect each other)

#### M6.2: AI Test Review Setup
- [ ] **AI reviewer runs automatically on every PR**
- [ ] **≥ 90% of PRs receive AI test suggestions** (predictable activation)
- [ ] **≥ 75% of suggestions found useful by developers** (quality threshold)
- [ ] Suggestions posted as PR comments within 2 minutes
- [ ] Developers can run locally with single command
- [ ] Kill switch documented and tested
- [ ] Clear workflow for reviewing AI suggestions

#### M6.3: Testing Standards
- [ ] Testing standards document created
- [ ] Coverage tracking automated in Xcode
- [ ] Tests run in CI on every commit
- [ ] Test naming conventions established
- [ ] Mock/stub strategy documented
- [ ] Test data factories created

### Non-Goals (Explicitly Out of Scope)

- ❌ 80%+ code coverage (too ambitious for M6)
- ❌ UI testing (deferred to future milestone)
- ❌ Performance testing framework
- ❌ AI-generated test code (Phase 3+)
- ❌ Mutation testing
- ❌ Load testing for CloudKit

---

