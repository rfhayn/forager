## Why

The current warm beige palette has near-invisible contrast between canvas backgrounds and card surfaces: 1.03:1 in light mode (white on almost-white beige) and 1.22:1 in dark mode (two shades of near-black). Users reported that "white on beige looks really bad" and "two shades of black look bad." Cards don't visually separate from backgrounds, making the UI feel flat and undefined. This is blocking App Store readiness.

## What Changes

- Update 18 color token values in ForagerTheme.swift to the "Parchment & Paper" palette
- Canvas backgrounds shift warmer/darker (parchment feel)
- Card surfaces shift to cool white/neutral gray (clean paper feel)
- Border colors shift cooler to complement the cool card surfaces
- The warm-vs-cool temperature contrast creates perceptual separation even at modest luminance ratios
- ALL accent colors, text colors, status colors, button colors unchanged
- No layout changes, no view structure changes, no file changes outside ForagerTheme.swift
- Reference mockup: `docs/mockups/option-c-final-mockup.html`

## Capabilities

### New Capabilities

None. This is a token value change, not a new capability.

### Modified Capabilities

None at the spec level. The visual appearance changes but no behavioral requirements change.

## Impact

- **ForagerTheme.swift**: 18 color token value updates (the only code change)
- **26+ view files**: Auto-update via token references, no code changes needed
- **ForagerCard.swift**: Card modifiers use surfacePrimary, will auto-update
- **All screens**: Visual appearance changes in both light and dark mode
- **No Core Data, service, or architectural changes**
