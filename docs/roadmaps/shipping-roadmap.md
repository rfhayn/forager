# Shipping Roadmap (Stream 3)

**Parent**: [`docs/project-roadmap.md`](../project-roadmap.md)
**Stream intent**: How work flows from idea to users. Launch management, bug reception, and the forward feature pipeline.
**Last Updated**: 2026-04-18
**Update cadence**: After each App Store review round + after each feature milestone scoping

---

## Launch Status

**Current state**: forager v1.0 in App Review

| Item | Status |
|------|--------|
| Version / build | v1.0, build 134 |
| Most recent submission | 2026-04-17 (rejection round 2 resolution) |
| Most recent reviewer action | Rejection round 2 — guideline 2.3.6 Accurate Metadata |
| Resolution | Metadata-only fix (Age Rating: Unrestricted Web Access = Yes, auto-bumps to 17+). No binary change. Replied via Resolution Center. |
| Awaiting | Re-review approval |
| Landing page | `docs/index.html` (published via GitHub Pages) |
| Privacy policy | `docs/privacy.html` |
| App Store listing copy | `docs/app-store-listing.md` |

**Confidence**: GREEN — reviewer gave explicit remedy, fix was metadata-only, no resubmit workflow needed for metadata rejections (verified).

---

## App Store Rejection History

| Round | Date | Guideline | Issue | Resolution |
|-------|------|-----------|-------|------------|
| 1 | (prior) | — | — | — |
| 2 | 2026-04-17 | 2.3.6 Accurate Metadata | Age Rating missing "Unrestricted Web Access: Yes" (recipe URL import qualifies) | Metadata-only fix in ASC; build 134 unchanged. Age rating auto-bumps to 17+. Reply in Resolution Center sufficient — metadata rejections continue review automatically. |

---

## Post-Launch Bug Reception Loop

**Status**: PLANNED (depends on `migrate-to-structured-logging`)

Until structured logging ships (app-health-roadmap Bucket 2), device log retrieval for production bugs will be difficult. The logging migration is prioritized so this loop can be stood up early in post-launch.

**Planned artifacts**:
- User feedback intake via TestFlight feedback + email (already configured)
- Diagnostic log retrieval from affected devices (pending Logger migration)
- Triage workflow: reproduce → log → fix → ship via `/release-prep`
- Known issues tracked here as they accumulate

---

## Feature Pipeline

Ordered roughly by priority. All new feature work uses OpenSpec change-id naming; existing backlog PRDs keep M-names until picked up into a focused milestone.

### Post-Launch Priority 1: Image Support

| Item | Estimate | Source |
|------|----------|--------|
| M11.1 Tier 2 — local image cache + download (offline images for imported recipes) | 8–12h | `docs/prds/active/m11.1-recipe-images.md` |
| M11.1 Tier 3 — camera + library integration for manually created recipes | 16–20h | same PRD |

Tier 1 (persist imageURL) already shipped as M10.4.0. These tiers remain.

### Post-Launch Priority 2: Meal Planning UX

| Item | Estimate | Source |
|------|----------|--------|
| FUI-2 — meal planner calendar grid view | TBD | (no PRD yet; scope in propose phase) |

### Post-Launch Priority 3: Ingredient Seeding

| Item | Estimate | Source |
|------|----------|--------|
| M10.7 — USDA seed dictionary (~1,500–2,000 pre-categorized ingredients) | 8–12h | `docs/prds/active/m10.7-usda-ingredient-seed-dictionary.md` |

### Post-Launch Priority 4: Multi-Store Shopping

| Item | Estimate | Source |
|------|----------|--------|
| M18.2 — multi-store + shopping trips (Phase 2 of store-aware shopping) | TBD | (no PRD yet; M18 Phase 1 shipped) |

### Deferred

| Item | Estimate | Source |
|------|----------|--------|
| M6 — Testing Foundation + AI augmentation | 12–18h | `docs/prds/active/milestone-6-testing-foundation-ai-augmentation.md` |

---

## Shipping Discipline Rules

- **One change = one branch = one PR = one squash commit to main** (unchanged from legacy)
- **Forward-only naming**: new feature branches use change-id (e.g., `feature/add-recipe-video-support`); legacy M-named branches retain their names through completion
- **Every feature milestone that touches a file >500 lines extracts ≥1 subview** (per app-health-roadmap Bucket 3 amortization rule)
- **Every pre-PR runs `/architecture-audit`** — zero new violations on the scope/saves patterns
- **Every post-launch bug report logs diagnostic context** — once logging migration ships

---

## Navigation

- Launch landing: https://rfhayn.github.io/forager/
- Privacy policy: https://rfhayn.github.io/forager/privacy.html
- TestFlight beta: link in ASC + landing page
- Historical record: `docs/development-journal.md`, `docs/prds/complete/`, `openspec/changes/archive/`
