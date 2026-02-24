# Recipe Import Test Site Matrix

**Date**: February 24, 2026
**Purpose**: Concrete URL list for JSON-LD extraction spike testing
**Total Sites**: 28 URLs across 4 tiers

---

## Tier 1: Major Recipe Platforms (9 sites)

High-traffic sites expected to have well-formed JSON-LD for Google Rich Results.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 1 | Allrecipes | https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/ | Yes | | | |
| 2 | Food Network | https://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe-1939524 | Yes | | | |
| 3 | Epicurious | https://www.epicurious.com/recipes/food/views/ba-syn-chocolate-chip-cookies | Yes | | | |
| 4 | Bon Appetit | https://www.bonappetit.com/recipe/classic-banana-bread | Yes | | | |
| 5 | Serious Eats | https://www.seriouseats.com/classic-banana-bread-recipe | Yes | | | |
| 6 | Simply Recipes | https://www.simplyrecipes.com/recipes/homemade_pizza/ | Yes | | | |
| 7 | Tasty | https://tasty.co/recipe/the-best-ever-chili | Yes | | | |
| 8 | Delish | https://www.delish.com/cooking/recipe-ideas/a23584/perfect-chocolate-chip-cookies-recipe/ | Yes | | | |
| 9 | Budget Bytes | https://www.budgetbytes.com/one-pot-chicken-and-rice/ | Yes | | | |

## Tier 2: Food Blogs (9 sites)

Popular food blogs, typically using WordPress recipe plugins (WPRM, Tasty Recipes, etc.).

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 10 | Sally's Baking Addiction | https://sallysbakingaddiction.com/best-brownies/ | Yes (WPRM) | | | |
| 11 | Half Baked Harvest | https://www.halfbakedharvest.com/better-than-takeout-kung-pao-cauliflower/ | Yes | | | |
| 12 | Pinch of Yum | https://pinchofyum.com/the-best-soft-chocolate-chip-cookies | Yes (Tasty) | | | |
| 13 | Minimalist Baker | https://minimalistbaker.com/perfect-banana-bread/ | Yes (WPRM) | | | |
| 14 | Cookie and Kate | https://cookieandkate.com/best-lentil-soup-recipe/ | Yes (WPRM) | | | |
| 15 | RecipeTin Eats | https://www.recipetineats.com/honey-garlic-chicken/ | Yes | | | |
| 16 | Smitten Kitchen | https://smittenkitchen.com/2019/01/chocolate-peanut-butter-cup-cookies/ | Yes (Jetpack) | | | |
| 17 | Love and Lemons | https://www.loveandlemons.com/best-pasta-salad-recipe/ | Yes (WPRM) | | | |
| 18 | Damn Delicious | https://damndelicious.net/2023/01/14/slow-cooker-beef-stew/ | Yes (WPRM) | | | |

## Tier 3: Challenging Sources (6 sites)

Known difficult or failure cases — validates graceful degradation.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 19 | NYT Cooking (paywall) | https://cooking.nytimes.com/recipes/1017937-chocolate-chip-cookies | Partial (paywall) | | | |
| 20 | Cook's Illustrated (paywall) | https://www.cooksillustrated.com/recipes/11904-perfect-french-omelets | Partial (paywall) | | | |
| 21 | Pinterest pin | https://www.pinterest.com/pin/360006563956104785/ | No (link aggregator) | | | |
| 22 | Plain blog (no JSON-LD) | https://www.101cookbooks.com/archives/the-best-black-bean-enchiladas-recipe.html | Possibly no | | | |
| 23 | GitHub Markdown recipe | https://github.com/kkga/no-bs-cookbook/blob/main/banana-bread.md | No | | | |
| 24 | Microdata only (no JSON-LD) | https://www.kingarthurbaking.com/recipes/classic-birthday-cake-recipe | Yes (may use both) | | | |

## Tier 4: International (4 sites)

Non-US sites — different JSON-LD patterns, metric units, potentially non-English content.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 25 | BBC Good Food | https://www.bbcgoodfood.com/recipes/classic-victoria-sponge | Yes | | | |
| 26 | Jamie Oliver | https://www.jamieoliver.com/recipes/chicken-recipes/classic-roast-chicken/ | Yes | | | |
| 27 | Marmiton (French) | https://www.marmiton.org/recettes/recette_gateau-au-yaourt_12719.aspx | Yes | | | |
| 28 | Chefkoch (German) | https://www.chefkoch.de/rezepte/1170581223320028/Lasagne.html | Yes | | | |

---

## Results Summary

_To be filled after extraction spike runs._

| Metric | Value |
|--------|-------|
| **Total sites tested** | 28 |
| **JSON-LD found** | /28 |
| **Full extraction (all core fields)** | /28 |
| **Partial extraction (some fields)** | /28 |
| **No extraction possible** | /28 |
| **@graph wrapper encountered** | /28 |
| **Array @type encountered** | /28 |
| **HowToStep instructions** | /28 |
| **HowToSection nesting** | /28 |
| **Unusual recipeYield formats** | /28 |
| **HTML entities in JSON-LD** | /28 |
| **Median extraction time** | ms |
| **Sites that blocked URLSession** | /28 |

## Edge Case Catalog

_To be filled during extraction spike._

| Edge Case | Sites Affected | Impact | Handling |
|-----------|---------------|--------|----------|
| | | | |

## Failure Taxonomy

_To be filled during extraction spike._

| Failure Type | Count | Example Sites | Mitigation |
|-------------|-------|---------------|------------|
| No JSON-LD on page | | | Fall through to heuristic |
| Paywall blocks content | | | Show partial + message |
| URLSession blocked (403) | | | User-Agent rotation or WKWebView |
| Malformed JSON | | | Error handling + fallback |
| Recipe nested in @graph | | | Recursive search |
| No recipe in JSON-LD | | | Check @type thoroughly |
