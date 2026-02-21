# Forager Development Journal

**Purpose**: A narrative chronicle of building Forager — capturing decisions, learning moments, AI tooling evolution, and the story behind the code. Unlike the technical insights log (quick-reference table) or learning notes (milestone summaries), this journal tells the *why* behind the *what*.

**Format**: Session-level entries in reverse chronological order. Each entry captures what happened, what decisions were made and why, what was learned about the tools and process, and what it means for the project's direction.

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
2. Ask Claude to update all 5 core docs simultaneously (current-story, next-prompt, roadmap, requirements, project-index)
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
