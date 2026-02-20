# Learning Note 37: iOS 26 Glass API Behavior

**Milestone**: M15.6 — Liquid Glass Integration
**Date**: February 20, 2026
**Scope**: SwiftUI `.glassEffect()`, Glass type members, button styles, tab bar behavior

---

## Context

M15.6 integrated iOS 26's Liquid Glass design language into Forager's card system, tab bar, and navigation. Four non-obvious API behaviors emerged that aren't clearly documented in Apple's current developer resources.

---

## 1. Glass Has Three Members, Not Four

The `Glass` type in SwiftUI has exactly 3 members:

| Member | Effect |
|--------|--------|
| `.regular` | Standard frosted glass — the default Liquid Glass look |
| `.clear` | Subtle translucency with minimal frosting |
| `.identity` | No visual effect (passthrough) |

There is **NO `.prominent` variant** despite WWDC session slides suggesting it. The "prominent" concept only exists for button styles:

```swift
// This exists:
.buttonStyle(.glassProminent)

// This does NOT exist:
.glassEffect(.prominent, in: shape)  // Compiler error
```

For emphasized cards, use `.regular` with a larger corner radius or combine with a tinted background for visual distinction.

---

## 2. Glass Replaces Shadows — Don't Use Both

`.glassEffect()` creates depth through light refraction and material blur. Adding `.shadow()` on top creates visual confusion — a "floating over floating" double depth cue.

```swift
// WRONG: double depth
CardView()
    .shadow(radius: 4)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

// RIGHT: glass handles depth
CardView()
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
```

Glass also handles dark mode elevation automatically. The pre-glass pattern of adding a 0.08-opacity white rim light overlay for dark mode edge definition becomes unnecessary — glass inherently provides edge definition through material contrast.

**Migration note**: When converting from custom card styles to glass, remove both `.shadow()` modifiers and any manual dark-mode rim light overlays.

---

## 3. `.buttonStyle(.glass)` Overrides Semantic Colors

`.buttonStyle(.glass)` completely replaces the button's label content styling — it overrides backgrounds, foreground colors, and borders with the glass material.

```swift
// All three buttons look identical despite different intents:
Button("Done") { ... }
    .buttonStyle(.glass)  // Glass material, no green

Button("Remove") { ... }
    .buttonStyle(.glass)  // Glass material, no red

Button("Cancel") { ... }
    .buttonStyle(.glass)  // Glass material, no grey
```

Glass buttons are best for **standalone, single-purpose CTAs** where the glass material itself is the visual language. For inline action buttons with distinct semantic states (success/danger/neutral), keep explicit `ForagerTheme`-based styling.

**Forager decision**: Primary CTAs and tab bar use glass. Inline action buttons (Done/Swap/Remove on meal plan cards) retain themed colors.

---

## 4. Tab Bar Minimize Behavior

`.tabBarMinimizeBehavior(.onScrollDown)` collapses the Liquid Glass tab bar when the user scrolls content down, maximizing screen real estate. The bar reappears on scroll-up.

Four options available:

| Option | Behavior |
|--------|----------|
| `.automatic` | System decides based on content |
| `.onScrollDown` | Collapses when scrolling down (recommended for content-heavy screens) |
| `.onScrollUp` | Collapses when scrolling up (unusual, niche use) |
| `.never` | Tab bar always visible |

Works automatically with `List` and `ScrollView` content — no additional configuration needed.

```swift
TabView {
    // tabs...
}
.tabBarMinimizeBehavior(.onScrollDown)
```

---

## Summary

| Behavior | Documentation Gap | Impact |
|----------|------------------|--------|
| No `.prominent` glass variant | WWDC slides imply it exists | Compiler error — use `.regular` + styling |
| Glass replaces shadows | Not explicitly stated | Visual artifacts if both applied |
| Glass button overrides colors | Easy to miss in API docs | Semantic buttons lose meaning |
| Tab bar minimize options | 4 options with subtle differences | Wrong choice = jarring scroll UX |

---

**Promoted from**: Insights Log entries — iOS26/GlassAPI (Feb 17), iOS26/GlassEffect (Feb 17), iOS26/GlassButtons (Feb 17), iOS26/TabBarMinimize (Feb 17)
