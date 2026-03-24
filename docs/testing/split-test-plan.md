# Split Ingredient Test Plan — Claude Desktop + Simulator

**Purpose**: Test the multi-ingredient splitting feature on the import preview screen.
**Simulator**: iPhone 17 Pro
**Build**: Latest Debug build from Xcode
**Recipe URL**: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`

---

## Setup

1. Open the iOS Simulator (iPhone 17 Pro)
2. Build and run Forager from Xcode (Debug config)
3. If the welcome walkthrough appears, tap through all 3 screens to dismiss
4. Navigate to the Recipes tab

---

## Test 1: Import Recipe and Check Auto-Split

**Steps:**
1. Tap the globe icon or "Browse for Recipe" to open the in-app browser
2. Navigate to: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
3. Wait for the page to load, then tap the Import button
4. Wait for extraction — the import preview screen should appear
5. If the import guide overlay appears (5-step walkthrough), tap through it or tap Skip

**Check these ingredients on the preview:**

| Original line from recipe | Expected behavior |
|--------------------------|-------------------|
| "2 teaspoons each chili powder and cumin" | Should be AUTO-SPLIT into two rows: "2 teaspoons chili powder" and "2 teaspoons cumin" |
| "1/2 teaspoon each onion powder and garlic powder" | Should either be auto-split into "1/2 teaspoon onion powder" + "1/2 teaspoon garlic powder", OR show a green "Tap to split" banner below it |
| "1/2 cup sour cream or full-fat Greek yogurt" | Should NOT be split. Should show amber "Contains alternatives — consider choosing one" banner |
| "8 small tortillas (corn or flour)" | Should NOT be split (parenthetical alternative). May show amber alternative indicator |

**Pass criteria:**
- At least the first "each X and Y" line is auto-split
- "or" alternatives are NOT split
- Green split banners appear on any remaining unsplit "and" lines
- Amber alternative banners appear on "or" lines

---

## Test 2: Tap the Split Banner

**Steps:**
1. On the import preview, find any ingredient with a green "Tap to split into separate ingredients" banner below it
2. Tap the green banner
3. The ingredient should split into two separate rows immediately
4. The green banner should disappear after splitting
5. The new rows should each have their own status dot and parsed display

**Pass criteria:**
- Tapping the green banner splits the ingredient into two rows
- Both new rows have quantities distributed correctly
- The split banner disappears after splitting
- Ingredient count increases by 1

**If the banner doesn't respond to taps:**
- Try tapping directly on the text "Tap to split into separate ingredients"
- Try tapping the arrow icon on the left of the banner
- Check the Xcode console for debug output starting with "🔀"
- Report the exact console output

---

## Test 3: Verify Split Results After Save

**Steps:**
1. After splitting all compound ingredients, tap Save
2. Navigate to the saved recipe in the Recipes tab
3. Tap to open the recipe detail
4. Scroll through ingredients

**Check:**
- "chili powder" and "cumin" appear as separate ingredients (not combined)
- "onion powder" and "garlic powder" appear as separate ingredients
- Each has the correct quantity (e.g., "2 teaspoons chili powder")
- "sour cream or full-fat Greek yogurt" appears as ONE ingredient (not split)

---

## Test 4: Context Menu Split (Backup Method)

**Steps:**
1. Import the same recipe again (or a new one with compound ingredients)
2. On the import preview, find a compound ingredient that was NOT auto-split
3. Long-press (press and hold for 2 seconds) on the ingredient row
4. A context menu should appear
5. Look for "Split Ingredients" option in the menu
6. Tap "Split Ingredients"
7. The ingredient should split into two rows

**Pass criteria:**
- Context menu appears on long-press
- "Split Ingredients" option is visible (only on detected compound lines)
- Tapping it splits the ingredient

---

## Test 5: Alternative Indicator (No Split)

**Steps:**
1. On the import preview, find "sour cream or full-fat Greek yogurt"
2. Verify an amber banner appears below it: "Contains alternatives — consider choosing one"
3. Verify there is NO green "Tap to split" banner on this line
4. The amber banner should NOT be tappable (informational only)

**Pass criteria:**
- Amber indicator appears on "or" ingredients
- No split action available for alternatives
- Alternatives stay as single ingredients after save

---

## Debug Information

If any test fails, capture the following from the Xcode console:

1. Lines starting with `🔀` — these show split detection and results
2. Lines starting with `⚠️ M9.33` — these show split failures
3. The exact ingredient text that failed to split (copy from console)

Also take a screenshot of the import preview showing the problematic ingredient.

---

## Expected Console Output (Success)

```
🔀 M9.33: Auto-split scanning 19 ingredients
🔀 Detected multi-ingredient at 8: '2 teaspoons each chili powder and cumin'
🔀 Split result: ["2 teaspoons chili powder", "2 teaspoons cumin"]
🔀 Detected multi-ingredient at 9: '1/2 teaspoon each onion powder and garlic powder'
🔀 Split result: ["1/2 teaspoon onion powder", "1/2 teaspoon garlic powder"]
```

If tapping the split banner:
```
🔀 performSplit at 10: '1/2 teaspoon each onion powder and garlic powder'
🔀 Split result: ["1/2 teaspoon onion powder", "1/2 teaspoon garlic powder"]
```
