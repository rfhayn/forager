# 05: Grocery Lists Screen -- UX Design Recommendations

**Created**: February 14, 2026
**Screen**: Grocery Lists (WeeklyListsView + GroceryListDetailView)
**Role**: PRIMARY daily-use screen -- the screen users open while pushing a cart
**Current Files**: `WeeklyListsView.swift`, `GroceryListDetailView.swift`, `AddListItemView.swift`
**Design System**: `ForagerTheme.swift` (forest green palette, warm neutrals, rounded typography)

---

## Table of Contents

1. [Design Principles](#1-design-principles)
2. [List Overview (WeeklyListsView)](#2-list-overview-weeklylistsview)
3. [Shopping Mode (GroceryListDetailView)](#3-shopping-mode-grocerylistdetailview)
4. [Adding Items](#4-adding-items)
5. [Item States](#5-item-states)
6. [Empty States](#6-empty-states)
7. [Micro-Interactions](#7-micro-interactions)
8. [Light and Dark Mode](#8-light-and-dark-mode)
9. [Current Implementation Audit](#9-current-implementation-audit)
10. [Research Sources](#10-research-sources)

---

## 1. Design Principles

### The Shopping Context

Forager users interact with the Grocery Lists screen in a very specific physical context: they are standing in a store, often pushing a cart with one hand, phone in the other, children nearby, mentally tracking a budget, and navigating aisles. Every design decision must respect this reality.

**Core principles for this screen:**

| Principle | Rationale |
|-----------|-----------|
| **One-thumb operable** | The user's other hand is on a cart handle, holding a child, or carrying a basket. All primary actions must live in the bottom 40% of the screen (the natural thumb arc). |
| **Glanceable** | Users look at their phone for 1-2 seconds between scanning shelves. Information hierarchy must be instantly parseable: what do I need, where is it, have I got it. |
| **Forgiving** | Accidental taps happen when your hand is unsteady. Undo must be trivial. Destructive actions need confirmation. |
| **Satisfying** | Checking off items is the core loop. It must *feel good* -- haptic, visual, and auditory feedback should create a micro-reward that keeps the user engaged. |
| **Low cognitive load** | Category grouping mirrors the physical store layout. The user should never have to think about where an item is in the list -- the list should match the aisle they are standing in. |

### Thumb Zone Reference

On a 6.7-inch iPhone (Pro Max), thumb reachability from a right-hand grip:

```
+---------------------------+
|                           |  <-- "Stretch zone" -- avoid primary actions here
|     (navigation bar)      |
|                           |
|---------------------------|
|                           |  <-- "Reach zone" -- secondary actions OK
|     (scrollable list)     |
|                           |
|---------------------------|
|                           |  <-- "Natural zone" -- primary actions MUST live here
|  (quick add, check-off,   |
|   category headers)       |
+---------------------------+
     Bottom 40% of screen
```

---

## 2. List Overview (WeeklyListsView)

### 2.1 Current State

The current implementation shows a flat `List` with `InsetGroupedListStyle`. Each row (`WeeklyListRowView`) displays the list name, creation date, a linear progress bar, and item counts. Creation uses a `+` toolbar button that generates from staples.

### 2.2 Recommended: Card-Based Layout with Progress Rings

**Replace the flat list rows with cards using `ForagerProgressRing`** (already defined in `ForagerTheme.swift` but unused on this screen).

```
+--------------------------------------------------+
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |  [Progress    "Weekly Shopping"            |  |
|  |    Ring ]     Feb 14, 2026                 |  |
|  |   67%         18 of 27 items       >       |  |
|  |                                            |  |
|  |  [Produce: 3] [Dairy: 5] [Meat: 2]        |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
|  +--------------------------------------------+  |
|  |                                            |  |
|  |  [Progress    "Costco Run"                 |  |
|  |    Ring ]     Feb 12, 2026                 |  |
|  |   100%        12 of 12 items   checkmark   |  |
|  |                                            |  |
|  +--------------------------------------------+  |
|                                                  |
+--------------------------------------------------+
```

**Specific recommendations:**

| Element | Current | Recommended |
|---------|---------|-------------|
| Progress indicator | Linear `ProgressView` bar | `ForagerProgressRing` (48pt, `forestGreen` to `springGreen` gradient). The ring is already built in `ForagerTheme.swift` and is far more glanceable than a thin bar. |
| Card surface | Default `List` row | `.foragerCard()` modifier with `ForagerTheme.cardBackground`. Provides elevation, warmth, and touch target clarity. |
| Category preview | None | Mini category pills below the title showing 2-3 most populated categories with item counts. Uses `ForagerTheme.categoryColor(for:)` as pill background at 15% opacity. Gives the user a quick sense of what the trip involves. |
| Completed lists | Green checkmark icon | Dim the entire card to 60% opacity, show a muted `springGreen` progress ring at 100%, and move completed lists to a collapsible "Completed" section at the bottom. |
| Typography | `.headline` + `.caption` | Use `ForagerTheme.displayFont(.headline)` for list name (rounded, warm) and `ForagerTheme.bodyFont(.caption)` for metadata. |
| Creation date | `Text(date, style: .date)` | Relative time: "Today", "Yesterday", "3 days ago" for recent lists; full date for older ones. More useful at a glance. |

### 2.3 List Creation Flow

**Current:** Tapping `+` immediately generates a list from staples with no user input.

**Recommended: Action sheet with three creation paths:**

```
+------------------------------------------+
|                                          |
|         Create a New List                |
|                                          |
|  [cart icon]  From Staples               |
|  Auto-generate from your staple items    |
|                                          |
|  [fork.knife] From Meal Plan             |
|  Generate from this week's planned meals |
|                                          |
|  [square.and.pencil] Empty List          |
|  Start from scratch                      |
|                                          |
|  ----                                    |
|  Cancel                                  |
|                                          |
+------------------------------------------+
```

**Rationale:** The meal plan integration is a key Forager differentiator. Surfacing it at creation time makes the connection between meal planning and grocery shopping explicit. An empty list option serves power users who curate manually.

**Naming:** When creating from staples or meal plan, pre-fill the name with a smart default ("Weekly Shopping -- Feb 14" or "Meals for Feb 14-20") but let the user edit it before confirming. The current auto-naming is fine for v1 but users will want to distinguish between "Costco Run" and "Trader Joe's".

### 2.4 Visual Hierarchy

```
Z-order (front to back):
1. Progress ring (draws the eye first -- "how done am I?")
2. List name (what is this list?)
3. Category pills (what kind of shopping is this?)
4. Date and item count (metadata, lowest priority)
```

Use `ForagerTheme.primaryText` (bark) for the list name, `ForagerTheme.secondaryText` (stone) for metadata, and `ForagerTheme.accentGreen` for the progress ring.

---

## 3. Shopping Mode (GroceryListDetailView)

This is the most critical screen in the entire app. The user is actively shopping. Every pixel matters.

### 3.1 One-Handed Usability

**Problem with current layout:** The quick-add field is at the TOP of the screen (below the progress header), which is the hardest area to reach one-handed. The toolbar `+` button is in the top-right corner -- the single worst position for right-handed thumb reach.

**Recommended layout (top to bottom):**

```
+------------------------------------------+
|  < Back     Weekly Shopping    [sort]     |  <-- Nav bar (system-managed)
|                                          |
|  ==========================================
|  |  Produce (3/5)              [v]  |    |  <-- Collapsible category header
|  ==========================================
|  |  [ ]  Bananas          6         |    |  <-- Item row (large tap target)
|  |  [ ]  Avocados         3         |    |
|  |  [x]  ~~Spinach~~      1 bag     |    |  <-- Checked item
|  ==========================================
|  |  Dairy & Fridge (0/4)       [v]  |    |
|  ==========================================
|  |  [ ]  Milk             1 gal     |    |
|  |  [ ]  Greek Yogurt     2         |    |
|  |  [ ]  Butter           1 lb      |    |
|  |  [ ]  Eggs             1 doz     |    |
|  ==========================================
|                                          |
|  +--------------------------------------+|
|  | [icon] Quick add...          [+]     ||  <-- BOTTOM quick-add bar
|  +--------------------------------------+|
|                                          |
|  [ 14/27 complete =====>........  52% ]  |  <-- Sticky bottom progress
+------------------------------------------+
```

**Key changes:**

| Change | Rationale |
|--------|-----------|
| **Move quick-add to BOTTOM** | The add bar should be a sticky footer above the progress indicator. This puts it squarely in the thumb zone. The current top placement requires the user to reach up. |
| **Sticky bottom progress** | The progress bar should be pinned to the bottom, always visible, so the user can glance at completion status without scrolling. Currently it is at the top and scrolls away. |
| **Remove "Complete All" from header** | Move to a context menu or long-press on the progress bar. "Complete All" is a dangerous action that should not be casually reachable. |
| **Enlarge check-off targets** | The checkbox tap target should be at minimum 44x44pt (Apple HIG minimum), ideally 48x48pt. Currently uses `.title2` icon size which is correct but the `ButtonStyle(BorderlessButtonStyle())` may not provide adequate padding. |
| **Full-row tap to check** | In addition to the checkbox button, tapping anywhere on the item row should toggle completion. Users in a hurry tap imprecisely. |

### 3.2 Check-Off Interaction

This is the single most important micro-interaction in Forager. It happens 20-50 times per shopping trip and must feel *crisp and rewarding*.

**Recommended multi-sensory check-off sequence (synchronized, ~300ms total):**

```
Frame 0ms:   User taps item row
Frame 0ms:   Haptic: UIImpactFeedbackGenerator(.medium).impactOccurred()
Frame 0-50:  Checkbox morphs: empty circle -> filled checkmark (scale 0.8 -> 1.1 -> 1.0)
Frame 0-200: Text color fades: ForagerTheme.primaryText -> ForagerTheme.secondaryText (0.5 opacity)
Frame 0-200: Strikethrough animates left-to-right across item name
Frame 0-200: Quantity text fades to match
Frame 200-300: Row background tints: clear -> ForagerTheme.mintTint (very subtle green wash)
Frame 300+:  Item remains in place (does NOT immediately move to bottom)
```

**Uncheck sequence (reversed, faster ~200ms):**

```
Frame 0ms:   User taps checked item
Frame 0ms:   Haptic: UIImpactFeedbackGenerator(.light).impactOccurred()  (lighter = "undo")
Frame 0-150: Checkbox morphs: filled -> empty (scale 1.0 -> 0.9 -> 1.0)
Frame 0-150: Text restores to full color, strikethrough retracts right-to-left
Frame 0-150: Row background clears
```

**Implementation notes:**
- Use `UIImpactFeedbackGenerator` (not `UINotificationFeedbackGenerator`) for check-off. The impact style gives a single clean "thunk" that feels like ticking off a physical checklist.
- The `.medium` weight for check and `.light` for uncheck creates an asymmetric feedback loop where checking feels more substantial than unchecking -- this subtly encourages forward progress.
- Synchronize the haptic with the visual peak of the checkbox animation (the moment it reaches 1.1x scale). This is critical for perceived responsiveness.

### 3.3 Category Grouping

**Current:** Categories render as standard `Section` headers with `categoryName` and `completedCount/totalCount`. No collapse. No color coding. No category-level progress.

**Recommended: Collapsible, color-coded category sections:**

```
+---------------------------------------------------+
|  [4px color bar]  Produce  (3/5)  [chevron.down]  |
+---------------------------------------------------+
```

Each category header should include:

| Element | Spec |
|---------|------|
| **Color accent strip** | 4pt-wide vertical bar on the leading edge using `ForagerTheme.categoryColor(for:)`. Use the `.categoryStrip()` modifier already defined in ForagerTheme. |
| **Category name** | `ForagerTheme.bodyFont(.headline)`, `ForagerTheme.primaryText` |
| **Progress fraction** | `(completed/total)` in `ForagerTheme.secondaryText` |
| **Collapse chevron** | `chevron.down` / `chevron.right` with rotation animation. Tap target is the entire header row. |
| **Category completion state** | When all items in a category are checked, the header dims slightly and the color strip changes to `ForagerTheme.springGreen`. This gives "section done" feedback without removing the section. |

**Collapse behavior:**
- Default state: all sections expanded (user is shopping and needs to see everything)
- Tapping a category header collapses/expands that section with a `.spring(response: 0.3, dampingFraction: 0.8)` animation
- Completed categories auto-collapse after a 2-second delay (configurable in settings). This progressively simplifies the list as the user shops.
- A "Collapse Completed" button in the toolbar (or progress bar context menu) collapses all fully-checked categories at once

**Category sort order:** Categories should sort by the user's custom `Category.sortOrder` (already implemented) so the list can match their store's physical layout. This is the current behavior and should be preserved.

### 3.4 Item Layout

**Current item row structure:**

```
[checkbox]  [name] [low-confidence badge]  (quantity)
            [recipe source badges]
            [merged source text]
```

**Recommended enhanced layout:**

```
+------------------------------------------------------+
| [O]  Chicken Breast                    2 lbs         |
|      From: Chicken Stir-Fry                          |
+------------------------------------------------------+
```

| Element | Current | Recommended |
|---------|---------|-------------|
| **Checkbox** | `circle` / `checkmark.circle.fill`, `.title2`, green/gray | Keep the icon pair. Add scale animation on toggle. Use `ForagerTheme.springGreen` for the filled state instead of system `.green`. |
| **Item name** | `.body.fontWeight(.medium)` | `ForagerTheme.bodyFont(.body).fontWeight(.medium)`. Max 2 lines with truncation. |
| **Quantity display** | Parenthesized after name: `(2 cups)`. Hidden when `displayText == "1"`. | Move quantity to trailing edge, right-aligned, in `ForagerTheme.secondaryText`. Drop the parentheses. Format: `2 cups`, `1 lb`, `6`. When `displayText == "1"`, show nothing (current behavior is correct). |
| **Source recipe** | Blue pill badges below name | Keep the pills but reduce visual weight. Use `ForagerTheme.info` at 10% opacity background with `ForagerTheme.info` text instead of system blue. Only show for recipe-sourced items (current filter is correct). |
| **Low-confidence badge** | Yellow warning triangle, visible below 0.7 | Acceptable. Consider replacing the triangle with a subtle dotted underline on the item name -- less alarming, still discoverable. The warning icon may cause anxiety in a shopping context. |
| **Row height** | Varies by content | Minimum 56pt for comfortable touch targets. Pad vertically with `ForagerTheme.spacingSM` (8pt) top and bottom. |

### 3.5 Checked Items Behavior

**Current:** Checked items stay in place within their category section. No reordering.

**Recommended: Keep in place (with visual de-emphasis):**

Checked items should remain in their current position within the category section rather than moving. The visual de-emphasis (strikethrough, 50% opacity, green tint) provides sufficient differentiation.

> **Design note (validated Feb 15, 2026):** A "sink-to-bottom with delay" pattern was originally considered here but is **not recommended** for Forager. The app uses `@FetchRequest` for live Core Data updates, which controls the sort order of list items. Implementing a delayed reorder would conflict with `@FetchRequest`'s automatic re-sorting behavior — the view would fight against Core Data's sort descriptors, causing items to snap between positions unpredictably. The alternatives (removing `@FetchRequest` in favor of manual array management, or using a secondary "display order" property) both introduce significant complexity and potential sync issues with CloudKit.

**Instead, rely on these visual signals for checked items:**
1. Immediate strikethrough animation + opacity reduction to 50% (see Section 3.2)
2. Green-tinted row background (`ForagerTheme.mintTint` at 30% opacity)
3. If ALL items in a category are checked, the category auto-collapses (with the 2-second delay mentioned in 3.3)

**Why keep items in place?** Users sometimes shop out of order and need to visually confirm they have everything *in a specific aisle* before moving on. Keeping checked items within their category preserves the spatial relationship with the store layout. The visual de-emphasis is strong enough that checked items recede without needing to physically move.

### 3.6 Progress Indication

**Current:** A custom progress bar at the top of the view with item count, percentage, and a "Complete All" button.

**Recommended: Dual progress display:**

1. **Sticky bottom progress bar** (always visible):
   - Thin (6pt) bar spanning the full width, directly below the quick-add field
   - Color: `ForagerTheme.forestGreen` fill on `ForagerTheme.pebble` track (at 30% opacity)
   - Animated fill with `.spring` timing
   - Text overlay: `"14 of 27"` centered, `ForagerTheme.bodyFont(.caption2)`, appears only when bar is > 30% filled (avoid text on empty bar)

2. **Category-level progress** (in each section header):
   - The `(3/5)` fraction already recommended in category headers
   - When a category reaches 100%, the fraction text changes to a small checkmark icon in `ForagerTheme.springGreen`

3. **Remove the large top progress header** entirely. It takes up valuable screen space and pushes list content down. The bottom bar + category fractions provide all needed progress info.

---

## 4. Adding Items

### 4.1 Quick Add (Bottom Bar)

**Current:** A `TextField` with `RoundedBorderTextFieldStyle` at the top of the list, with a `plus.circle.fill` button. Autocomplete suggestions appear in a dropdown below.

**Recommended: Sticky bottom quick-add bar:**

```
+--------------------------------------------------+
|  [leaf.circle]  "Add an item..."         [+]     |
+--------------------------------------------------+
```

| Spec | Value |
|------|-------|
| **Position** | Sticky footer, above the progress bar, below the scrollable list |
| **Background** | `ForagerTheme.cardBackground` with subtle top border (`ForagerTheme.border`) |
| **Icon** | `leaf.circle` in `ForagerTheme.leafGreen` (branding touch; current uses no leading icon) |
| **Placeholder** | "Add an item..." (shorter than current "Quick add (e.g., \"2 cups flour\")") |
| **Add button** | `plus.circle.fill` in `ForagerTheme.forestGreen` (replace current system blue) |
| **Keyboard** | When focused, keyboard appears and the bar rises above it using `.safeAreaInset(edge: .bottom)`. Autocomplete suggestions appear between the list and the bar. **⚠️ Implementation caveat:** `.safeAreaInset` with a `TextField` inside has known keyboard-avoidance bugs on physical devices (iOS 16-18). The bar may not track the keyboard correctly when the keyboard appears or dismisses, especially on iPhone 15 Pro and later. Test thoroughly on physical hardware. If issues arise, fall back to a `GeometryReader` + keyboard-height observer pattern using `UIResponder.keyboardWillChangeFrameNotification` for manual positioning. |
| **Submit** | Both the `+` button and keyboard return key add the item. Current `onSubmit` behavior is correct. |

**Autocomplete dropdown improvements:**

```
+--------------------------------------------------+
|  Flour, All-Purpose          Boxed & Canned      |
|  Flour, Whole Wheat          Boxed & Canned      |
|  Flaxseed                    Snacks & Other   *  |
+--------------------------------------------------+
       (appears ABOVE the quick-add bar)
```

| Change | Rationale |
|--------|-----------|
| Show suggestions ABOVE the bar (not below) | When the bar is at the bottom, suggestions must appear above it. This also keeps them in the thumb zone. |
| Limit to 4 suggestions (current: 5) | Fewer options = faster selection. 4 fits well without scrolling on most devices. |
| Highlight matching text portion | Bold the characters that match the user's input within the suggestion name. Aids scanability. |
| Show category inline, trailing | Replace the stacked layout with a single-line layout: name on left, category on right in `ForagerTheme.secondaryText`. More compact. |
| Keep staple star indicator | The orange star for staple items is useful. Replace with `ForagerTheme.warning` for palette consistency. |

### 4.2 From Recipes (Full Add Modal)

**Current:** The `AddListItemView` is a full modal `Form` with ingredient text field, autocomplete, category picker, and "Add to List" button. A secondary modal prompts to save unknown ingredients as templates.

**Recommended changes to AddListItemView:**

| Change | Rationale |
|--------|-----------|
| **Add "From Recipe" section** | Include a "Browse Recipes" button that presents a recipe picker. Selecting a recipe adds all its ingredients to the list at once with proper category assignment and source attribution. This bridges the recipe-to-list workflow without requiring the user to go through meal planning. |
| **Reduce modal complexity** | The current Form has 4 sections. Combine "Item Details" and "Category" into a single section. The category should auto-populate from the matched template (current behavior) and only show a picker if the user wants to override. |
| **Streamline template creation prompt** | The "Add to Ingredients?" sheet interrupts the adding flow. Instead, show a subtle inline banner: "New ingredient -- save to your list?" with [Save] and [Skip] buttons, without a separate modal. This reduces context-switching. |

### 4.3 Bulk Operations

**Currently absent. Recommended additions:**

| Operation | Trigger | Behavior |
|-----------|---------|----------|
| **Add from recipe** | Button in add modal or toolbar action | Present recipe picker, then add all ingredients with merge logic (use existing `QuantityMergeService`) |
| **Add from previous list** | Long-press on `+` in list overview, or option in creation action sheet | Copy unchecked items from a selected previous list into the current list |
| **Uncheck all** | Context menu on progress bar | Resets all items to unchecked (useful for recurring weekly lists) |
| **Delete checked** | Context menu on progress bar | Removes all checked items (clean up after shopping) |

---

## 5. Item States

### 5.1 State Matrix

| State | Visual Treatment | Interaction |
|-------|-----------------|-------------|
| **Unchecked** | Full opacity. `ForagerTheme.primaryText` name. `ForagerTheme.secondaryText` quantity trailing. Empty circle checkbox in `ForagerTheme.stone`. Clear background. | Tap anywhere on row to check. Swipe right to check. Swipe left to delete. |
| **Checked** | 50% opacity overall. Strikethrough on name (animated). `ForagerTheme.mintTint` background wash. Filled checkmark in `ForagerTheme.springGreen`. | Tap to uncheck. Swipe right to uncheck. Swipe left to delete. |
| **Low-confidence (< 0.7)** | Unchecked state + subtle dotted underline on item name in `ForagerTheme.warning`. No icon (reduce visual noise). | Tap and hold to see parsed interpretation: "Parsed as: 2 cups flour (80% sure)". Long-press context menu offers "Edit item" to correct. |
| **Recipe-sourced** | Unchecked state + small pill badge below name. Pill: `ForagerTheme.info` text on `ForagerTheme.info.opacity(0.1)` background, `ForagerTheme.radiusSM` corners. | Tap pill to navigate to source recipe (deep link). |
| **Merged** | Unchecked state + "Merged from N items" caption in `ForagerTheme.secondaryText`. | Tap merged indicator to see breakdown (which recipes contributed). |
| **Newly added** | Brief green glow animation (border pulse) for 1 second after adding via quick-add. | Standard interactions. The glow confirms the item was added and helps the user locate it in the list. |

### 5.2 Quantity Display

| Quantity | Display |
|----------|---------|
| `1` (default) | Show nothing (most items default to "1", showing it adds clutter) |
| `2` | `"2"` |
| `2 cups` | `"2 cups"` |
| `1.5 lbs` | `"1.5 lbs"` |
| `1 dozen` | `"1 doz"` |

Quantities should be right-aligned, trailing edge, in `ForagerTheme.secondaryText` with `ForagerTheme.bodyFont(.callout)`. This creates a clean left-aligned name column + right-aligned quantity column layout, similar to a price column in a receipt. The current parenthesized inline format (`(2 cups)`) breaks the visual rhythm.

---

## 6. Empty States

### 6.1 First List Ever (WeeklyListsView, no lists exist)

**Current:** `StandardEmptyStateView` with "No Grocery Lists" title, "Generate your first list to get started!" subtitle, and a blue "Generate from Staples" button.

**Recommended redesign:**

```
+--------------------------------------------------+
|                                                  |
|                                                  |
|              [illustration: sprout               |
|               growing from a list]               |
|                                                  |
|           Your pantry awaits                     |
|                                                  |
|      Create your first grocery list to           |
|      start organized shopping.                   |
|                                                  |
|     +----------------------------------+         |
|     |  [cart] Generate from Staples    |         |  <-- ForagerPrimaryButtonStyle
|     +----------------------------------+         |
|                                                  |
|         or start with an empty list              |  <-- Tertiary text link
|                                                  |
+--------------------------------------------------+
```

| Change | Current | Recommended |
|--------|---------|-------------|
| **Icon** | SF Symbol `list.clipboard` in system blue | Forager-branded illustration (the app's sprout icon emerging from a grocery bag or checklist). Falls back to SF Symbol `leaf.circle` in `ForagerTheme.leafGreen` if no custom illustration. |
| **Title** | "No Grocery Lists" (negative framing) | "Your pantry awaits" (inviting, positive framing). Empty states should inspire action, not report absence. |
| **Subtitle** | "Generate your first list to get started!" | "Create your first grocery list to start organized shopping." (Describes the benefit, not the mechanism.) |
| **Primary button** | Blue pill with `cart.badge.plus` | Use `ForagerPrimaryButtonStyle` (forest green, rounded). Icon: `cart`. Text: "Generate from Staples". |
| **Secondary option** | None | Text link "or start with an empty list" below the primary button in `ForagerTheme.secondaryText`. Provides an alternative without modal complexity. |
| **Background** | `Color(.systemGroupedBackground)` | `ForagerTheme.primaryBackground` (warm cream in light mode, warm near-black in dark mode). |

### 6.2 Empty List (GroceryListDetailView, list exists but has no items)

**Current:** Centered layout with cart icon, "Empty List" title, "Add some items to get started shopping!" subtitle, and a blue "Add Item" button.

**Recommended redesign:**

```
+--------------------------------------------------+
|                                                  |
|              [illustration: empty                |
|               shopping basket]                   |
|                                                  |
|            Ready to shop                         |
|                                                  |
|      Add items below or import from              |
|      a recipe to fill your list.                 |
|                                                  |
|     +----------------------------------+         |
|     |  [plus] Add Your First Item      |         |
|     +----------------------------------+         |
|                                                  |
|     +----------------------------------+         |
|     |  [book] Add from Recipe          |         |  <-- ForagerSecondaryButtonStyle
|     +----------------------------------+         |
|                                                  |
+--------------------------------------------------+
|  [leaf.circle]  "Add an item..."         [+]     |  <-- Quick-add bar still visible
+--------------------------------------------------+
```

**Key difference from 6.1:** The quick-add bar should STILL be visible at the bottom even in the empty state. This means the user can immediately start typing without tapping a button. The empty state illustration and buttons serve as orientation, but the always-present input bar removes one tap from the critical path.

---

## 7. Micro-Interactions

### 7.1 Check/Uncheck Animation

Detailed in Section 3.2. Summary of the animation stack:

```swift
// Check animation sequence
withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
    item.isCompleted = true
}

// Haptic (synchronized with animation start)
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.prepare()  // Call on view appear for zero-latency
generator.impactOccurred()

// Visual changes driven by isCompleted binding:
// - Checkbox: .scaleEffect(item.isCompleted ? 1.0 : 0.9) with spring
// - Name: .strikethrough(item.isCompleted, color: ForagerTheme.secondaryText)
// - Name: .foregroundColor(item.isCompleted ? ForagerTheme.secondaryText.opacity(0.5) : ForagerTheme.primaryText)
// - Row background: ForagerTheme.mintTint.opacity(item.isCompleted ? 0.3 : 0)
```

**Haptic rationale:** `UIImpactFeedbackGenerator(.medium)` produces a single clean "tick" -- similar to checking a physical checkbox. The `.light` style for uncheck creates an asymmetric feedback loop: checking feels more substantial than unchecking, subtly encouraging forward progress through the list. Avoid `.heavy` -- it feels aggressive and drains battery faster. Avoid `UINotificationFeedbackGenerator` which is designed for system-level events, not repeated user actions.

**Pre-warm the haptic engine:** Call `generator.prepare()` in the view's `onAppear` so the first check has zero latency. The system keeps the Taptic Engine in a ready state for a few seconds after `prepare()` is called.

### 7.2 Swipe Actions

**Current:** Leading swipe = Complete/Undo (green/orange). Trailing swipe = Delete (red).

**Recommended enhancements:**

| Direction | Action | Color | Icon | Haptic |
|-----------|--------|-------|------|--------|
| **Leading (right swipe)** | Toggle check | `ForagerTheme.springGreen` (check) / `ForagerTheme.warning` (undo) | `checkmark` / `arrow.uturn.left` | `.medium` / `.light` |
| **Trailing (left swipe, partial)** | Edit item | `ForagerTheme.info` | `pencil` | None |
| **Trailing (left swipe, full)** | Delete | `ForagerTheme.danger` | `trash` | `.warning` (UINotificationFeedbackGenerator) |

Adding an "Edit" swipe action at partial reveal gives users quick access to modify quantity or name without opening a modal. The full-swipe delete with a distinct haptic (notification warning) differentiates it from the edit action.

### 7.3 Category Collapse/Expand

```swift
// Category header tap
withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
    collapsedCategories.toggle(categoryName)
}

// Chevron rotation
Image(systemName: "chevron.right")
    .rotationEffect(.degrees(isExpanded ? 90 : 0))
    .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isExpanded)

// No haptic for collapse -- it's a navigation action, not a completion action.
// Adding haptics to everything dilutes the check-off reward.
```

### 7.4 List Completion Celebration

When the final item is checked and the list reaches 100%:

**Sequence:**

```
Frame 0ms:     Final item check-off animation (standard)
Frame 300ms:   Haptic: UINotificationFeedbackGenerator(.success)
Frame 300ms:   Progress bar fills to 100%, color shifts to ForagerTheme.springGreen
Frame 500ms:   Brief confetti burst from the progress bar (subtle, 1-2 seconds)
               Use lightweight particle emitter, leaf-green and spring-green particles
               OR a simple scale-up pulse on the progress percentage text
Frame 500ms:   Banner appears (non-blocking): "All done! Great shopping."
Frame 3000ms:  Banner auto-dismisses
```

**Important:** The celebration should be *brief and tasteful*, not circus-like. A full confetti shower would feel out of place in an earthy, organic-themed app. Consider a gentle "burst" of small leaf-shaped particles in `ForagerTheme.springGreen` and `ForagerTheme.leafGreen`, or even simpler: a quick scale-pulse on the "100%" text with a satisfying haptic.

**Repeat tolerance:** If the user unchecks an item and re-checks it (bringing the list back to 100%), the celebration should NOT play again during the same session. Track with a local `@State` flag.

### 7.5 Quick-Add Confirmation

When an item is added via quick-add:

```
Frame 0ms:    Input clears, keyboard stays open (ready for next item)
Frame 0ms:    Haptic: UIImpactFeedbackGenerator(.light)
Frame 0ms:    New item appears in its category with a brief green border glow
Frame 0-300:  The list scrolls to reveal the newly added item (if off-screen)
Frame 1000ms: Green glow fades out
```

This sequence confirms the add was successful, shows the user where the item landed (since it is categorized and may not be at the top), and keeps the keyboard open for rapid successive adds.

---

## 8. Light and Dark Mode

### 8.1 Palette Mapping

`ForagerTheme.swift` already defines adaptive colors for light/dark mode. The grocery list screen should use these exclusively -- no hard-coded system colors.

| Element | Light Mode | Dark Mode |
|---------|-----------|-----------|
| **Screen background** | `primaryBackground` (cream, #F5F0E8) | `primaryBackground` (warm near-black, ~#1A1715) |
| **Category header background** | `secondaryBackground` (sand, #EDE6D8) | `secondaryBackground` (~#231F1C) |
| **Item row background** | `cardBackground` (white) | `cardBackground` (~#2B2924) |
| **Checked row tint** | `mintTint` at 30% opacity (#E8F0E0) | `mintTint` at 15% opacity (subtle green on dark) |
| **Item name text** | `primaryText` (bark, #2C2418) | `primaryText` (warm off-white, ~#EDE6DB) |
| **Quantity/metadata text** | `secondaryText` (stone, #7A7067) | `secondaryText` (~#998F85) |
| **Checkbox (unchecked)** | `stone` (#7A7067) | `pebble` (#D4CBC0) at 60% opacity |
| **Checkbox (checked)** | `springGreen` (#6B9B37) | `springGreen` slightly brighter (~#7DB043) |
| **Progress bar track** | `pebble` at 30% opacity | `border` (dark mode value) |
| **Progress bar fill** | `forestGreen` (#2D5016) | `accentGreen` (adaptive, ~#6B9B37 in dark) |
| **Category color strip** | Full saturation category colors | Same colors at 80% saturation to avoid overpowering on dark backgrounds |
| **Quick-add bar background** | `cardBackground` (white) with top `border` | `cardBackground` (dark card) with top `border` |
| **Swipe action: check** | `springGreen` | `springGreen` |
| **Swipe action: delete** | `danger` (#C4402F) | `danger` at 90% (slightly muted on dark) |
| **Recipe source pill** | `info` at 10% bg / `info` text | `info` at 15% bg / `info` text (increase contrast) |

### 8.2 Contrast and Accessibility

**WCAG 2.1 AA targets (minimum 4.5:1 for body text, 3:1 for large text):**

| Pair | Light Mode Ratio | Dark Mode Ratio | Passes AA? |
|------|-----------------|-----------------|------------|
| `primaryText` on `cardBackground` | bark (#2C2418) on white = ~16:1 | off-white on #2B2924 = ~12:1 | Yes |
| `secondaryText` on `cardBackground` | stone (#7A7067) on white = ~4.8:1 | #998F85 on #2B2924 = ~4.6:1 | Yes (borderline -- monitor) |
| `springGreen` on `cardBackground` | #6B9B37 on white = ~4.2:1 | #7DB043 on #2B2924 = ~4.5:1 | Borderline -- use for large text/icons only, not body text |
| Checked item text (50% opacity) | ~2.4:1 | ~2.3:1 | No -- this is intentional. Checked items are de-emphasized. Compensate with strikethrough for redundant signaling. |

**Notes on checked-item accessibility:** The 50% opacity reduction on checked items deliberately fails contrast requirements because checked items are *meant* to recede visually. However, we provide redundant signals (strikethrough + colored background + checkbox state) so no single channel carries all the meaning. For VoiceOver users, announce "checked" state explicitly in the accessibility label.

### 8.3 Dark Mode Specific Concerns

- **No true black (#000000):** The `ForagerTheme.primaryBackground` dark mode value uses warm near-black (~#1A1715), which is correct. True black kills depth perception and creates harsh edges against cards.
- **Desaturate category colors in dark mode:** Full-saturation greens and reds on dark backgrounds create visual vibration. Apply 80% saturation or use the adaptive `accentGreen` pattern for category strips.
- **Elevation through brightness, not shadow:** In dark mode, `.foragerShadow()` becomes invisible. Instead, differentiate elevation by making higher surfaces slightly brighter (the `cardBackground` dark value is already brighter than `primaryBackground`).
- **Test the mint tint:** The `mintTint` checked-item background must be barely perceptible in dark mode (15% opacity recommended). Too much green on a dark surface looks like a selection highlight and creates ambiguity.

---

## 9. Current Implementation Audit

### What Works Well (Preserve)

| Feature | Assessment |
|---------|-----------|
| **Category grouping by `Category.sortOrder`** | Excellent. This mirrors store layout and is a key differentiator. |
| **Autocomplete from `IngredientTemplate`** | Strong. The 2-character trigger threshold and 5-suggestion limit are reasonable. Reduce to 4 suggestions. |
| **Swipe actions (leading: check, trailing: delete)** | Good affordance. Add edit swipe as described in 7.2. |
| **Recipe source badges** | Valuable. Users need to know *why* an item is on the list. Restyle to match ForagerTheme palette. |
| **`@FetchRequest` for live updates** | Correct architecture. The fix to move from relationship access to `@FetchRequest` ensures real-time progress tracking. |
| **Progress tracking (completion percentage)** | Core feature. The math is correct. Relocate the UI as described. |

### What Needs Improvement

| Issue | Current Code | Recommendation |
|-------|-------------|----------------|
| **Quick-add position** | Top of screen in `GroceryListDetailView.quickAddSection` | Move to bottom sticky bar (Section 3.1) |
| **No haptic feedback** | `toggleItemCompletion` does `item.isCompleted.toggle()` + save, no haptic | Add `UIImpactFeedbackGenerator` as described in 3.2 and 7.1 |
| **No check animation** | Only `strikethrough(item.isCompleted)` which is binary, no animated transition | Add spring animation wrapper (Section 7.1) |
| **Progress header takes space** | `progressHeader` is a 60pt+ fixed view at top | Replace with sticky bottom bar (Section 3.6) |
| **No category collapse** | Categories are always expanded | Add collapsible sections (Section 3.3) |
| **No category color coding** | Headers are plain text with count | Add `.categoryStrip()` modifier (already in ForagerTheme) |
| **System blue throughout** | Quick-add button, toolbar, empty state buttons all use `.blue` | Replace with `ForagerTheme.forestGreen` / `ForagerTheme.accentGreen` |
| **No list creation options** | Only "Generate from Staples" via `+` button | Add action sheet with three paths (Section 2.3) |
| **Complete All too accessible** | "Complete All" button at top-right of progress header | Move to context menu on progress bar |
| **StandardEmptyStateView uses system blue** | Icon: `.foregroundColor(.blue)`, Button: `.background(Color.blue)` | Replace with ForagerTheme colors (Section 6.1) |
| **Quantity display inline** | `(2 cups)` parenthesized after name | Move to trailing edge, right-aligned (Section 3.4) |
| **No celebration on 100%** | Completion is silent | Add subtle celebration (Section 7.4) |
| **`viewContext.save()` in toggleItemCompletion** | Direct context save in view code | Route through a service per M7.5+ standard. Minor issue but noted for architecture consistency. |

---

## 10. Research Sources

- [Speed, UX & Trust: Building Grocery Apps for Real-Time, Mobile-First Retail](https://orafox.com/grocery-app-ux-speed-orafox/)
- [Online Grocery UX: 4 Best Practices -- Baymard Institute](https://baymard.com/blog/grocery-ecommerce-benchmark)
- [How To Design Mobile Apps For One-Hand Usage -- Smashing Magazine](https://www.smashingmagazine.com/2020/02/design-mobile-apps-one-hand-usage/)
- [Thumb-Friendly Design: Optimizing Mobile UI for One-Handed Use](https://medium.com/@uxandyouti/thumb-friendly-design-optimizing-mobile-ui-for-one-handed-use-0f4acc446b3f)
- [The One Thumb, One Eyeball Test for Good Mobile Design -- IxDF](https://www.interaction-design.org/literature/article/using-mobile-apps-the-one-thumb-one-eyeball-test-for-good-mobile-design)
- [Haptic UX -- The Design Guide for Building Touch Experiences](https://medium.muz.li/haptic-ux-the-design-guide-for-building-touch-experiences-84639aa4a1b8)
- [2025 Guide to Haptics: Enhancing Mobile UX with Tactile Feedback](https://saropa-contacts.medium.com/2025-guide-to-haptics-enhancing-mobile-ux-with-tactile-feedback-676dd5937774)
- [Multi-Sensory UX: Integrating Haptics, Sound, and Visual Cues](https://wings.design/multi-sensory-ux-integrating-haptics-sound-and-visual-cues-to-enhance-user-interaction/)
- [Bottom Sheets: Definition and UX Guidelines -- NN/g](https://www.nngroup.com/articles/bottom-sheet/)
- [Designing Empty States in Complex Applications -- NN/g](https://www.nngroup.com/articles/empty-state-interface-design/)
- [Empty State UX: Designing for Possibility -- LogRocket](https://blog.logrocket.com/ux-design/empty-state-ux/)
- [The Role Of Empty States In User Onboarding -- Smashing Magazine](https://www.smashingmagazine.com/2017/02/user-onboarding-empty-states-mobile-apps/)
- [Dark Mode: Best Practices for Accessibility](https://dubbot.com/dubblog/2023/dark-mode-a11y.html)
- [Dark Mode in App Design: Principles & Tips -- Ramotion](https://www.ramotion.com/blog/dark-mode-in-app-design/)
- [Color in the Age of Dark Mode: Building Adaptive Palettes](https://www.illustration.app/blog/color-in-the-age-of-dark-mode-building-adaptive-palettes)
- [Listonic vs AnyList: Shopping List App Comparison](https://listonic.com/compare-apps/listonic-vs-anylist)
- [Thumb-Zone Optimization: Mobile Navigation Patterns](https://webdesignerindia.medium.com/thumb-zone-optimization-mobile-navigation-patterns-9fbc54418b81)
- [How to design for thumbs in the Era of Huge Screens -- Scott Hurff](https://www.scotthurff.com/posts/how-to-design-for-thumbs-in-the-era-of-huge-screens/)
- [ConfettiSwiftUI Package](https://github.com/simibac/ConfettiSwiftUI)

---

*This document provides UX recommendations only. Implementation requires translating these into SwiftUI code changes, likely as a dedicated milestone (suggested: M10 or equivalent). Prioritize the check-off interaction (Section 3.2/7.1) and bottom quick-add bar (Section 4.1) as they have the highest impact-to-effort ratio.*
