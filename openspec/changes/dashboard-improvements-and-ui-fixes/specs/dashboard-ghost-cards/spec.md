## ADDED Requirements

### Requirement: Dashboard always shows three primary cards
The dashboard SHALL always display three cards (Tonight's Meal, Shopping List, Meal Plan Overview) regardless of whether data exists. When data exists, the card SHALL render as a solid card with content. When no data exists, the card SHALL render as a ghost card.

#### Scenario: All data present
- **WHEN** the user has an active meal plan with today's meal, an incomplete shopping list, and an active meal plan
- **THEN** all three cards render as solid cards with data content

#### Scenario: No data at all
- **WHEN** the user has no meal plans, no shopping lists, and no planned meals
- **THEN** all three cards render as ghost cards with dashed outlines and action text

#### Scenario: Partial data
- **WHEN** the user has a shopping list but no meal plan
- **THEN** the Shopping List card renders as solid and the other two render as ghost cards

### Requirement: Ghost card visual style
Ghost cards SHALL have a dashed border outline with no background fill (transparent). The dashed border SHALL use `ForagerTheme.borderSubtle` color. Ghost card content SHALL use `textTertiary` for the message and `accentPrimary` for action text. Ghost cards SHALL have the same dimensions (padding, corner radius) as solid cards.

#### Scenario: Ghost card appearance
- **WHEN** a card has no data and renders as a ghost
- **THEN** it displays with a dashed outline, no fill, and descriptive text with an action prompt

### Requirement: Tonight's Meal ghost card opens recipe picker
When the Tonight's Meal card is in ghost state, tapping it SHALL present RecipeListView in a sheet. Selecting a recipe SHALL assign it to today's meal plan.

#### Scenario: Pick recipe with no existing meal plan
- **WHEN** the user taps the Tonight's Meal ghost card and selects a recipe
- **THEN** a new meal plan is auto-created (standard naming convention, default duration from settings) and the recipe is assigned to today

#### Scenario: Pick recipe with existing meal plan
- **WHEN** the user taps the Tonight's Meal ghost card, an active meal plan covers today, and the user selects a recipe
- **THEN** the recipe is assigned to today in the existing meal plan

### Requirement: Shopping List ghost card opens create dialog
When the Shopping List card is in ghost state, tapping it SHALL present the create list confirmation dialog with options: "From Staples", "From Meal Plan", "Empty List".

#### Scenario: Create list from ghost card
- **WHEN** the user taps the Shopping List ghost card and selects "Empty List"
- **THEN** a new empty shopping list is created and the card transitions to solid state

### Requirement: Meal Plan ghost card opens create sheet
When the Meal Plan Overview card is in ghost state, tapping it SHALL present CreateMealPlanSheet.

#### Scenario: Create meal plan from ghost card
- **WHEN** the user taps the Meal Plan ghost card
- **THEN** CreateMealPlanSheet is presented
- **WHEN** the user saves a new meal plan
- **THEN** the card transitions to solid state showing the new plan

### Requirement: Tomorrow's Meal card (conditional, no ghost)
The dashboard SHALL display a Tomorrow's Meal card only when the active meal plan has a PlannedMeal for tomorrow. The card SHALL NOT have a ghost state.

#### Scenario: Tomorrow has a planned meal
- **WHEN** the active meal plan has a recipe assigned to tomorrow
- **THEN** a Tomorrow's Meal card appears showing the recipe name, servings, and cook time

#### Scenario: No meal planned for tomorrow
- **WHEN** no meal is planned for tomorrow
- **THEN** the Tomorrow's Meal card is completely hidden

### Requirement: Quick action buttons centered
The quick action buttons (New List, Add Recipe, Plan Meals) SHALL be horizontally centered on screen.

#### Scenario: Quick actions layout
- **WHEN** the dashboard renders
- **THEN** the quick action button row is centered, not left-justified

### Requirement: Dashboard background matches other tabs
The dashboard SHALL use `ForagerTheme.backgroundCanvas` as its background color, matching all other tab views.

#### Scenario: Tab switching
- **WHEN** the user switches between Dashboard, Lists, Recipes, and Meal Plans tabs
- **THEN** the background color is visually identical across all tabs

### Requirement: UI theme consistency across app
All views SHALL use ForagerTheme tokens for colors and fonts. No hardcoded `.white` on dynamic accent backgrounds. No UIKit system colors (`Color(.systemGray6)`, etc.).

#### Scenario: Dark mode contrast
- **WHEN** the app is in dark mode
- **THEN** text on accent-colored backgrounds (buttons, indicators) meets WCAG AA contrast ratio (4.5:1 minimum)

#### Scenario: Theme token usage
- **WHEN** any view renders in light or dark mode
- **THEN** all colors come from ForagerTheme tokens, not UIKit system colors
