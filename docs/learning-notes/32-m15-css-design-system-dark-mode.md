# Learning Note 32: CSS Design System & Dark Mode Patterns

**Milestone**: M15 — UX Design System
**Date**: February 17, 2026
**Scope**: CSS custom properties, dark mode architecture, mockup-as-specification technique

---

## Context

M15 involved building a comprehensive HTML/CSS mockup (18 phone frames + 6 inline reference cards) as the design specification for a SwiftUI implementation. The mockup uses CSS custom properties as the design token system, with a `[data-theme="dark"]` override block for dark mode. Seven insights emerged around CSS architecture decisions that directly impact implementation quality.

---

## 1. Semantic Tokens Eliminate Manual Dark Mode Overrides

**Before**: Each element that needed white text on an accent background had two CSS rules:
```css
.quick-add-btn { color: #FFFFFF; }
[data-theme="dark"] .quick-add-btn { color: #1C1A14; }
```

**After**: One rule using a semantic variable:
```css
.quick-add-btn { color: var(--btn-primary-text); }
```

The variable flips automatically in the dark theme block. This removed 4 redundant dark mode overrides in a single audit pass.

**Principle**: Every hardcoded color outside `:root` is a dark mode liability. Every semantic variable is one fewer thing that can go stale.

**SwiftUI mapping**: This maps directly to `Color("btnPrimaryText")` in an asset catalog with light/dark appearance variants — same principle, different mechanism.

---

## 2. `color-mix()` for Derived Colors

Category chip backgrounds were previously hardcoded `rgba()` values that could drift from the `--cat-*` text color variables:

```css
/* Before: duplicated color knowledge */
.cat-chip.produce { background: rgba(76, 140, 43, 0.12); }

/* After: derived from single source */
.cat-chip.produce { background: color-mix(in srgb, var(--cat-produce) 12%, transparent); }
```

One source of truth per category. Dark mode category colors automatically produce correct chip backgrounds without any override.

**SwiftUI mapping**: `Color.catProduce.opacity(0.12)` — same derivation pattern.

---

## 3. Type Scale Variables as Implementation Contracts

Defining `--font-*` CSS variables (8 sizes: 10/12/13/15/17/20/28/34) without refactoring existing CSS rules creates a contract:

```css
:root {
  --font-caption2: 10px;
  --font-caption: 12px;
  --font-footnote: 13px;
  --font-body: 15px;
  --font-headline: 17px;
  --font-title3: 20px;
  --font-title: 28px;
  --font-largeTitle: 34px;
}
```

Individual CSS rules still use raw `px` values (migration deferred to M15.2). But the variable definitions are the single source of truth — SwiftUI developers reference the variable names, not grep for scattered `font-size` values.

**Key insight**: Define the scale early, migrate incrementally. The variables are the spec; the inline values are legacy.

---

## 4. CSS Specificity Traps with Compound Selectors

When a class uses `border` shorthand, it resets ALL four borders — including `border-left` set by an earlier class:

```css
/* This: */
.cat-strip { border-left: 4px solid var(--cat-produce); }
.ingredient-lib-card { border: 1px solid var(--border-subtle); }

/* ...wipes out border-left because 'border' shorthand has equal specificity
   and comes later in source order. Fix with compound selector: */
.ingredient-lib-card.cat-strip { border-left: 4px solid var(--cat-produce); }
```

The compound selector bumps to 2-class specificity, overriding the shorthand.

---

## 5. Hardcoded Color Sweep Methodology

After any batch of mockup work, grep for literal hex values outside `:root`:

```bash
grep -n '#FFFFFF\|#000\|white\|black' mockup.html
```

Only `:root` variable definitions should match. Every hit outside that is:
- A dark mode bug waiting to happen
- A maintenance liability requiring a manual `[data-theme="dark"]` override

In the M15 review: 5 inline `#FFFFFF` values were found and replaced (swipe demos, day-chip dot, toggle thumb), removing 1 manual dark mode override in the process.

---

## 6. Orphaned Variable Maintenance

CSS custom property definitions have zero runtime cost but real maintenance cost — every unused variable is a false signal when scanning `:root`.

**Remove**: `--r-xl: 20px` was defined but never referenced by any `var(--r-xl)`.

**Keep**: `--info-fg` and `--info-bg` were currently unused but needed for Phase 3 error states — keeping them was correct because their future use was planned and imminent.

**Rule of thumb**: `grep 'var(--token-name)'` — zero hits AND no planned use = remove.

---

## 7. Translucent vs Semantic Backgrounds in Dark Mode

Translucent backgrounds (`rgba()`) that look correct in light mode can become invisible in dark mode:

```css
/* Invisible on dark canvas: */
.progress-bar-track { background: rgba(176, 168, 158, 0.3); }

/* Works on both: */
.progress-bar-track { background: var(--bg-tertiary); }
```

The semantic token already has a tested dark-mode value. The `rgba()` value was designed for one specific canvas color.

**Rule**: If an element must be visible on both themes, use a semantic token, not a translucent overlay.

---

## Summary

| Pattern | Benefit | SwiftUI Equivalent |
|---------|---------|-------------------|
| Semantic color tokens | Auto dark mode, zero overrides | Asset catalog appearance variants |
| `color-mix()` derivation | Single source of truth per color | `.opacity()` modifier |
| Type scale variables | Implementation contract | `Font.system(size:)` scale |
| Compound selectors | Specificity control | N/A (SwiftUI doesn't cascade) |
| Hex grep sweep | Catch dark mode bugs | Asset catalog completeness check |
| Orphaned variable removal | Clean token contract | Unused color set cleanup |
| Semantic vs translucent | Cross-theme reliability | Semantic `Color` vs `.opacity()` |

---

**Promoted from**: Insights Log entries — CSS/SemanticTokensDarkMode, CSS/TypeScaleVariables, CSS/OrphanedVariables, CSS/ColorMixFunction, CSS/SpecificityBorderTrap, CSS/HardcodedColorSweep, Design/ProgressBarDarkMode
