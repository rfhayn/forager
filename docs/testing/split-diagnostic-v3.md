# Split Diagnostic Test — v3

**Purpose**: Capture console output to diagnose why split isn't working.
**Branch**: `main` (all fixes merged)
**Build**: Build from Xcode to iPhone 17 Pro simulator (Product > Run)

## IMPORTANT: Verify the build

Before testing, check the Xcode console shows the build starting. You should see CoreML/Espresso messages. If you don't see any console output at all, the console isn't connected.

## Steps

1. Build and run Forager from Xcode to the simulator
2. Skip welcome walkthrough if it appears
3. Go to Recipes tab
4. Import: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
5. Wait for import preview to appear
6. Skip import guide if it appears
7. **IMMEDIATELY check the Xcode console** for lines starting with `🔀`

## Expected Console Output

You should see lines like:
```
🔀 M9.33: Auto-split scanning XX ingredients
🔀 [8] has 'and'/'each': '2 teaspoons each chili powder and cumin' detected=true
🔀 Split result for [8]: ["2 teaspoons chili powder", "2 teaspoons cumin"]
🔀 [9] has 'and'/'each': '1/2 teaspoon each onion powder and garlic powder' detected=true
🔀 Split result for [9]: ["1/2 teaspoon onion powder", "1/2 teaspoon garlic powder"]
```

## What to Capture

1. **ALL lines containing `🔀`** — copy and paste them
2. **ALL lines containing `M9.33`** — copy and paste them
3. If NO `🔀` lines appear, note that explicitly
4. Take a screenshot of the import preview showing the ingredient list

## Then Test the Banner Tap

1. Find any ingredient with a green "Tap to split" banner
2. Tap the banner
3. Check console for: `🔀 performSplit at X: '...'`
4. Note whether the ingredient split or not

## Results Template

```
Console output on import preview load:
[paste all 🔀 lines here]

Banner tap console output:
[paste all 🔀 lines here, or "no output"]

Did the ingredient split after tapping banner? YES / NO

Screenshot: [describe what you see]
```
