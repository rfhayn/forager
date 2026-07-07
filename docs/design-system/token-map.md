# Provisions Press Token Map

> **LIVING DOCUMENT** — promoted from `openspec/changes/reskin-provisions-press/`
> on 2026-07-06 (task 6.1). This copy in `docs/design-system/` is authoritative
> going forward; the change-folder copy is frozen history once archived.


Complete `ForagerTheme` token replacement. Every ratio below is computed WCAG relative-luminance contrast (script: session scratchpad `contrast.py`, 69 verified pairs, all passing). Requirements: **7:1 AAA** primary text, **4.5:1 AA** other text, **3:1** UI components/accents/category fills.

## Backgrounds

| Token | Light | Dark | Notes |
|---|---|---|---|
| backgroundCanvas | `#E8E6DF` | `#191714` | butcher paper / warm ink (NOT grey) |
| backgroundPrimary | `#E0DDD4` | `#201D19` | |
| backgroundSecondary | `#D8D4C9` | `#282420` | |
| backgroundTertiary | `#CFCBBE` | `#302B26` | |

## Surfaces

| Token | Light | Dark | Notes |
|---|---|---|---|
| surfacePrimary | `#F2F0EA` | `#262220` | textPrimary on it: 14.72 / 12.06 (AAA) |
| surfaceSecondary | `#F7F5F0` | `#2E2A26` | sheets, popovers |
| surfaceAccent | `#F2DCD7` | `#3A2A26` | selected state — tomato tint (was green tint) |
| surfaceWarning | `#F4E7CC` | `#362D1A` | mustard tint |
| surfaceDanger | `#F4DAD4` | `#3A241F` | tomato tint |
| surfaceSuccess | `#DCE9DD` | `#22302A` | print-green tint |

## Text

| Token | Light | Dark | Contrast on canvas (L/D) |
|---|---|---|---|
| textPrimary | `#201D1A` | `#E4E1D8` | 13.43 / 13.68 — AAA |
| textSecondary | `#55504A` | `#B8B3A8` | 6.39 / 8.56 — AA+ |
| textTertiary | `#6C665E` | `#9A948A` | 4.54 / 5.94 — AA |
| textDisabled | `#A39D92` | `#5E594F` | (decorative, no req) |
| textLink | `#1A5F5B` | `#6FB3AE` | 5.94 / 7.44 — teal, was green |

## Accents

| Token | Light | Dark | Contrast on canvas (L/D) |
|---|---|---|---|
| accentPrimary | `#C8402E` | `#E05A44` | 3.98 / 4.87 — **tomato** (was forest green) |
| accentSecondary | `#A9761F` | `#D89A2B` | 3.17 / 7.31 — mustard (ink-weight in light) |
| accentTertiary | `#1F6E6A` | `#4E9B95` | 4.81 / 5.49 — teal |
| accentTint | `#F2DCD7` | `#3A2A26` | = surfaceAccent |

## Status

| Token | Light | Dark | FG on own BG (L/D) | FG on canvas (L/D) |
|---|---|---|---|---|
| statusSuccessFG | `#266B45` | `#6FAF87` | 5.12 / 5.35 | 5.14 / 6.95 |
| statusSuccessBG | `#DCE9DD` | `#22302A` | | |
| statusWarningFG | `#7A5710` | `#D8A64A` | 5.36 / 6.12 | 5.26 / 8.07 |
| statusWarningBG | `#F4E7CC` | `#362D1A` | | |
| statusDangerFG | `#B03A28` | `#E67560` | 4.55 / 4.87 | 4.83 / 6.03 |
| statusDangerBG | `#F4DAD4` | `#3A241F` | | |
| statusInfoFG | `#34689A` | `#6E9EC8` | 4.64 / 5.12 | 4.68 / 6.29 |
| statusInfoBG | `#DEE6EE` | `#202A34` | | |

## Borders

| Token | Light | Dark |
|---|---|---|
| borderDefault | `#C6C2B6` | `#44403A` |
| borderSubtle | `#D6D2C7` | `#38342E` |
| borderStrong | `#A9A497` | `#56524A` |
| borderAccent | `#C8402E` | `#E05A44` |

## Buttons

| Token | Light | Dark | Notes |
|---|---|---|---|
| buttonPrimaryDefault | `#C8402E` | `#E05A44` | text contrast 4.97 / 4.88 |
| buttonPrimaryPressed | `#A5301F` | `#EA7A64` | light presses darker, dark presses **lighter** (glass brightens under touch); text 6.90 / 6.38 |
| buttonPrimaryDisabled | `#D2CEC3` | `#38342E` | |
| buttonPrimaryText | `#FFFFFF` | `#1B1613` | white-on-tomato light; ink-on-tomato dark |
| buttonPrimaryDisabledText | `#8F897D` | `#5E594F` | |

## Categories (hue-family continuity — all fills ≥3:1 on canvas; white label ≥3:1 on every light fill)

| Category | Light | Dark | Family kept |
|---|---|---|---|
| produce | `#2E7A52` | `#5FA97E` | green → print green |
| dairy & fridge | `#34689A` | `#6E9EC8` | blue |
| deli & meat | `#C8402E` | `#E06A55` | red = tomato primary |
| bread & bakery | `#B0762A` | `#C9924A` | golden brown |
| pantry & canned | `#77563A` | `#A5825F` | brown |
| frozen | `#3C7D96` | `#6BA7BE` | ice blue |
| beverages | `#6A4E92` | `#9C82C4` | purple |
| snacks & other | `#C2662C` | `#D98A52` | orange |
| seafood | `#1F6E6A` | `#4E9B95` | teal (palette anchor) |
| household | `#5E6E60` | `#8DA890` | grey-green |
| uncategorized | `#7A7368` | `#948D82` | neutral |

Dark-mode category tags keep their **light** fills when rendered as filled tags (verified ≥3:1 vs `#191714` via the dark column when used as FG/dot colors).

## Typography roles (replaces SF Pro Rounded system)

| Role | Spec | Replaces |
|---|---|---|
| screenTitle | SF Compact `.largeTitle` heavy, uppercase styling at call sites optional | 34pt Bold Rounded |
| detailTitle | SF Compact 28 heavy | 28 Bold Rounded |
| cardTitle | SF Compact 20 bold | 20 Semibold Rounded |
| bodyFont | SF Pro `.body` (unchanged) | — |
| secondaryFont | SF Pro `.subheadline` (unchanged) | — |
| footnoteFont | SF Compact condensed-feel `.footnote` semibold | Rounded semibold |
| captionFont | SF Compact `.caption` semibold | Rounded semibold |
| tabLabel | SF Compact 10 semibold | Rounded medium |
| **quantityFont** (NEW) | SF Mono `.footnote`/13 semibold, monospacedDigit | — functional signature |
| **quantityFontLarge** (NEW) | SF Mono 15 semibold | — |

Note: SwiftUI has no `.compact` Font.Design; SF Compact is reached via `.system(..., design: .default)` with heavy weights + width where available (`Font.width(.condensed)` on iOS 16+) — implementation uses `.default` design + `.condensed` width for the crate-label voice.
