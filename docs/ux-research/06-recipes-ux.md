# 06: Recipes Screen UX Recommendations

**Date:** 2026-02-14
**Scope:** RecipeListView, RecipeDetailView, CreateRecipeView, EditRecipeView, RecipeScalingView, AddIngredientsToListView
**Design System Reference:** `ForagerTheme.swift` (ui/design-overhaul branch)

---

## Executive Summary

The Recipes screen is the intellectual heart of Forager. While the grocery list is transactional and the meal plan is logistical, recipes are where users invest creative energy. The current implementation is functionally complete -- search, scaling, ingredient parsing, grocery list integration, and household filtering all work. But the visual presentation reads as a data table rather than a recipe collection. These recommendations transform the browsing experience into something that feels editorial and warm without relying on food photography, using typography, color, and spatial hierarchy as the primary design tools.

---

## 1. Recipe Browsing

### Current State

The recipe list uses a standard `InsetGroupedListStyle` with `EnhancedRecipeRowView` showing title, servings, usage count, last-used date, prep time, and search match indicators. It is purely a text list with system fonts on a system background. Every recipe looks identical in visual weight.

### Problems

- **Visual monotony.** Every row has the same typographic hierarchy. There is no way to scan for recipes at a glance the way you flip through a cookbook.
- **No personality.** System fonts and `systemGray6` backgrounds produce a utilitarian feel that contradicts the warm, organic Forager brand identity.
- **Sorting is invisible.** The list sorts by `lastUsed` descending, then `title` ascending, but users cannot change the sort order and are not told what sorting is active.
- **Favorites have no prominence.** A small red heart icon is the only favorite indicator, buried at the trailing edge of the row.

### Recommendations

#### 1.1 Card-Based Layout (without photos)

Replace the flat list with a card layout using `ForagerTheme.cardBackground` on `ForagerTheme.primaryBackground`. Since Forager has no food photography, the card must earn its visual interest through typography and metadata alone.

**Card anatomy (top to bottom):**

```
+-----------------------------------------------+
| [Category color strip - 4pt left edge]         |
|                                                |
|  Chocolate Chip Cookies          [heart icon]  |
|  ---- serif title, 20pt ----                   |
|                                                |
|  24 servings  *  25 min total                  |
|  ---- caption, stone color ----                |
|                                                |
|  [clock icon] 15m prep   [flame] 10m cook      |
|  ---- pill badges, mintTint background ----    |
|                                                |
|  Made 3 times  *  Last used Jan 12             |
|  ---- caption2, secondary text ----            |
|                                                |
|  [household badge]  [tags: "quick", "baking"]  |
+-----------------------------------------------+
```

Key design decisions:
- **Serif title.** Use `ForagerTheme.serifFont(20)` for recipe names. This immediately distinguishes the Recipes tab from the rest of the app (which uses rounded system fonts) and creates an editorial, cookbook-like feel. NYT Cooking and Kitchen Stories both use serif or semi-serif type for recipe titles to evoke print-magazine authority.
- **Category color strip.** A 4pt vertical bar on the left edge uses the dominant ingredient category color (produce green, dairy blue, etc.). This provides scannable visual variety without photography. Use the `categoryStrip()` modifier from ForagerTheme.
- **Timing pills.** Prep and cook times display in small pill badges with `ForagerTheme.mintTint` background and `ForagerTheme.leafGreen` text. These are the most scannable metadata for recipe selection (per SideChef UX research).
- **No disclosure chevron.** Remove the NavigationLink chevron. Cards are self-evidently tappable. The chevron adds clutter.

**Card sizing:** Fixed height is unnecessary. Let cards size to content. Use 12pt spacing between cards. Apply `foragerCard()` modifier for consistent shadow and radius.

**Favorite treatment:** Favorited recipes get a subtle `ForagerTheme.cream` background tint and a filled heart icon at the trailing edge of the title line, rendered in `ForagerTheme.danger` (#C4402F) rather than system red.

#### 1.2 Sort and Filter Controls

Add a toolbar button (or inline segmented control below the search bar) with these sort options:

| Sort Option | Description |
|---|---|
| **Recent** (default) | Last used date, descending |
| **A-Z** | Alphabetical by title |
| **Most Made** | Usage count, descending |
| **Quickest** | Total time (prep + cook), ascending |
| **Newest** | Date created, descending |

Implementation: Use a `Menu` with `Picker` inside a toolbar item. Display the active sort as a label: "Sorted by: Recent". This solves the invisible-sort problem.

Add filter chips below the search bar for:
- **Favorites only** (heart icon toggle)
- **Quick meals** (total time under 30 minutes)
- **Tag filters** (show existing tags as tappable chips)

#### 1.3 Search Enhancements

The current search is solid (title, ingredient, instruction matching with visual indicators). Improve it by:

- **Show search scope pills** above results: "Titles (3)", "Ingredients (5)", "Instructions (1)" -- tappable to filter results to one scope.
- **Replace the blue magnifying glass** empty-search icon with `ForagerTheme.leafGreen` and a cookbook-themed icon (`book.closed` or `text.magnifyingglass`).
- **Search suggestions:** Show recent searches in `ForagerTheme.secondaryBackground` chips with a clock icon, matching the warm palette instead of plain text rows.

#### 1.4 Empty State

Replace `StandardEmptyStateView` (blue icon, blue button) with a branded variant:

- Icon: `book.closed.fill` in `ForagerTheme.leafGreen`
- Title: "Your Recipe Collection" in serif font
- Subtitle: "Start building your personal cookbook by adding your first recipe." in `ForagerTheme.stone`
- Button: "Add Your First Recipe" using `ForagerPrimaryButtonStyle` (forest green background, white text, rounded design)

This is the user's first impression if they navigate to Recipes early. It should feel inviting, not clinical.

---

## 2. Recipe Detail

### Current State

`RecipeDetailView` is a vertical `ScrollView` with sections: header (title + servings), timing (prep/cook/total), usage analytics, ingredients (grouped by category), and instructions. The "Add to List" button is a small green pill next to the Ingredients section header. Toolbar has icons for scaling, mark-used, meal plan, and edit.

### Problems

- **Title uses system `.largeTitle`.** This is the same font as every other screen in the app. Recipe titles deserve special typographic treatment to create emotional resonance.
- **Timing section wastes vertical space.** Three VStacks stacked horizontally with icons, labels, and values is verbose for just three numbers.
- **Usage analytics compete with content.** "Times Made" and "Last Used" are useful metadata but they visually interrupt the flow from title to ingredients to instructions. Cooks want: title, then what they need, then what to do.
- **"Add to List" CTA is too small.** A 6pt caption pill button is easy to miss. This is one of the two most important actions on the detail screen (the other is scaling).
- **Instructions are plain body text.** No step numbering, no visual separation between steps, no ability to track progress through a recipe.

### Recommendations

#### 2.1 Hero Header

```
+-----------------------------------------------+
|                                                |
|  Chocolate Chip Cookies                        |
|  ---- .serifFont(28), bold, bark ----          |
|                                                |
|  24 servings  [heart toggle]                   |
|  ---- subheadline, stone ----                  |
|                                                |
|  [clock] 15m   [flame] 10m   [timer] 25m      |
|  ---- horizontal pills in mintTint ----        |
|                                                |
|  [household icon] The Haynes Family            |
|  ---- caption, leafGreen if household ----     |
|                                                |
+-----------------------------------------------+
```

- **Serif title at 28pt.** Use `ForagerTheme.serifFont(28)` with `.bold` weight. This is the largest use of serif in the app and creates an editorial centerpiece.
- **Compact timing row.** Replace the three-column VStack layout with a single HStack of pill badges: "[clock] 15m prep | [flame] 10m cook | [timer] 25m total". Each pill uses `ForagerTheme.mintTint` background. This reclaims 80+ points of vertical space.
- **Heart as tappable toggle.** Move the favorite heart next to the servings line and make it tappable (currently it is display-only). Tap to toggle favorite status with a spring animation.
- **Household attribution.** If the recipe belongs to a household, show the household name in `ForagerTheme.leafGreen` with a people icon. This replaces needing a separate badge system.

#### 2.2 Ingredients Section with Prominent CTA

Restructure the ingredients section to put the primary CTA (Add to Grocery List) in a sticky footer or a prominent position:

```
+-----------------------------------------------+
| INGREDIENTS (8)                    [Scale: 1x] |
+-----------------------------------------------+
|                                                |
|  PRODUCE                                       |
|  [dot] 3 avocados                              |
|  [dot] 2 organic tomatoes                      |
|                                                |
|  DAIRY & FRIDGE                                |
|  [dot] 1/2 cup sour cream                      |
|                                                |
+-----------------------------------------------+
|  [cart icon]  Add All to Grocery List           |
|  ---- full-width ForagerPrimaryButtonStyle ---- |
+-----------------------------------------------+
```

Key changes:
- **Full-width CTA button** below the ingredients list, using `ForagerPrimaryButtonStyle`. This is forest green with white text, impossible to miss.
- **Inline scaling indicator.** Show "[Scale: 1x]" as a tappable button next to the section header. Tapping opens the scaling sheet. When a non-1x scale is active, display it in `ForagerTheme.springGreen` to indicate the recipe is currently scaled.
- **Category headers.** Keep the current category grouping but use `foragerSectionHeader()` modifier (uppercase, tracked, forestGreen) instead of custom styling.
- **Ingredient bullets.** Replace the 6pt secondary-color circle with a 4pt `ForagerTheme.leafGreen` circle for parseable ingredients and a 4pt `ForagerTheme.warning` circle for low-confidence parsed items (replacing the yellow triangle icon with something subtler).
- **Checkbox mode for cooking.** Consider a toggle: "Cooking mode" that replaces bullets with checkboxes, letting users mark off ingredients as they prep. This is a standard pattern in NYT Cooking and Kitchen Stories.

#### 2.3 Instructions Section with Editorial Typography

```
+-----------------------------------------------+
| INSTRUCTIONS                                   |
+-----------------------------------------------+
|                                                |
|  1   Preheat oven to 375 degrees F.            |
|      ---- serif body, lineSpacing 6 ----       |
|                                                |
|  2   Mix dry ingredients: flour, baking         |
|      powder, and salt in a large bowl.          |
|                                                |
|  3   In a separate bowl, cream together         |
|      butter and sugar until light and fluffy.   |
|                                                |
+-----------------------------------------------+
```

- **Serif body text.** Use `ForagerTheme.serifFont(17)` for instruction text. This creates the editorial, cookbook-page feel. Combined with the serif title, the recipe detail page reads like a magazine spread.
- **Step numbers.** Parse numbered instructions (lines beginning with "1.", "2.", etc.) and render the number as a large, bold element in `ForagerTheme.forestGreen` with the step text alongside. Use a leading number column width of ~28pt.
- **Line spacing.** Set `.lineSpacing(6)` for comfortable reading during cooking, when users glance at their phone from a distance.
- **Step separators.** Add 16pt spacing between steps (not dividers -- whitespace is cleaner for long-form reading).

#### 2.4 Usage Analytics (De-emphasized)

Move "Times Made" and "Last Used" to the bottom of the page, below instructions, as a collapsible "Activity" section or simply a quiet footer:

```
Made 3 times  |  Last made Jan 12, 2026
```

This is useful information but should not compete with the recipe content. Cooks come to this screen to cook, not to review analytics.

#### 2.5 Toolbar Simplification

Current toolbar has 4 icons (scale, mark-used, ellipsis menu, edit). This is crowded. Recommended:

| Position | Action | Notes |
|---|---|---|
| Trailing 1 | Edit (pencil) | Always visible |
| Trailing 2 | More (...) menu | Contains: Scale Recipe, Mark as Used, Add to Meal Plan, Share |

Reduce from 4 icons to 2. Scale and Mark-Used are not frequent enough to justify permanent toolbar real estate.

---

## 3. Recipe Creation

### Current State

`CreateRecipeView` presents a vertical ScrollView with section cards: Basic Information (name, servings, favorite toggle), Timing (prep/cook pickers), Ingredients (text field with autocomplete and reorderable list), Instructions (TextEditor), and Tags (text field). System `RoundedBorderTextFieldStyle`, `systemGray6` backgrounds.

### Problems

- **Long vertical scroll.** Users must scroll through 5 sections to create a recipe. On smaller devices, they may not realize Tags exist at the bottom.
- **Ingredient entry friction.** The autocomplete dropdown appears inline, pushing content down. The plus button is blue (not on-brand). The ingredient list uses permanent edit mode with drag handles visible at all times.
- **Instructions are a blank TextEditor.** No guidance on format, no line numbering, no placeholder steps.
- **Category assignment modal interrupts save.** If ingredients need categories, the save flow pauses for a modal. This is jarring.

### Recommendations

#### 3.1 Progressive Disclosure Form Flow

Rather than showing all 5 sections simultaneously, use a structured flow that reveals sections as the user progresses:

**Section 1: Essentials (always visible)**
- Recipe name (large text field, serif placeholder: "What are we making?")
- Servings stepper
- Timing row (prep + cook as compact inline steppers, not sheet pickers)

**Section 2: Ingredients (expands after name is entered)**
- Full-width text field with green plus button using `ForagerTheme.springGreen`
- Autocomplete dropdown styled with `foragerCard()` shadow and warm backgrounds
- Ingredient list with swipe-to-delete (hide drag handles until explicitly editing)

**Section 3: Instructions (expands after at least 1 ingredient)**
- TextEditor with placeholder: "1. Start by...\n2. Then...\n3. Finally..."
- Add numbered step template buttons: "+ Add Step" inserts a numbered line

**Section 4: Extras (collapsible)**
- Tags input with chip display
- Favorite toggle
- Notes field (future)

This flow guides users through the natural recipe-writing process: name it, list what you need, describe how to make it, then add metadata.

#### 3.2 Ingredient Parsing UX Improvements

The parse-then-autocomplete flow is architecturally sound. Visual improvements:

- **Parse confidence indicator.** After adding an ingredient, show a brief (1.5s) animated checkmark in `ForagerTheme.springGreen` for high-confidence parses, or a subtle amber dot for low-confidence items. This gives users immediate feedback that the parser understood their input.
- **"Did you mean?" suggestions.** When an ingredient is manually entered (no autocomplete match), show a subtle inline suggestion below the added item: "Did you mean 'flour' (all-purpose)?" linking to the closest template match.
- **Batch paste.** Support pasting multiple ingredients at once (one per line). Detect newlines in the input field and parse each line as a separate ingredient. This dramatically speeds up recipe entry from copied web recipes.
- **Autocomplete styling.** Replace `systemBackground` + `Color.black.opacity(0.15)` shadow with `ForagerTheme.cardBackground` + `foragerShadow()`. Show category color dots next to each suggestion.

#### 3.3 Save Flow Polish

- **Inline validation.** Show validation errors next to the relevant field (red border + caption text) rather than in an alert dialog. This follows modern form UX conventions.
- **Category assignment.** If uncategorized templates are found, show an inline expandable section at the bottom of the ingredients list (not a separate modal sheet). Label it: "These ingredients need a category:" with category picker dropdowns inline.
- **Save button.** Move from toolbar to a prominent bottom-anchored button using `ForagerPrimaryButtonStyle`. Disabled state uses `ForagerTheme.pebble` background.

---

## 4. Recipe Scaling

### Current State

`RecipeScalingView` opens as a sheet with a header (original vs. scaled servings), a slider (1x-4x with tick marks and snap points), and an ingredients preview list grouped by category. The slider uses standard `Slider` with custom tick marks rendered via GeometryReader.

### Problems

- **No sub-1x scaling.** The slider starts at 1x. Users who want to halve a recipe (common for baking) cannot.
- **Slider is imprecise on mobile.** Snapping to 17 discrete values on a slider requires fine motor control that is difficult during cooking.
- **Read-only preview.** Users can see scaled ingredients but cannot act on them (no "Add scaled to list" button).
- **Sheet dismisses without applying.** The "Done" button dismisses but does not save the scale factor. Users must re-scale every visit.

### Recommendations

#### 4.1 Visual Multiplier with Preset Buttons

Replace the continuous slider with a row of preset buttons plus a fine-tuning control:

```
+-----------------------------------------------+
|           Scale Recipe                          |
|                                                |
|  Original: 24 servings  -->  Scaled: 12        |
|                                                |
|  [ 0.5x ] [ 1x ] [ 1.5x ] [ 2x ] [ 3x ] [4x] |
|  ---- pill buttons, selected = forestGreen ---- |
|                                                |
|  Fine tune:  [ - ]  1.5x  [ + ]               |
|  ---- stepper for 0.25 increments ----         |
|                                                |
+-----------------------------------------------+
```

- **Extend range to 0.25x-4x.** Include half and quarter options for baking.
- **Preset pills.** Six tap targets are easier to hit than a slider. Use `ForagerPrimaryButtonStyle` for the selected preset, `ForagerSecondaryButtonStyle` for others.
- **Fine-tune stepper.** A +/- stepper below the presets adjusts in 0.25x increments for custom scales. Display the current multiplier prominently in serif font.
- **Servings display.** Show the resulting servings count in large `ForagerTheme.springGreen` text as the multiplier changes.

#### 4.2 Scaled Ingredients with Actions

Below the multiplier controls, show the scaled ingredient list with:

- **Green checkmark** for successfully scaled items (parseable, high confidence)
- **Amber info icon** for unscalable items ("salt to taste") with the note "(not scaled)"
- **Quantity comparison:** Show "was: 1 cup --> now: 1 1/2 cups" for scaled items in a compact format
- **"Add Scaled to List" button** at the bottom using `ForagerPrimaryButtonStyle`. This lets users scale AND add in one flow, instead of dismissing the scaling sheet and then separately opening Add to List.

#### 4.3 Persistent Scale State (Optional Enhancement)

Consider storing the user's preferred scale factor per recipe as a property on the `Recipe` Core Data entity (e.g., `lastScaleFactor: Double`). When they return to a recipe they previously scaled, offer to restore: "Last time you made this at 2x (48 servings). Scale again?"

> **Implementation note (validated Feb 15, 2026):** Use a Core Data property on the `Recipe` entity rather than `UserDefaults`. Forager uses CloudKit sync via `NSPersistentCloudKitContainer`, and `UserDefaults` values do not sync across devices. A Core Data property ensures the scale factor follows the recipe through CloudKit sync to all household members' devices. This aligns with the service layer pattern (M7.5+) where `RecipeScalingService` would manage the persisted value.

---

## 5. Adding to Grocery List

### Current State

`AddIngredientsToListView` opens as a sheet with a header (recipe name, ingredient count), a servings adjustment stepper, a list of ingredients with checkbox selection grouped by category, and a selection summary footer. It auto-selects all ingredients. The "Add Selected" toolbar button triggers template creation, uncategorized template checking, and list selection.

### Problems

- **No merge preview.** When ingredients will be merged with existing list items (same ingredient already on the list), users have no visibility into what will happen. Quantities are silently combined.
- **List selection is invisible.** The flow automatically picks the most recent WeeklyList. Users with multiple lists have no choice.
- **Scaled quantity display is confusing.** Blue text for scaled quantities and "(was: ...)" annotations are helpful but visually noisy.
- **The flow has too many hidden steps.** Template creation, category checking, list selection, and item addition happen in a callback chain that can fail silently.

### Recommendations

#### 5.1 Ingredient Selection with Clear Feedback

Improve the selection interface:

```
+-----------------------------------------------+
| Add to Grocery List                            |
| Chocolate Chip Cookies (8 ingredients)         |
+-----------------------------------------------+
| Making: [ - ] 24 servings [ + ]   (1x scale)  |
+-----------------------------------------------+
|                                                |
| DAIRY & FRIDGE                                 |
| [x] 1/2 cup butter                            |
|     ---- if scaled: "2x: 1 cup" in spring ---- |
| [x] 2 eggs                                    |
|                                                |
| PRODUCE                                        |
| [x] 1 tsp vanilla extract                     |
|                                                |
+-----------------------------------------------+
| [ ] Select All   8 of 8 selected              |
+-----------------------------------------------+
|                                                |
| Adding to: This Week's List  [Change]          |
|                                                |
| [ Add 8 Ingredients to List ]                  |
| ---- ForagerPrimaryButtonStyle, full-width ---- |
+-----------------------------------------------+
```

Key improvements:
- **List selector.** Show the target list name with a "Change" button that presents a picker sheet. Default to most recent, but let users choose.
- **Scaled quantities inline.** Instead of "(was: 1/2 cup)", show "2x: 1 cup" in `ForagerTheme.springGreen` below the original ingredient name. Simpler and more scannable.
- **Bottom CTA.** Replace the toolbar "Add Selected" button with a full-width bottom button showing the count: "Add 8 Ingredients to List".
- **Select All as toggle.** Move "Select All" to a leading position in the footer. Make it a toggle: tap once to select all, tap again to deselect all.

#### 5.2 Merge Preview

When ingredients will merge with existing list items, show a preview section:

```
+-----------------------------------------------+
| WILL MERGE WITH EXISTING                       |
|                                                |
| butter: 1/4 cup (on list) + 1/2 cup (recipe)  |
|         --> 3/4 cup                            |
|                                                |
| eggs: 3 (on list) + 2 (recipe)                |
|       --> 5                                    |
+-----------------------------------------------+
```

This builds trust in the merge system and prevents "where did my ingredient go?" confusion. Show this section only when merges will occur, collapsed by default with a "2 items will merge" disclosure button.

#### 5.3 Success Confirmation

After adding to the list, show a brief toast or banner (not a new screen):

```
+-----------------------------------------------+
| [checkmark] Added 8 items to This Week's List  |
|             2 quantities merged                 |
|                        [View List]              |
+-----------------------------------------------+
```

Auto-dismiss after 3 seconds. "View List" navigates to the grocery list tab.

---

## 6. Visual Design

### 6.1 Brand Palette on Cards

Apply the ForagerTheme palette consistently across all recipe surfaces:

| Element | Light Mode | Dark Mode |
|---|---|---|
| Card background | `cardBackground` (white) | `cardBackground` (#2C2924) |
| Card shadow | black @ 6% opacity, 4pt blur | black @ 12% opacity, 4pt blur |
| Page background | `primaryBackground` (cream) | `primaryBackground` (#1A1816) |
| Section headers | `forestGreen` uppercase, tracked | `accentGreen` (spring green) |
| Recipe title | `bark` (#2C2418) in serif | `primaryText` (warm white) |
| Metadata text | `stone` (#7A7067) | `secondaryText` (warm gray) |
| Timing pills | `mintTint` bg, `leafGreen` text | `forestGreen` @ 20% bg, `springGreen` text |
| Primary CTA | `forestGreen` bg, white text | `leafGreen` bg, white text |
| Favorite heart | `danger` (#C4402F) | `danger` brightened 10% |

#### 6.2 Editorial Feel Without Photography

Since Forager does not include food photos, the editorial identity must come from:

1. **Typography contrast.** Serif for recipe titles and instructions; rounded sans-serif for everything else. This dual-font strategy is how publications like Bon Appetit and NYT Cooking create visual hierarchy without relying solely on images.
2. **Color-coded categories.** The left-edge color strips on cards, category headers, and ingredient bullets create visual variety across the recipe collection. Each recipe card looks slightly different based on its dominant ingredient category.
3. **Generous whitespace.** Use `ForagerTheme.spacingXL` (24pt) between major sections, `spacingLG` (16pt) within sections. Let the content breathe. Dense layouts feel utilitarian; spacious layouts feel editorial.
4. **Subtle textures.** The cream background (`#F5F0E8`) already suggests parchment. In dark mode, the warm near-black (`#1A1816`) suggests a dark wood surface. These warm undertones are the texture.

#### 6.3 Personal vs. Household Distinction

Recipes belong to either personal scope or a household. Distinguish them visually:

- **Personal recipes:** No extra indicator. The default state.
- **Household recipes:** Show a small `person.2.fill` icon in `ForagerTheme.leafGreen` at the trailing edge of the card, next to the household name in caption text. This is subtle but always present.
- **On the detail screen:** Show the household name below the title in `ForagerTheme.leafGreen` if the recipe is household-scoped. Personal recipes show nothing (cleaner).
- **In search results:** Household recipes show "(shared)" after the title in secondary text.

Do NOT use separate sections or tabs for personal vs. household recipes. They should intermingle in one list, with the visual badge as the only distinction. Users think in terms of "my recipes" (which includes both personal and shared household recipes), not "personal database vs. shared database."

---

## 7. Light/Dark Mode

### 7.1 Card Appearance

**Light Mode:**
- Cards are white on cream background. The cream-to-white contrast is intentionally subtle (approximately 3% luminance difference), creating a soft, layered feel rather than stark contrast.
- Shadows at 6% opacity, 4pt blur, 2pt Y-offset provide just enough elevation to distinguish card from background.
- Category color strips at full saturation.

**Dark Mode:**
- Cards use warm dark gray (#2C2924) on warm near-black (#1A1816). The warm undertone (slight brown/amber shift) distinguishes Forager from apps that use pure gray dark modes.
- Shadows increase to 12% opacity for visibility against dark backgrounds.
- Category color strips desaturate slightly (10-15%) to avoid harsh neon against dark surfaces. Use the adaptive `categoryColor(for:)` method in ForagerTheme, adjusting saturation in dark mode.
- Card backgrounds lighten with elevation (Apple's "implied light source" pattern). The scaling sheet and add-to-list sheet use a slightly lighter card background (#342F2A) to indicate they are above the main content.

### 7.2 Typography Contrast

- **Serif titles in dark mode:** Use `primaryText` (warm off-white, #EDE6DB) rather than pure white. Pure white serif text on dark backgrounds creates excessive contrast that causes eye strain during evening cooking.
- **Body text:** Use `secondaryText` for metadata and captions. Maintain WCAG AA contrast ratio (minimum 4.5:1 for body text, 3:1 for large text). The warm gray (#998F85) on warm near-black (#1A1816) achieves approximately 5.2:1.
- **Green accent text** (`accentGreen`) shifts from `forestGreen` in light mode to `springGreen` in dark mode. The darker green would be illegible on dark backgrounds.

### 7.3 Interactive Element Adaptation

| Element | Light Mode | Dark Mode |
|---|---|---|
| Primary button (CTA) | `forestGreen` bg | `leafGreen` bg (brighter for visibility) |
| Secondary button | `cream` bg, `forestGreen` border | `secondaryBackground` bg, `accentGreen` border |
| Toggle/checkbox active | `springGreen` | `springGreen` (no change needed) |
| Search bar | White bg, `pebble` border | `secondaryBackground` bg, `border` color |
| Autocomplete dropdown | White bg, shadow | `cardBackground`, stronger shadow |
| Scaling slider/pills | `mintTint` bg | `forestGreen` @ 20% bg |
| Low-confidence badge | `warning` amber | `warning` slightly brighter |

### 7.4 Elevation Hierarchy (Dark Mode)

In dark mode, elevation replaces shadow as the primary depth cue:

| Layer | Background | Use |
|---|---|---|
| Base (L0) | `primaryBackground` (#1A1816) | Page background |
| Card (L1) | `cardBackground` (#2C2924) | Recipe cards, list rows |
| Sheet (L2) | #342F2A | Bottom sheets, modals |
| Dropdown (L3) | #3D3833 | Autocomplete, menus |

Each layer adds approximately 4% white overlay, following Apple's implied-light-source model but using warm-tinted overlays instead of pure white.

---

## Implementation Priority

| Priority | Recommendation | Effort | Impact |
|---|---|---|---|
| P0 | Apply ForagerTheme colors to all recipe views | Low | High - brand consistency |
| P0 | Serif typography for recipe titles and instructions | Low | High - editorial feel |
| P1 | Card layout for recipe list | Medium | High - browsing experience |
| P1 | Full-width "Add to Grocery List" CTA on detail | Low | Medium - conversion |
| P1 | Sort/filter controls on recipe list | Medium | Medium - findability |
| P2 | Preset scaling buttons (replace slider) | Medium | Medium - usability |
| P2 | Merge preview on add-to-list | Medium | Medium - trust |
| P2 | Dark mode warm color adaptation | Medium | Medium - evening cooking |
| P3 | Progressive disclosure form flow | High | Medium - creation experience |
| P3 | Batch paste for ingredients | Medium | Low-Medium - power users |
| P3 | Cooking mode checkboxes | Low | Low - delight feature |
| P3 | Persistent scale state (Core Data, not UserDefaults) | Low | Low - convenience |

---

## Research Sources

- [Tubik Studio: Recipe Cards UI Experiments](https://uxplanet.org/ui-experiments-recipe-cards-options-in-a-food-app-36dce82d7b01)
- [Tubik Studio: Perfect Recipes App Case Study](https://blog.tubikstudio.com/case-study-recipes-app-ux-design/)
- [SideChef: UX Best Practices for Recipe Platforms](https://www.sidechef.com/business/recipe-platform/ux-best-practices-for-recipe-sites)
- [NYT Cooking Recipe Page Redesign (Suriyeseul)](https://www.suriyeseul.design/work/nyt-cooking)
- [IXD@Pratt: NYT Cooking Mobile App Design Critique](https://ixd.prattsi.org/2025/02/design-critique-nyt-cooking-mobile-app/)
- [Kitchen Stories Minimal App Design (DesignRush)](https://www.designrush.com/best-designs/apps/kitchen-stories)
- [Smashing Magazine: Designing the Perfect Slider UX](https://www.smashingmagazine.com/2017/07/designing-perfect-slider/)
- [Prototypr: Dark Mode for iOS -- The Ultimate Guide](https://blog.prototypr.io/designing-a-dark-mode-for-your-ios-app-the-ultimate-guide-6b043303b941)
- [AppInventiv: How to Design Dark Mode for Mobile App (2026)](https://appinventiv.com/blog/guide-on-designing-dark-mode-for-mobile-app/)
- [Eleken: Card UI Design Examples and Best Practices](https://www.eleken.co/blog-posts/card-ui-examples-and-best-practices-for-product-owners)
- [Figma: 31 Best Serif Fonts to Elevate Your Designs](https://www.figma.com/resource-library/best-serif-fonts/)
- [NYT Cooking Design System for Android (Editor and Publisher)](https://www.editorandpublisher.com/stories/how-the-new-times-made-a-design-system-for-nyt-cooking-on-android,175501)
