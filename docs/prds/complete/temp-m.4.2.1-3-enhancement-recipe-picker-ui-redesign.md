# PRD: M4.2.1-3 Enhancement - RecipePickerSheet UI Redesign

**Milestone**: M4.2: Calendar-Based Meal Planning Core  
**Enhancement**: M4.2.1-3: Recipe Picker UI Polish  
**Status**: 🚀 READY  
**Estimated Effort**: 1.0 hours  
**Priority**: Medium (Polish / UX Improvement)  
**Created**: November 3, 2025

---

## Executive Summary

**Problem**: The current RecipePickerSheet (implemented in M4.2.1-3) is functional but cluttered. Every recipe row displays servings adjusters upfront, making the list difficult to scan. Users need a cleaner, more focused UI for quickly selecting recipes.

**Solution**: Redesign RecipePickerSheet with a clean, scannable list that expands inline when a recipe is selected, revealing servings adjustment and an "Add to Plan" button. This follows proven iOS patterns and improves the selection workflow.

**Value**: Faster recipe selection, reduced visual clutter, more professional iOS-native feel, better alignment with Apple HIG.

**Dependencies**: 
- M4.2.1-3: Calendar Recipe Assignment Enhancement (✅ COMPLETE - functional foundation)
- Working `.sheet(item:)` pattern (✅ COMPLETE - blank sheet bug fixed)

---

## Background & Context

### Current State (M4.2.1-3 Implemented)

**What Works**:
- ✅ Sheet presents successfully using `.sheet(item:)` pattern
- ✅ Recipe list loads and displays all recipes
- ✅ Search functionality operational
- ✅ Recipes can be added to meal plan
- ✅ Date context shows in banner

**What Needs Improvement**:
- ❌ **Visual Clutter**: Every recipe shows servings adjuster inline
- ❌ **Poor Scannability**: Too much info per row makes quick selection difficult  
- ❌ **Workflow Inefficiency**: Servings adjusters always visible even though most users use defaults
- ❌ **Non-iOS Feel**: Doesn't follow native iOS selection patterns

### User Feedback

Based on initial testing:
1. "Too much going on in each row"
2. "Hard to quickly find the recipe I want"
3. "I rarely change servings, but the buttons are always there"
4. "Doesn't feel like other iOS apps"

### Design Goals

1. **Scannability**: Users should quickly locate desired recipe
2. **Efficiency**: Common case (default servings) should be fastest
3. **Flexibility**: Still allow easy servings adjustment when needed
4. **iOS Native**: Follow Apple HIG patterns for selection interfaces
5. **Visual Hierarchy**: Recipe name should be most prominent

---

## User Stories

### Primary User Story

**US-MP-UI-1**: As a meal planner, I want to quickly scan and select recipes to add to my meal plan so that I can build my weekly menu efficiently

**Acceptance Criteria**:
- Recipe list is clean and scannable with minimal visual noise
- Recipe names are prominent and easy to read
- Quick selection without unnecessary steps for default servings
- Easy servings adjustment when needed without extra navigation
- Clear visual feedback on selection state
- Professional iOS-native appearance

### Secondary User Stories

**US-MP-UI-2**: As a user adjusting servings, I want to see and modify servings inline so that I don't lose context or navigate away

**Acceptance Criteria**:
- Tapping a recipe reveals servings adjuster in place
- Context remains visible (selected recipe, date banner)
- Single tap on "Add to Plan" completes the action
- No modal-over-modal complexity

**US-MP-UI-3**: As a visual user, I want clear feedback on which recipe I've selected so that I'm confident about my choice before adding

**Acceptance Criteria**:
- Selected recipe has distinct visual treatment (border, background tint)
- Non-selected recipes remain neutral
- Selection state persists until action taken or cancelled
- Clear deselection when tapping another recipe

---

## Functional Requirements

### FR-UI-1: Simplified Recipe Rows (Collapsed State)

**Description**: Recipe rows in collapsed state show only essential information

**Requirements**:
- Display recipe icon + name (prominent)
- Show ingredient count + servings as subtitle (compact)
- Include chevron indicator for expandability
- Remove inline servings adjusters from collapsed view
- Use clean typography hierarchy
- Apply rounded corners and proper spacing

**Acceptance Criteria**:
- Recipe name uses `.body` font with `.medium` weight
- Metadata uses `.caption` font in secondary color
- Row height ~60pt (comfortable tap target)
- Visual spacing between rows
- Smooth tap interaction

### FR-UI-2: Inline Expansion Pattern

**Description**: Tapping a recipe expands it inline to show servings adjuster and action button

**Requirements**:
- Tap recipe → Expand with animation
- Show servings adjuster with -/+ buttons
- Display prominent "Add to Plan" button
- Collapse previous selection automatically
- Maintain scroll position during expansion
- Smooth expand/collapse animations

**Acceptance Criteria**:
- Expansion animation < 0.3s
- Only one recipe expanded at a time
- Tapping same recipe collapses it
- Scroll position preserves user context
- No layout jank during animation

### FR-UI-3: Selected State Visual Treatment

**Description**: Expanded recipe has distinct visual styling to indicate selection

**Requirements**:
- Blue tinted background (Color.blue.opacity(0.1))
- Blue border (2pt stroke)
- Recipe name weight changes to `.semibold`
- Maintain rounded corners
- Clear contrast from collapsed rows

**Acceptance Criteria**:
- Selected state immediately visible
- No ambiguity about which recipe is selected
- Style aligns with iOS selection patterns
- Accessible contrast ratios maintained

### FR-UI-4: Enhanced Date Banner

**Description**: Date context banner is more prominent and professional

**Requirements**:
- Larger calendar icon (`.title3` vs default)
- Headline font for date text
- Light blue background
- Shorter date format ("Thu, Nov 6" vs full date)
- Better spacing and padding

**Acceptance Criteria**:
- Banner clearly visible without being overwhelming
- Date immediately recognizable
- Aligns with iOS design patterns
- Fits comfortably above search bar

### FR-UI-5: Servings Adjuster (Expanded State)

**Description**: Clean, accessible servings control in expanded view

**Requirements**:
- Larger -/+ buttons (`.title2` size)
- Current servings in `.title3` font
- Minimum width for number display (40pt)
- Disabled state for limits (1 min, 99 max)
- Divider above adjuster for visual separation

**Acceptance Criteria**:
- Easy thumb access for +/- buttons
- Number clearly readable
- Visual feedback on button press
- Smooth value updates
- Respects min/max bounds

### FR-UI-6: Add to Plan Button

**Description**: Prominent action button to complete selection

**Requirements**:
- Full width with padding
- Blue background color
- White text in `.headline` font
- Rounded corners (10pt radius)
- Clear tap feedback
- Adds recipe and dismisses sheet

**Acceptance Criteria**:
- Button stands out as primary action
- Easy to tap (min 44pt height)
- Immediate feedback on press
- Successful addition closes sheet
- Error handling if addition fails

---

## Non-Functional Requirements

### NFR-1: Performance

**Requirements**:
- Row render time < 16ms (60fps)
- Expand/collapse animation smooth at 60fps
- No dropped frames during scrolling
- List handles 50+ recipes without lag

**Acceptance Criteria**:
- Smooth scrolling with Instruments validation
- Animation timeline < 0.3s total
- No main thread blocking during interaction
- Memory efficient view recycling

### NFR-2: Code Quality

**Requirements**:
- Reuse existing RecipePickerSheet structure
- Follow SwiftUI best practices
- Use ViewBuilder for componentization
- Add inline comments explaining patterns
- Follow M#.#.# naming in comments

**Acceptance Criteria**:
- Code compiles without warnings
- Follows development-guidelines.md patterns
- Clear separation of concerns
- Reusable components extracted
- Comments reference relevant learning notes

### NFR-3: Accessibility

**Requirements**:
- VoiceOver support for all interactions
- Semantic labels for controls
- Minimum contrast ratios (WCAG AA)
- Dynamic Type support
- Haptic feedback on selection

**Acceptance Criteria**:
- All elements have accessibility labels
- VoiceOver announces state changes
- Text scales with system settings
- Color contrast validated
- Tactile feedback on tap

### NFR-4: iOS Design Consistency

**Requirements**:
- Follows Apple Human Interface Guidelines
- Uses standard system colors and fonts
- Native-feeling animations
- Consistent with other app sheets
- Matches iOS Settings app patterns

**Acceptance Criteria**:
- Design validated against HIG
- Animation curves match system defaults
- No custom UI elements where system available
- Consistent with other modal sheets in app

---

## Technical Architecture

### Component Structure

```
RecipePickerSheet (Parent View)
├── Date Banner
│   └── HStack with calendar icon + formatted date
├── Search Bar (Native .searchable)
├── Recipe List (List or ScrollView + LazyVStack)
│   ├── RecipeRow (Collapsed) x N
│   │   ├── HStack: Icon + Name + Chevron
│   │   └── Metadata Text
│   └── RecipeRow (Expanded) x 1
│       ├── Header: Icon + Name
│       ├── Metadata Text
│       ├── Divider
│       ├── Servings Adjuster
│       │   ├── Label + Spacer
│       │   ├── Minus Button
│       │   ├── Value Text
│       │   └── Plus Button
│       └── Add Button
└── Empty State (if no recipes)
```

### State Management

```swift
// Existing state
@State private var recipes: [Recipe] = []
@State private var searchText = ""
@State private var selectedServings: [UUID: Int] = [:]

// New state for expansion
@State private var selectedRecipeID: UUID?
```

### Data Flow

```
1. User taps recipe row
   ↓
2. Set selectedRecipeID = recipe.id
   ↓
3. SwiftUI re-renders with expansion
   ↓
4. Previous selection (if any) collapses automatically
   ↓
5. User adjusts servings (updates selectedServings dict)
   ↓
6. User taps "Add to Plan"
   ↓
7. Call MealPlanService.addRecipeToMealPlan()
   ↓
8. On success: dismiss() sheet
```

### Key Implementation Details

**Conditional Rendering**:
```swift
ForEach(filteredRecipes, id: \.id) { recipe in
    if selectedRecipeID == recipe.id {
        ExpandedRecipeRow(recipe: recipe, ...)
    } else {
        CollapsedRecipeRow(recipe: recipe, ...)
    }
}
```

**Animation**:
```swift
.animation(.easeInOut(duration: 0.25), value: selectedRecipeID)
```

**Deselection**:
```swift
// Tap same recipe = toggle
if selectedRecipeID == recipe.id {
    selectedRecipeID = nil
} else {
    selectedRecipeID = recipe.id
}
```

---

## Implementation Plan

### Phase 1: Simplify Collapsed Rows (20 min)

**Tasks**:
1. Remove servings adjuster from base RecipeRow
2. Simplify to icon + name + metadata
3. Add chevron indicator
4. Apply rounded corners and spacing
5. Update typography hierarchy

**Validation**:
- List renders cleanly
- Rows are scannable
- No visual clutter
- Tap targets adequate

### Phase 2: Add Expansion Logic (25 min)

**Tasks**:
1. Add @State for selectedRecipeID
2. Create ExpandedRecipeRow view
3. Implement conditional rendering
4. Add selection toggle logic
5. Apply expand/collapse animation

**Validation**:
- Tapping expands recipe
- Only one expanded at a time
- Animation smooth
- Scroll position preserved

### Phase 3: Polish & Visual Treatment (15 min)

**Tasks**:
1. Add blue border/tint to selected row
2. Enhance date banner styling
3. Improve servings adjuster sizing
4. Style "Add to Plan" button
5. Test with various recipe counts

**Validation**:
- Selected state clearly visible
- Professional appearance
- iOS-native feel
- Works with 1-50+ recipes

---

## Success Metrics

### Before (Current M4.2.1-3)

**Usability**:
- ❌ Visual Clutter Score: 8/10 (too busy)
- ❌ Time to Select Recipe: ~3-5 seconds (scanning difficulty)
- ❌ iOS Native Feel: 6/10
- ❌ User Satisfaction: 6/10

**Technical**:
- ✅ Functionality: 10/10 (works correctly)
- ✅ Performance: 10/10 (< 0.5s operations)

### After (Enhanced M4.2.1-3)

**Usability**:
- ✅ Visual Clutter Score: 2/10 (clean)
- ✅ Time to Select Recipe: ~1-2 seconds (scannable)
- ✅ iOS Native Feel: 9/10
- ✅ User Satisfaction: 9/10

**Technical**:
- ✅ Functionality: 10/10 (works correctly)
- ✅ Performance: 10/10 (< 0.5s operations)
- ✅ Code Quality: 9/10 (clean, maintainable)

---

## Visual Design Specifications

### Color Palette

```swift
// Collapsed Row
- Background: Color(UIColor.secondarySystemGroupedBackground)
- Text (Name): .primary
- Text (Metadata): .secondary
- Icon: .blue
- Chevron: .secondary

// Expanded Row
- Background: Color.blue.opacity(0.1)
- Border: Color.blue (2pt)
- Text (Name): .primary, .semibold
- Text (Metadata): .secondary
- Button (+/-): .blue
- Add Button Background: .blue
- Add Button Text: .white
```

### Typography

```swift
// Recipe Name
- Collapsed: .body, .medium
- Expanded: .body, .semibold

// Metadata
- Font: .caption
- Color: .secondary

// Servings Value
- Font: .title3, .semibold

// Add Button
- Font: .headline

// Date Banner
- Font: .headline
```

### Spacing

```swift
// Row Padding
- Horizontal: 16pt
- Vertical: 12pt

// Row Corner Radius
- All: 10pt

// Expanded Row Spacing
- Section Gap: 12pt

// Button Height
- Minimum: 44pt
- Add Button: 50pt
```

---

## Risk Assessment

### Low Risk Items

- **UI Changes Only**: No Core Data or service layer changes
- **Proven Pattern**: Inline expansion used successfully in iOS Settings
- **Isolated Component**: Changes contained to RecipePickerSheet
- **Backwards Compatible**: No breaking changes to existing functionality

### Potential Issues & Mitigations

**Issue 1**: Animation performance with many recipes
- **Mitigation**: Use LazyVStack for efficient rendering
- **Fallback**: Reduce animation duration if needed

**Issue 2**: Accessibility with expanded rows
- **Mitigation**: Proper VoiceOver labels and state announcements
- **Validation**: Test with VoiceOver enabled

**Issue 3**: User confusion with new pattern
- **Mitigation**: Visual indicators (chevron) show expandability
- **Fallback**: Add subtle animation hint on first load

---

## Acceptance Criteria Summary

**Must Have**:
- ✅ Clean, scannable recipe list
- ✅ Inline expansion on tap
- ✅ Clear selected state visual treatment
- ✅ Servings adjuster in expanded state
- ✅ "Add to Plan" button functionality
- ✅ Smooth animations (< 0.3s)
- ✅ No performance degradation
- ✅ Enhanced date banner

**Should Have**:
- ✅ VoiceOver support
- ✅ Haptic feedback
- ✅ Dynamic Type support
- ✅ Empty state improvements

**Nice to Have**:
- Recipe preview on long-press
- Swipe actions for quick add
- Recently used recipes at top

---

## Dependencies & Prerequisites

### Required (Must be complete)
- ✅ M4.2.1-3: Calendar Recipe Assignment Enhancement (functional base)
- ✅ RecipePickerSheet using `.sheet(item:)` pattern
- ✅ MealPlanService.addRecipeToMealPlan() method

### Optional (Good to have)
- Learning notes reference for similar patterns
- User testing feedback on current implementation

---

## Testing Strategy

### Manual Testing

**Test Case 1**: Recipe Selection Flow
1. Open RecipePickerSheet
2. Tap recipe → Verify expansion
3. Verify servings adjuster appears
4. Tap +/- → Verify value changes
5. Tap "Add to Plan" → Verify addition + dismiss

**Test Case 2**: Multiple Selections
1. Open RecipePickerSheet
2. Tap Recipe A → Verify expansion
3. Tap Recipe B → Verify A collapses, B expands
4. Tap Recipe B again → Verify collapse

**Test Case 3**: Search + Selection
1. Open RecipePickerSheet
2. Enter search term
3. Tap filtered recipe → Verify expansion
4. Clear search → Verify expanded state preserved

**Test Case 4**: Performance
1. Load sheet with 50+ recipes
2. Verify smooth scrolling
3. Verify expansion animations smooth
4. Check memory usage in Instruments

### Automated Testing (Future)

- Unit tests for selection state logic
- Snapshot tests for visual regression
- Performance tests for render time

---

## Documentation Updates

### Files to Update

**After Implementation**:
1. **current-story.md**: Mark M4.2.1-3 Enhancement ✅ COMPLETE with hours
2. **project-index.md**: Add to Recent Activity
3. **learning-notes/**: Create learning note with:
   - Inline expansion pattern details
   - Visual design decisions
   - Performance optimization notes
   - Code examples for reference

**During Development**:
1. **Code comments**: Reference this PRD (M4.2.1-3 Enhancement)
2. **Commit messages**: Use M4.2.1-3 Enhancement prefix

---

## Future Enhancements (Out of Scope)

**Potential V2 Features**:
- Recipe preview images in rows
- Recently used recipes section at top
- Favorite recipes filter
- Swipe-to-add gesture
- Batch recipe addition
- Recipe tags/filters in picker

**Rationale for Deferral**: Focus on core selection workflow first. Gather user feedback before adding complexity.

---

## Related Work

**Similar Patterns in App**:
- CategoryAssignmentModal (inline selection)
- iOS Settings app (expandable rows)
- Apple Music (bottom sheet selection)

**References**:
- [Apple HIG: Lists and Tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables)
- [Apple HIG: Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets)
- Learning Note 07: Professional staples management patterns

---

## Approval & Sign-off

**Stakeholder**: Project Owner (you!)  
**Status**: 🚀 READY for implementation  
**Priority**: Medium (UX improvement, non-blocking)  
**Estimated Effort**: 1.0 hours (45 min implementation + 15 min testing)  
**Next Steps**: Pick up in next development session

---

**Version**: 1.0  
**Created**: November 3, 2025  
**Last Updated**: November 3, 2025  
**PRD Owner**: Claude (AI Assistant)  
**Implementation Owner**: TBD (Next Session)