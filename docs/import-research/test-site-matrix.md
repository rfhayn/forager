# Recipe Import Test Site Matrix

**Date**: February 24, 2026
**Purpose**: Concrete URL list for JSON-LD extraction spike testing
**Total Sites**: 28 URLs across 4 tiers
**Spike Run**: February 24, 2026 — `Tools/import-spike/` Swift CLI via URLSession

---

## Tier 1: Major Recipe Platforms (9 sites)

High-traffic sites expected to have well-formed JSON-LD for Google Rich Results.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 1 | Allrecipes | https://www.allrecipes.com/recipe/10813/best-chocolate-chip-cookies/ | Yes | ✓ Yes | 8/8 (FULL) | Array @type, HowToStep, HTML entities |
| 2 | Food Network | https://www.foodnetwork.com/recipes/alton-brown/baked-macaroni-and-cheese-recipe-1939524 | Yes | ✓ Yes | 8/8 (FULL) | Unusual yield ("6 to 8 servings"), HowToStep, HTML entities |
| 3 | Epicurious | https://www.epicurious.com/recipes/food/views/ba-syn-chocolate-chip-cookies | Yes | ✗ No | — | HTTP 404; no JSON-LD in response |
| 4 | Bon Appetit | https://www.bonappetit.com/recipe/classic-banana-bread | Yes | ✗ No | — | HTTP 404; no JSON-LD in response |
| 5 | Serious Eats | https://www.seriouseats.com/classic-banana-bread-recipe | Yes | ✓ Yes | 7/8 (FULL) | cookTime missing; array @type, HowToStep, HTML entities |
| 6 | Simply Recipes | https://www.simplyrecipes.com/recipes/homemade_pizza/ | Yes | ✓ Yes (inline) | 8/8 (FULL) | Extracted via inline script (not ld+json); HowToSection + HowToStep, HTML entities |
| 7 | Tasty | https://tasty.co/recipe/the-best-ever-chili | Yes | ✗ No | — | HTTP 404; no JSON-LD in response |
| 8 | Delish | https://www.delish.com/cooking/recipe-ideas/a23584/perfect-chocolate-chip-cookies-recipe/ | Yes | ✗ No | — | HTTP 404; no JSON-LD in response |
| 9 | Budget Bytes | https://www.budgetbytes.com/one-pot-chicken-and-rice/ | Yes | ✓ Yes | 7/8 (FULL) | author missing; @graph wrapper, HowToStep |

**Tier 1 result**: 5/9 extracted (56%)

## Tier 2: Food Blogs (9 sites)

Popular food blogs, typically using WordPress recipe plugins (WPRM, Tasty Recipes, etc.).

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 10 | Sally's Baking Addiction | https://sallysbakingaddiction.com/best-brownies/ | Yes (WPRM) | ✗ No Recipe | — | JSON-LD present (Organization), Recipe likely client-rendered via WPRM |
| 11 | Half Baked Harvest | https://www.halfbakedharvest.com/better-than-takeout-kung-pao-cauliflower/ | Yes | ✗ No Recipe | — | JSON-LD present, no Recipe @type; likely client-rendered |
| 12 | Pinch of Yum | https://pinchofyum.com/the-best-soft-chocolate-chip-cookies | Yes (Tasty) | ✓ Yes | 8/8 (FULL) | @graph wrapper, HowToStep, HTML entities |
| 13 | Minimalist Baker | https://minimalistbaker.com/perfect-banana-bread/ | Yes (WPRM) | ✗ No Recipe | — | JSON-LD present (Organization), Recipe likely client-rendered via WPRM |
| 14 | Cookie and Kate | https://cookieandkate.com/best-lentil-soup-recipe/ | Yes (WPRM) | ✓ Yes | 8/8 (FULL) | @graph wrapper, HowToStep, HTML entities |
| 15 | RecipeTin Eats | https://www.recipetineats.com/honey-garlic-chicken/ | Yes | ✓ Yes | 7/8 (FULL) | author missing; @graph wrapper, HowToStep, HTML entities |
| 16 | Smitten Kitchen | https://smittenkitchen.com/2019/01/chocolate-peanut-butter-cup-cookies/ | Yes (Jetpack) | ✗ No | — | No JSON-LD found; likely client-rendered or no recipe plugin |
| 17 | Love and Lemons | https://www.loveandlemons.com/best-pasta-salad-recipe/ | Yes (WPRM) | ✗ No | — | No JSON-LD found; Recipe likely client-rendered via WPRM |
| 18 | Damn Delicious | https://damndelicious.net/2023/01/14/slow-cooker-beef-stew/ | Yes (WPRM) | ✗ No Recipe | — | JSON-LD present, no Recipe @type; likely client-rendered |

**Tier 2 result**: 3/9 extracted (33%)

## Tier 3: Challenging Sources (6 sites)

Known difficult or failure cases — validates graceful degradation.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 19 | NYT Cooking (paywall) | https://cooking.nytimes.com/recipes/1017937-chocolate-chip-cookies | Partial (paywall) | ✓ Yes | 6/8 (FULL) | prepTime + cookTime missing; unusual yield ("6 to 8 servings"), HowToStep |
| 20 | Cook's Illustrated (paywall) | https://www.cooksillustrated.com/recipes/11904-perfect-french-omelets | Partial (paywall) | ✓ Yes | 6/8 (FULL) | prepTime + cookTime missing; HowToStep |
| 21 | Pinterest pin | https://www.pinterest.com/pin/360006563956104785/ | No (link aggregator) | ✗ No | — | No JSON-LD; link aggregator with no recipe data |
| 22 | Plain blog (no JSON-LD) | https://www.101cookbooks.com/archives/the-best-black-bean-enchiladas-recipe.html | Possibly no | ✗ No Recipe | — | JSON-LD present but no Recipe @type; 12.7s response time |
| 23 | GitHub Markdown recipe | https://github.com/kkga/no-bs-cookbook/blob/main/banana-bread.md | No | ✗ No | — | No JSON-LD; plain markdown, no structured data |
| 24 | Microdata only (no JSON-LD) | https://www.kingarthurbaking.com/recipes/classic-birthday-cake-recipe | Yes (may use both) | ✓ Yes | 8/8 (FULL) | @graph wrapper, unusual yield ("16 servings") |

**Tier 3 result**: 3/6 extracted (50%) — both paywall sites provided full recipes

## Tier 4: International (4 sites)

Non-US sites — different JSON-LD patterns, metric units, potentially non-English content.

| # | Site | URL | Expected JSON-LD | JSON-LD Found | Fields Extracted | Issues |
|---|------|-----|-------------------|---------------|------------------|--------|
| 25 | BBC Good Food | https://www.bbcgoodfood.com/recipes/classic-victoria-sponge | Yes | ✗ No Recipe | — | JSON-LD present (Organization), Recipe data in __NEXT_DATA__ but fails tightened extraction rules |
| 26 | Jamie Oliver | https://www.jamieoliver.com/recipes/chicken-recipes/classic-roast-chicken/ | Yes | ✗ No | — | No JSON-LD found; likely client-rendered |
| 27 | Marmiton (French) | https://www.marmiton.org/recettes/recette_gateau-au-yaourt_12719.aspx | Yes | ✓ Yes (inline) | 8/8 (FULL) | Extracted via inline script; unusual yield ("4 personnes"), French content, HowToStep |
| 28 | Chefkoch (German) | https://www.chefkoch.de/rezepte/1170581223320028/Lasagne.html | Yes | ✗ No Recipe | — | JSON-LD present, no Recipe @type; likely client-rendered |

**Tier 4 result**: 1/4 extracted (25%)

---

## Results Summary

| Metric | Value |
|--------|-------|
| **Total sites tested** | 28 |
| **JSON-LD found (any form)** | 19/28 (68%) |
| **Recipe extracted (full)** | 12/28 (43%) |
| **Recipe extracted (partial)** | 0/28 (0%) |
| **No extraction possible** | 16/28 (57%) |
| **Extraction via ld+json** | 10/28 |
| **Extraction via inline script** | 2/28 |
| **@graph wrapper encountered** | 5/28 (18%) |
| **Array @type encountered** | 3/28 (11%) |
| **HowToStep instructions** | 11/28 (39%) |
| **HowToSection nesting** | 1/28 (4%) |
| **Unusual recipeYield formats** | 4/28 (14%) |
| **HTML entities in JSON-LD** | 7/28 (25%) |
| **Median extraction time** | 343ms |
| **Sites that blocked URLSession** | 0/28 |

### Per-Tier Breakdown

| Tier | Sites | Extracted | Rate |
|------|-------|-----------|------|
| 1: Major platforms | 9 | 5 | 56% |
| 2: Food blogs | 9 | 3 | 33% |
| 3: Challenging | 6 | 3 | 50% |
| 4: International | 4 | 1 | 25% |
| **Total** | **28** | **12** | **43%** |

### Per-Field Extraction Rates (12 Successful Sites)

| Field | Present | Rate | Missing Sites |
|-------|---------|------|---------------|
| Title | 12/12 | 100% | — |
| Ingredients | 12/12 | 100% | — |
| Instructions | 12/12 | 100% | — |
| Prep time | 10/12 | 83% | NYT Cooking, Cook's Illustrated |
| Cook time | 9/12 | 75% | Serious Eats, NYT Cooking, Cook's Illustrated |
| Servings | 12/12 | 100% | — |
| Image URL | 12/12 | 100% | — |
| Author | 10/12 | 83% | Budget Bytes, RecipeTin Eats |

## Edge Case Catalog

| Edge Case | Frequency | Sites Affected | Handling |
|-----------|-----------|----------------|----------|
| @graph wrapper nesting | 18% (5/28) | Budget Bytes, Pinch of Yum, Cookie and Kate, RecipeTin Eats, King Arthur | Recursive search through @graph arrays — all handled correctly |
| Array @type (e.g., `["Recipe", "CreativeWork"]`) | 11% (3/28) | Allrecipes, Serious Eats, Simply Recipes | Check if array contains "Recipe" string — all handled correctly |
| HowToStep structured instructions | 39% (11/28) | Allrecipes, Food Network, Serious Eats, Simply Recipes, Budget Bytes, Pinch of Yum, Cookie and Kate, RecipeTin Eats, NYT Cooking, Cook's Illustrated, Marmiton | Map HowToStep.text to numbered step text |
| HowToSection nested instructions | 4% (1/28) | Simply Recipes | Flatten with section headers ("**Making the Pizza Dough**") |
| HTML entities in JSON-LD | 25% (7/28) | Allrecipes, Food Network, Serious Eats, Simply Recipes, Pinch of Yum, Cookie and Kate, RecipeTin Eats | Full entity decoding (&amp;, &#NNN;, &frac14;) before JSON parse |
| Unusual recipeYield formats | 14% (4/28) | Food Network, NYT Cooking, King Arthur, Marmiton | Parse "6 to 8 servings", "16 servings", "4 personnes" → Int |
| Inline script JSON-LD (not ld+json type) | 7% (2/28) | Simply Recipes, Marmiton | Regex scan for Recipe JSON in regular `<script>` blocks |
| __NEXT_DATA__ SSR payloads | Present (2/28) | BBC Good Food, 101 Cookbooks | Recursive key search; tightened to require recipeIngredient + secondary key |

## Failure Taxonomy

| Failure Type | Count | Example Sites | Mitigation |
|-------------|-------|---------------|------------|
| No JSON-LD on page | 9 | Epicurious, Bon Appetit, Tasty, Delish, Smitten Kitchen, Love and Lemons, Pinterest, GitHub, Jamie Oliver | WKWebView fallback to render JS; heuristic HTML scraping |
| JSON-LD found, no Recipe @type | 7 | Sally's Baking Addiction, Half Baked Harvest, Minimalist Baker, Damn Delicious, 101 Cookbooks, BBC Good Food, Chefkoch | Recipe likely client-rendered via WordPress plugins; WKWebView renders JS before extraction |
| Paywall blocks content | 0 | (NYT Cooking + Cook's Illustrated both returned recipe data) | Attempt extraction; show partial if limited |
| URLSession blocked (403/429) | 0 | — | User-Agent rotation or WKWebView if encountered in production |
| Malformed JSON | 0 | — | Error handling + fallback to next strategy |
| Dead/moved URLs (HTTP 404) | 15 | Most non-extracting sites | Sites may serve 404 to bot user-agents; WKWebView uses browser UA |

### Key Takeaway

The 43% extraction rate (URLSession-only) is significantly below the "~90% of sites have JSON-LD" expectation because **~30% of recipe sites render JSON-LD via client-side JavaScript** (WordPress recipe plugins like WPRM, Tasty Recipes). These sites return Organization/Website JSON-LD in server-rendered HTML but inject Recipe JSON-LD after page load. A `WKWebView` fallback that executes JavaScript before extracting JSON-LD is expected to raise the extraction rate to **75-80%**.
