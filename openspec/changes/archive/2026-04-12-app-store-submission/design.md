## Context

forager is feature-complete for v1. All code milestones are merged to main. Two categories of work remain before App Store submission:

1. **Web/docs assets** — Apple requires a live privacy policy URL, support URL, and app metadata. A landing page and README update are also needed for professional presence.
2. **M9.28 logging strip** — DiagnosticLogger and DebugLogService are active in Release builds, writing to disk and exposing a diagnostics UI in Settings. Must be gated before shipping.

GitHub Pages is already configured (serves from `main:/docs`). Privacy policy exists but needs AI disclosure update.

## Goals / Non-Goals

**Goals:**
- Privacy policy accurately reflects all data flows including optional Claude API
- GitHub Pages root serves a minimal landing page (Marketing URL for ASC)
- README reflects current project state with correct stats
- All App Store Connect metadata drafted and ready to enter
- Manual submission steps documented as a checklist
- Release builds have zero diagnostic logging file I/O
- Settings hides diagnostics section in Release

**Non-Goals:**
- App Store screenshots (user handles manually on real device)
- App Store Connect data entry (manual)
- Actual submission (manual)
- New features or UI changes
- Privacy policy legal review (best-effort disclosure)

## Decisions

### 1. No-op stub pattern for logging (not `#if DEBUG` at call sites)

Wrapping 100+ call sites in `#if DEBUG` clutters the code. Instead, gate the full class behind `#if DEBUG` and provide an `#else` stub with the same API surface but empty method bodies. The compiler optimizes away empty function calls in Release. Call sites compile unchanged in both configurations.

**Alternative considered:** Deleting the logging classes entirely. Rejected because they're useful for future debugging — gating preserves them for Debug builds.

### 2. Minimal landing page (not full marketing site)

A simple HTML page matching the existing privacy.html aesthetic. No JavaScript, no framework, no screenshots on the page. The purpose is to give ASC a Marketing URL and stop the GitHub Pages root from 404-ing.

**Alternative considered:** Full landing page with screenshots and app preview. Rejected as unnecessary for v1 submission — can be enhanced post-launch.

### 3. App Store copy in a markdown reference file

Draft all metadata in `docs/app-store-listing.md` rather than entering directly in ASC. This makes it reviewable in PR, version-controlled, and easy to copy-paste into ASC.

### 4. Keywords exclude words already in app name

Apple automatically indexes words in the app name and subtitle for search. The 100-character keyword field should use terms NOT already in the name/subtitle to maximize search coverage.

## Risks / Trade-offs

- **Privacy policy accuracy** — Best-effort disclosure of Claude API data flow. Not reviewed by legal counsel. Risk: Apple could ask for more specific language. Mitigation: disclosure is conservative and thorough.
- **Logging stub overhead** — Empty singleton allocation in Release. Risk: negligible (one object, no file handles). Mitigation: compiler may optimize away entirely.
- **README stats** — Test count (531) and hours (~345) are point-in-time. Risk: stale within weeks. Mitigation: these are approximate and clearly presented as such.
