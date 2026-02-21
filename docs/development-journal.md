# Forager Development Journal

**Purpose**: A narrative chronicle of building Forager — capturing decisions, learning moments, AI tooling evolution, and the story behind the code. Unlike the technical insights log (quick-reference table) or learning notes (milestone summaries), this journal tells the *why* behind the *what*.

**Format**: Session-level entries in reverse chronological order. Each entry captures what happened, what decisions were made and why, what was learned about the tools and process, and what it means for the project's direction.

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
