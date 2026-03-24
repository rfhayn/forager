# Parsing Stress Test v2 — Post-M9.35 Hardening

**Purpose**: Validate M9.35 parsing fixes against 50 recipes. Regression test on working recipes + new URLs replacing broken ones.
**Branch**: `feature/M9.35-parsing-pipeline-hardening`
**Build**: Build from Xcode (Product > Run), iPhone 17 Pro simulator
**Duration**: ~60-90 minutes

---

## Setup

1. Build and run from Xcode to iPhone 17 Pro simulator
2. Skip welcome walkthrough
3. For each recipe: Import → check preview → note issues → Cancel (don't save)

---

## What to Capture Per Recipe

For EACH recipe, record:

1. **Recipe #** and **URL**
2. **Total ingredients** extracted
3. **Auto-splits**: How many auto-split on load?
4. **Split banners**: How many "Tap to split" banners remain?
5. **False positive splits**: Split banners on single ingredients?
6. **False positive alternatives**: Amber banners on non-alternative lines?
7. **Missed compounds**: "X and Y" lines that should have been detected but weren't?
8. **Word-split bugs**: Any "eg g", "lemo n" style splits? (P0 regression check)
9. **Prep in names**: Any prep/notes text left in ingredient names? (P1 check)
10. **Site junk**: Any prices, note references, double-parens in names? (P2 check)
11. **Extraction failures**: Did the import fail or return zero ingredients?

---

## Recipe List (50 Recipes)

### American / Comfort (1-10)
1. `https://www.allrecipes.com/recipe/23600/worlds-best-lasagna/`
2. `https://www.budgetbytes.com/one-pot-creamy-cajun-chicken-pasta/`
3. `https://damndelicious.net/2018/12/01/instant-pot-lo-mein/`
4. `https://www.simplyrecipes.com/one-pot-mac-and-cheese-recipe-7964109`
5. `https://www.seriouseats.com/the-best-buffalo-wings-oven-fried-wings-recipe`
6. `https://www.skinnytaste.com/turkey-chili-taco-soup/`
7. `https://www.recipetineats.com/honey-garlic-chicken/`
8. `https://sallysbakingaddiction.com/best-homemade-bread/`
9. `https://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe-1939524`
10. `https://cookieandkate.com/best-lentil-soup-recipe/`

### Italian (11-15)
11. `https://www.simplyrecipes.com/pasta-carbonara-recipe-7643664`
12. `https://www.recipetineats.com/chicken-parmesan/`
13. `https://www.loveandlemons.com/caprese-salad/`
14. `https://www.seriouseats.com/the-best-slow-cooked-bolognese-sauce-recipe`
15. `https://www.budgetbytes.com/creamy-tomato-spinach-pasta/`

### Mexican / Latin (16-20)
16. `https://www.simplyrecipes.com/red-chile-chicken-enchiladas-recipe-7643839`
17. `https://www.recipetineats.com/mexican-rice/`
18. `https://www.budgetbytes.com/hearty-black-bean-quesadillas/`
19. `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
20. `https://www.skinnytaste.com/chicken-burrito-bowls/`

### Asian (21-30)
21. `https://www.recipetineats.com/chicken-stir-fry/`
22. `https://www.budgetbytes.com/pad-thai/`
23. `https://damndelicious.net/2019/02/16/korean-beef-bowl/`
24. `https://www.simplyrecipes.com/recipes/chicken_fried_rice/`
25. `https://www.seriouseats.com/thai-green-curry-recipe`
26. `https://www.recipetineats.com/teriyaki-chicken/`
27. `https://www.skinnytaste.com/asian-lettuce-wraps/`
28. `https://www.loveandlemons.com/stir-fry-recipe/`
29. `https://halfbakedharvest.com/better-than-takeout-kung-pao-chicken/`
30. `https://www.budgetbytes.com/sesame-noodles/`

### Soups & Salads (31-35)
31. `https://www.simplyrecipes.com/recipes/chicken_noodle_soup/`
32. `https://www.recipetineats.com/caesar-salad/`
33. `https://www.budgetbytes.com/chunky-lentil-vegetable-soup/`
34. `https://www.seriouseats.com/french-onion-soup-recipe`
35. `https://www.skinnytaste.com/greek-salad/`

### Baking & Desserts (36-40)
36. `https://sallysbakingaddiction.com/best-banana-bread-recipe/`
37. `https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/`
38. `https://www.recipetineats.com/easy-pancake-recipe/`
39. `https://www.loveandlemons.com/blueberry-muffins/`
40. `https://halfbakedharvest.com/better-than-mix-fudgy-cocoa-brownies/`

### Seafood (41-45)
41. `https://www.recipetineats.com/baked-salmon-with-lemon/`
42. `https://www.simplyrecipes.com/recipes/grilled_shrimp/`
43. `https://www.budgetbytes.com/lemon-garlic-shrimp-pasta/`
44. `https://www.seriouseats.com/pan-seared-salmon-recipe`
45. `https://www.skinnytaste.com/shrimp-scampi-with-zoodles/`

### Vegetarian / Vegan (46-50)
46. `https://www.loveandlemons.com/vegetable-curry/`
47. `https://www.budgetbytes.com/greek-stuffed-peppers/`
48. `https://www.simplyrecipes.com/recipes/homemade_pizza/`
49. `https://cookieandkate.com/vegetarian-chili-recipe/`
50. `https://www.skinnytaste.com/eggplant-parmesan/`

---

## Changes from v1

**Replaced (broken sites):**
- cafedelites x6 → SeriousEats x4, HalfBakedHarvest x2 (no Cloudflare blocks)
- hostthetoast → SallysBakingAddiction (bread recipe)
- delish → CookieAndKate (lentil soup)

**Updated URLs (404'd in v1):**
- SimplyRecipes: using current URLs instead of old `/recipes/` format
- Recipe #5 changed to SeriousEats buffalo wings
- Recipe #36 changed to SallysBakingAddiction banana bread

**New sources added:**
- SeriousEats (4 recipes) — well-structured JSON-LD
- SallysBakingAddiction (2 recipes) — baking-focused with precise measurements
- HalfBakedHarvest (2 recipes) — complex ingredients with lots of qualifiers
- CookieAndKate (2 recipes) — vegetarian focus, clean formatting

---

## Results Table Template

```
| # | Source | Recipe Name | Ingr | Auto-Splits | Split Banners | F+ Split | F+ Alt | Missed | Word-Split | Prep-in-Name | Site Junk | Fail? |
|---|--------|------------|------|-------------|---------------|----------|--------|--------|-----------|-------------|----------|-------|
| 1 | allrecipes | Lasagna | 19 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | No |
```

---

## Detailed Issue Logging

For any issues found:

```
### Recipe #X: [Recipe Name]
**URL**: [url]
**Issue type**: [word-split | prep-in-name | site-junk | false-positive | missed-compound | extraction-fail]
**Ingredient text**: "[exact text from import preview]"
**Expected**: [what should happen]
**Actual**: [what did happen]
```

---

## Key Regression Checks (from v1)

These specific items MUST be verified:

| Check | v1 Result | Expected v2 |
|-------|-----------|------------|
| "egg" word-split ("eg g") | FAIL | PASS — merged by P2 |
| "lemon" word-split ("lemo n") | FAIL | PASS — merged by P2 |
| "jalapeño" word-split ("jalape ño") | FAIL | PASS — merged by P2 |
| Budget Bytes "$0.50" in name | FAIL | PASS — stripped by P1 |
| RecipeTinEats "((Note 1))" in name | FAIL | PASS — stripped by P1 |
| "garlic, minced" prep in name | FAIL | PASS — separated by P3 |
| "(for garnish)" in name | FAIL | PASS — moved to notes by P3 |
| "2 or 3 tablespoons" range in name | FAIL | PASS — parsed by P4 |
| "more or less to taste" false positive | FAIL | PASS — excluded |
| "1/2 tsp each onion powder and garlic powder" split | FAIL in v1 | PASS — Unicode whitespace normalized |

---

## Summary Template

```
## Summary

Total recipes tested: X / 50
Successful imports: X
Failed imports: X (list URLs)

Parse issue counts:
- Word-split bugs: X (was 10+ in v1)
- Prep in names: X (was ~285 in v1)
- Site-specific junk: X (was ~65 in v1)
- Orphan fragments: X (was 5+ in v1)
- False positive split/alt: X
- Missed compounds: X
- Quantity range issues: X (was 5+ in v1)
- Total issues: X (was ~300 in v1)

Improvement: X% reduction in total issues
```
