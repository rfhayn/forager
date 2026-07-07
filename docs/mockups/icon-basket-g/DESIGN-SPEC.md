# Basket-g Icon — Design Spec (future vector pass)

**Status**: Concept approved, execution deferred (2026-07-06). Clean `fgr` ships in the meantime.
**Concept** (Rich's): in the `fgr` wordmark, the g's bowl becomes a woven basket. Craft lives *inside* the letterform.

## Fixed parameters (do not change)
- Wordmark: lowercase `fgr`, **Space Mono Bold**, tracking −6% em, optically centered, nudged up 2–4% of icon height
- Field: tomato `#C8402E` (light) / ink `#201D1A` (dark) / transparent + white glyph (tinted)
- Letters: cream `#F2F0EA` (light) / paper `#E4E1D8` (dark)
- Accent: mustard `#D89A2B` (handle)
- Same drawing at all sizes; must read at 60 px

## The composition that came closest (V6c, see final-v6c-light.png)
- g bowl: filled solid (counter removed), keeps the g's stem + descender hook untouched
- Weave inside bowl: 1 horizontal rim line (~30% down the bowl) + 2 vertical staves below it, field-colored
- Handle: mustard arc over the bowl, endpoints landing ON the bowl rim (~215°–325°)

## What a proper vector pass must fix (why the PIL renders fail)
1. **Bowl shape**: use Space Mono's actual bowl outline (extract via fontTools), not an ellipse — the real bowl is subtly squarish
2. **Handle**: needs taper/weight modulation and true tangent joins at the rim — not a naive stroked arc
3. **Weave**: over-under gaps where staves cross the rim (real weave), slight stave curvature following the bowl
4. **Optical balance**: bowl-with-basket is visually heavier than f/r — letters may need ±1–2% repositioning

## Measured geometry (1024 px canvas, production layout)
- g draw bbox: (400, 397) – (624, 656); counter: (462, 441) – (557, 543); stem stroke ≈ 46 px
- Failed directions (don't retry): dense lattice (mush at 60 px), sparse diagonal lattice (reads "crossed-out ball"), rim-only (reads "hat")

## Handoff
Deliver one master SVG (light); the PIL pipeline in the session scratchpad regenerates AppIcon light/dark/tinted + LaunchIcon ×6 + web icon.png from any master. Icon swaps don't require App Review resubmission — ship whenever ready.
