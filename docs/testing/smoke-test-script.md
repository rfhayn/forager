# Forager Smoke Test Script — Claude Desktop + Simulator

**Purpose**: Automated visual testing via Claude Desktop computer use against the iOS Simulator.
**Simulator**: iPhone 17 Pro
**Prerequisites**: App installed on simulator, no iCloud sign-in required
**Scope**: Everything except household sharing (requires real devices)

---

## Setup

1. Open Simulator with iPhone 17 Pro
2. Delete the app if installed: `xcrun simctl uninstall booted com.richhayn.forager`
3. Build and install fresh: build from Xcode to the simulator (Debug config)
4. The app should launch to the welcome walkthrough (fresh install)

---

## Test 1: Welcome Walkthrough

**Steps:**
1. App launches → verify 3-screen welcome carousel appears
2. Screen 1: "Welcome to forager" with app icon → tap "Get Started"
3. Screen 2: "How Forager Works" with 3 flow cards (Import, Plan, Shop) → tap "Continue"
4. Screen 3: "Power Up" with AI + Household cards → tap "Let's Go"
5. Verify: tabs appear (Lists, Recipes, Meals, Settings, Search)
6. Verify: all tabs show empty states with action buttons

**Expected**: Welcome completes, all 5 tabs accessible, no crashes.

---

## Test 2: Recipe Import from URL

**Steps:**
1. Tap Recipes tab
2. Tap "Browse for Recipe" or the globe icon
3. Navigate to: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
4. Tap the import button in the browser
5. Wait for extraction → import preview should appear
6. Verify: title shows "Spicy Shrimp Tacos with Garlic Cilantro Lime Slaw"
7. Verify: ingredients are listed with status dots (green/amber/plus icons)
8. Verify: "2 teaspoons each chili powder and cumin" was AUTO-SPLIT into two entries
9. Verify: "sour cream or full-fat Greek yogurt" shows amber "Contains alternatives" indicator
10. Verify: no "Split" indicator on non-compound ingredients
11. Tap "Save"
12. Verify: recipe appears in Recipes tab
13. Tap the recipe → verify detail view shows all ingredients with bold green names

**Expected**: Recipe imports cleanly, ingredients parsed, split/alternative indicators visible.

---

## Test 3: Import Guide Walkthrough (First Import Only)

**Steps:**
1. On first import (Test 2), the 5-step import guide should appear over the preview
2. Step 1: "Review the Recipe" — spotlights title area
3. Step 2: "Ingredient Status" — spotlights ingredient row
4. Step 3: "Smart Indicators" — explains split/alternative rows
5. Step 4: "AI-Powered Parsing" — spotlights Parse with AI button
6. Step 5: "Save Your Recipe" — spotlights Save button with "Got It" button
7. Tap through all steps or skip
8. Verify: subsequent imports do NOT show the guide

**Expected**: Guide appears once, teaches key features, doesn't repeat.

---

## Test 4: Recipe Detail View

**Steps:**
1. From Recipes tab, tap the imported recipe
2. Verify: title, servings, prep/cook time displayed
3. Verify: ingredient rows show green bullet + bold ingredient name + category dot
4. Verify: scaling pills visible (1/2x through 3x)
5. Tap 2x scaling → verify quantities double
6. Tap 1x to reset
7. Scroll to instructions → verify numbered steps
8. Verify: "Add to Grocery List" button visible

**Expected**: Recipe detail renders correctly, scaling works, all sections present.

---

## Test 5: Meal Plan Creation

**Steps:**
1. Tap Meals tab
2. Tap + to create new meal plan
3. Enter name: "Test Week"
4. Set duration and start day
5. Tap Create
6. Verify: meal plan card appears with day dots
7. Tap into the meal plan detail
8. Verify: calendar strip is centered
9. Tap a day → search for the imported recipe → add it
10. Verify: recipe appears on that day with servings and Done/Swap/Remove buttons

**Expected**: Meal plan created, recipe assigned to a day, calendar centered.

---

## Test 6: Generate Grocery List from Meal Plan

**Steps:**
1. From meal plan detail, tap "Add to Grocery List"
2. Select or create a grocery list
3. Verify: ingredients from the recipe appear on the grocery list
4. Verify: ingredient names are CLEAN (qty + ingredient, no qualifiers)
5. Verify: "shrimp" not "large shrimp, peeled and deveined, tails removed"
6. Verify: category dots appear below each item
7. Verify: items are grouped by category (Produce, Deli & Meat, etc.)

**Expected**: Grocery list generated with clean names, proper categories, no qualifier clutter.

---

## Test 7: Shopping List Interaction

**Steps:**
1. Tap Lists tab → tap the grocery list
2. Verify: items show boxed card style matching recipe detail
3. Tap checkbox on an item → verify strikethrough + green check
4. Tap again → verify unchecked
5. Verify: progress bar updates at bottom
6. Tap book icon in toolbar → verify recipe source toggle works
7. With sources on: verify subtle gray bulleted recipe names below items
8. With sources off: verify recipe names hidden
9. Quick-add bar: type "butter" → verify search icon + plain text field styling

**Expected**: All shopping interactions work, recipe source toggle works, card styling consistent.

---

## Test 8: Settings Navigation

**Steps:**
1. Tap Settings tab
2. Tap Ingredients → verify ingredients list loads → tap back
3. Tap Categories → verify categories list loads → tap back
4. Tap Restore Default Categories → verify confirmation dialog → Cancel
5. Scroll to AI Integration → toggle on → verify provider shows "Claude (API Key)"
6. Toggle off
7. Scroll to Diagnostics → tap Diagnostic Log → verify log viewer → back
8. Scroll to About → tap Replay Onboarding → verify welcome carousel appears → skip
9. Tap Replay Import Guide → verify "Ready" indicator appears

**Expected**: All Settings items independently tappable, no navigation conflicts.

---

## Test 9: Recipe Filters

**Steps:**
1. Tap Recipes tab
2. Verify: All / Favorites / Recent pills visible
3. Tap Favorites → verify empty state with "Heart a recipe to see it here"
4. Verify: All / Favorites / Recent pills STILL VISIBLE (not hidden)
5. Tap All → recipes reappear
6. Tap Recent → verify empty or shows recipes
7. Go to recipe detail → tap heart icon → go back
8. Tap Favorites → verify recipe appears

**Expected**: Filter pills always visible, favorites filter works.

---

## Test 10: Search

**Steps:**
1. Tap Search tab
2. Type recipe name → verify results appear
3. Type ingredient name → verify template results
4. Clear search → verify empty state

**Expected**: Search returns relevant results across recipes and ingredients.

---

## Test 11: Visual Regression (Dark Mode)

**Steps:**
1. Switch simulator to dark mode: `xcrun simctl ui booted appearance dark`
2. Navigate through all 5 tabs
3. Verify: no white backgrounds, all text readable, cards have proper borders
4. Check: Settings, recipe detail, grocery list detail, meal plan detail
5. Switch back to light mode: `xcrun simctl ui booted appearance light`
6. Verify: warm cream backgrounds, proper contrast

**Expected**: Both modes render correctly with ForagerTheme colors.

---

## Test 12: Long-Press Name Editing

**Steps:**
1. Create a grocery list → long-press the list name on the card → verify edit mode
2. Change name → press Done → verify saved
3. Create a meal plan → long-press plan name → verify edit mode
4. From grocery list detail → long-press navigation title → verify edit mode
5. From meal plan detail → long-press navigation title → verify edit mode

**Expected**: Long-press editing works on all list/plan names (card and detail views).

---

## Test 13: Multi-Ingredient Splitting

**Steps:**
1. Import a recipe that has compound ingredients (the Spicy Shrimp Tacos recipe works)
2. On import preview, verify "each X and Y" lines were auto-split
3. If any unsplit "and" lines remain, verify green "Tap to split" row appears
4. Tap the split row → verify line splits into two entries
5. Verify "or" alternatives show amber indicator (not split)
6. Save and verify: recipe has clean individual ingredients

**Expected**: Auto-split works, manual split works, alternatives flagged but not split.

---

## Not Tested (Requires Real Devices)

- Household creation and sharing
- Member invitation acceptance
- CloudKit sync between devices
- Returning user detection after reinstall
- CKShare permission management
- Household API key sharing

These are tested manually on physical devices (Rich, Mary, Joe).
