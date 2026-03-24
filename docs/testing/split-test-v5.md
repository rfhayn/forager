# Split Test v5 — Whitespace Fix Verification

**Purpose**: Verify the Unicode whitespace normalization fix for ingredient splitting.
**Branch**: `main`
**Build**: Build from Xcode (Product > Run), iPhone 17 Pro simulator
**Recipe URL**: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`

---

## Setup

1. Build and run from Xcode to iPhone 17 Pro simulator
2. Skip welcome walkthrough if shown
3. Delete any existing "Spicy Shrimp Tacos" recipe if present

---

## Test 1: Both "each" Lines Auto-Split

**Steps:**
1. Import the recipe URL
2. Skip import guide if shown
3. Check the import preview ingredients list

**Verify:**
- "2 teaspoons each chili powder and cumin" auto-split into TWO rows: "2 teaspoons chili powder" + "2 teaspoons cumin"
- "1/2 teaspoon each onion powder and garlic powder" auto-split into TWO rows: "1/2 teaspoon onion powder" + "1/2 teaspoon garlic powder"
- NO green "Tap to split" banners should remain (both lines auto-split)

**Check console for:**
```
🔀 localSplitText split: first='chili powder' second='cumin'
🔀 localSplitText split: first='onion powder' second='garlic powder'
```

**Result:** PASS / FAIL

---

## Test 2: "or" Alternatives Correct

**Verify on import preview:**
- "1/2 cup sour cream or full-fat Greek yogurt" — amber "Contains alternatives" banner (CORRECT)
- "8 small tortillas (corn or flour)" — amber banner (CORRECT)
- "1/4 teaspoon cayenne pepper (more or less to taste)" — NO amber banner (the "more or less" false positive should be fixed)

**Result:** PASS / FAIL

---

## Test 3: Banner Tap Works (if any unsplit lines remain)

If any green "Tap to split" banners are visible:
1. Tap the banner
2. Ingredient should split into two rows immediately

If no banners remain (all auto-split), this test is N/A (PASS by default).

**Result:** PASS / FAIL / N/A

---

## Test 4: Save and Verify

1. Tap Save
2. Open the saved recipe detail
3. Scroll through ingredients

**Verify:**
- "chili powder" — separate entry with "2 teaspoons"
- "cumin" — separate entry with "2 teaspoons"
- "onion powder" — separate entry with "1/2 teaspoon"
- "garlic powder" — separate entry with "1/2 teaspoon"
- "sour cream or full-fat Greek yogurt" — ONE entry (not split)

**Result:** PASS / FAIL

---

## Results Template

```
Test 1 (Both auto-split):  PASS / FAIL
Test 2 (Alternatives):     PASS / FAIL
Test 3 (Banner tap):       PASS / FAIL / N/A
Test 4 (Save & verify):    PASS / FAIL

Console output (all 🔀 lines):
[paste here]
```
