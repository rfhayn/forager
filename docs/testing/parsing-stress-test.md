# Parsing & Splitting Stress Test — 50 Recipes

**Purpose**: Import 50 diverse recipes to identify parsing gaps, splitting failures, and false positives across real-world ingredient formats.
**Branch**: `main`
**Build**: Build from Xcode (Product > Run), iPhone 17 Pro simulator
**Duration**: ~60-90 minutes

---

## Setup

1. Build and run Forager from Xcode to iPhone 17 Pro simulator
2. Skip welcome walkthrough
3. Skip import guide on first import
4. For each recipe: Import → check preview → note issues → Cancel (don't save, to keep data clean)

---

## What to Capture Per Recipe

For EACH recipe, record in the results table:

1. **Recipe #** and **URL**
2. **Total ingredients** extracted
3. **Auto-splits**: How many "Tap to split" banners appeared? How many auto-split on load?
4. **False positive splits**: Any split banners on single ingredients? (e.g., "bread and butter")
5. **False positive alternatives**: Any amber banners on non-alternative lines? (e.g., "more or less")
6. **Missed compounds**: Any "X and Y" lines that should have been detected but weren't?
7. **Parsing issues**: Any ingredients that parsed incorrectly (wrong quantity, name, or garbled text)?
8. **Extraction failures**: Did the import fail or return zero ingredients?

---

## Recipe List (50 Recipes — Diverse Sources)

### American / Comfort (1-10)
1. `https://www.allrecipes.com/recipe/23600/worlds-best-lasagna/`
2. `https://www.budgetbytes.com/one-pot-creamy-cajun-chicken-pasta/`
3. `https://damndelicious.net/2019/04/18/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw/`
4. `https://www.simplyrecipes.com/recipes/homemade_mac_and_cheese/`
5. `https://cafedelites.com/best-hamburger-patties/`
6. `https://www.skinnytaste.com/turkey-chili/`
7. `https://www.recipetineats.com/honey-garlic-chicken/`
8. `https://hostthetoast.com/the-best-grilled-cheese-sandwich/`
9. `https://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe-1939524`
10. `https://www.delish.com/cooking/recipe-ideas/a25648/chicken-pot-pie-recipe/`

### Italian (11-15)
11. `https://www.simplyrecipes.com/recipes/spaghetti_carbonara/`
12. `https://www.recipetineats.com/chicken-parmesan/`
13. `https://www.loveandlemons.com/caprese-salad/`
14. `https://cafedelites.com/tuscan-chicken/`
15. `https://www.budgetbytes.com/italian-wonderpot/`

### Mexican / Latin (16-20)
16. `https://www.simplyrecipes.com/recipes/chicken_enchiladas/`
17. `https://www.recipetineats.com/mexican-rice/`
18. `https://www.budgetbytes.com/black-bean-quesadillas/`
19. `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
20. `https://www.skinnytaste.com/chicken-burrito-bowl/`

### Asian (21-30)
21. `https://www.recipetineats.com/chicken-stir-fry/`
22. `https://www.budgetbytes.com/easy-pad-thai/`
23. `https://damndelicious.net/2018/12/01/instant-pot-lo-mein/`
24. `https://www.simplyrecipes.com/recipes/chicken_fried_rice/`
25. `https://cafedelites.com/thai-coconut-curry/`
26. `https://www.recipetineats.com/teriyaki-chicken/`
27. `https://www.skinnytaste.com/asian-lettuce-wraps/`
28. `https://www.loveandlemons.com/vegetable-stir-fry/`
29. `https://damndelicious.net/2019/02/16/korean-beef-bowl/`
30. `https://www.budgetbytes.com/sesame-noodles/`

### Soups & Salads (31-35)
31. `https://www.simplyrecipes.com/recipes/chicken_noodle_soup/`
32. `https://www.recipetineats.com/caesar-salad/`
33. `https://www.budgetbytes.com/chunky-lentil-vegetable-soup/`
34. `https://cafedelites.com/broccoli-cheddar-soup/`
35. `https://www.skinnytaste.com/greek-salad/`

### Baking & Desserts (36-40)
36. `https://www.simplyrecipes.com/recipes/banana_bread/`
37. `https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/`
38. `https://www.recipetineats.com/easy-pancake-recipe/`
39. `https://www.loveandlemons.com/blueberry-muffins/`
40. `https://cafedelites.com/best-fudgy-brownies/`

### Seafood (41-45)
41. `https://www.recipetineats.com/baked-salmon-with-lemon/`
42. `https://www.simplyrecipes.com/recipes/grilled_shrimp/`
43. `https://www.budgetbytes.com/lemon-garlic-shrimp-pasta/`
44. `https://cafedelites.com/pan-seared-salmon/`
45. `https://www.skinnytaste.com/shrimp-scampi/`

### Vegetarian / Vegan (46-50)
46. `https://www.loveandlemons.com/vegetable-curry/`
47. `https://www.budgetbytes.com/greek-stuffed-peppers/`
48. `https://www.simplyrecipes.com/recipes/vegetarian_chili/`
49. `https://minimalistbaker.com/easy-vegan-fried-rice/`
50. `https://www.skinnytaste.com/eggplant-parmesan/`

---

## Results Table Template

For each recipe, fill in one row:

```
| # | Source | Ingredients | Auto-Splits | Split Banners | False+ Split | False+ Alt | Missed Compounds | Parse Issues | Extract Fail |
|---|--------|-------------|-------------|---------------|-------------|-----------|-----------------|-------------|-------------|
| 1 | allrecipes | 22 | 0 | 0 | 0 | 0 | 0 | none | no |
| 2 | budgetbytes | 15 | 1 | 0 | 0 | 0 | 0 | none | no |
```

---

## Detailed Issue Logging

For any issues found, log the details below the table:

```
### Recipe #X: [Recipe Name]
**URL**: [url]
**Issue**: [description]
**Ingredient text**: "[exact text from import preview]"
**Expected**: [what should happen]
**Actual**: [what did happen]
```

---

## Categories of Issues to Watch For

### Splitting Issues
- Compound ingredients not detected ("garlic and ginger" left as one)
- False positive splits ("bread and butter pudding" flagged incorrectly)
- "Each" pattern not handled ("1 tsp each salt and pepper")
- Quantity not distributed correctly after split

### Alternative Issues
- "Or" alternatives not flagged ("chicken or tofu" missing amber banner)
- False positive alternatives ("season with salt or to taste" flagged)
- Parenthetical alternatives missed ("tortillas (corn or flour)")

### Parsing Issues
- Wrong quantity extracted ("2-3 cloves garlic" → wrong number)
- Unit confusion ("1 can (14 oz) tomatoes" → unit is "can" not "oz")
- Name includes prep words ("finely diced onion" → name should be "onion")
- Notes not separated ("flour, sifted" → "sifted" should be in notes)
- Multiple items on one line not detected ("salt, pepper, and paprika")

### Extraction Issues
- Zero ingredients extracted (site blocks scraping)
- Ingredients from wrong section (instructions mixed in)
- Duplicate ingredients
- Missing ingredients (partial extraction)

---

## Summary Template

At the end, provide:

```
## Summary

Total recipes tested: X / 50
Successful imports: X
Failed imports: X (list URLs)

Split detection:
- Total auto-splits triggered: X
- Total split banners shown: X
- False positive splits: X
- Missed compounds: X

Alternative detection:
- Total amber banners shown: X
- False positive alternatives: X

Parsing issues: X total
- Wrong quantity: X
- Wrong name: X
- Missing ingredients: X
- Other: X

Top 5 most common issues:
1. [description]
2. [description]
3. [description]
4. [description]
5. [description]
```
