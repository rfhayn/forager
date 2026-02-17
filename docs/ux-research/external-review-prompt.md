# External Review Prompt for M15 Implementation Plans

Use this prompt when submitting the document bundle to ChatGPT, Gemini, or another LLM for review.

---

## Prompt

You are reviewing a detailed, 8-phase implementation plan for M15 — a comprehensive UX overhaul of an iOS grocery/recipe/meal planning app called Forager. The app is built in Swift/SwiftUI with Core Data and CloudKit sync. The target platform is iOS 26 (Liquid Glass design language).

I'm sharing the following documents for review:

1. **PRD** (`m15-ux-design-system.md`) — The product requirements document specifying colors, typography, spacing, components, and per-screen layouts.
2. **8 Implementation Plans** (`m15.1` through `m15.7`, including `m15.5b`) — Sequential, cumulative plans with code snippets, dependency graphs, risk analysis, time estimates, and testing checklists.
3. **CLAUDE.md** — The project's architecture guide covering Core Data dual-store setup, service layer patterns, naming conventions, and git workflow.
4. **Roadmap** — Where M15 fits in the broader project trajectory.
5. **ADR 011** — Architecture decision record for the tab reduction (6→5 tabs).

### What I Need From You

Please review these documents critically across the following dimensions. Be specific — cite plan IDs (M15.X), sub-phase letters, and code snippets where applicable.

#### 1. Architectural Consistency
- Do the plans follow the architecture patterns described in CLAUDE.md? (Service layer writes, repository reads, @FetchRequest for live data, etc.)
- Are there any places where plans violate the established patterns?
- Do the phase dependencies make sense? Could any phases be parallelized or reordered?

#### 2. API & Code Accuracy
- Do the Swift/SwiftUI code snippets use correct API signatures? (We've already fixed several issues — look for any remaining ones)
- Are iOS 26 APIs referenced correctly? (`.glassEffect()`, `Tab(role: .search)`, `.tabBarMinimizeBehavior()`, `ContentUnavailableView`, etc.)
- Are Core Data entity properties referenced correctly? (Check against the entity descriptions in CLAUDE.md)

#### 3. Completeness & Gaps
- Does the PRD specify anything that NO plan covers? (We already identified and addressed the Settings/Categories/Household gap as M15.5b — are there others?)
- Are there user flows that would break during intermediate phases? (e.g., between M15.3 and M15.4, can the user still navigate the full app?)
- Are any files modified by multiple phases in conflicting ways?

#### 4. Risk Assessment
- Are the risk tables realistic? Any underestimated or missing risks?
- The plans propose a `List` + `.listRowBackground()` pattern instead of `ScrollView` to preserve `.swipeActions()` — is this technically sound on iOS 26?
- Core Data v6 migration adds `quickOption: String?` as a lightweight migration — any concerns?

#### 5. Time Estimates
- Do the time estimates (63-65 hours total across 8 phases) seem realistic for a solo developer working in Swift/SwiftUI?
- Which phases are most likely to exceed their estimates? Why?

#### 6. Testing & Quality
- Are the testing checklists comprehensive enough?
- What's missing from a QA perspective?
- The M15.7 accessibility sub-phases — are they thorough enough for App Store approval?

#### 7. Design System Coherence
- Is the ForagerTheme token system (38 colors, 8 typography sizes, spacing scale) well-structured?
- Are there any token naming conflicts or redundancies?
- Does the warm earth-tone palette (forest greens, bark browns, parchment) work for both light and dark mode?

### What I Do NOT Need
- Don't rewrite the plans or code snippets
- Don't suggest alternative architectures (the dual-store CloudKit + service layer pattern is established and working)
- Don't evaluate the product concept — focus on implementation feasibility and quality

### Format
Please organize your feedback as:
1. **Critical Issues** (would cause build failures, data loss, or broken user flows)
2. **Important Improvements** (would significantly improve quality or prevent rework)
3. **Minor Suggestions** (nice-to-haves, polish)
4. **Positive Observations** (what's done well — helps calibrate the review)

For each item, specify: which document, which section, what the issue is, and what you'd recommend.
