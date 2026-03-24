# Split Ingredient Test Plan v2 — Claude Desktop + Simulator

**Purpose**: Retest the 3 bugs found in v1: banner tap, context menu split, false positive detection.
**Simulator**: iPhone 17 Pro
**Build**: Build from Xcode first (branch `feature/M9.33-split-fixes`), Debug config
**Recipe URL**: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`

---

## Pre-Test Setup

1. In Terminal, verify the correct branch:
   ```
   cd /Users/rich/Development/forager && git branch
   ```
   Should show `* feature/M9.33-split-fixes`

2. Build and run from Xcode to the iPhone 17 Pro simulator (Product > Run or Cmd+R)
3. If welcome walkthrough appears, skip through it
4. Delete any existing imported copy of "Spicy Shrimp Tacos" recipe if present

---

## Test 1: Auto-Split on Import (Regression Check)

**Steps:**
1. Go to Recipes tab
2. Import the recipe URL: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
3. Wait for import preview to load
4. If the import guide overlay appears, skip it

**Verify:**
- "2 teaspoons each chili powder and cumin" should be AUTO-SPLIT into two separate rows: "2 teaspoons chili powder" and "2 teaspoons cumin"
- This worked in v1 and should still work

**Check Xcode console for:**
```
🔀 M9.33: Auto-split scanning XX ingredients
🔀 Detected multi-ingredient at X: '2 teaspoons each chili powder and cumin'
🔀 Split result: ["2 teaspoons chili powder", "2 teaspoons cumin"]
```

**Result:** PASS / FAIL

---

## Test 2: Banner Tap Split (Bug Fix #1)

**Steps:**
1. On the import preview, find "1/2 teaspoon each onion powder and garlic powder"
2. It should have a green banner below it: "Tap to split into separate ingredients"
3. Tap the green banner — tap directly on the text or the arrow icon
4. The ingredient should split into two rows immediately

**Expected after tap:**
- Original row replaced with: "1/2 teaspoon onion powder" and "1/2 teaspoon garlic powder"
- Green banner disappears
- Ingredient count increases by 1
- Both new rows have status dots and parsed display

**Check Xcode console for:**
```
🔀 performSplit at X: '1/2 teaspoon each onion powder and garlic powder'
🔀 Split result: ["1/2 teaspoon onion powder", "1/2 teaspoon garlic powder"]
```

**If tap doesn't work, check console for:**
```
⚠️ M9.33: localSplitText returned 1 result — no split performed
```
This would mean the text doesn't match the split pattern. Copy the exact text from the console output.

**Result:** PASS / FAIL

---

## Test 3: Context Menu Split (Bug Fix #2)

**Steps:**
1. If Test 2 passed and the ingredient was already split, import the recipe AGAIN to get a fresh preview
2. Find an unsplit compound ingredient (any line with green "Tap to split" banner)
3. Long-press (hold for 2-3 seconds) on the ingredient row itself (not the banner)
4. Context menu should appear
5. Tap "Split Ingredients"
6. The ingredient should split into two rows

**Expected:**
- Context menu appears with "Split Ingredients" option
- Tapping it splits the ingredient
- Same split result as Test 2

**Check Xcode console for:**
```
🔀 performSplit at X: '...'
🔀 Split result: [...]
```

**Result:** PASS / FAIL

---

## Test 4: False Positive Fix (Bug Fix #3)

**Steps:**
1. On the import preview, find "1/4 teaspoon cayenne pepper (more or less to taste)"
2. Check if an amber "Contains alternatives" banner appears below it

**Expected:**
- NO amber banner should appear (the "or" in "more or less" is not an ingredient alternative)
- This was a false positive in v1 that should now be fixed

**Also verify these still show amber banners correctly:**
- "1/2 cup sour cream or full-fat Greek yogurt" — should still show amber banner (real alternative)
- "8 small tortillas (corn or flour)" — should still show amber banner (real alternative)

**Result:** PASS / FAIL

---

## Test 5: Save and Verify

**Steps:**
1. After all splits are done, tap Save
2. Go to the saved recipe detail
3. Scroll through ingredients

**Verify:**
- "chili powder" and "cumin" are separate ingredients with correct quantities
- "onion powder" and "garlic powder" are separate ingredients (if Test 2 passed)
- "sour cream or full-fat Greek yogurt" is ONE ingredient (not split)
- "cayenne pepper" has no alternative indicator in the saved view

**Result:** PASS / FAIL

---

## Console Output to Capture

Copy ALL lines from Xcode console that start with `🔀` or `⚠️ M9.33` and paste them at the bottom of the results.

---

## Results Template

```
Test 1 (Auto-Split): PASS / FAIL
Test 2 (Banner Tap): PASS / FAIL
Test 3 (Context Menu): PASS / FAIL
Test 4 (False Positive): PASS / FAIL
Test 5 (Save & Verify): PASS / FAIL

Console output:
[paste here]
```
