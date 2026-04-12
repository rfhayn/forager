## Context

The grocery list detail uses `.listStyle(.insetGrouped)` with `Section { items } header: { ForagerSectionHeader }`. The `insetGrouped` style renders section headers on the canvas background above the rounded card. `ForagerSectionHeader` is a custom centered header with a collapse chevron, title, and count badge. The centering and canvas placement look good in dark mode but flat in light mode.

There are two grouping modes:
1. **Category-only** (store grouping off): `ForEach(groupedItems) > Section(header: category)`
2. **Store > Category** (store grouping on): `ForEach(stores) > Section(header: store) > ForEach(categories) > Section(header: category)`

## Goals / Non-Goals

**Goals:**
- Headers render on card surface for proper contrast in light mode
- Collapsed sections show as a single-row card (header only)
- Expanded sections show header + items in one unified card
- Works for both category-only and store > category modes

**Non-Goals:**
- Changing header design (font, centering, chevron, count badge stay)
- Changing other views that use ForagerSectionHeader
- Adding new features to the grocery list

## Decisions

### 1. Move header into section content, use empty header

Instead of `Section { items } header: { ForagerSectionHeader }`, restructure to `Section { headerRow + items }` with an empty or hidden section header. The `ForagerSectionHeader` becomes a regular row inside the section, followed by an optional divider and the items. The `insetGrouped` style then wraps the header and items in one card.

**Alternative considered**: Keeping the header outside but adding a background. Rejected because it creates two visual layers (header card + items card) that feel busy.

### 2. Divider between header and items

When expanded, a `Divider()` separates the header row from the item rows. This provides subtle visual separation within the unified card without needing a second card boundary.

### 3. ForagerSectionHeader stays centered

Keep the centered layout with chevron left and count badge right. The visual weight comes from the card surface background now, so centering works. No need to switch to left-aligned.

## Risks / Trade-offs

- **[Risk] List row styling on header** → The header row needs `.listRowBackground(ForagerTheme.surfacePrimary)` and `.listRowSeparator(.hidden)` to match item rows.
- **[Risk] Store headers in nested sections** → Store-level headers with nested category sections need careful restructuring. The store header becomes the first row of the outer section, with category sub-sections below.
- **[Trade-off] Empty section headers** → Using `Section { }` without a header may cause `.insetGrouped` to add default spacing. May need `Section(header: EmptyView())` or similar.
