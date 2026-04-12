## Context

ForagerTheme.swift defines all semantic color tokens via `adaptiveColor(light:dark:)`. The app has 26+ view files and 3 card modifier components that reference these tokens. Because all colors flow through the theme, changing the token values in one file cascades to every view automatically.

A full UI audit confirmed: no hardcoded hex colors in production code, no improper use of Color.white/black for backgrounds. All 150+ color usages go through ForagerTheme tokens. Opacity modifiers on accent colors (`.opacity(0.12)` on quick action buttons, `.opacity(0.3)` on shadows) will work fine since accent colors are unchanged.

## Goals / Non-Goals

**Goals:**
- Increase canvas-to-surface contrast in both light and dark mode
- Add warm-vs-cool temperature split for perceptual depth
- Keep the warm forager identity in the canvas layer
- Single-file change that cascades to all views

**Non-Goals:**
- Changing accent colors, text colors, or status colors
- Changing any view layouts or structures
- Changing ForagerCard modifier behavior
- Redesigning any screens

## Decisions

### 1. "Parchment & Paper" temperature split over uniform warmth

Shift canvas backgrounds warmer (parchment) while shifting card surfaces cooler (paper). The warm-vs-cool temperature difference creates perceptual contrast even at modest luminance ratios. This is more effective than simply darkening the canvas while keeping everything warm.

**Alternative considered**: Option A "Warm Linen" (deeper warm canvas, white cards). Rejected because same-temperature colors need larger luminance gaps to read as different. Option B "Stone & Sage" (Apple system grays). Rejected because it loses the warm forager identity.

### 2. Cooler borders to match cool surfaces

Borders shift from warm (#E0D8CC) to neutral (#D8D6D0) in light mode, and from warm-brown (#3A3630) to neutral-gray (#3A3A3A) in dark mode. This prevents warm borders from clashing with cool card surfaces.

### 3. Dark mode surfaces shift to neutral gray

Dark mode cards shift from warm brown (#2E2A1F) to neutral gray (#282828). This creates stronger separation from the warm-black canvas (#141210) and better readability for all content.

## Risks / Trade-offs

- **[Risk] Opacity modifiers might need tweaking** → Verified: accent colors unchanged, so `.opacity(0.12)` on quick action buttons works identically.
- **[Risk] ForagerCard rim light effect** → Verified: uses hardcoded `Color.white.opacity(0.06)`, not a theme token. Unaffected.
- **[Risk] Canvas-to-surface contrast still below WCAG 3:1** → Expected: decorative surface separation is intentionally subtle. Text contrast is 12-16:1 (excellent).
- **[Trade-off] Slightly reduced text contrast in light mode** → 14.80:1 → 12.54:1. Still well above WCAG AA 4.5:1.
