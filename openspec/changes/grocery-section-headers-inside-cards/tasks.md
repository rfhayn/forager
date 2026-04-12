## 1. Restructure Category-Only Mode

- [x] 1.1 In GroceryListDetailView shoppingListView, move ForagerSectionHeader from Section header to first row inside Section content for category-only mode (store grouping off)
- [x] 1.2 Add Divider between header row and item rows when section is expanded
- [x] 1.3 Apply .listRowBackground(ForagerTheme.surfacePrimary) and .listRowSeparator(.hidden) to header row
- [x] 1.4 Use Section without header (or with EmptyView header) to avoid double headers

## 2. Restructure Store Grouping Mode

- [x] 2.1 Move store-level ForagerSectionHeader into Section content as first row
- [x] 2.2 Move category-level ForagerSectionHeader into sub-Section content as first row
- [x] 2.3 Apply same row styling (background, separator hidden) to both header levels
- [x] 2.4 Add dividers between store header and category content, and between category headers and items

## 3. Build and Verify

- [x] 3.1 Build iOS target — confirm zero errors
- [ ] 3.2 Visual check: light mode — headers visible on card surface, not floating on canvas
- [ ] 3.3 Visual check: dark mode — headers still look good inside cards
- [ ] 3.4 Test collapse/expand — collapsed sections show single-row card, expanded show unified card
- [ ] 3.5 Test store grouping mode — both store and category headers inside cards
