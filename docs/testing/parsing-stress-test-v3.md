# Parsing Stress Test v3 — Validated URLs + Bug Fixes

**Purpose**: Retest M9.35 parsing fixes with VALIDATED URLs only. All URLs verified working.
**Branch**: `main` (all fixes merged)
**Build**: Build from Xcode (Product > Run), iPhone 17 Pro simulator

---

## CRITICAL: Test Procedure

Follow this cycle for EVERY recipe:

1. **Build and run** from Xcode (Product > Run)
2. Skip welcome walkthrough if it appears
3. Import the recipe URL → check import preview → record results
4. Tap Cancel (do NOT save)
5. **Write results** — append to results file immediately
6. **Delete the app**: `xcrun simctl uninstall booted com.richhayn.forager`
7. **Quit simulator**: Simulator > Quit Simulator (Cmd+Q)
8. **Wait 3 seconds**
9. **Relaunch from Xcode** — Product > Run
10. Repeat for next recipe

Write results to: `/Users/rich/Development/forager/docs/testing/stress-test-v3-results.md`

---

## What to Capture Per Recipe

| Column | What to Record |
|--------|---------------|
| Ingr | Total ingredients extracted |
| Word-Split | "eg g", "lemo n" style bugs (should be 0 now) |
| Word-Merge | "vinegaror", "yogurtor" style bugs (should be 0 now) |
| Prep-in-Name | Prep instructions left in name count |
| Site Junk | Prices, notes, metrics left in name count |
| F+ Alt | False positive alternative banners |
| Fail? | Import failure |

---

## Recipe List (30 Recipes — All URLs Verified Working in v2)

### From v2 Successes (25 recipes)
1. `https://www.allrecipes.com/recipe/23600/worlds-best-lasagna/`
2. `https://www.budgetbytes.com/one-pot-creamy-cajun-chicken-pasta/`
3. `https://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe-1939524`
4. `https://www.recipetineats.com/honey-garlic-chicken/`
5. `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
6. `https://www.simplyrecipes.com/recipes/chicken_fried_rice/`
7. `https://www.loveandlemons.com/caprese-salad/`
8. `https://www.budgetbytes.com/creamy-tomato-spinach-pasta/`
9. `https://www.budgetbytes.com/hearty-black-bean-quesadillas/`
10. `https://www.recipetineats.com/chicken-parmigiana/`
11. `https://www.recipetineats.com/teriyaki-chicken/`
12. `https://www.loveandlemons.com/stir-fry-recipe/`
13. `https://www.budgetbytes.com/sesame-noodles/`
14. `https://www.simplyrecipes.com/recipes/chicken_noodle_soup/`
15. `https://www.budgetbytes.com/chunky-lentil-vegetable-soup/`
16. `https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/`
17. `https://www.loveandlemons.com/blueberry-muffins/`
18. `https://www.loveandlemons.com/vegetable-curry/`
19. `https://www.simplyrecipes.com/recipes/homemade_pizza/`
20. `https://cookieandkate.com/vegetarian-chili-recipe/`
21. `https://sallysbakingaddiction.com/best-homemade-bread/`
22. `https://www.recipetineats.com/caesar-salad/`
23. `https://cookieandkate.com/best-lentil-soup-recipe/`
24. `https://damndelicious.net/2020/01/25/roasted-leg-of-lamb/`
25. `https://www.skinnytaste.com/greek-salad-dressing/`

### New Replacements (5 recipes — diversify sources)
26. `https://www.onceuponachef.com/recipes/chicken-tortilla-soup.html`
27. `https://www.gimmesomeoven.com/baked-chicken-breast/`
28. `https://natashaskitchen.com/perfect-salmon-recipe/`
29. `https://www.inspiredtaste.net/15938/easy-and-smooth-hummus-recipe/`
30. `https://minimalistbaker.com/easy-vegan-fried-rice/`

---

## Key Regression Checks

These MUST be verified — they were bugs in v1/v2:

| # | Check | Recipe | v2 Result | Expected v3 |
|---|-------|--------|-----------|------------|
| 1 | "egg" word-split | #1, #16 | "eg g" / "egg s" | PASS — no split |
| 2 | "vinegaror" word-merge | #7, #18 | space lost before "or" | PASS — space preserved |
| 3 | Budget Bytes "$0.50" | #2, #8, #9, #13, #15 | prices in name | PASS — stripped |
| 4 | RecipeTinEats "((Note 1))" | #4, #10, #11, #22 | double-parens in name | PASS — stripped |
| 5 | "(for garnish)" in name | multiple | in name | PASS — moved to notes |
| 6 | "garlic, finely minced" | multiple | prep in name | PASS — separated |
| 7 | Metric "(90g)" leakage | new sites if applicable | metrics in name | PASS — stripped |
| 8 | "&frac12;" HTML entity | #20 | literal text | PASS — decoded to "1/2" |
| 9 | "avocado s" plural split | #5 | trailing letter split | PASS — no split |
| 10 | "more or less" false positive | #5 | excluded | PASS — still excluded |

---

## Results Table Template

```
| # | Source | Recipe Name | Ingr | Word-Split | Word-Merge | Prep-in-Name | Site Junk | F+ Alt | Fail? |
|---|--------|------------|------|-----------|-----------|-------------|----------|--------|-------|
| 1 | AllRecipes | Lasagna | 20 | 0 | 0 | 3 | 0 | 0 | No |
```

---

## Summary Template

```
Total recipes tested: X / 30
Successful imports: X
Failed imports: X

Issue counts:
- Word-split bugs: X (v2 baseline: 5)
- Word-merge bugs: X (v2 baseline: 15)
- Prep in names: X (v2 baseline: 157)
- Site-specific junk: X (v2 baseline: 128)
- Total issues: X (v2 baseline: 333)

Improvement vs v2: X% reduction
```
