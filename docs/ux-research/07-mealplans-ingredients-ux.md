# 07 - Meal Plans & Ingredients UX Redesign

**Date:** 2026-02-14
**Screens:** MealPlansListView, MealPlanDetailView, CreateMealPlanSheet, IngredientsView
**Palette:** Forest Green (#2D5016), Leaf Green (#4A7C2E), Spring Green (#6B9B37), Cream (#F5F0E8), Sand (#EDE6D8)
**Design System:** ForagerTheme (established on `ui/design-overhaul` branch)

---

## Table of Contents

1. [Meal Plan Overview (List Screen)](#1-meal-plan-overview-list-screen)
2. [Meal Plan Detail (Calendar Layout)](#2-meal-plan-detail-calendar-layout)
3. [Generate Grocery List from Plan](#3-generate-grocery-list-from-plan)
4. [Empty States & Onboarding](#4-empty-states--onboarding)
5. [Ingredients Template Browser](#5-ingredients-template-browser)
6. [Review Workflow (needsReview)](#6-review-workflow-needsreview)
7. [Staple Management](#7-staple-management)
8. [Visual Design & Category Colors](#8-visual-design--category-colors)
9. [Light/Dark Mode](#9-lightdark-mode)
10. [Implementation Priority](#10-implementation-priority)

---

## Current State Analysis

### Meal Plans (MealPlansListView)
- Standard `InsetGroupedListStyle` with Active/Upcoming/Completed sections
- MealPlanRowView shows name, date range, and a horizontal progress bar ("X of Y days")
- Active badge is a small green pill
- Completed section uses `DisclosureGroup` (collapsed by default)
- Status colors: green (active), blue (upcoming), gray (completed) -- these are stock iOS colors, not ForagerTheme
- No visual distinction for "this week" vs other weeks
- No summary of what is planned (recipe names, fill percentage)

### Meal Plan Detail (MealPlanDetailView)
- ScrollView with VStack of `DayRowView` cards -- pure vertical list
- Each day shows: header date, inline autocomplete search field, or assigned recipe card
- Only 1 recipe per day (no breakfast/lunch/dinner slots)
- "Add All to Shopping List" button in header (green, full-width)
- Assigned recipes show blue card with checkbox, recipe name, servings, trash button
- No visual distinction for today, past days, or future days
- No drag-and-drop, no horizontal calendar navigation

### Ingredients (IngredientsView)
- Horizontal ScrollView of FilterPill components (Category, Staples, Review, Sort)
- InsetGroupedList with category sections
- Category headers have colored circle + emoji + uppercase name + count badge
- IngredientRowView: category dot, name (tap to edit inline), folder icon, pin icon
- needsReview shows yellow triangle badge
- Edit mode enables multi-select with checkmark circles
- Bulk actions: Change Category, Mark as Staples, Remove Staple Status, Delete

### Gaps Identified
- Meal plans feel like a database table, not a calendar experience
- No "at a glance" week view -- user must scroll through 7+ individual cards
- The primary action (generate grocery list) is buried inside plan detail
- Ingredients lack search bar (it was removed in M7.4 in favor of `.searchable()` — **verify current state on main branch**, as `.searchable()` may or may not have been applied since this document was written)
- No visual connection between staples and grocery list generation
- Review workflow (needsReview) is passive -- no guided merge flow
- Category colors are hardcoded in two places (IngredientsView + IngredientRowView) instead of using ForagerTheme

---

## 1. Meal Plan Overview (List Screen)

### Problem
The current list view is functional but flat. Plans are just rows in a list. Users cannot see at a glance what is planned for the current week, how full their plan is, or quickly jump to today.

### Recommendation: Weekly Summary Cards

Replace the standard list rows with richer **weekly summary cards** that provide a visual week-at-a-glance.

#### Card Layout (Active Plan)

```
+--------------------------------------------------+
|  THIS WEEK                           Feb 10 - 16  |
|                                                    |
|  Mo   Tu   We   Th   Fr   Sa   Su                |
|  [*]  [*]  [*]  [ ]  [ ]  [ ]  [ ]              |
|                                                    |
|  3 of 7 planned  |  Today: Chicken Stir Fry       |
|                                                    |
|  [ Generate Grocery List ]                         |
+--------------------------------------------------+
```

**Design details:**

- **Card container:** `ForagerTheme.cardBackground` with `radiusLG (16pt)`, subtle shadow (`foragerShadow()`), 4px left border in `forestGreen` for active plan
- **Week indicator dots:** A row of 7 small circles (one per day). Filled circle = recipe assigned. Hollow circle = empty. Today's circle has a ring highlight in `forestGreen`. Past days use `springGreen` (completed) or `stone` (missed)
- **"Today" snippet:** If today has an assigned recipe, show the recipe name in a secondary line. This answers the #1 question users have: "What am I making tonight?"
- **Active vs. Upcoming vs. Completed distinction:**
  - Active: `forestGreen` left border, full-width card, prominent
  - Upcoming: No left border, slightly smaller card, `sand` background
  - Completed: Muted opacity (0.6), `stone` text, collapsed by default (keep existing DisclosureGroup)

#### Current vs. Past Plan Hierarchy

- Active plan always appears first and takes more vertical space (include the week dots + today snippet + generate button)
- Upcoming plans show just the date range and fill indicator (compact)
- Completed plans remain in a collapsible section, show only name and date range

#### Quick Actions on Active Card

The active plan card should include two tappable actions directly on the card surface:
1. **Tap the card** to navigate to plan detail
2. **"Generate Grocery List" button** directly on the card (see Section 3)

This means users can generate their grocery list without ever entering plan detail -- a significant workflow shortcut.

### Navigation

Keep `NavigationLink` to `MealPlanDetailView` for the full card tap. The "Generate Grocery List" button uses the existing `SelectListSheet` flow but is triggered from the list view.

---

## 2. Meal Plan Detail (Calendar Layout)

### Problem
The current vertical list of day cards makes it hard to see the full week at a glance. Users must scroll to find specific days. There is no sense of temporal context (which day is today? which days are past?). Only 1 recipe per day limits meal planning flexibility.

### Recommendation: Horizontal Day Strip + Vertical Day Detail

A two-part layout inspired by Apple Calendar's week view and Plan to Eat's drag-to-plan pattern.

#### Layout Structure

```
+--------------------------------------------------+
|  < This Week                    Feb 10 - 16, 2026 |
|                                                    |
|  [Mon] [Tue] [Wed] [THU] [Fri] [Sat] [Sun]       |
|   10    11    12    *13*   14    15    16          |
|   *     *     *           *                        |
+--------------------------------------------------+
|                                                    |
|  THURSDAY, FEB 13                         TODAY    |
|                                                    |
|  +----------------------------------------------+ |
|  |  Dinner                                       | |
|  |  Chicken Stir Fry            4 servings       | |
|  |  [check] [edit servings] [swap] [remove]      | |
|  +----------------------------------------------+ |
|                                                    |
|  + Add another meal                                |
|                                                    |
+--------------------------------------------------+
|                                                    |
|  [ Add All to Shopping List ]                      |
|                                                    |
+--------------------------------------------------+
```

#### Horizontal Day Strip (Top)

> **Implementation note (validated Feb 15, 2026):** The day strip must be **fixed above the ScrollView**, not pinned inside it. SwiftUI's `pinnedViews` in `LazyVStack` only supports vertical section headers/footers — it cannot pin a horizontal strip. Use a `VStack` with the day strip as a fixed element above the `ScrollView` body:
>
> ```swift
> VStack(spacing: 0) {
>     DayStripView(days: plan.days, selectedDay: $selectedDay)  // Fixed, not scrollable
>     ScrollView {
>         LazyVStack { /* day detail sections */ }
>     }
> }
> ```
>
> This pattern ensures the strip remains visible during vertical scrolling without fighting the scroll container.

- **Fixed above** the ScrollView (not inside it — see implementation note above)
- 7 day abbreviations in a horizontal row (Mon-Sun or Sun-Sat based on locale)
- Date numbers below each day abbreviation
- **Today highlight:** Circle background in `forestGreen` with white text
- **Past days:** Text in `stone` color, slightly muted
- **Future days:** Text in `bark` (primary text)
- **Recipe indicator:** Small dot below the date number if a recipe is assigned (filled = assigned, outline = empty)
- **Tap a day** to scroll the detail section to that day
- Uses `ScrollViewReader` + `scrollTo(id:)` for programmatic scrolling

#### Why Not a Full 7x3 Grid?

A 7-column x 3-row (breakfast/lunch/dinner) grid looks great on tablets but is too cramped on iPhone. Each cell would be approximately 48pt wide -- not enough for recipe names. The horizontal strip + vertical detail pattern gives:
- At-a-glance week overview (strip)
- Full detail space for the selected day (scrollable detail)
- Room for multiple meals per day

This matches patterns from Apple Calendar (week strip), Mealime (day focus), and Plan to Eat (day-centric planning).

#### Vertical Day Detail (Scrollable Body)

Each day renders as a section with:

```swift
// Day Section Structure
VStack(alignment: .leading, spacing: ForagerTheme.spacingSM) {
    // Day header
    HStack {
        Text("THURSDAY, FEB 13")
            .foragerSectionHeader()
        Spacer()
        if isToday { TodayBadge() }
    }

    // Meal slots (if assigned)
    ForEach(mealsForDay) { meal in
        MealCard(meal: meal)
    }

    // Add recipe button
    AddRecipeButton(date: day.date)
}
```

**MealCard design:**
- `ForagerTheme.cardBackground` with `radiusMD`
- Left border strip in category color of the recipe's primary ingredient category (or `forestGreen` default)
- Recipe title in `.body` weight `.medium`
- Servings count as secondary text
- Action row: checkbox (completion), servings stepper, swap (replace recipe), remove (trash)
- Completed meals: strikethrough + reduced opacity (keep existing pattern)

**"Add recipe" inline search** remains largely the same as current `DayRowView.autocompleteSearchField`, but styled with ForagerTheme:
- Search field uses `ForagerTheme.cardBackground` with `radiusSM`
- Magnifying glass icon in `secondaryText`
- Recipe results use `forestGreen` instead of blue for the fork.knife and plus.circle icons

#### Multi-Meal Support (Future Enhancement)

The current data model supports only 1 PlannedMeal per day. For the UX redesign, keep 1-meal-per-day as the default but design the card layout to visually support adding more later. The "+ Add another meal" button is always visible below assigned meals, ready for the data model expansion.

#### Today Auto-Scroll

On `onAppear`, if the plan contains today's date, automatically scroll to today's section and highlight the day in the strip. This reduces the common friction of opening a plan and having to find the current day.

---

## 3. Generate Grocery List from Plan

### Problem
This is THE key action in the meal planning workflow. Currently it is:
- A green button inside the plan detail header
- Only visible after scrolling into the detail view
- Labeled "Add All to Shopping List" (action-oriented, good)
- Triggers `SelectListSheet` with servings adjustment

The button is well-designed but poorly placed. Most users open a meal plan to answer "What am I making?" and then want to generate a grocery list. These are the two primary use cases, yet generating a list requires navigating into the plan first.

### Recommendation: Three Placement Points

#### 3a. On the Active Plan Card (List View)

Place a prominent CTA directly on the active plan's summary card in `MealPlansListView`.

```
+--------------------------------------------------+
|  THIS WEEK                         Feb 10 - 16    |
|  Mo  Tu  We  Th  Fr  Sa  Su                       |
|  [*] [*] [*] [ ] [ ] [ ] [ ]                      |
|                                                    |
|  [cart icon]  Generate Grocery List  [>]           |
+--------------------------------------------------+
```

**Design:**
- Full-width button inside the card, below the week dots
- Background: `ForagerTheme.forestGreen`
- Text: White, `.headline` weight `.semibold`
- Icon: `cart.fill.badge.plus` (same as current)
- Only shown when the plan has at least 1 recipe assigned
- Tapping opens `SelectListSheet` directly (no navigation to detail needed)

**This is the highest-impact UX change in this document.** It removes one full navigation step from the most important user flow.

#### 3b. Sticky Bottom Bar (Detail View)

Inside `MealPlanDetailView`, replace the current header button with a **sticky bottom bar** that remains visible regardless of scroll position.

```
+--------------------------------------------------+
|  [Day strip + scrollable content above]            |
|                                                    |
+--------------------------------------------------+
|  [cart icon]  Add All to Shopping List         [>] |
+--------------------------------------------------+
```

**Design:**
- Pinned to bottom using `.safeAreaInset(edge: .bottom)` (note: since this is a static button rather than a text input, it avoids the keyboard-tracking bugs documented in doc 05 Section 4.1 — but test on physical devices)
- Background: `ForagerTheme.forestGreen` with slight translucency
- Always visible, never scrolls away
- Shows recipe count: "Add 5 recipes to list"
- Disabled state when no recipes are assigned (gray background, muted text)

#### 3c. Contextual Action on Individual Meals

For users who want to add just one day's recipe to their list (not the full plan), add a swipe action or context menu option on individual `MealCard` components:

- Swipe left on a meal card to reveal "Add to List" action
- Uses `swipeActions(edge: .trailing)` with `ForagerTheme.forestGreen` background
- Single-recipe flow skips the servings adjustment and goes straight to list selection

### Progress Overlay

Keep the existing progress overlay for bulk add operations. Update styling to use ForagerTheme:
- Progress bar tint: `ForagerTheme.forestGreen`
- Text: `ForagerTheme.primaryText` / `secondaryText`
- Background card: `ForagerTheme.cardBackground` with `radiusLG`

---

## 4. Empty States & Onboarding

### Problem
Current empty states use `StandardEmptyStateView` with blue icons -- these do not match the ForagerTheme and provide minimal guidance.

### Recommendation: Themed, Contextual Empty States

#### 4a. No Meal Plans (MealPlansListView)

```
+--------------------------------------------------+
|                                                    |
|            [calendar.badge.plus icon]              |
|            60pt, ForagerTheme.leafGreen            |
|                                                    |
|         Plan Your Week's Meals                     |
|                                                    |
|    Create a meal plan to organize dinners,         |
|    track what you're making, and generate          |
|    a grocery list with one tap.                    |
|                                                    |
|    +------------------------------------------+   |
|    |  Your plan will:                          |   |
|    |  [calendar] Last 7 days                   |   |
|    |  [calendar.day] Start on Monday           |   |
|    |  [cart] Generate grocery lists             |   |
|    +------------------------------------------+   |
|                                                    |
|    [ Create Your First Plan ]                      |
|    ForagerPrimaryButtonStyle                       |
|                                                    |
+--------------------------------------------------+
```

**Changes from current:**
- Icon color: `ForagerTheme.leafGreen` (not `.blue`)
- Title: "Plan Your Week's Meals" (benefit-oriented, not "No Meal Plans Yet")
- Subtitle: Explains the value proposition with the grocery list connection
- Info card uses `ForagerTheme.sand` background, not `secondarySystemGroupedBackground`
- Button uses `ForagerPrimaryButtonStyle` (forestGreen background)
- Remove the "Change meal plan settings" link -- settings are accessible from the tab, not needed here

#### 4b. Empty Day in Plan Detail

When a day has no recipe assigned:

```
+--------------------------------------------------+
|  WEDNESDAY, FEB 12                                 |
|                                                    |
|  [magnifying glass] Search recipes...              |
|                                                    |
|  or browse your recipe collection                  |
+--------------------------------------------------+
```

- Keep the inline search field (current pattern works well)
- Add a subtle "or browse your recipe collection" link below the search field that navigates to the Recipes tab (deep link)
- Empty day cards use `ForagerTheme.sand` background (lighter than filled day cards) to create visual contrast between planned and unplanned days

#### 4c. No Recipes Available (Autocomplete Returns Empty)

When search yields no results:

```
No recipes matching "tacos"
[Create a new recipe?]
```

- Link to recipe creation flow (if available)
- Or suggest: "Try searching for something else"

#### 4d. First-Time Onboarding Hint

On the very first meal plan creation, add a coach mark or subtle hint:

```
Tip: After planning your meals, tap "Generate Grocery List"
to create your shopping list automatically.
```

This can be a dismissible banner at the top of the detail view, shown only once (tracked via UserDefaults).

---

## 5. Ingredients Template Browser

### Problem
The Ingredients screen currently displays 100+ items in an `InsetGroupedList` with category sections. Browsing is functional but has several UX issues:
- Search was removed from the view (M7.4 notes `.searchable()` pattern) but `.searchable()` is never actually applied to the NavigationStack
- Filter pills scroll horizontally but compete for attention with the list
- Category dropdown is a `Menu` -- user cannot see all categories at once
- All ingredients appear in one long list regardless of whether the user is browsing, reviewing, or managing staples

### Recommendation: Search + Segmented Browsing

#### 5a. Restore Search

> **Status note (validated Feb 15, 2026):** Verify whether `.searchable()` has been applied to `IngredientsView` on the current `main` branch before implementing. The M7.4 notes indicated the old search bar was removed in favor of `.searchable()`, but this may or may not have been completed. Check `IngredientsView.swift` for an existing `.searchable()` modifier.

If not already present, add `.searchable(text: $searchText, prompt: "Search ingredients")` to the view. This provides:
- Native iOS search bar that integrates with the navigation bar
- Keyboard dismiss on scroll
- Clear button built in
- Consistent with Apple's HIG and the rest of the app

```swift
.searchable(text: $searchText, prompt: "Search ingredients")
```

This is a critical fix -- with 100+ items, scrolling without search is not viable.

#### 5b. Filter Pill Bar Improvements

Keep the horizontal filter pill bar but refine it:

**Current pills:** All Categories | Staples | Review (N) | Sort
**Recommended pills:** All | [Produce] [Dairy] [Meat] ... | Staples | Review (N)

Changes:
- Replace the "All Categories" dropdown Menu with **individual category pills** that appear inline. With 6 categories, all pills fit in a single horizontal scroll row
- Each category pill shows the category color dot and abbreviated name
- Tapping a category pill filters to that category (toggle behavior -- tap again to deselect)
- Move Sort into the toolbar as a `Menu` (sort is a secondary action, not a filter)
- Active pill uses `ForagerTheme.forestGreen` fill (already done on design-overhaul branch)
- Inactive pill uses `ForagerTheme.sand` fill

**Pill layout:**

```
[ All ] [ Produce ] [ Dairy ] [ Meat ] [ Bread ] [ Boxed ] [ Snacks ] [ Staples ] [ Review (3) ]
```

Each category pill shows a 6pt colored circle before the text, using `ForagerTheme.categoryColor(for:)`.

#### 5c. List Organization

Keep the current grouped-by-category list layout with section headers. This is well-structured and familiar. Improvements:

- **Section headers:** Use `ForagerTheme.categoryColor` left border strip (via `.categoryStrip()` modifier) instead of the current circle+emoji pattern. The emoji approach does not scale well and competes visually with the category dot on each row
- **Item count badge:** Keep the count badge but style with `ForagerTheme.pebble.opacity(0.3)` background (matches design-overhaul branch)
- **Sticky section headers:** Ensure `Section` headers are sticky during scroll (default behavior with `List` + `InsetGroupedListStyle`)

#### 5d. Alphabetical Index (Optional Enhancement)

For 100+ items, consider adding a section index (the A-Z scrubber on the right edge of the list). This requires switching to alphabetical primary sort when the "A-Z" sort option is active. SwiftUI `List` supports section index via the `sectionHeader` approach.

---

## 6. Review Workflow (needsReview)

### Problem
The current `needsReview` system is passive: a yellow triangle appears next to flagged items, and users must tap the name to edit. There is no guided flow for reviewing multiple items. Users must find flagged items by scrolling or using the Review filter pill.

### Recommendation: Guided Review Mode

#### 6a. Review Banner

When `needsReviewCount > 0`, show a banner at the top of IngredientsView (above the filter pills):

```
+--------------------------------------------------+
|  [!] 3 ingredients need review                     |
|      Names may contain quantities or qualifiers    |
|                                                    |
|      [ Review Now ]                                |
+--------------------------------------------------+
```

**Design:**
- Background: `ForagerTheme.warning.opacity(0.1)` (warm amber tint)
- Icon: `exclamationmark.triangle.fill` in `ForagerTheme.warning`
- "Review Now" button in `ForagerTheme.forestGreen`
- Dismissible (X button) but reappears if new items are flagged
- Auto-hides when `needsReviewCount == 0`

#### 6b. Review Sheet (Guided Flow)

Tapping "Review Now" opens a dedicated review sheet that presents flagged items one at a time:

```
+--------------------------------------------------+
|  Review Ingredients               1 of 3    [X]   |
+--------------------------------------------------+
|                                                    |
|  Current name:                                     |
|  "2 cups flour, all-purpose"                       |
|                                                    |
|  Suggested name:                                   |
|  [ Flour, All-Purpose          ]  <-- editable     |
|                                                    |
|  Category: [ Boxed & Canned  v ]                   |
|  Staple:   [ ] Mark as staple                      |
|                                                    |
|  +----------------------------------------------+ |
|  | Similar items in your collection:             | |
|  | - All-Purpose Flour (Boxed & Canned)          | |
|  |   [ Merge into this ]                         | |
|  +----------------------------------------------+ |
|                                                    |
|  [ Skip ]                    [ Save & Next ]       |
+--------------------------------------------------+
```

**Key features:**
- **One item at a time:** Reduces cognitive load. User sees the current name, suggested cleaned name, and options
- **Suggested name:** Auto-strip quantities and qualifiers using existing `extractCleanIngredientName()` logic
- **Merge detection:** Query for existing templates with similar canonical names. If found, show "Merge into this" option that uses the existing merge-on-rename logic from `IngredientRowView.saveNameEdit()`
- **Skip:** Move to next item without changes
- **Save & Next:** Apply changes and advance
- **Progress indicator:** "1 of 3" counter at top
- **Batch completion:** After all items reviewed, show success state with count of renamed/merged items

#### 6c. Inline Review Indicators

Keep the yellow triangle badge on rows but enhance it:
- Add a tooltip on long press: "Name may contain quantities -- tap to edit"
- When the Review filter is active, highlight the entire row with a faint `warning.opacity(0.05)` background to draw attention

---

## 7. Staple Management

### Problem
Staples are a powerful feature (items you always have on hand, used for auto-generating grocery lists) but the connection between staples and grocery list generation is not visually communicated. Users may not understand why they should mark items as staples.

### Recommendation: Staple Section + Generation Link

#### 7a. Staples Summary Header

When the Staples filter is active, show a summary header above the list:

```
+--------------------------------------------------+
|  STAPLE ITEMS                         12 items     |
|                                                    |
|  These items are always on your shopping list.     |
|  Generate a grocery list from staples to start     |
|  your weekly shopping.                             |
|                                                    |
|  [ Generate from Staples ]                         |
+--------------------------------------------------+
```

**Design:**
- Background: `ForagerTheme.mintTint`
- "Generate from Staples" button uses `ForagerSecondaryButtonStyle` (cream background, forestGreen text and border)
- Connects to the existing "Generate from Staples" flow in WeeklyListsView

This creates a clear mental model: **Staples = your baseline shopping list.**

#### 7b. Staple Toggle Improvements

Current: Pin icon (filled orange for staples, outline gray for non-staples)

**Enhancements:**
- Keep the pin metaphor (users understand it)
- Add a subtle animation when toggling: pin icon rotates 45 degrees and changes color
- Update colors to ForagerTheme: `ForagerTheme.categoryBread` for active (warm amber/orange from the design-overhaul branch) and `ForagerTheme.stone` for inactive
- On toggle, show a brief toast/snackbar: "Olive Oil added to staples" or "Olive Oil removed from staples"

#### 7c. Bulk Staple Management

The current bulk "Mark as Staples" / "Remove Staple Status" in edit mode is good. Keep it. Add:
- A "Select All in Category" option when edit mode is active and a category filter is selected
- Quick action: Long-press a category header to mark/unmark all items in that category as staples

#### 7d. Staples Badge on Tab

Consider adding a badge on the Ingredients tab icon showing the number of items flagged for review (not staple count). This draws attention to maintenance tasks without being intrusive.

---

## 8. Visual Design & Category Colors

### Problem
Category colors are defined in two separate places (IngredientsView and IngredientRowView) using stock SwiftUI colors. The design-overhaul branch centralizes these in `ForagerTheme.categoryColor(for:)` with warmer tones. The current main branch needs to adopt these.

### Recommendation: Unified Category Color System

#### 8a. Color Mapping (ForagerTheme)

Use the colors already defined on the design-overhaul branch:

| Category | Current (main) | Recommended (ForagerTheme) | Hex |
|---|---|---|---|
| Produce | `.green` | `categoryProduce` | #5B9A3C |
| Deli & Meat | `.red` | `categoryMeat` | #C4402F |
| Dairy & Fridge | `.blue` | `categoryDairy` | #3D7A9C |
| Bread & Frozen | `.orange` | `categoryBread` | #D4882E |
| Boxed & Canned | `.brown` | `categoryBoxed` | #8B6F4E |
| Snacks, Drinks, & Other | `.purple` | `categorySnacks` | #7B5EA7 |
| Uncategorized | `.gray` | `stone` | #7A7067 |

These are warmer and more muted than stock iOS colors, fitting the earthy Forager brand.

#### 8b. Category Indicator Patterns

Three levels of category color usage:

1. **Dot indicator** (12pt circle): Used on ingredient rows to show category at a glance
2. **Section header strip** (4pt left border): Used on category section headers via `.categoryStrip()` modifier
3. **Section background tint** (category color at 0.08 opacity): Subtle background tint on section headers (already implemented on design-overhaul branch)

#### 8c. Emoji Removal

The current category headers use emojis inside small circles. This is problematic:
- Emojis render inconsistently across iOS versions
- At 10pt font size, emojis are illegible
- Emojis add visual noise

**Recommendation:** Remove emojis from category headers. The colored dot + category name is sufficient for identification. If a visual icon is desired, use SF Symbols instead:

| Category | SF Symbol |
|---|---|
| Produce | `leaf.fill` |
| Deli & Meat | `flame.fill` |
| Dairy & Fridge | `snowflake` |
| Bread & Frozen | `takeoutbag.and.cup.and.straw.fill` |
| Boxed & Canned | `archivebox.fill` |
| Snacks & Other | `cup.and.saucer.fill` |

#### 8d. Filter Pill Theming

Update FilterPill to use ForagerTheme consistently:

```swift
// Active state
.background(ForagerTheme.forestGreen)  // not .accentColor
.foregroundColor(.white)

// Inactive state
.background(ForagerTheme.sand)  // not .secondarySystemBackground
.foregroundColor(ForagerTheme.primaryText)
.overlay(ForagerTheme.border)  // not Color(.separator)
```

Category-specific pills should show a subtle tint of their category color when active:
```swift
.background(isSelected ? ForagerTheme.categoryColor(for: name).opacity(0.8) : ForagerTheme.sand)
```

---

## 9. Light/Dark Mode

### Problem
The current main branch uses stock iOS system colors (`Color(UIColor.secondarySystemGroupedBackground)`, `Color(.systemGray5)`, etc.) which provide automatic light/dark support but do not match the Forager brand. The design-overhaul branch defines adaptive colors in `ForagerTheme` but they need to be applied to these screens.

### Recommendation: ForagerTheme Adaptive Colors

#### 9a. Meal Plans -- Light Mode

| Element | Color |
|---|---|
| Background | `ForagerTheme.primaryBackground` (cream #F5F0E8) |
| Card background | `ForagerTheme.cardBackground` (white) |
| Active plan border | `ForagerTheme.forestGreen` (#2D5016) |
| Section headers | `ForagerTheme.forestGreen` uppercase text |
| Day strip background | `ForagerTheme.sand` (#EDE6D8) |
| Today circle | `ForagerTheme.forestGreen` fill, white text |
| Progress dots (filled) | `ForagerTheme.springGreen` (#6B9B37) |
| Progress dots (empty) | `ForagerTheme.pebble` (#D4CBC0) |
| Recipe card | `ForagerTheme.mintTint` (#E8F0E0) with `forestGreen` border |
| Generate List button | `ForagerTheme.forestGreen` fill, white text |

#### 9b. Meal Plans -- Dark Mode

| Element | Color |
|---|---|
| Background | `ForagerTheme.primaryBackground` (dark: #1A1714) |
| Card background | `ForagerTheme.cardBackground` (dark: #2B2924) |
| Active plan border | `ForagerTheme.accentGreen` (brighter green for contrast) |
| Section headers | `ForagerTheme.accentGreen` uppercase text |
| Day strip background | `ForagerTheme.secondaryBackground` (dark: #242220) |
| Today circle | `ForagerTheme.accentGreen` fill, dark text |
| Progress dots (filled) | `ForagerTheme.springGreen` |
| Progress dots (empty) | `ForagerTheme.border` (dark: #3F3B38) |
| Recipe card | `ForagerTheme.forestGreen.opacity(0.15)` with `accentGreen` border |
| Generate List button | `ForagerTheme.accentGreen` fill, dark text |

#### 9c. Ingredients -- Light Mode

| Element | Color |
|---|---|
| Background | `ForagerTheme.primaryBackground` (cream) |
| Filter pills (active) | `ForagerTheme.forestGreen` fill |
| Filter pills (inactive) | `ForagerTheme.sand` fill |
| Category header bg | Category color at 0.08 opacity |
| Category header text | `ForagerTheme.forestGreen` |
| Ingredient row text | `ForagerTheme.primaryText` (bark #2C2418) |
| Pin icon (staple) | `ForagerTheme.categoryBread` (#D4882E) |
| Pin icon (non-staple) | `ForagerTheme.stone` (#7A7067) |
| Review badge | `ForagerTheme.warning` (#D4A017) |

#### 9d. Ingredients -- Dark Mode

| Element | Color |
|---|---|
| Background | `ForagerTheme.primaryBackground` (dark) |
| Filter pills (active) | `ForagerTheme.accentGreen` fill |
| Filter pills (inactive) | `ForagerTheme.secondaryBackground` fill |
| Category header bg | Category color at 0.12 opacity (slightly stronger for dark) |
| Category header text | `ForagerTheme.accentGreen` |
| Ingredient row text | `ForagerTheme.primaryText` (dark: #EDE6DB) |
| Pin icon (staple) | `ForagerTheme.categoryBread` (same -- amber reads well on dark) |
| Pin icon (non-staple) | `ForagerTheme.secondaryText` |
| Review badge | `ForagerTheme.warning` (same -- amber reads well on dark) |

#### 9e. Key Principles

1. **Never use stock `.blue` or `.green` for interactive elements.** Use `ForagerTheme.forestGreen` / `accentGreen` and `ForagerTheme.leafGreen` instead
2. **Backgrounds should be warm**, not pure white or pure black. The cream/bark spectrum gives Forager its identity
3. **Category colors are constant** across light and dark mode -- they are already designed to work on both backgrounds
4. **Use the adaptive color properties** (`ForagerTheme.primaryBackground`, `.cardBackground`, etc.) which already contain `UIColor { traits in ... }` closures for automatic mode switching
5. **Test contrast ratios** -- ensure text on colored backgrounds meets WCAG AA (4.5:1 for body text, 3:1 for large text). The ForagerTheme colors were designed with this in mind

---

## 10. Implementation Priority

### Tier 1: High Impact, Low Effort (Do First)

| Change | Screen | Impact | Effort |
|---|---|---|---|
| Add `.searchable()` to IngredientsView | Ingredients | Critical -- 100+ items unsearchable | 1 line of code |
| Move "Generate Grocery List" to active plan card | Meal Plans List | Eliminates 1 navigation step from primary flow | Small (extract button + pass data) |
| Apply ForagerTheme colors to both screens | Both | Brand consistency | Medium (systematic color replacement) |
| Remove emojis from category headers | Ingredients | Cleaner visual design | Small |
| Fix FilterPill to use ForagerTheme | Ingredients | Brand consistency | Small |

### Tier 2: Moderate Impact, Moderate Effort

| Change | Screen | Impact | Effort |
|---|---|---|---|
| Weekly summary cards for plan list | Meal Plans List | Better at-a-glance overview | Medium (new card component) |
| Horizontal day strip in plan detail | Meal Plan Detail | Calendar feel, today auto-scroll | Medium (new strip component) |
| Review banner + guided review sheet | Ingredients | Reduces template clutter | Medium (new sheet) |
| Staples summary header | Ingredients | Connects staples to grocery generation | Small-Medium |
| Sticky bottom bar for "Generate List" | Meal Plan Detail | Always-visible primary CTA | Small |

### Tier 3: Polish & Future Enhancement

| Change | Screen | Impact | Effort |
|---|---|---|---|
| Individual category pills (not dropdown) | Ingredients | Faster category filtering | Medium |
| Today auto-scroll in plan detail | Meal Plan Detail | Convenience | Small |
| Swipe-to-add-to-list on individual meals | Meal Plan Detail | Power user feature | Medium |
| Alphabetical section index (A-Z scrubber) | Ingredients | Faster browsing at scale | Medium |
| Multi-meal per day support | Meal Plan Detail | Feature expansion | Large (data model change) |
| Coach marks for first-time users | Both | Onboarding | Medium |
| Drag-and-drop recipe reordering | Meal Plan Detail | Desktop-quality interaction | Large |

---

## Competitive Reference

| App | Calendar UX | Grocery Integration | Ingredient Management |
|---|---|---|---|
| **Mealime** | Weeknight-focused, no full calendar in free tier | Auto-generated list, Instacart integration | Minimal -- focuses on recipes |
| **Plan to Eat** | Full calendar with drag-drop, reusable meal plans | Auto grocery list from plan, one-click | Recipe-centric ingredient parsing |
| **Paprika** | Calendar view with meal categories | Grocery list from recipes | Category-based pantry |
| **Forager (current)** | Vertical day list, no calendar feel | "Add All to Shopping List" in detail | Category groups with filter pills |
| **Forager (proposed)** | Day strip + vertical detail, today highlight | CTA on list card + sticky bottom bar | Search + guided review + staple link |

---

## Sources

- [Plan to Eat - Meal Planner](https://www.plantoeat.com/tour/meal-planner/)
- [Mealime - Meal Planning App](https://www.mealime.com/)
- [Calendar UI Examples: 33 Inspiring Designs](https://www.eleken.co/blog-posts/calendar-ui)
- [UX Case Study: Meal Planner App (Medium)](https://medium.com/@teenatomy/ux-case-study-meal-planner-app-b0aec02f274f)
- [Meal Planner App UI Kit (Figma)](https://www.figma.com/community/file/1042726207857424115/meal-planner-app-ui-kit)
- [HorizonCalendar - iOS Calendar Component (GitHub)](https://github.com/airbnb/HorizonCalendar)
- [Building Calendar in SwiftUI (Swift with Majid)](https://swiftwithmajid.com/2020/05/06/building-calendar-without-uicollectionview-in-swiftui/)
- [Your Pantry UX Redesign (Keeley Ireland)](https://www.keeleyireland.com/your-pantry-ux-redesign)
- [Wholesum - Managing Duplicate Ingredients](https://wholesum.app/support_articles/26)
- [ReciPal - Replacing and Merging Ingredients](https://www.recipal.com/blog/features/replacing-and-merging-ingredients)
- [Case Study: Perfect Recipes App (Tubik Studio)](https://blog.tubikstudio.com/case-study-recipes-app-ux-design/)
- [Best Meal Planning Apps for 2025](https://ai-mealplan.com/blog/best-meal-planning-apps)
- [MealFlow: Top Meal Planning App with Grocery List](https://www.mealflow.ai/blog/meal-planning-app-with-grocery-list)
