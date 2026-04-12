## Why

Grocery list section headers (DELI & MEAT, DAIRY & FRIDGE, COSTCO, TARGET) render as centered text floating on the parchment canvas background between white section cards. In light mode this looks flat and disconnected: gray text (#5A5347) on warm beige (#EDE8DF) has low visual weight and the headers feel like they're floating in space rather than anchoring the sections below them. Dark mode looks fine because the contrast is sufficient, but the light mode appearance is a visual quality issue.

## What Changes

- Move section headers from the `Section { } header: { }` pattern to being the first row inside each section's card content
- Headers render on the white card surface instead of the parchment canvas, getting proper contrast in both modes
- When collapsed, the card shows just the header row (chevron + title + count badge)
- When expanded, header + items appear as one unified card with the header as the top row
- Thin divider separates header from items within the card
- Applies to both category headers and store headers in store-grouping mode

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `grocery-lists`: Section headers move inside insetGrouped cards instead of floating above them

## Impact

- **GroceryListDetailView.swift**: Restructure `shoppingListView` section rendering to put headers inside card content
- **ForagerSectionHeader.swift**: May need minor layout adjustment for in-card rendering (remove centering, adjust padding)
- **No Core Data, service, or architectural changes**
