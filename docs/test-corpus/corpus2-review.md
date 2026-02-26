# Recipe Corpus 2 — Validation Set Review File

**Generated**: 2026-02-26T15:30:32Z
**Total Recipes**: 50
**Purpose**: Validation corpus — unseen recipes to verify pipeline generalization.

---

## Summary Statistics

| Category | Recipes | Lines | Ingredients |
|----------|---------|-------|-------------|
| clean | 10 | 228 | 95 |
| no-headers | 10 | 175 | 81 |
| unusual-metadata | 10 | 256 | 119 |
| messy | 10 | 146 | 47 |
| international | 10 | 248 | 111 |

### Quantity Extraction

- **With qty**: 421/453 (92.9%)
- **Nil qty**: 32

### Classification Distribution

| Type | Count | % |
|------|-------|---|
| title | 92 | 8.7% |
| ingredient | 453 | 43.0% |
| instruction | 278 | 26.4% |
| metadata | 100 | 9.5% |
| sectionHeader | 72 | 6.8% |
| unknown | 58 | 5.5% |

### Parser Usage

| Parser | Count | % |
|--------|-------|---|
| regex | 416 | 91.8% |
| ml | 37 | 8.2% |
| nlp | 0 | 0.0% |

---

## clean-01-beef-sunday-roast

**Category**: clean | **Lines**: 24 | **Ingredients found**: 7

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Sunday Roast | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 8 slices Beef | ingredient | 0.95 | Y | |
| 7 | - 12 florets Broccoli | ingredient | 0.60 | Y | |
| 8 | - 1 Packet Potatoes | ingredient | 0.60 | Y | |
| 9 | - 1 Packet Carrots | ingredient | 0.60 | Y | |
| 10 | - 140g plain flour | ingredient | 0.60 | Y | |
| 11 | - 4 Eggs | ingredient | 0.60 | Y | |
| 12 | - 200ml milk | ingredient | 0.60 | Y | |
| 13 | - drizzle (for cooking) sunflower oil | instruction | 0.40 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Cook the Broccoli and Carrots in a pan of boiling water until tender. | instruction | 0.60 | Y | |
| 16 | 2. Roast the Beef and Potatoes in the oven for 45mins, the potatoes may need to  | instruction | 0.70 | Y | |
| 17 | 3. To make the Yorkshire puddings: | instruction | 0.30 | Y | |
| 18 | 4. Heat oven to 230C/fan 210C/gas 8. Drizzle a little sunflower oil evenly into  | instruction | 0.60 | Y | |
| 19 | 5. To make the batter, tip 140g plain flour into a bowl and beat in four eggs un | instruction | 0.30 | Y | |
| 20 | 6. Plate up and add the Gravy as desired. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 8 slices Beef | 8 | slice | Beef | 1.00 | regex | Y | |
| 7 | - 12 florets Broccoli | 12 | — | florets Broccoli | 0.92 | regex | Y | |
| 8 | - 1 Packet Potatoes | 1 | — | Packet Potatoes | 0.92 | regex | Y | |
| 9 | - 1 Packet Carrots | 1 | — | Packet Carrots | 0.92 | regex | Y | |
| 10 | - 140g plain flour | 140 | g | plain flour | 1.00 | regex | Y | |
| 11 | - 4 Eggs | 4 | — | Egg s | 0.92 | regex | Y | |
| 12 | - 200ml milk | 200 | ml | milk | 1.00 | regex | Y | |

---

## clean-02-mini-chilli-beef-pies

**Category**: clean | **Lines**: 29 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Mini chilli beef pies | title | 0.50 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 450g Ready rolled shortcrust pastry | ingredient | 0.60 | Y | |
| 7 | - 1 tablespoon Sunflower Oil | ingredient | 0.95 | Y | |
| 8 | - 1 small Onion | ingredient | 0.60 | Y | |
| 9 | - 2 tsp Hot Chilli Powder | ingredient | 0.95 | Y | |
| 10 | - 2 tsp Ground Cumin | ingredient | 0.95 | Y | |
| 11 | - 250g Minced Beef | ingredient | 0.60 | Y | |
| 12 | - 85g Tomato Puree | ingredient | 0.60 | Y | |
| 13 | - 150ml Beef Stock | ingredient | 0.60 | Y | |
| 14 | - Pinch Ground Cinnamon | ingredient | 0.45 | Y | |
| 15 | - 200g Kidney Beans | ingredient | 0.60 | Y | |
| 16 | - 1 large Potatoes | ingredient | 0.60 | Y | |
| 17 | - 3  tablespoons Sour Cream | ingredient | 0.95 | Y | |
| 18 | - 2 tablespoons Chopped Chive | ingredient | 0.95 | Y | |
| 19 | Instructions: | sectionHeader | 0.90 | Y | |
| 20 | 1. step 1 | instruction | 0.30 | Y | |
| 21 | 2. To make chilli, heat oil in a pan and fry onion for 5 mins until soft. Add sp | instruction | 0.30 | Y | |
| 22 | 3. step 2 | instruction | 0.30 | Y | |
| 23 | 4. Heat oven to 200C/fan 180C/gas 6. Using a 7cm pastry cutter, stamp out 12 cir | instruction | 0.70 | Y | |
| 24 | 5. step 3 | instruction | 0.30 | Y | |
| 25 | 6. Meanwhile, cook the potato in boiling water until tender. Drain, mash with so | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 450g Ready rolled shortcrust pastry | 450 | g | Ready rolled shortcrust pastry | 1.00 | regex | Y | |
| 7 | - 1 tablespoon Sunflower Oil | 1 | tbsp | Sunflower Oil | 1.00 | regex | Y | |
| 8 | - 1 small Onion | 1 | — | small Onion | 0.92 | regex | Y | |
| 9 | - 2 tsp Hot Chilli Powder | 2 | tsp | Hot Chilli Powder | 1.00 | regex | Y | |
| 10 | - 2 tsp Ground Cumin | 2 | tsp | Ground Cumin | 1.00 | regex | Y | |
| 11 | - 250g Minced Beef | 250 | g | Minced Beef | 1.00 | regex | Y | |
| 12 | - 85g Tomato Puree | 85 | g | Tomato Puree | 1.00 | regex | Y | |
| 13 | - 150ml Beef Stock | 150 | ml | Beef Stock | 1.00 | regex | Y | |
| 14 | - Pinch Ground Cinnamon | 0.12 | — | ground cinnamon | 0.95 | regex | Y | |
| 15 | - 200g Kidney Beans | 200 | g | Kidney Beans | 1.00 | regex | Y | |
| 16 | - 1 large Potatoes | 1 | — | large Potatoes | 0.92 | regex | Y | |
| 17 | - 3  tablespoons Sour Cream | 3 | tbsp | Sour Cream | 1.00 | regex | Y | |
| 18 | - 2 tablespoons Chopped Chive | 2 | tbsp | Chopped Chive | 1.00 | regex | Y | |

---

## clean-03-peanut-butter-cheesecake

**Category**: clean | **Lines**: 26 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Peanut Butter Cheesecake | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 50g Butter | ingredient | 0.60 | Y | |
| 7 | - 175g Peanut Cookies | ingredient | 0.60 | Y | |
| 8 | - 5 Gelatine Leafs | ingredient | 0.60 | Y | |
| 9 | - 500g Ricotta | ingredient | 0.60 | Y | |
| 10 | - 175g Peanut Butter | ingredient | 0.60 | Y | |
| 11 | - 175g Golden Syrup | ingredient | 0.60 | Y | |
| 12 | - 150ml Milk | ingredient | 0.60 | Y | |
| 13 | - 275ml Double Cream | ingredient | 0.60 | Y | |
| 14 | - 2 tblsp Light Brown Soft Sugar | ingredient | 0.60 | Y | |
| 15 | - Crushed Peanut Brittle | title | 0.30 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Oil and line a 20cm round loose- bottomed cake tin with cling film, making it | ingredient | 0.35 | Y | |
| 18 | 2. Soak the gelatine in water while you make the filling. Tip the ricotta into a | instruction | 0.30 | Y | |
| 19 | 3. Take the soaked gelatine from the water and squeeze dry. Put it into a pan wi | instruction | 0.30 | Y | |
| 20 | 4. To freeze, leave in the tin and as soon as it is solid, cover the surface wit | instruction | 0.30 | Y | |
| 21 | 5. To defrost, thaw in the fridge overnight. | instruction | 0.30 | Y | |
| 22 | 6. To serve, carefully remove from the tin. Whisk the cream with the sugar until | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 50g Butter | 50 | g | Butter | 1.00 | regex | Y | |
| 7 | - 175g Peanut Cookies | 175 | g | Peanut Cookies | 1.00 | regex | Y | |
| 8 | - 5 Gelatine Leafs | 5 | — | Gelatine Leafs | 0.92 | regex | Y | |
| 9 | - 500g Ricotta | 500 | g | Ricotta | 1.00 | regex | Y | |
| 10 | - 175g Peanut Butter | 175 | g | Peanut Butter | 1.00 | regex | Y | |
| 11 | - 175g Golden Syrup | 175 | g | Golden Syrup | 1.00 | regex | Y | |
| 12 | - 150ml Milk | 150 | ml | Milk | 1.00 | regex | Y | |
| 13 | - 275ml Double Cream | 275 | ml | Double Cream | 1.00 | regex | Y | |
| 14 | - 2 tblsp Light Brown Soft Sugar | 2 | — | tblsp Light Brown Soft Sugar | 0.92 | regex | Y | |
| 17 | 1. Oil and line a 20cm round loose- bottomed cake tin with c | 1 | — | oil and line a 20cm round loos | 0.67 | ml | Y | |

---

## clean-04-potato-salad-olivier-salad

**Category**: clean | **Lines**: 29 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Potato Salad (Olivier Salad) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 4 Potatoes | ingredient | 0.60 | Y | |
| 7 | - 3 Carrots | ingredient | 0.60 | Y | |
| 8 | - 1 tbs Salt | ingredient | 0.95 | Y | |
| 9 | - 1/2 tbs White Wine Vinegar | ingredient | 0.95 | Y | |
| 10 | - 4 Eggs | ingredient | 0.60 | Y | |
| 11 | - 7 oz Sausages | ingredient | 0.95 | Y | |
| 12 | - 4 oz Dill | ingredient | 0.95 | Y | |
| 13 | - 1 can Peas | ingredient | 0.95 | Y | |
| 14 | - 4 Onions | ingredient | 0.60 | Y | |
| 15 | - 1 cup Mayonnaise | ingredient | 0.95 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Cut the potatoes and carrots into small uniform cubes. | instruction | 0.40 | Y | |
| 18 | 2. Place them in a large pot and fill with water. | instruction | 0.40 | Y | |
| 19 | 3. Add salt and vinegar. Bring it to a boil over medium high heat, and then redu | instruction | 0.70 | Y | |
| 20 | 4. Meanwhile, cut the sausage and pickles into small cubes, and chop the green o | instruction | 0.30 | Y | |
| 21 | 5. Cut the hard-boiled eggs into small cubes as well. | instruction | 0.40 | Y | |
| 22 | 6. If using fresh dill, chop them as well. | instruction | 0.30 | Y | |
| 23 | 7. In a large bowl, combine potatoes, carrots, sausage, pickles, peas and green  | instruction | 0.30 | Y | |
| 24 | 8. Add mayo and dill and mix until well combined. | instruction | 0.40 | Y | |
| 25 | 9. Salt and pepper to taste. Cover with a plastic wrap and refrigerate for at le | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 4 Potatoes | 4 | — | Potatoe s | 0.92 | regex | Y | |
| 7 | - 3 Carrots | 3 | — | Carrot s | 0.92 | regex | Y | |
| 8 | - 1 tbs Salt | 1 | tbsp | Salt | 1.00 | regex | Y | |
| 9 | - 1/2 tbs White Wine Vinegar | 0.5 | tbsp | White Wine Vinegar | 1.00 | regex | Y | |
| 10 | - 4 Eggs | 4 | — | Egg s | 0.92 | regex | Y | |
| 11 | - 7 oz Sausages | 7 | oz | Sausages | 1.00 | regex | Y | |
| 12 | - 4 oz Dill | 4 | oz | Dill | 1.00 | regex | Y | |
| 13 | - 1 can Peas | 1 | can | Peas | 1.00 | regex | Y | |
| 14 | - 4 Onions | 4 | — | Onion s | 0.92 | regex | Y | |
| 15 | - 1 cup Mayonnaise | 1 | cup | Mayonnaise | 1.00 | regex | Y | |

---

## clean-05-mushroom-soup-with-buckwheat

**Category**: clean | **Lines**: 21 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Mushroom soup with buckwheat | title | 0.50 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 150g Mushrooms | ingredient | 0.60 | Y | |
| 7 | - 50g Buckwheat | ingredient | 0.60 | Y | |
| 8 | - 4 tbs Vegetable Oil | ingredient | 0.95 | Y | |
| 9 | - 40g Onion | ingredient | 0.60 | Y | |
| 10 | - 2 cloves Garlic | ingredient | 0.95 | Y | |
| 11 | - 1 Bay Leaf | ingredient | 0.60 | Y | |
| 12 | - 1tbsp Vegetable Stock Cube | ingredient | 0.60 | Y | |
| 13 | - 50 ml Sour Cream | ingredient | 0.95 | Y | |
| 14 | - Dash White Wine Vinegar | ingredient | 0.45 | Y | |
| 15 | - Top Parsley | title | 0.30 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Chop the onion and garlic, slice the mushrooms and wash the buckwheat. Heat t | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 150g Mushrooms | 150 | g | Mushrooms | 1.00 | regex | Y | |
| 7 | - 50g Buckwheat | 50 | g | Buckwheat | 1.00 | regex | Y | |
| 8 | - 4 tbs Vegetable Oil | 4 | tbsp | Vegetable Oil | 1.00 | regex | Y | |
| 9 | - 40g Onion | 40 | g | Onion | 1.00 | regex | Y | |
| 10 | - 2 cloves Garlic | 2 | clove | Garlic | 1.00 | regex | Y | |
| 11 | - 1 Bay Leaf | 1 | — | Bay Leaf | 0.92 | regex | Y | |
| 12 | - 1tbsp Vegetable Stock Cube | 1 | tbsp | Vegetable Stock Cube | 1.00 | regex | Y | |
| 13 | - 50 ml Sour Cream | 50 | ml | Sour Cream | 1.00 | regex | Y | |
| 14 | - Dash White Wine Vinegar | 0.12 | — | white wine vinegar | 0.95 | regex | Y | |

---

## clean-06-croatian-lamb-peka

**Category**: clean | **Lines**: 43 | **Ingredients found**: 14

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Croatian lamb peka | title | 0.50 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 600g Potatoes | ingredient | 0.60 | Y | |
| 7 | - 1 chopped Courgettes | ingredient | 0.60 | Y | |
| 8 | - 1 chopped Carrots | ingredient | 0.60 | Y | |
| 9 | - 1 chopped Green Pepper | ingredient | 0.60 | Y | |
| 10 | - 1 small Aubergine | ingredient | 0.60 | Y | |
| 11 | - 1 Large Chopped Onion | ingredient | 0.60 | Y | |
| 12 | - 800g Lamb Shoulder | ingredient | 0.60 | Y | |
| 13 | - 1 tbs Garlic Sauce | ingredient | 0.95 | Y | |
| 14 | - 1 tbs Tomato Puree | ingredient | 0.95 | Y | |
| 15 | - 80 ml Olive Oil | ingredient | 0.95 | Y | |
| 16 | - Sprinking Thyme | title | 0.30 | Y | |
| 17 | - 250ml White Wine | ingredient | 0.60 | Y | |
| 18 | - Pinch Pepper | ingredient | 0.45 | Y | |
| 19 | Instructions: | sectionHeader | 0.90 | Y | |
| 20 | 1. Preheat oven to 200°C fan / 220°C / 425°F / Gas mark 7 | instruction | 0.55 | Y | |
| 21 | 2. If you have not bought diced lamb, cut your lamb shoulder or leg into large c | instruction | 0.30 | Y | |
| 22 | 3. Chunks of chopped lamb of a red chopping board | instruction | 0.30 | Y | |
| 23 | 4. Make oil marinade - | instruction | 0.30 | Y | |
| 24 | 5. Mix 80ml of olive oil in a bowl with garlic puree, sundried tomato puree ,bla | instruction | 0.60 | Y | |
| 25 | 6. olive oil, gia sundried tomato puree and gia garlic puree and black pepper mi | instruction | 0.30 | Y | |
| 26 | 7. Add potatoes and vegetables into a large lidded casserole dish. | instruction | 0.60 | Y | |
| 27 | 8. Chopped up vegetables which consist of chopped up red onion, courgette, potat | instruction | 0.30 | Y | |
| 28 | 9. Place diced lamb on top of the vegetables, pour the marinade and wine over th | instruction | 0.60 | Y | |
| 29 | 10. Chunks of lamb covered in in a sundried tomato oil sauce which is on top of  | instruction | 0.30 | Y | |
| 30 | 11. Add the rosemary, thyme and sage, trying to keep the herbs on top. | instruction | 0.60 | Y | |
| 31 | 12. So you can easily remove the herb stalks once cooked. | ingredient | 0.45 | Y | |
| 32 | 13. Chunks of lamb coated in a sundried tomato oil sauce and covered with thyme, | instruction | 0.30 | Y | |
| 33 | 14. Place lid on the casserole dish and cook for 1hr 30 minute | instruction | 0.50 | Y | |
| 34 | 15. If you do not have a lid cover very well with kitchen foil | instruction | 0.30 | Y | |
| 35 | 16. Cast iron dish with lid on in the oven | instruction | 0.30 | Y | |
| 36 | 17. Take the lid off, remove any thick herb stems. Stir in 2 tbsp of olive oil. | ingredient | 0.45 | Y | |
| 37 | 18. Cook for a further 20-30 mins. | instruction | 0.50 | Y | |
| 38 | 19. Cooked Croatian Lamb Peka in a cast iron pan in the oven | instruction | 0.30 | Y | |
| 39 | 20. Serve with fresh homemade bread to dip into the juices. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 600g Potatoes | 600 | g | Potatoes | 1.00 | regex | Y | |
| 7 | - 1 chopped Courgettes | 1 | — | chopped Courgettes | 0.92 | regex | Y | |
| 8 | - 1 chopped Carrots | 1 | — | chopped Carrots | 0.92 | regex | Y | |
| 9 | - 1 chopped Green Pepper | 1 | — | chopped Green Pepper | 0.92 | regex | Y | |
| 10 | - 1 small Aubergine | 1 | — | small Aubergine | 0.92 | regex | Y | |
| 11 | - 1 Large Chopped Onion | 1 | — | Large Chopped Onion | 0.92 | regex | Y | |
| 12 | - 800g Lamb Shoulder | 800 | g | Lamb Shoulder | 1.00 | regex | Y | |
| 13 | - 1 tbs Garlic Sauce | 1 | tbsp | Garlic Sauce | 1.00 | regex | Y | |
| 14 | - 1 tbs Tomato Puree | 1 | tbsp | Tomato Puree | 1.00 | regex | Y | |
| 15 | - 80 ml Olive Oil | 80 | ml | Olive Oil | 1.00 | regex | Y | |
| 17 | - 250ml White Wine | 250 | ml | White Wine | 1.00 | regex | Y | |
| 18 | - Pinch Pepper | 0.12 | — | pepper | 0.95 | regex | Y | |
| 31 | 12. So you can easily remove the herb stalks once cooked. | 12 | can | easily remove the herb stalks  | 0.82 | ml | Y | |
| 36 | 17. Take the lid off, remove any thick herb stems. Stir in 2 | — | — | 17 | 0.65 | ml | Y | |

---

## clean-07-sugar-pie

**Category**: clean | **Lines**: 20 | **Ingredients found**: 7

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Sugar Pie | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 cups Brown Sugar | ingredient | 0.95 | Y | |
| 7 | - ¼ cup Butter | ingredient | 1.00 | Y | |
| 8 | - 2 Eggs | ingredient | 0.60 | Y | |
| 9 | - 1 tsp Vanilla Extract | ingredient | 0.95 | Y | |
| 10 | - 1 tsp Salt | ingredient | 0.95 | Y | |
| 11 | - ½ cup Plain Flour | ingredient | 1.00 | Y | |
| 12 | - 1 1/2 cups Milk | ingredient | 0.95 | Y | |
| 13 | Instructions: | sectionHeader | 0.90 | Y | |
| 14 | 1. Preheat oven to 350 degrees F (175 degrees C). Grease a 9-inch pie dish. | instruction | 0.75 | Y | |
| 15 | 2. Place the brown sugar and butter in a mixing bowl, and beat them together wit | instruction | 0.60 | Y | |
| 16 | 3. Bake in the preheated oven for 35 minutes; remove pie, and cover the rim with | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 cups Brown Sugar | 2 | cup | Brown Sugar | 1.00 | regex | Y | |
| 7 | - ¼ cup Butter | 0.25 | cup | Butter | 1.00 | regex | Y | |
| 8 | - 2 Eggs | 2 | — | Egg s | 0.92 | regex | Y | |
| 9 | - 1 tsp Vanilla Extract | 1 | tsp | Vanilla Extract | 1.00 | regex | Y | |
| 10 | - 1 tsp Salt | 1 | tsp | Salt | 1.00 | regex | Y | |
| 11 | - ½ cup Plain Flour | 0.5 | cup | Plain Flour | 1.00 | regex | Y | |
| 12 | - 1 1/2 cups Milk | 1.5 | cup | Milk | 1.00 | regex | Y | |

---

## clean-08-moroccan-carrot-soup

**Category**: clean | **Lines**: 32 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Moroccan Carrot Soup | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 6 chopped Carrots | ingredient | 0.60 | Y | |
| 7 | - 1 sliced Onion | ingredient | 0.60 | Y | |
| 8 | - 4 Garlic Clove | ingredient | 0.95 | Y | |
| 9 | - 1 tsp Cumin | ingredient | 0.95 | Y | |
| 10 | - 1/2 tsp Coriander | ingredient | 0.95 | Y | |
| 11 | - 1 tbs Olive Oil | ingredient | 0.95 | Y | |
| 12 | - 1/4 tsp Garam Masala | ingredient | 0.95 | Y | |
| 13 | - 1 tsp Lemon Juice | ingredient | 0.95 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Step 1 | instruction | 0.30 | Y | |
| 16 | 2. Preheat oven to 180° C. | instruction | 0.55 | Y | |
| 17 | 3. Step 2 | instruction | 0.30 | Y | |
| 18 | 4. Combine carrots, onion, garlic, cumin seeds, coriander seeds, salt and olive  | instruction | 0.60 | Y | |
| 19 | 5. Step 3 | instruction | 0.30 | Y | |
| 20 | 6. Put the baking tray in preheated oven and roast for 10-12 minutes or till car | instruction | 0.30 | Y | |
| 21 | 7. Step 4 | instruction | 0.30 | Y | |
| 22 | 8. Grind the baked carrot mixture along with some water to make a smooth paste a | instruction | 0.30 | Y | |
| 23 | 9. Step 5 | instruction | 0.30 | Y | |
| 24 | 10. Heat the carrot mixture in a non-stick pan. Add two cups of water and bring  | instruction | 0.60 | Y | |
| 25 | 11. Step 6 | instruction | 0.30 | Y | |
| 26 | 12. Remove from heat, add lemon juice and mix well. | instruction | 0.40 | Y | |
| 27 | 13. Step 7 | instruction | 0.30 | Y | |
| 28 | 14. Serve hot. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 6 chopped Carrots | 6 | — | chopped Carrots | 0.92 | regex | Y | |
| 7 | - 1 sliced Onion | 1 | — | sliced Onion | 0.92 | regex | Y | |
| 8 | - 4 Garlic Clove | 4 | — | Garlic Clove | 0.92 | regex | Y | |
| 9 | - 1 tsp Cumin | 1 | tsp | Cumin | 1.00 | regex | Y | |
| 10 | - 1/2 tsp Coriander | 0.5 | tsp | Coriander | 1.00 | regex | Y | |
| 11 | - 1 tbs Olive Oil | 1 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 12 | - 1/4 tsp Garam Masala | 0.25 | tsp | Garam Masala | 1.00 | regex | Y | |
| 13 | - 1 tsp Lemon Juice | 1 | tsp | Lemon Juice | 1.00 | regex | Y | |

---

## clean-09-croatian-bean-stew

**Category**: clean | **Lines**: 18 | **Ingredients found**: 7

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Croatian Bean Stew | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 cans Cannellini Beans | ingredient | 0.95 | Y | |
| 7 | - 3 tbs Vegetable Oil | ingredient | 0.95 | Y | |
| 8 | - 2 cups Tomatoes | ingredient | 0.95 | Y | |
| 9 | - 5 Challots | ingredient | 0.60 | Y | |
| 10 | - 2 cloves Garlic | ingredient | 0.95 | Y | |
| 11 | - Pinch Parsley | ingredient | 0.45 | Y | |
| 12 | - 1/2 kg chopped Chorizo | ingredient | 0.95 | Y | |
| 13 | Instructions: | sectionHeader | 0.90 | Y | |
| 14 | 1. Heat the oil in a pan. Add the chopped vegetables and sauté until tender. Tak | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 cans Cannellini Beans | 2 | can | Cannellini Beans | 1.00 | regex | Y | |
| 7 | - 3 tbs Vegetable Oil | 3 | tbsp | Vegetable Oil | 1.00 | regex | Y | |
| 8 | - 2 cups Tomatoes | 2 | cup | Tomatoes | 1.00 | regex | Y | |
| 9 | - 5 Challots | 5 | — | Challot s | 0.92 | regex | Y | |
| 10 | - 2 cloves Garlic | 2 | clove | Garlic | 1.00 | regex | Y | |
| 11 | - Pinch Parsley | 0.12 | — | parsley | 0.95 | regex | Y | |
| 12 | - 1/2 kg chopped Chorizo | 0.5 | kg | chopped Chorizo | 1.00 | regex | Y | |

---

## clean-10-lamb-pilaf-plov

**Category**: clean | **Lines**: 26 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Lamb Pilaf (Plov) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 50g Lamb | ingredient | 0.60 | Y | |
| 7 | - 120g Prunes | ingredient | 0.60 | Y | |
| 8 | - 1 tbs Lemon Juice | ingredient | 0.95 | Y | |
| 9 | - 2 tbs Butter | ingredient | 0.95 | Y | |
| 10 | - 1 chopped Onion | ingredient | 0.60 | Y | |
| 11 | - 450g Lamb | ingredient | 0.60 | Y | |
| 12 | - 2 cloves Garlic | ingredient | 0.95 | Y | |
| 13 | - 600ml Vegetable Stock | ingredient | 0.60 | Y | |
| 14 | - 2 cups Rice | ingredient | 0.95 | Y | |
| 15 | - Pinch Saffron | ingredient | 0.45 | Y | |
| 16 | - Garnish Parsley | instruction | 0.40 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. Place the raisins and prunes into a small bowl and pour over enough water to  | instruction | 0.70 | Y | |
| 19 | 2. Meanwhile, heat the butter in a large pan, add the onion, and cook for 5 minu | instruction | 0.30 | Y | |
| 20 | 3. Pour 2/3 cup (150 milliliters) of stock into the pan. Bring to a boil, then l | instruction | 0.70 | Y | |
| 21 | 4. Add the remaining stock and bring to a boil. Add rinsed long-grain white rice | instruction | 0.70 | Y | |
| 22 | 5. Add the drained raisins, drained chopped prunes, and salt and pepper to taste | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 50g Lamb | 50 | g | Lamb | 1.00 | regex | Y | |
| 7 | - 120g Prunes | 120 | g | Prunes | 1.00 | regex | Y | |
| 8 | - 1 tbs Lemon Juice | 1 | tbsp | Lemon Juice | 1.00 | regex | Y | |
| 9 | - 2 tbs Butter | 2 | tbsp | Butter | 1.00 | regex | Y | |
| 10 | - 1 chopped Onion | 1 | — | chopped Onion | 0.92 | regex | Y | |
| 11 | - 450g Lamb | 450 | g | Lamb | 1.00 | regex | Y | |
| 12 | - 2 cloves Garlic | 2 | clove | Garlic | 1.00 | regex | Y | |
| 13 | - 600ml Vegetable Stock | 600 | ml | Vegetable Stock | 1.00 | regex | Y | |
| 14 | - 2 cups Rice | 2 | cup | Rice | 1.00 | regex | Y | |
| 15 | - Pinch Saffron | 0.12 | — | saffron | 0.95 | regex | Y | |

---

## no-headers-01-cajun-spiced-fish-tacos

**Category**: no-headers | **Lines**: 21 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Cajun spiced fish tacos | title | 0.50 | Y | |
| 2 | 2 tbsp cajun | ingredient | 0.95 | Y | |
| 3 | 1 tsp cayenne pepper | ingredient | 0.95 | Y | |
| 4 | 4 fillets white fish | ingredient | 0.60 | Y | |
| 5 | 1 tsp vegetable oil | ingredient | 0.95 | Y | |
| 6 | 8 flour tortilla | ingredient | 0.60 | Y | |
| 7 | 1 sliced avocado | ingredient | 0.60 | Y | |
| 8 | 2 shredded little gem lettuce | ingredient | 0.60 | Y | |
| 9 | 4 shredded Spring Onions | ingredient | 0.60 | Y | |
| 10 | 1 x 300ml salsa | ingredient | 0.60 | Y | |
| 11 | 1 pot sour cream | ingredient | 0.60 | Y | |
| 12 | 1 lemon | ingredient | 0.60 | Y | |
| 13 | 1 clove finely chopped garlic | ingredient | 0.95 | Y | |
| 14 | Cooking in a cajun spice and cayenne pepper marinade makes this fish super succu | unknown | 0.10 | Y | |
| 15 | On a large plate, mix the cajun spice and cayenne pepper with a little seasoning | unknown | 0.10 | Y | |
| 16 | Heat a little oil in a frying pan, add in the fish and cook over a medium heat u | instruction | 0.70 | Y | |
| 17 | Meanwhile, prepare the dressing by combining all the ingredients with a little s | unknown | 0.10 | Y | |
| 18 | Soften the tortillas by heating in the microwave for 5-10 seconds. Pile high wit | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 tbsp cajun | 2 | tbsp | cajun | 1.00 | regex | Y | |
| 3 | 1 tsp cayenne pepper | 1 | tsp | cayenne pepper | 1.00 | regex | Y | |
| 4 | 4 fillets white fish | 4 | — | fillets white fish | 0.92 | regex | Y | |
| 5 | 1 tsp vegetable oil | 1 | tsp | vegetable oil | 1.00 | regex | Y | |
| 6 | 8 flour tortilla | 8 | — | flour tortilla | 0.92 | regex | Y | |
| 7 | 1 sliced avocado | 1 | — | sliced avocado | 0.92 | regex | Y | |
| 8 | 2 shredded little gem lettuce | 2 | — | shredded little gem lettuce | 0.92 | regex | Y | |
| 9 | 4 shredded Spring Onions | 4 | — | shredded Spring Onions | 0.92 | regex | Y | |
| 10 | 1 x 300ml salsa | 1 | — | x 300ml salsa | 0.92 | regex | Y | |
| 11 | 1 pot sour cream | 1 | — | pot sour cream | 0.92 | regex | Y | |
| 12 | 1 lemon | 1 | — | lemo n | 0.92 | regex | Y | |
| 13 | 1 clove finely chopped garlic | 1 | clove | finely chopped garlic | 1.00 | regex | Y | |

---

## no-headers-02-tonkatsu-pork

**Category**: no-headers | **Lines**: 21 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Tonkatsu pork | title | 0.50 | Y | |
| 2 | 4 Pork Chops | ingredient | 0.60 | Y | |
| 3 | 100g Flour | ingredient | 0.60 | Y | |
| 4 | 2 Beaten Eggs | ingredient | 0.60 | Y | |
| 5 | 100g Breadcrumbs | ingredient | 0.60 | Y | |
| 6 | Fry Vegetable Oil | instruction | 0.40 | Y | |
| 7 | 2 tbs Tomato Ketchup | ingredient | 0.95 | Y | |
| 8 | 2 tbs Worcestershire Sauce | ingredient | 0.95 | Y | |
| 9 | 1 tbs Oyster Sauce | ingredient | 0.95 | Y | |
| 10 | 2 tblsp Caster Sugar | ingredient | 0.60 | Y | |
| 11 | STEP 1 | unknown | 0.10 | Y | |
| 12 | Remove the large piece of fat on the edge of each pork loin, then bash each of t | instruction | 0.60 | Y | |
| 13 | STEP 2 | unknown | 0.10 | Y | |
| 14 | Put the flour, eggs and panko breadcrumbs into three separate wide-rimmed bowls. | unknown | 0.10 | Y | |
| 15 | STEP 3 | unknown | 0.10 | Y | |
| 16 | In a large frying or sauté pan, add enough oil to come 2cm up the side of the pa | instruction | 0.30 | Y | |
| 17 | STEP 4 | unknown | 0.10 | Y | |
| 18 | While the pork is resting, make the sauce by whisking the ingredients together,  | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 4 Pork Chops | 4 | — | Pork Chops | 0.92 | regex | Y | |
| 3 | 100g Flour | 100 | g | Flour | 1.00 | regex | Y | |
| 4 | 2 Beaten Eggs | 2 | — | Beaten Eggs | 0.92 | regex | Y | |
| 5 | 100g Breadcrumbs | 100 | g | Breadcrumbs | 1.00 | regex | Y | |
| 7 | 2 tbs Tomato Ketchup | 2 | tbsp | Tomato Ketchup | 1.00 | regex | Y | |
| 8 | 2 tbs Worcestershire Sauce | 2 | tbsp | Worcestershire Sauce | 1.00 | regex | Y | |
| 9 | 1 tbs Oyster Sauce | 1 | tbsp | Oyster Sauce | 1.00 | regex | Y | |
| 10 | 2 tblsp Caster Sugar | 2 | — | tblsp Caster Sugar | 0.92 | regex | Y | |

---

## no-headers-03-fish-fofos

**Category**: no-headers | **Lines**: 24 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Fish fofos | title | 0.50 | Y | |
| 2 | 600g Haddock | ingredient | 0.60 | Y | |
| 3 | 300g Potatoes | ingredient | 0.60 | Y | |
| 4 | 1 chopped Green Chilli | ingredient | 0.60 | Y | |
| 5 | 3 tbs Coriander | ingredient | 0.95 | Y | |
| 6 | 1 tsp Cumin Seeds | ingredient | 0.95 | Y | |
| 7 | 1/2 tsp Pepper | ingredient | 0.95 | Y | |
| 8 | 3 cloves Garlic | ingredient | 0.95 | Y | |
| 9 | 2 pieces Ginger | ingredient | 0.95 | Y | |
| 10 | 2 tbs Flour | ingredient | 0.95 | Y | |
| 11 | 3 Eggs | ingredient | 0.60 | Y | |
| 12 | 75g Breadcrumbs | ingredient | 0.60 | Y | |
| 13 | For frying Vegetable Oil | title | 0.30 | Y | |
| 14 | STEP 1 | unknown | 0.10 | Y | |
| 15 | Put the fish into a lidded pan and pour over enough water to cover. Bring to a s | instruction | 0.30 | Y | |
| 16 | STEP 2 | unknown | 0.10 | Y | |
| 17 | Put the fish, potato, green chilli, coriander, cumin, black pepper, garlic and g | instruction | 0.30 | Y | |
| 18 | STEP 3 | unknown | 0.10 | Y | |
| 19 | Heat 1cm of oil in a large frying pan over a medium heat. Fry the fofos in batch | instruction | 0.70 | Y | |
| 20 | STEP 4 | unknown | 0.10 | Y | |
| 21 | For the onion salad, mix together the onion, coriander and lemon juice with a pi | sectionHeader | 0.90 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 600g Haddock | 600 | g | Haddock | 1.00 | regex | Y | |
| 3 | 300g Potatoes | 300 | g | Potatoes | 1.00 | regex | Y | |
| 4 | 1 chopped Green Chilli | 1 | — | chopped Green Chilli | 0.92 | regex | Y | |
| 5 | 3 tbs Coriander | 3 | tbsp | Coriander | 1.00 | regex | Y | |
| 6 | 1 tsp Cumin Seeds | 1 | tsp | Cumin Seeds | 1.00 | regex | Y | |
| 7 | 1/2 tsp Pepper | 0.5 | tsp | Pepper | 1.00 | regex | Y | |
| 8 | 3 cloves Garlic | 3 | clove | Garlic | 1.00 | regex | Y | |
| 9 | 2 pieces Ginger | 2 | piece | Ginger | 1.00 | regex | Y | |
| 10 | 2 tbs Flour | 2 | tbsp | Flour | 1.00 | regex | Y | |
| 11 | 3 Eggs | 3 | — | Egg s | 0.92 | regex | Y | |
| 12 | 75g Breadcrumbs | 75 | g | Breadcrumbs | 1.00 | regex | Y | |

---

## no-headers-04-portuguese-barbecued-pork-febras-assadas

**Category**: no-headers | **Lines**: 25 | **Ingredients found**: 7

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Portuguese barbecued pork (Febras assadas) | title | 0.50 | Y | |
| 2 | 2 Pork | ingredient | 0.60 | Y | |
| 3 | 200ml White Wine | ingredient | 0.60 | Y | |
| 4 | 1/2 tsp Paprika | ingredient | 0.95 | Y | |
| 5 | 2 Lemon | ingredient | 0.60 | Y | |
| 6 | 1/2 Lemon Juice | ingredient | 0.60 | Y | |
| 7 | Dash Olive Oil | ingredient | 0.45 | Y | |
| 8 | To serve Mayonnaise | title | 0.30 | Y | |
| 9 | 1 kg Potatoes | ingredient | 0.95 | Y | |
| 10 | For frying Vegetable Oil | title | 0.30 | Y | |
| 11 | STEP 1 | unknown | 0.10 | Y | |
| 12 | Cut the tenderloins into 5 equal-size pieces leaving the tail ends a little long | instruction | 0.60 | Y | |
| 13 | STEP 2 | unknown | 0.10 | Y | |
| 14 | Put the wine, paprika, some salt and pepper and the juice of ½ a lemon in a bowl | instruction | 0.30 | Y | |
| 15 | STEP 3 | unknown | 0.10 | Y | |
| 16 | To make the chips, fill a basin with cool water and cut the potatoes into 3cm-th | instruction | 0.30 | Y | |
| 17 | STEP 4 | unknown | 0.10 | Y | |
| 18 | Heat the oil in a deep fryer or a deep heavy-based pan with a lid to 130C and lo | instruction | 0.70 | Y | |
| 19 | STEP 5 | unknown | 0.10 | Y | |
| 20 | The pork will cook quickly so do it in 2 batches. Take the pieces out of the mar | instruction | 0.30 | Y | |
| 21 | STEP 6 | unknown | 0.10 | Y | |
| 22 | Serve by piling a plate with chips, drop the pork on top of each pile and pourin | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 Pork | 2 | — | Por k | 0.92 | regex | Y | |
| 3 | 200ml White Wine | 200 | ml | White Wine | 1.00 | regex | Y | |
| 4 | 1/2 tsp Paprika | 0.5 | tsp | Paprika | 1.00 | regex | Y | |
| 5 | 2 Lemon | 2 | — | Lemo n | 0.92 | regex | Y | |
| 6 | 1/2 Lemon Juice | 0.5 | — | Lemon Juice | 0.92 | regex | Y | |
| 7 | Dash Olive Oil | 0.12 | — | olive oil | 0.95 | regex | Y | |
| 9 | 1 kg Potatoes | 1 | kg | Potatoes | 1.00 | regex | Y | |

---

## no-headers-05-japanese-gohan-rice

**Category**: no-headers | **Lines**: 12 | **Ingredients found**: 2

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Japanese gohan rice | title | 0.50 | Y | |
| 2 | 300g Sushi Rice | ingredient | 0.60 | Y | |
| 3 | 1 tbs Mirin | ingredient | 0.95 | Y | |
| 4 | Garnish Pickle Juice | instruction | 0.40 | Y | |
| 5 | Garnish Spring Onions | instruction | 0.40 | Y | |
| 6 | STEP 1 | unknown | 0.10 | Y | |
| 7 | Rinsing and soaking your rice is key to achieving the perfect texture. Measure t | unknown | 0.10 | Y | |
| 8 | STEP 2 | unknown | 0.10 | Y | |
| 9 | Tip the rinsed rice into a saucepan with 400ml water, or 200ml dashi and 200ml w | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 300g Sushi Rice | 300 | g | Sushi Rice | 1.00 | regex | Y | |
| 3 | 1 tbs Mirin | 1 | tbsp | Mirin | 1.00 | regex | Y | |

---

## no-headers-06-blini-pancakes

**Category**: no-headers | **Lines**: 24 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Blini Pancakes | title | 0.70 | Y | |
| 2 | 1/2 cup Buckwheat | ingredient | 0.95 | Y | |
| 3 | 2/3 Cup Flour | ingredient | 0.95 | Y | |
| 4 | 1/2 tsp Salt | ingredient | 0.95 | Y | |
| 5 | 1 tsp Yeast | ingredient | 0.95 | Y | |
| 6 | 1 cup Milk | ingredient | 0.95 | Y | |
| 7 | 2 tbs Butter | ingredient | 0.95 | Y | |
| 8 | 1 Seperated Egg | ingredient | 0.60 | Y | |
| 9 | In a large bowl, whisk together 1/2 cup buckwheat flour, 2/3 cup all-purpose flo | unknown | 0.10 | Y | |
| 10 | Make a well in the center and pour in 1 cup warm milk, whisking until the batter | ingredient | 0.35 | Y | |
| 11 | Cover the bowl and let the batter rise until doubled, about 1 hour. | instruction | 0.70 | Y | |
| 12 | Enrich and Rest the Batter | title | 0.30 | Y | |
| 13 | Stir 2 tablespoons melted butter and 1 egg yolk into the batter. | instruction | 0.60 | Y | |
| 14 | In a separate bowl, whisk 1 egg white until stiff, but not dry. | unknown | 0.10 | Y | |
| 15 | Fold the whisked egg white into the batter. | instruction | 0.40 | Y | |
| 16 | Cover the bowl and let the batter stand 20 minutes. | instruction | 0.50 | Y | |
| 17 | Pan-Fry the Blini | title | 0.30 | Y | |
| 18 | Heat butter in a large nonstick skillet over medium heat. | instruction | 0.40 | Y | |
| 19 | Drop quarter-sized dollops of batter into the pan, being careful not to overcrow | instruction | 0.30 | Y | |
| 20 | Turn and cook for about 30 additional seconds. | instruction | 0.40 | Y | |
| 21 | Remove the finished blini onto a plate and cover them with a clean kitchen towel | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1/2 cup Buckwheat | 0.5 | cup | Buckwheat | 1.00 | regex | Y | |
| 3 | 2/3 Cup Flour | 0.67 | cup | Flour | 1.00 | regex | Y | |
| 4 | 1/2 tsp Salt | 0.5 | tsp | Salt | 1.00 | regex | Y | |
| 5 | 1 tsp Yeast | 1 | tsp | Yeast | 1.00 | regex | Y | |
| 6 | 1 cup Milk | 1 | cup | Milk | 1.00 | regex | Y | |
| 7 | 2 tbs Butter | 2 | tbsp | Butter | 1.00 | regex | Y | |
| 8 | 1 Seperated Egg | 1 | — | Seperated Egg | 0.92 | regex | Y | |
| 10 | Make a well in the center and pour in 1 cup warm milk, whisk | — | — | Make a well in the center and  | 0.59 | ml | Y | |

---

## no-headers-07-sweet-and-sour-pork

**Category**: no-headers | **Lines**: 28 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Sweet and Sour Pork | title | 0.70 | Y | |
| 2 | 200g Pork | ingredient | 0.60 | Y | |
| 3 | 1 Egg | ingredient | 0.60 | Y | |
| 4 | Dash Water | ingredient | 0.45 | Y | |
| 5 | 1/2 tsp Salt | ingredient | 0.95 | Y | |
| 6 | 1 tsp Sugar | ingredient | 0.95 | Y | |
| 7 | 10g Soy Sauce | ingredient | 0.60 | Y | |
| 8 | 10g Starch | ingredient | 0.60 | Y | |
| 9 | 30g Tomato Puree | ingredient | 0.60 | Y | |
| 10 | 10g Vinegar | ingredient | 0.60 | Y | |
| 11 | Dash Coriander | ingredient | 0.45 | Y | |
| 12 | Preparation | sectionHeader | 0.90 | Y | |
| 13 | Crack the egg into a bowl. Separate the egg white and yolk. | instruction | 0.30 | Y | |
| 14 | Sweet and Sour Pork | title | 0.30 | Y | |
| 15 | Slice the pork tenderloin into strips. | ingredient | 0.45 | Y | |
| 16 | Prepare the marinade using a pinch of salt, one teaspoon of starch, two teaspoon | ingredient | 0.35 | Y | |
| 17 | Marinade the pork strips for about 20 minutes. | instruction | 0.30 | Y | |
| 18 | Put the remaining starch in a bowl. Add some water and vinegar to make a starchy | instruction | 0.30 | Y | |
| 19 | Sweet and Sour Pork | title | 0.30 | Y | |
| 20 | Cooking Instructions | title | 0.30 | Y | |
| 21 | Pour the cooking oil into a wok and heat to 190°C (375°F). Add the marinated por | instruction | 0.75 | Y | |
| 22 | Leave some oil in the wok. Put the tomato sauce and white sugar into the wok, an | instruction | 0.30 | Y | |
| 23 | Add some water to the wok and thoroughly heat the sweet and sour sauce before ad | instruction | 0.60 | Y | |
| 24 | Pour in the starchy sauce. Stir-fry all the ingredients until the pork and sauce | instruction | 0.60 | Y | |
| 25 | Serve on a plate and add some coriander for decoration. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 200g Pork | 200 | g | Pork | 1.00 | regex | Y | |
| 3 | 1 Egg | 1 | — | Eg g | 0.92 | regex | Y | |
| 4 | Dash Water | 0.12 | — | water | 0.95 | regex | Y | |
| 5 | 1/2 tsp Salt | 0.5 | tsp | Salt | 1.00 | regex | Y | |
| 6 | 1 tsp Sugar | 1 | tsp | Sugar | 1.00 | regex | Y | |
| 7 | 10g Soy Sauce | 10 | g | Soy Sauce | 1.00 | regex | Y | |
| 8 | 10g Starch | 10 | g | Starch | 1.00 | regex | Y | |
| 9 | 30g Tomato Puree | 30 | g | Tomato Puree | 1.00 | regex | Y | |
| 10 | 10g Vinegar | 10 | g | Vinegar | 1.00 | regex | Y | |
| 11 | Dash Coriander | 0.12 | — | coriander | 0.95 | regex | Y | |
| 15 | Slice the pork tenderloin into strips. | — | slice | the pork tenderloin | 0.79 | ml | Y | |
| 16 | Prepare the marinade using a pinch of salt, one teaspoon of  | — | — | Prepare the marinade using a p | 0.75 | ml | Y | |

---

## no-headers-08-warm-roast-asparagus-salad

**Category**: no-headers | **Lines**: 20 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Warm roast asparagus salad | instruction | 0.40 | Y | |
| 2 | 500g Asparagus | ingredient | 0.60 | Y | |
| 3 | 2 tbsp Red Wine Vinegar | ingredient | 0.95 | Y | |
| 4 | 4 Tomato | ingredient | 0.60 | Y | |
| 5 | 1 tbsp Extra Virgin Olive Oil | ingredient | 0.95 | Y | |
| 6 | 12 Streaky Bacon | ingredient | 0.60 | Y | |
| 7 | 1 teaspoon Clear Honey | ingredient | 0.95 | Y | |
| 8 | 16 Jersey Royal Potatoes | ingredient | 0.60 | Y | |
| 9 | 2 tblsp Extra Virgin Olive Oil | ingredient | 0.60 | Y | |
| 10 | 1 teaspoon Dijon Mustard | ingredient | 0.95 | Y | |
| 11 | 100g Rocket | ingredient | 0.60 | Y | |
| 12 | step 1 | unknown | 0.10 | Y | |
| 13 | Preheat the oven to 200C/Gas 6/fan 180C. Snap off the woody ends of the asparagu | instruction | 0.70 | Y | |
| 14 | step 2 | unknown | 0.10 | Y | |
| 15 | In the meantime, boil the potatoes until tender. Whisk the vinegar, olive oil, m | unknown | 0.10 | Y | |
| 16 | step 3 | unknown | 0.10 | Y | |
| 17 | Drain the potatoes and cut in half. Gently toss them in the rest of the dressing | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 500g Asparagus | 500 | g | Asparagus | 1.00 | regex | Y | |
| 3 | 2 tbsp Red Wine Vinegar | 2 | tbsp | Red Wine Vinegar | 1.00 | regex | Y | |
| 4 | 4 Tomato | 4 | — | Tomat o | 0.92 | regex | Y | |
| 5 | 1 tbsp Extra Virgin Olive Oil | 1 | tbsp | Extra Virgin Olive Oil | 1.00 | regex | Y | |
| 6 | 12 Streaky Bacon | 12 | — | Streaky Bacon | 0.92 | regex | Y | |
| 7 | 1 teaspoon Clear Honey | 1 | tsp | Clear Honey | 1.00 | regex | Y | |
| 8 | 16 Jersey Royal Potatoes | 16 | — | Jersey Royal Potatoes | 0.92 | regex | Y | |
| 9 | 2 tblsp Extra Virgin Olive Oil | 2 | — | tblsp Extra Virgin Olive Oil | 0.92 | regex | Y | |
| 10 | 1 teaspoon Dijon Mustard | 1 | tsp | Dijon Mustard | 1.00 | regex | Y | |
| 11 | 100g Rocket | 100 | g | Rocket | 1.00 | regex | Y | |

---

## no-headers-09-rappie-pie

**Category**: no-headers | **Lines**: 17 | **Ingredients found**: 6

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Rappie Pie | title | 0.70 | Y | |
| 2 | 2 tbs Butter | ingredient | 0.95 | Y | |
| 3 | 2 chopped Onions | ingredient | 0.60 | Y | |
| 4 | 4 qt Chicken Stock | ingredient | 0.95 | Y | |
| 5 | 1.5kg Chicken Breast | instruction | 0.50 | Y | |
| 6 | 4kg Potatoes | ingredient | 0.60 | Y | |
| 7 | 2 tbs Salt | ingredient | 0.95 | Y | |
| 8 | 1tbsp Black Pepper | ingredient | 0.60 | Y | |
| 9 | Preheat oven to 400 degrees F (200 degrees C). Grease a 10x14x2-inch baking pan. | instruction | 0.75 | Y | |
| 10 | Heat margarine in a skillet over medium heat; stir in onion. Cook and stir until | instruction | 0.70 | Y | |
| 11 | Bring chicken broth to a boil in a large pot; stir in chicken breasts, reduce he | instruction | 0.30 | Y | |
| 12 | Juice potatoes with an electric juicer; place dry potato flesh into a bowl and d | unknown | 0.10 | Y | |
| 13 | Spread half of potato mixture evenly into the prepared pan. Lay cooked chicken b | instruction | 0.60 | Y | |
| 14 | Bake in the preheated oven until golden brown, about 1 hour. Reheat chicken brot | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 tbs Butter | 2 | tbsp | Butter | 1.00 | regex | Y | |
| 3 | 2 chopped Onions | 2 | — | chopped Onions | 0.92 | regex | Y | |
| 4 | 4 qt Chicken Stock | 4 | quart | Chicken Stock | 1.00 | regex | Y | |
| 6 | 4kg Potatoes | 4 | kg | Potatoes | 1.00 | regex | Y | |
| 7 | 2 tbs Salt | 2 | tbsp | Salt | 1.00 | regex | Y | |
| 8 | 1tbsp Black Pepper | 1 | tbsp | Black Pepper | 1.00 | regex | Y | |

---

## no-headers-10-lamb-and-lemon-souvlaki

**Category**: no-headers | **Lines**: 13 | **Ingredients found**: 5

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Lamb and Lemon Souvlaki | title | 0.70 | Y | |
| 2 | 2 cloves Garlic | ingredient | 0.95 | Y | |
| 3 | 2 tsp Sea Salt | ingredient | 0.95 | Y | |
| 4 | 4 tbs Olive Oil | ingredient | 0.95 | Y | |
| 5 | Zest and juice of 1 Lemon | unknown | 0.10 | Y | |
| 6 | 1 tbs Dill | ingredient | 0.95 | Y | |
| 7 | 750g Lamb Leg | ingredient | 0.60 | Y | |
| 8 | To serve Pita Bread | title | 0.30 | Y | |
| 9 | Pound the garlic with sea salt in a pestle and mortar (or use a small food proce | instruction | 0.30 | Y | |
| 10 | If you’ve prepared the lamb the previous day, take it out of the fridge 30 mins  | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 cloves Garlic | 2 | clove | Garlic | 1.00 | regex | Y | |
| 3 | 2 tsp Sea Salt | 2 | tsp | Sea Salt | 1.00 | regex | Y | |
| 4 | 4 tbs Olive Oil | 4 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 6 | 1 tbs Dill | 1 | tbsp | Dill | 1.00 | regex | Y | |
| 7 | 750g Lamb Leg | 750 | g | Lamb Leg | 1.00 | regex | Y | |

---

## unusual-metadata-01-provenal-omelette-cake

**Category**: unusual-metadata | **Lines**: 28 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Provençal Omelette Cake | title | 0.70 | Y | |
| 2 | Yield: 4 portions | metadata | 0.60 | Y | |
| 3 | Active time: 25 minutes | metadata | 0.60 | Y | |
| 4 | Total: 1 hour | metadata | 0.70 | Y | |
| 5 | Difficulty: Medium | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 10 Eggs | ingredient | 0.60 | Y | |
| 8 | - 1 tbs Olive Oil | ingredient | 0.95 | Y | |
| 9 | - 2 finely chopped Courgettes | ingredient | 0.60 | Y | |
| 10 | - 3 finely chopped Spring Onions | ingredient | 0.60 | Y | |
| 11 | - 4 Red Pepper | ingredient | 0.60 | Y | |
| 12 | - 1 clove peeled crushed Garlic Clove | ingredient | 0.95 | Y | |
| 13 | - 1 Red Chilli | ingredient | 0.60 | Y | |
| 14 | - 300g Cream Cheese | ingredient | 0.60 | Y | |
| 15 | - 6 tblsp Milk | ingredient | 0.60 | Y | |
| 16 | - 4 tbs Chives | ingredient | 0.95 | Y | |
| 17 | - 2 tbs Basil | ingredient | 0.95 | Y | |
| 18 | - to serve Rocket | ingredient | 0.30 | Y | |
| 19 | - to serve Parmesan | ingredient | 0.30 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Break the eggs into two bowls, five in each. Whisk lightly and season with sa | instruction | 0.30 | Y | |
| 22 | 2. Heat a little oil in a 20-23cm frying pan, preferably non-stick. Pour the egg | instruction | 0.60 | Y | |
| 23 | 3. Now make the filling. Beat the cheese to soften it, then beat in the milk to  | instruction | 0.30 | Y | |
| 24 | 4. To serve, invert the omelette cake onto a serving plate and peel off the clin | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 10 Eggs | 10 | — | Egg s | 0.92 | regex | Y | |
| 8 | - 1 tbs Olive Oil | 1 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 9 | - 2 finely chopped Courgettes | 2 | — | finely chopped Courgettes | 0.92 | regex | Y | |
| 10 | - 3 finely chopped Spring Onions | 3 | — | finely chopped Spring Onions | 0.92 | regex | Y | |
| 11 | - 4 Red Pepper | 4 | — | Red Pepper | 0.92 | regex | Y | |
| 12 | - 1 clove peeled crushed Garlic Clove | 1 | clove | peeled crushed Garlic Clove | 1.00 | regex | Y | |
| 13 | - 1 Red Chilli | 1 | — | Red Chilli | 0.92 | regex | Y | |
| 14 | - 300g Cream Cheese | 300 | g | Cream Cheese | 1.00 | regex | Y | |
| 15 | - 6 tblsp Milk | 6 | — | tblsp Milk | 0.92 | regex | Y | |
| 16 | - 4 tbs Chives | 4 | tbsp | Chives | 1.00 | regex | Y | |
| 17 | - 2 tbs Basil | 2 | tbsp | Basil | 1.00 | regex | Y | |
| 18 | - to serve Rocket | — | — | - to serve Rocket | 0.95 | ml | Y | |
| 19 | - to serve Parmesan | — | — | - to serve Parmesan | 0.99 | ml | Y | |

---

## unusual-metadata-02-skillet-apple-pork-chops-with-roasted-sw

**Category**: unusual-metadata | **Lines**: 34 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Skillet Apple Pork Chops with Roasted Sweet Potatoes & Zucchini | title | 0.70 | Y | |
| 2 | Makes: 4 servings | title | 0.30 | Y | |
| 3 | Hands-on: 20 min | unknown | 0.10 | Y | |
| 4 | Cuisine: American | metadata | 0.60 | Y | |
| 5 | Oven: 180C / 350F | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 2 Potatoes | ingredient | 0.60 | Y | |
| 8 | - 1 Apples | ingredient | 0.60 | Y | |
| 9 | - 2 cloves Garlic | ingredient | 0.95 | Y | |
| 10 | - 1 Lemon | ingredient | 0.60 | Y | |
| 11 | - 2 Pork | ingredient | 0.60 | Y | |
| 12 | - 1 Zucchini | ingredient | 0.60 | Y | |
| 13 | - 1 Chicken Stock | ingredient | 0.60 | Y | |
| 14 | - 1 tbsp Vegetable Oil | ingredient | 0.95 | Y | |
| 15 | - 1 1/2 tsp Sugar | ingredient | 0.95 | Y | |
| 16 | - 2 tbsp Butter | ingredient | 0.95 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. Serves 2 | metadata | 0.70 | Y | |
| 19 | 2. | instruction | 0.50 | Y | |
| 20 | 3. Adjust racks to top and middle positions and preheat oven to 450 degrees. Was | instruction | 0.45 | Y | |
| 21 | 4. | instruction | 0.50 | Y | |
| 22 | 5. Meanwhile, halve and core apple; thinly slice into half-moons. Peel and finel | instruction | 0.30 | Y | |
| 23 | 6. | instruction | 0.50 | Y | |
| 24 | 7. Pat pork dry with paper towels and season all over with salt and pepper. Heat | instruction | 0.30 | Y | |
| 25 | 8. | instruction | 0.50 | Y | |
| 26 | 9. Once sweet potatoes have roasted 12 minutes, transfer baking sheet with zucch | instruction | 0.30 | Y | |
| 27 | 10. | instruction | 0.50 | Y | |
| 28 | 11. Meanwhile, melt 1 TBSP butter (2 TBSP for 4 servings) in pan used for pork o | instruction | 0.30 | Y | |
| 29 | 12. | instruction | 0.50 | Y | |
| 30 | 13. Remove pan with apple from heat; stir in 1 TBSP butter (2 TBSP for 4 serving | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 2 Potatoes | 2 | — | Potatoe s | 0.92 | regex | Y | |
| 8 | - 1 Apples | 1 | — | Apple s | 0.92 | regex | Y | |
| 9 | - 2 cloves Garlic | 2 | clove | Garlic | 1.00 | regex | Y | |
| 10 | - 1 Lemon | 1 | — | Lemo n | 0.92 | regex | Y | |
| 11 | - 2 Pork | 2 | — | Por k | 0.92 | regex | Y | |
| 12 | - 1 Zucchini | 1 | — | Zucchin i | 0.92 | regex | Y | |
| 13 | - 1 Chicken Stock | 1 | — | Chicken Stock | 0.92 | regex | Y | |
| 14 | - 1 tbsp Vegetable Oil | 1 | tbsp | Vegetable Oil | 1.00 | regex | Y | |
| 15 | - 1 1/2 tsp Sugar | 1.5 | tsp | Sugar | 1.00 | regex | Y | |
| 16 | - 2 tbsp Butter | 2 | tbsp | Butter | 1.00 | regex | Y | |

---

## unusual-metadata-03-katsu-chicken-curry

**Category**: unusual-metadata | **Lines**: 34 | **Ingredients found**: 16

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Katsu Chicken curry | title | 0.70 | Y | |
| 2 | Portions: 4 | title | 0.30 | Y | |
| 3 | Preparation: 15 min | unknown | 0.10 | Y | |
| 4 | Cooking: 40 min | unknown | 0.10 | Y | |
| 5 | Origin: Japanese | title | 0.30 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 4 pounded to 1cm thickness chicken breast | ingredient | 0.60 | Y | |
| 8 | - 2 tablespoons plain flour | ingredient | 0.95 | Y | |
| 9 | - 1 beaten egg | ingredient | 0.60 | Y | |
| 10 | - 100g fine breadcrumbs | ingredient | 0.60 | Y | |
| 11 | - 230ml frying vegetable oil | ingredient | 0.60 | Y | |
| 12 | - 2 tablespoons sunflower oil | ingredient | 0.95 | Y | |
| 13 | - 2 sliced onions | ingredient | 0.60 | Y | |
| 14 | - 5 chopped cloves garlic | ingredient | 0.95 | Y | |
| 15 | - 2 sliced carrot | ingredient | 0.60 | Y | |
| 16 | - 2 tablespoons plain flour | ingredient | 0.95 | Y | |
| 17 | - 4 teaspoons curry powder | ingredient | 0.95 | Y | |
| 18 | - 600ml chicken stock | ingredient | 0.60 | Y | |
| 19 | - 2 teaspoons honey | ingredient | 0.95 | Y | |
| 20 | - 4 teaspoons soy sauce | ingredient | 0.95 | Y | |
| 21 | - 1 bay leaf | ingredient | 0.60 | Y | |
| 22 | - 1 teaspoon garam masala | ingredient | 0.95 | Y | |
| 23 | Instructions: | sectionHeader | 0.90 | Y | |
| 24 | 1. Prep:15min  ›  Cook:30min  ›  Ready in:45min | metadata | 0.70 | Y | |
| 25 | 2. For the curry sauce: Heat oil in medium non-stick saucepan, add onion and gar | sectionHeader | 0.90 | Y | |
| 26 | 3. Add flour and curry powder; cook for 1 minute. Gradually stir in stock until  | instruction | 0.70 | Y | |
| 27 | 4. Turn down heat and simmer for 20 minutes or until sauce thickens but is still | instruction | 0.70 | Y | |
| 28 | 5. For the chicken: Season both sides of chicken breasts with salt and pepper. P | sectionHeader | 0.90 | Y | |
| 29 | 6. Heat oil in large frying pan over medium-high heat. Place chicken into hot oi | instruction | 0.70 | Y | |
| 30 | 7. Pour curry sauce over chicken, serve with white rice and enjoy! | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 4 pounded to 1cm thickness chicken breast | 4 | — | pounded to 1cm thickness chick | 0.92 | regex | Y | |
| 8 | - 2 tablespoons plain flour | 2 | tbsp | plain flour | 1.00 | regex | Y | |
| 9 | - 1 beaten egg | 1 | — | beaten egg | 0.92 | regex | Y | |
| 10 | - 100g fine breadcrumbs | 100 | g | fine breadcrumbs | 1.00 | regex | Y | |
| 11 | - 230ml frying vegetable oil | 230 | ml | frying vegetable oil | 1.00 | regex | Y | |
| 12 | - 2 tablespoons sunflower oil | 2 | tbsp | sunflower oil | 1.00 | regex | Y | |
| 13 | - 2 sliced onions | 2 | — | sliced onions | 0.92 | regex | Y | |
| 14 | - 5 chopped cloves garlic | 5 | — | chopped cloves garlic | 0.92 | regex | Y | |
| 15 | - 2 sliced carrot | 2 | — | sliced carrot | 0.92 | regex | Y | |
| 8 | - 2 tablespoons plain flour | 2 | tbsp | plain flour | 1.00 | regex | Y | |
| 17 | - 4 teaspoons curry powder | 4 | tsp | curry powder | 1.00 | regex | Y | |
| 18 | - 600ml chicken stock | 600 | ml | chicken stock | 1.00 | regex | Y | |
| 19 | - 2 teaspoons honey | 2 | tsp | honey | 1.00 | regex | Y | |
| 20 | - 4 teaspoons soy sauce | 4 | tsp | soy sauce | 1.00 | regex | Y | |
| 21 | - 1 bay leaf | 1 | — | bay leaf | 0.92 | regex | Y | |
| 22 | - 1 teaspoon garam masala | 1 | tsp | garam masala | 1.00 | regex | Y | |

---

## unusual-metadata-04-stuffed-lamb-tomatoes

**Category**: unusual-metadata | **Lines**: 27 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Stuffed Lamb Tomatoes | title | 0.70 | Y | |
| 2 | Yield: 6 | metadata | 0.60 | Y | |
| 3 | Active time: 30 minutes | metadata | 0.60 | Y | |
| 4 | Total: 1 hour 15 minutes | metadata | 0.70 | Y | |
| 5 | Difficulty: Easy | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 4 large Tomatoes | ingredient | 0.60 | Y | |
| 8 | - Pinch Sugar | ingredient | 0.45 | Y | |
| 9 | - 4 tbs Olive Oil | ingredient | 0.95 | Y | |
| 10 | - 1 chopped Onion | ingredient | 0.60 | Y | |
| 11 | - 2 finely chopped Garlic Clove | ingredient | 0.95 | Y | |
| 12 | - 200g Lamb | ingredient | 0.60 | Y | |
| 13 | - 1 tbs Cinnamon | ingredient | 0.95 | Y | |
| 14 | - 2 tbs chopped Tomato Puree | ingredient | 0.95 | Y | |
| 15 | - 50g Rice | ingredient | 0.60 | Y | |
| 16 | - 100ml Chicken Stock | ingredient | 0.60 | Y | |
| 17 | - 4 tbs Dill | ingredient | 0.95 | Y | |
| 18 | - 2 tbs Chopped Parsley | ingredient | 0.95 | Y | |
| 19 | - 1 tbs Mint | ingredient | 0.95 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Heat oven to 180C/160C fan/gas 4. Slice the tops off the tomatoes and reserve | instruction | 0.60 | Y | |
| 22 | 2. Heat 2 tbsp olive oil in a large frying pan, add the onion and garlic, then g | instruction | 0.70 | Y | |
| 23 | 3. Stuff the tomatoes up to the brim, top tomatoes with their lids, drizzle with | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 4 large Tomatoes | 4 | — | large Tomatoes | 0.92 | regex | Y | |
| 8 | - Pinch Sugar | 0.12 | — | sugar | 0.95 | regex | Y | |
| 9 | - 4 tbs Olive Oil | 4 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 10 | - 1 chopped Onion | 1 | — | chopped Onion | 0.92 | regex | Y | |
| 11 | - 2 finely chopped Garlic Clove | 2 | — | finely chopped Garlic Clove | 0.92 | regex | Y | |
| 12 | - 200g Lamb | 200 | g | Lamb | 1.00 | regex | Y | |
| 13 | - 1 tbs Cinnamon | 1 | tbsp | Cinnamon | 1.00 | regex | Y | |
| 14 | - 2 tbs chopped Tomato Puree | 2 | tbsp | chopped Tomato Puree | 1.00 | regex | Y | |
| 15 | - 50g Rice | 50 | g | Rice | 1.00 | regex | Y | |
| 16 | - 100ml Chicken Stock | 100 | ml | Chicken Stock | 1.00 | regex | Y | |
| 17 | - 4 tbs Dill | 4 | tbsp | Dill | 1.00 | regex | Y | |
| 18 | - 2 tbs Chopped Parsley | 2 | tbsp | Chopped Parsley | 1.00 | regex | Y | |
| 19 | - 1 tbs Mint | 1 | tbsp | Mint | 1.00 | regex | Y | |

---

## unusual-metadata-05-pistachio-cake

**Category**: unusual-metadata | **Lines**: 29 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Pistachio cake | title | 0.50 | Y | |
| 2 | Serves: 4-6 | title | 0.30 | Y | |
| 3 | Time: 45 minutes | unknown | 0.10 | Y | |
| 4 | Cuisine: Polish | metadata | 0.60 | Y | |
| 5 | Level: Intermediate | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 250g Butter | ingredient | 0.60 | Y | |
| 8 | - 200g Pistachio | ingredient | 0.60 | Y | |
| 9 | - 80g Plain Flour | ingredient | 0.60 | Y | |
| 10 | - 1 tsp Baking Powder | ingredient | 0.95 | Y | |
| 11 | - 225g Caster Sugar | ingredient | 0.60 | Y | |
| 12 | - 4 Egg | ingredient | 0.60 | Y | |
| 13 | - 1 tsp Vanilla Extract | ingredient | 0.95 | Y | |
| 14 | - 100g Icing Sugar | ingredient | 0.60 | Y | |
| 15 | - 250g Mascarpone | ingredient | 0.60 | Y | |
| 16 | - 200ml Double Cream | ingredient | 0.60 | Y | |
| 17 | - 100g Pistachio Paste | ingredient | 0.60 | Y | |
| 18 | - 400g Raspberries | ingredient | 0.60 | Y | |
| 19 | - 1 Unwaxed Lime | ingredient | 0.60 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Heat the oven to 180C/160C fan/gas 4. Butter and line a 23cm springform cake  | instruction | 0.70 | Y | |
| 22 | 2. step 2 | instruction | 0.30 | Y | |
| 23 | 3. Meanwhile, sift the icing sugar into a bowl, then tip in the mascarpone, doub | instruction | 0.30 | Y | |
| 24 | 4. step 3 | instruction | 0.30 | Y | |
| 25 | 5. Cut the cooled cake in half horizontally using a serrated knife, so you have  | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 250g Butter | 250 | g | Butter | 1.00 | regex | Y | |
| 8 | - 200g Pistachio | 200 | g | Pistachio | 1.00 | regex | Y | |
| 9 | - 80g Plain Flour | 80 | g | Plain Flour | 1.00 | regex | Y | |
| 10 | - 1 tsp Baking Powder | 1 | tsp | Baking Powder | 1.00 | regex | Y | |
| 11 | - 225g Caster Sugar | 225 | g | Caster Sugar | 1.00 | regex | Y | |
| 12 | - 4 Egg | 4 | — | Eg g | 0.92 | regex | Y | |
| 13 | - 1 tsp Vanilla Extract | 1 | tsp | Vanilla Extract | 1.00 | regex | Y | |
| 14 | - 100g Icing Sugar | 100 | g | Icing Sugar | 1.00 | regex | Y | |
| 15 | - 250g Mascarpone | 250 | g | Mascarpone | 1.00 | regex | Y | |
| 16 | - 200ml Double Cream | 200 | ml | Double Cream | 1.00 | regex | Y | |
| 17 | - 100g Pistachio Paste | 100 | g | Pistachio Paste | 1.00 | regex | Y | |
| 18 | - 400g Raspberries | 400 | g | Raspberries | 1.00 | regex | Y | |
| 19 | - 1 Unwaxed Lime | 1 | — | Unwaxed Lime | 0.92 | regex | Y | |

---

## unusual-metadata-06-snert-dutch-split-pea-soup

**Category**: unusual-metadata | **Lines**: 30 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Snert (Dutch Split Pea Soup) | title | 0.70 | Y | |
| 2 | Yield: 4 portions | metadata | 0.60 | Y | |
| 3 | Active time: 25 minutes | metadata | 0.60 | Y | |
| 4 | Total: 1 hour | metadata | 0.70 | Y | |
| 5 | Difficulty: Medium | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 2L Water | ingredient | 0.60 | Y | |
| 8 | - 300g Peas | ingredient | 0.60 | Y | |
| 9 | - 100g Pork | ingredient | 0.60 | Y | |
| 10 | - 1 Vegetable Stock Cube | ingredient | 0.60 | Y | |
| 11 | - 2 Celery | ingredient | 0.60 | Y | |
| 12 | - 2 Carrots | ingredient | 0.60 | Y | |
| 13 | - 1 large Potatoes | ingredient | 0.60 | Y | |
| 14 | - 1 small Onion | ingredient | 0.60 | Y | |
| 15 | - 1 small Leek | ingredient | 0.60 | Y | |
| 16 | - 1 cup Celeriac | ingredient | 0.95 | Y | |
| 17 | - 1 pound Sausages | ingredient | 0.95 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Gather the ingredients. | instruction | 0.30 | Y | |
| 20 | 2. In a large soup pot, bring water, split peas, pork belly or bacon, pork chop, | instruction | 0.30 | Y | |
| 21 | 3. Remove the pork chop, debone, and thinly slice the meat. Set aside. | instruction | 0.60 | Y | |
| 22 | 4. Add the celery, carrots, potato, onion, leek, and celeriac to the soup. Retur | instruction | 0.70 | Y | |
| 23 | 5. Add the smoked sausage for the last 15 minutes of cooking time. When the vege | instruction | 0.70 | Y | |
| 24 | 6. If you prefer a smooth consistency, purée the soup with a stick blender. Seas | instruction | 0.30 | Y | |
| 25 | 7. Serve in heated bowls or soup plates, garnished with slices of rookworst and  | instruction | 0.60 | Y | |
| 26 | 8. Enjoy! | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 2L Water | 2 | l | Water | 1.00 | regex | Y | |
| 8 | - 300g Peas | 300 | g | Peas | 1.00 | regex | Y | |
| 9 | - 100g Pork | 100 | g | Pork | 1.00 | regex | Y | |
| 10 | - 1 Vegetable Stock Cube | 1 | — | Vegetable Stock Cube | 0.92 | regex | Y | |
| 11 | - 2 Celery | 2 | — | Celer y | 0.92 | regex | Y | |
| 12 | - 2 Carrots | 2 | — | Carrot s | 0.92 | regex | Y | |
| 13 | - 1 large Potatoes | 1 | — | large Potatoes | 0.92 | regex | Y | |
| 14 | - 1 small Onion | 1 | — | small Onion | 0.92 | regex | Y | |
| 15 | - 1 small Leek | 1 | — | small Leek | 0.92 | regex | Y | |
| 16 | - 1 cup Celeriac | 1 | cup | Celeriac | 1.00 | regex | Y | |
| 17 | - 1 pound Sausages | 1 | lb | Sausages | 1.00 | regex | Y | |

---

## unusual-metadata-07-lamb-tzatziki-burgers

**Category**: unusual-metadata | **Lines**: 25 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Lamb Tzatziki Burgers | title | 0.70 | Y | |
| 2 | Makes: 4 servings | title | 0.30 | Y | |
| 3 | Hands-on: 20 min | unknown | 0.10 | Y | |
| 4 | Cuisine: Greek | metadata | 0.60 | Y | |
| 5 | Oven: 180C / 350F | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 25g Bulgur Wheat | ingredient | 0.60 | Y | |
| 8 | - 500g Lamb Mince | ingredient | 0.60 | Y | |
| 9 | - 1 tsp Cumin | ingredient | 0.95 | Y | |
| 10 | - 1 tsp Coriander | ingredient | 0.95 | Y | |
| 11 | - 1 tsp Paprika | ingredient | 0.95 | Y | |
| 12 | - 1 clove finely chopped Garlic | ingredient | 0.95 | Y | |
| 13 | - For frying Olive Oil | title | 0.30 | Y | |
| 14 | - 4 Bun | ingredient | 0.60 | Y | |
| 15 | - Grated Cucumber | title | 0.30 | Y | |
| 16 | - 200g Greek Yogurt | ingredient | 0.60 | Y | |
| 17 | - 2 tbs Mint | ingredient | 0.95 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Tip the bulghar into a pan, cover with water and boil for 10 mins. Drain real | instruction | 0.30 | Y | |
| 20 | 2. To make the tzatziki, squeeze and discard the juice from the cucumber, then m | instruction | 0.30 | Y | |
| 21 | 3. Work the bulghar into the lamb with the spices, garlic (if using) and seasoni | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 25g Bulgur Wheat | 25 | g | Bulgur Wheat | 1.00 | regex | Y | |
| 8 | - 500g Lamb Mince | 500 | g | Lamb Mince | 1.00 | regex | Y | |
| 9 | - 1 tsp Cumin | 1 | tsp | Cumin | 1.00 | regex | Y | |
| 10 | - 1 tsp Coriander | 1 | tsp | Coriander | 1.00 | regex | Y | |
| 11 | - 1 tsp Paprika | 1 | tsp | Paprika | 1.00 | regex | Y | |
| 12 | - 1 clove finely chopped Garlic | 1 | clove | finely chopped Garlic | 1.00 | regex | Y | |
| 14 | - 4 Bun | 4 | — | Bu n | 0.92 | regex | Y | |
| 16 | - 200g Greek Yogurt | 200 | g | Greek Yogurt | 1.00 | regex | Y | |
| 17 | - 2 tbs Mint | 2 | tbsp | Mint | 1.00 | regex | Y | |

---

## unusual-metadata-08-flapper-pie

**Category**: unusual-metadata | **Lines**: 31 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Flapper Pie | title | 0.70 | Y | |
| 2 | Portions: 4 | title | 0.30 | Y | |
| 3 | Preparation: 15 min | unknown | 0.10 | Y | |
| 4 | Cooking: 40 min | unknown | 0.10 | Y | |
| 5 | Origin: Canadian | title | 0.30 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1 1/2 cups Graham Cracker Crumbs | ingredient | 0.95 | Y | |
| 8 | - 6 tablespoons Melted Butter | ingredient | 0.95 | Y | |
| 9 | - 1/2 cup Sugar | ingredient | 0.95 | Y | |
| 10 | - 1/2 tsp Ground Cinnamon | ingredient | 0.95 | Y | |
| 11 | - 2 1/2 cups Milk | ingredient | 0.95 | Y | |
| 12 | - 1/2 cup Sugar | ingredient | 0.95 | Y | |
| 13 | - 1/4 cup Cornstarch | ingredient | 0.95 | Y | |
| 14 | - 3 Egg Yolks | ingredient | 0.60 | Y | |
| 15 | - 1 tsp Vanilla Extract | ingredient | 0.95 | Y | |
| 16 | - 1/4 tsp Salt | ingredient | 0.95 | Y | |
| 17 | - 3 Egg White | ingredient | 0.60 | Y | |
| 18 | - 1/4 cup Sugar | ingredient | 0.95 | Y | |
| 19 | - 1/4 tsp Cream Of Tartar | ingredient | 0.95 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Preheat the oven to 350˚F. | instruction | 0.40 | Y | |
| 22 | 2. Mix all the crust ingredients (graham cracker crumbs, melted butter, granulat | instruction | 0.70 | Y | |
| 23 | 3. Combine the vanilla custard filling ingredients (milk, granulated sugar, corn | instruction | 0.60 | Y | |
| 24 | 4. In the bowl of a stand mixer fitted with the beater attachment or in a large  | instruction | 0.30 | Y | |
| 25 | 5. To assemble the pie, pour the filling into the crust and top with a thick lay | instruction | 0.30 | Y | |
| 26 | 6. Bake until the meringue browns, around 10 minutes, making sure to watch it ca | instruction | 0.70 | Y | |
| 27 | 7. Chill in the fridge and eat within a few hours of baking. This pie is best ea | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1 1/2 cups Graham Cracker Crumbs | 1.5 | cup | Graham Cracker Crumbs | 1.00 | regex | Y | |
| 8 | - 6 tablespoons Melted Butter | 6 | tbsp | Melted Butter | 1.00 | regex | Y | |
| 9 | - 1/2 cup Sugar | 0.5 | cup | Sugar | 1.00 | regex | Y | |
| 10 | - 1/2 tsp Ground Cinnamon | 0.5 | tsp | Ground Cinnamon | 1.00 | regex | Y | |
| 11 | - 2 1/2 cups Milk | 2.5 | cup | Milk | 1.00 | regex | Y | |
| 9 | - 1/2 cup Sugar | 0.5 | cup | Sugar | 1.00 | regex | Y | |
| 13 | - 1/4 cup Cornstarch | 0.25 | cup | Cornstarch | 1.00 | regex | Y | |
| 14 | - 3 Egg Yolks | 3 | — | Egg Yolks | 0.92 | regex | Y | |
| 15 | - 1 tsp Vanilla Extract | 1 | tsp | Vanilla Extract | 1.00 | regex | Y | |
| 16 | - 1/4 tsp Salt | 0.25 | tsp | Salt | 1.00 | regex | Y | |
| 17 | - 3 Egg White | 3 | — | Egg White | 0.92 | regex | Y | |
| 18 | - 1/4 cup Sugar | 0.25 | cup | Sugar | 1.00 | regex | Y | |
| 19 | - 1/4 tsp Cream Of Tartar | 0.25 | tsp | Cream Of Tartar | 1.00 | regex | Y | |

---

## unusual-metadata-09-coddled-pork-with-cider

**Category**: unusual-metadata | **Lines**: 27 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Coddled pork with cider | title | 0.50 | Y | |
| 2 | Yield: 6 | metadata | 0.60 | Y | |
| 3 | Active time: 30 minutes | metadata | 0.60 | Y | |
| 4 | Total: 1 hour 15 minutes | metadata | 0.70 | Y | |
| 5 | Difficulty: Easy | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - Knob Butter | title | 0.30 | Y | |
| 8 | - 2 Pork Chops | ingredient | 0.60 | Y | |
| 9 | - 4 Bacon | ingredient | 0.60 | Y | |
| 10 | - 2 Potatoes | ingredient | 0.60 | Y | |
| 11 | - 1 Carrots | ingredient | 0.60 | Y | |
| 12 | - 1/2 Swede | ingredient | 0.60 | Y | |
| 13 | - 1/2 Cabbage | ingredient | 0.60 | Y | |
| 14 | - 1 Bay Leaf | ingredient | 0.60 | Y | |
| 15 | - 100ml Cider | ingredient | 0.60 | Y | |
| 16 | - 100g Chicken Stock | ingredient | 0.60 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. STEP 1 | instruction | 0.30 | Y | |
| 19 | 2. Heat the butter in a casserole dish until sizzling, then fry the pork for 2-3 | instruction | 0.70 | Y | |
| 20 | 3. STEP 2 | instruction | 0.30 | Y | |
| 21 | 4. Tip the bacon, carrot, potatoes and swede into the pan, then gently fry until | instruction | 0.30 | Y | |
| 22 | 5. STEP 3 | instruction | 0.30 | Y | |
| 23 | 6. Serve at the table spooned straight from the dish. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 8 | - 2 Pork Chops | 2 | — | Pork Chops | 0.92 | regex | Y | |
| 9 | - 4 Bacon | 4 | — | Baco n | 0.92 | regex | Y | |
| 10 | - 2 Potatoes | 2 | — | Potatoe s | 0.92 | regex | Y | |
| 11 | - 1 Carrots | 1 | — | Carrot s | 0.92 | regex | Y | |
| 12 | - 1/2 Swede | 0.5 | — | Swed e | 0.92 | regex | Y | |
| 13 | - 1/2 Cabbage | 0.5 | — | Cabbag e | 0.92 | regex | Y | |
| 14 | - 1 Bay Leaf | 1 | — | Bay Leaf | 0.92 | regex | Y | |
| 15 | - 100ml Cider | 100 | ml | Cider | 1.00 | regex | Y | |
| 16 | - 100g Chicken Stock | 100 | g | Chicken Stock | 1.00 | regex | Y | |

---

## unusual-metadata-10-fish-pie

**Category**: unusual-metadata | **Lines**: 31 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Fish pie | title | 0.50 | Y | |
| 2 | Serves: 4-6 | title | 0.30 | Y | |
| 3 | Time: 45 minutes | unknown | 0.10 | Y | |
| 4 | Cuisine: British | metadata | 0.60 | Y | |
| 5 | Level: Intermediate | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 900g Floury Potatoes | ingredient | 0.60 | Y | |
| 8 | - 2 tbsp Olive Oil | ingredient | 0.95 | Y | |
| 9 | - 600ml Semi-skimmed Milk | ingredient | 0.60 | Y | |
| 10 | - 800g White Fish Fillets | ingredient | 0.60 | Y | |
| 11 | - 1 tbsp Plain flour | ingredient | 0.95 | Y | |
| 12 | - Grating Nutmeg | title | 0.30 | Y | |
| 13 | - 3 tbsp Double Cream | ingredient | 0.95 | Y | |
| 14 | - 200g Jerusalem Artichokes | ingredient | 0.60 | Y | |
| 15 | - 1 finely sliced Leek | ingredient | 0.60 | Y | |
| 16 | - 200g peeled raw Prawns | ingredient | 0.60 | Y | |
| 17 | - Large handful Parsley | title | 0.30 | Y | |
| 18 | - Handful Dill | title | 0.30 | Y | |
| 19 | - Grated zest of 1 Lemon | ingredient | 0.30 | Y | |
| 20 | - 25g grated Gruyère | ingredient | 0.60 | Y | |
| 21 | - Juice of 1 Lemon | ingredient | 0.30 | Y | |
| 22 | Instructions: | sectionHeader | 0.90 | Y | |
| 23 | 1. Put the potatoes in a large pan of cold salted water and bring to the boil. L | instruction | 0.30 | Y | |
| 24 | 2. Meanwhile put the milk in a large sauté pan, add the fish and bring to the bo | instruction | 0.30 | Y | |
| 25 | 3. Heat the remaining oil in a pan, stir in the flour and cook for 30 seconds. G | instruction | 0.70 | Y | |
| 26 | 4. Preheat the oven to 190°C/fan170°C/gas 5. Grate the artichokes and add to the | instruction | 0.75 | Y | |
| 27 | 5. Spoon the mash onto the fish mixture, then use a fork to make peaks, which wi | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 900g Floury Potatoes | 900 | g | Floury Potatoes | 1.00 | regex | Y | |
| 8 | - 2 tbsp Olive Oil | 2 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 9 | - 600ml Semi-skimmed Milk | 600 | ml | Semi-skimmed Milk | 1.00 | regex | Y | |
| 10 | - 800g White Fish Fillets | 800 | g | White Fish Fillets | 1.00 | regex | Y | |
| 11 | - 1 tbsp Plain flour | 1 | tbsp | Plain flour | 1.00 | regex | Y | |
| 13 | - 3 tbsp Double Cream | 3 | tbsp | Double Cream | 1.00 | regex | Y | |
| 14 | - 200g Jerusalem Artichokes | 200 | g | Jerusalem Artichokes | 1.00 | regex | Y | |
| 15 | - 1 finely sliced Leek | 1 | — | finely sliced Leek | 0.92 | regex | Y | |
| 16 | - 200g peeled raw Prawns | 200 | g | peeled raw Prawns | 1.00 | regex | Y | |
| 19 | - Grated zest of 1 Lemon | 1 | — | lemon | 0.99 | ml | Y | |
| 20 | - 25g grated Gruyère | 25 | g | grated Gruyère | 1.00 | regex | Y | |
| 21 | - Juice of 1 Lemon | 1 | — | lemon | 0.95 | regex | Y | |

---

## messy-01-beef-dumpling-stew

**Category**: messy | **Lines**: 21 | **Ingredients found**: 5

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Dumpling Stew | title | 0.70 | Y | |
| 2 | This is a family favorite that's been passed down for generations. Here's what y | unknown | 0.10 | Y | |
| 3 | 2 tbs Olive Oil, 25g Butter, 750g Beef, 2 tblsp Plain Flour, 2 cloves minced Gar | ingredient | 0.85 | Y | |
| 4 | 150g Celery, 150g Carrots, 2 chopped Leek, 200g Swede, 150ml Red Wine, and 500g  | ingredient | 0.50 | Y | |
| 5 | 2 Bay Leaf, 3 tbs Thyme, 3 tblsp chopped Parsley, 125g Plain Flour, 1 tsp Baking | ingredient | 0.85 | Y | |
| 6 | Splash Water. | title | 0.30 | Y | |
| 7 | Preheat the oven to 180C/350F/Gas 4. | instruction | 0.40 | Y | |
| 8 | For the beef stew, heat the oil and butter in an ovenproof casserole and fry the | sectionHeader | 0.90 | Y | |
| 9 | Sprinkle over the flour and cook for a further 2-3 minutes. | instruction | 0.50 | Y | |
| 10 | Add the garlic and all the vegetables and fry for 1-2 minutes. | instruction | 0.70 | Y | |
| 11 | Stir in the wine, stock and herbs, then add the Worcestershire sauce and balsami | instruction | 0.60 | Y | |
| 12 | Cover with a lid, transfer to the oven and cook for about two hours, or until th | instruction | 0.60 | Y | |
| 13 | For the dumplings, sift the flour, baking powder and salt into a bowl. | sectionHeader | 0.90 | Y | |
| 14 | Add the suet and enough water to form a thick dough. | instruction | 0.40 | Y | |
| 15 | With floured hands, roll spoonfuls of the dough into small balls. | ingredient | 0.30 | Y | |
| 16 | After two hours, remove the lid from the stew and place the balls on top of the  | instruction | 0.30 | Y | |
| 17 | To serve, place a spoonful of mashed potato onto each of four serving plates and | ingredient | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 2 tbs Olive Oil, 25g Butter, 750g Beef, 2 tblsp Plain Flour, | 2 | tbsp | Olive Oil, 25g Butter, 750g Be | 1.00 | regex | Y | |
| 4 | 150g Celery, 150g Carrots, 2 chopped Leek, 200g Swede, 150ml | 150 | g | Celery, 150g Carrots, 2 choppe | 1.00 | regex | Y | |
| 5 | 2 Bay Leaf, 3 tbs Thyme, 3 tblsp chopped Parsley, 125g Plain | 2 | — | Bay Leaf, 3 tbs Thyme, 3 tblsp | 0.92 | regex | Y | |
| 15 | With floured hands, roll spoonfuls of the dough into small b | — | — | With floured hands, roll spoon | 0.58 | ml | Y | |
| 17 | To serve, place a spoonful of mashed potato onto each of fou | — | — | To serve, place a spoonful of  | 0.56 | ml | Y | |

---

## messy-02-braised-beef-chilli

**Category**: messy | **Lines**: 15 | **Ingredients found**: 4

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Braised Beef Chilli | title | 0.70 | Y | |
| 2 | I picked this one up from a cooking class a few years ago. You'll need | title | 0.30 | Y | |
| 3 | 1kg Beef, 3 Onions, 4 cloves Garlic, Dash Olive oil, and 300g Chorizo. | ingredient | 0.95 | Y | |
| 4 | 2 tsp Cumin, 2 tsp Allspice, 1 tsp Cloves, 1 large Cinnamon stick, and 3 Bay Lea | ingredient | 0.85 | Y | |
| 5 | 2 tsp dried Oregano, 2 ancho Ancho Chillies, 3 tbsp Balsamic Vinegar, 2 x 400g P | ingredient | 0.85 | Y | |
| 6 | 2 tbsp Dark Brown Sugar, and 2 x 400g tins Borlotti Beans. | ingredient | 0.95 | Y | |
| 7 | Preheat the oven to 120C/225F/gas mark 1. | instruction | 0.40 | Y | |
| 8 | Take the meat out of the fridge to de-chill. Pulse the onions and garlic in a fo | unknown | 0.10 | Y | |
| 9 | Set to one side and add another small slug of oil to brown the chorizo. Remove a | instruction | 0.60 | Y | |
| 10 | Put all the meat back into the pot with 400ml water (or red wine if you prefer), | unknown | 0.10 | Y | |
| 11 | After 2 hours, check the meat and add the beans. Cook for a further hour and jus | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 1kg Beef, 3 Onions, 4 cloves Garlic, Dash Olive oil, and 300 | 1 | kg | Beef, 3 Onions, 4 cloves Garli | 1.00 | regex | Y | |
| 4 | 2 tsp Cumin, 2 tsp Allspice, 1 tsp Cloves, 1 large Cinnamon  | 2 | tsp | Cumin, 2 tsp Allspice, 1 tsp C | 1.00 | regex | Y | |
| 5 | 2 tsp dried Oregano, 2 ancho Ancho Chillies, 3 tbsp Balsamic | 2 | tsp | dried Oregano, 2 ancho Ancho C | 1.00 | regex | Y | |
| 6 | 2 tbsp Dark Brown Sugar, and 2 x 400g tins Borlotti Beans. | 2 | tbsp | Dark Brown Sugar, and 2 x 400g | 1.00 | regex | Y | |

---

## messy-03-pork-cassoulet

**Category**: messy | **Lines**: 13 | **Ingredients found**: 2

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Pork Cassoulet | title | 0.70 | Y | |
| 2 | One of those comfort food classics that never gets old. Gather up | title | 0.30 | Y | |
| 3 | 4 tbsp Goose Fat, 350g Pork, 1 large Onion, 10 Garlic, and 1 thinly sliced Carro | ingredient | 0.85 | Y | |
| 4 | 1 tsp Fennel Seeds, 2 tblsp Red Wine Vinegar, 600ml Vegetable Stock, 1 tblsp Tom | ingredient | 0.85 | Y | |
| 5 | Handful Parsley, 400g Haricot Beans, 2 tblsp Breadcrumbs, drizzle Oil, and to se | unknown | 0.10 | Y | |
| 6 | to serve Broccoli. | unknown | 0.10 | Y | |
| 7 | Heat oven to 140C/120C fan/gas 1. Put a large ovenproof pan (with a tight-fittin | instruction | 0.60 | Y | |
| 8 | Pour over the red wine vinegar, scraping any meaty bits off the bottom of the pa | instruction | 0.70 | Y | |
| 9 | Remove the pan from the oven and heat the grill. Scatter the top with the remain | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 4 tbsp Goose Fat, 350g Pork, 1 large Onion, 10 Garlic, and 1 | 4 | tbsp | Goose Fat, 350g Pork, 1 large  | 1.00 | regex | Y | |
| 4 | 1 tsp Fennel Seeds, 2 tblsp Red Wine Vinegar, 600ml Vegetabl | 1 | tsp | Fennel Seeds, 2 tblsp Red Wine | 1.00 | regex | Y | |

---

## messy-04-beef-caldereta

**Category**: messy | **Lines**: 18 | **Ingredients found**: 4

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Caldereta | title | 0.70 | Y | |
| 2 | A friend shared this recipe with me and I've been making it ever since. For this | unknown | 0.10 | Y | |
| 3 | 2kg cut cubes Beef, 1 Beef Stock, 1 tbs Soy Sauce, and 2 cups Water. | ingredient | 0.95 | Y | |
| 4 | 1 sliced Green Pepper, 1 sliced Red Pepper, 1 sliced Potatoes, and 1 sliced Carr | ingredient | 0.50 | Y | |
| 5 | 8 ounces Tomato Puree, 3  tablespoons Peanut Butter, 5 Chilli Powder, and 1 chop | ingredient | 0.85 | Y | |
| 6 | 5 cloves Garlic, and 3 tbs Olive Oil. | ingredient | 0.95 | Y | |
| 7 | Heat oil in a cooking pot. Saute onion and garlic until onion softens | instruction | 0.60 | Y | |
| 8 | Add beef. Saute until the outer part turns light brown. | instruction | 0.40 | Y | |
| 9 | Add soy sauce. Pour tomato sauce and water. Let boil. | instruction | 0.40 | Y | |
| 10 | Add Knorr Beef Cube. Cover the pressure cooker. Cook for 30 minutes. | instruction | 0.70 | Y | |
| 11 | Pan-fry carrot and potato until it browns. Set aside. | unknown | 0.10 | Y | |
| 12 | Add chili pepper, liver spread and peanut butter. Stir. | instruction | 0.40 | Y | |
| 13 | Add bell peppers, fried potato and carrot. Cover the pot. Continue cooking for 5 | instruction | 0.70 | Y | |
| 14 | Season with salt and ground black pepper. Serve. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 2kg cut cubes Beef, 1 Beef Stock, 1 tbs Soy Sauce, and 2 cup | 2 | kg | cut cubes Beef, 1 Beef Stock,  | 1.00 | regex | Y | |
| 4 | 1 sliced Green Pepper, 1 sliced Red Pepper, 1 sliced Potatoe | 1 | — | sliced Green Pepper, 1 sliced  | 0.92 | regex | Y | |
| 5 | 8 ounces Tomato Puree, 3  tablespoons Peanut Butter, 5 Chill | 8 | oz | Tomato Puree, 3  tablespoons P | 1.00 | regex | Y | |
| 6 | 5 cloves Garlic, and 3 tbs Olive Oil. | 5 | clove | Garlic, and 3 tbs Olive Oil. | 1.00 | regex | Y | |

---

## messy-05-bigos-polish-hunters-stew

**Category**: messy | **Lines**: 16 | **Ingredients found**: 4

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Bigos (Polish hunter's stew) | title | 0.50 | Y | |
| 2 | This dish takes a bit of time but it's absolutely worth the effort. The ingredie | unknown | 0.10 | Y | |
| 3 | 1 sliced White Cabbage, 250ml Beef Stock, 100g Mushrooms, 2 tablespoons Lard, an | ingredient | 0.85 | Y | |
| 4 | 250g Bacon, 2 chopped Onion, 750g Beef, 200g Prunes, and 1 Bay Leaf. | ingredient | 0.60 | Y | |
| 5 | 2 Cloves, 12 Peppercorns, 4 Juniper Berries, 4 Allspice Berries, and 90 ml Red W | ingredient | 0.85 | Y | |
| 6 | 2 tablespoons Tomato Puree. | ingredient | 0.95 | Y | |
| 7 | step 1 | unknown | 0.10 | Y | |
| 8 | Put the cabbage in a heavy casserole dish, add the stock and cook over a low hea | instruction | 0.30 | Y | |
| 9 | step 2 | unknown | 0.10 | Y | |
| 10 | Cut the soaked mushrooms into strips and save the soaking water. Heat the lard a | instruction | 0.70 | Y | |
| 11 | step 3 | unknown | 0.10 | Y | |
| 12 | Add the mushrooms and their liquid along with all the cooked meat, onions and pr | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 1 sliced White Cabbage, 250ml Beef Stock, 100g Mushrooms, 2  | 1 | — | sliced White Cabbage, 250ml Be | 0.92 | regex | Y | |
| 4 | 250g Bacon, 2 chopped Onion, 750g Beef, 200g Prunes, and 1 B | 250 | g | Bacon, 2 chopped Onion, 750g B | 1.00 | regex | Y | |
| 5 | 2 Cloves, 12 Peppercorns, 4 Juniper Berries, 4 Allspice Berr | 2 | clove | , 12 Peppercorns, 4 Juniper Be | 1.00 | regex | Y | |
| 6 | 2 tablespoons Tomato Puree. | 2 | tbsp | Tomato Puree. | 1.00 | regex | Y | |

---

## messy-06-singapore-noodles-with-shrimp

**Category**: messy | **Lines**: 27 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Singapore Noodles with Shrimp | title | 0.70 | Y | |
| 2 | This is a family favorite that's been passed down for generations. Here's what y | unknown | 0.10 | Y | |
| 3 | 2 tsp Sesame Seed Oil, 2 tablespoons Soy Sauce, 2 tablespoons Seasoned Rice Vine | ingredient | 0.55 | Y | |
| 4 | 1 clove finely chopped Garlic, 2 Carrots, 1 sliced Jalapeno, 1/2 Onion, 1/2 tsp  | ingredient | 0.85 | Y | |
| 5 | 1/2 Napa Cabbage, 4 Scallions, 1/2 Red Pepper, 2 tsp Curry Powder, 1/2 lb Shrimp | ingredient | 0.85 | Y | |
| 6 | For the sweet onion, look for Vidalia, OSO Sweet, or Walla Walla. The super-swee | sectionHeader | 0.90 | Y | |
| 7 | Make the sauce: | ingredient | 0.30 | Y | |
| 8 | In a bowl, combine the sesame oil, soy sauce, and rice vinegar. | ingredient | 0.30 | Y | |
| 9 | Cook the rice noodles: | instruction | 0.40 | Y | |
| 10 | Bring a large saucepan of water to a boil, add the noodles, and use tongs to tur | instruction | 0.30 | Y | |
| 11 | Drain, rinse with cold water, and use scissors to snip the noodles several times | ingredient | 0.30 | Y | |
| 12 | Scramble the eggs: | ingredient | 0.30 | Y | |
| 13 | In a small bowl whisk together the eggs. Heat the skillet or Dutch oven over med | instruction | 0.30 | Y | |
| 14 | Cook the vegetables: | instruction | 0.40 | Y | |
| 15 | Add 1 tablespoon of the remaining oil to the pan. When it is hot, add the ginger | instruction | 0.70 | Y | |
| 16 | Add the remaining ingredients: | instruction | 0.40 | Y | |
| 17 | Sprinkle the vegetable mixture with the remaining 1 tablespoon peanut or canola  | instruction | 0.70 | Y | |
| 18 | Add the shrimp and cook, stirring, for 3 more minutes or until the shrimp are br | instruction | 0.60 | Y | |
| 19 | Add the noodles in batches: | instruction | 0.40 | Y | |
| 20 | Add the eggs, the sauce mixture, and half the noodles to the pan. Toss for 1 min | instruction | 0.70 | Y | |
| 21 | Add the remaining noodles and continue tossing for 1 minute more until they are  | instruction | 0.70 | Y | |
| 22 | Serve: | ingredient | 0.30 | Y | |
| 23 | Taste for seasoning and add more salt or soy sauce, if you like. Sprinkle with c | ingredient | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 2 tsp Sesame Seed Oil, 2 tablespoons Soy Sauce, 2 tablespoon | 2 | tsp | Sesame Seed Oil, 2 tablespoons | 1.00 | regex | Y | |
| 4 | 1 clove finely chopped Garlic, 2 Carrots, 1 sliced Jalapeno, | 1 | clove | finely chopped Garlic, 2 Carro | 1.00 | regex | Y | |
| 5 | 1/2 Napa Cabbage, 4 Scallions, 1/2 Red Pepper, 2 tsp Curry P | 0.5 | — | Napa Cabbage, 4 Scallions, 1/2 | 0.92 | regex | Y | |
| 7 | Make the sauce: | — | — | make the sauce | 0.71 | ml | Y | |
| 8 | In a bowl, combine the sesame oil, soy sauce, and rice vineg | — | — | combine the sesame oil soy sau | 0.86 | ml | Y | |
| 11 | Drain, rinse with cold water, and use scissors to snip the n | — | — | drain | 0.83 | ml | Y | |
| 12 | Scramble the eggs: | — | — | scramble the eggs | 0.70 | ml | Y | |
| 22 | Serve: | — | — | serve | 0.82 | ml | Y | |
| 23 | Taste for seasoning and add more salt or soy sauce, if you l | — | — | Taste for seasoning and add mo | 0.74 | ml | Y | |

---

## messy-07-beef-mechado

**Category**: messy | **Lines**: 15 | **Ingredients found**: 3

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Mechado | title | 0.70 | Y | |
| 2 | I picked this one up from a cooking class a few years ago. You'll need | title | 0.30 | Y | |
| 3 | 3 cloves Garlic, 1 sliced Onion, 2 Lbs Beef, and 8 ounces Tomato Puree. | ingredient | 0.95 | Y | |
| 4 | 1 cup Water, 3 tbs Olive Oil, 1 Slice Lemon, and 1 large Potatoes. | ingredient | 0.95 | Y | |
| 5 | 1/4 cup Soy Sauce, 1/2 tsp Black Pepper, 2 Bay Leaves, and To taste Salt. | ingredient | 0.95 | Y | |
| 6 | Make the beef tenderloin marinade by combining soy sauce, vinegar, ginger, garli | unknown | 0.10 | Y | |
| 7 | Add the cubed beef tenderloin to the bowl with the beef tenderloin marinade. Gen | instruction | 0.70 | Y | |
| 8 | Using a metal or bamboo skewer, assemble the beef kebob by skewering the vegetab | instruction | 0.60 | Y | |
| 9 | Heat-up the grill and start grilling the beef kebobs for 3 minutes per side. Thi | instruction | 0.30 | Y | |
| 10 | Transfer to a serving plate. Serve with Saffron rice. | instruction | 0.40 | Y | |
| 11 | Share and enjoy! | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 3 cloves Garlic, 1 sliced Onion, 2 Lbs Beef, and 8 ounces To | 3 | clove | Garlic, 1 sliced Onion, 2 Lbs  | 1.00 | regex | Y | |
| 4 | 1 cup Water, 3 tbs Olive Oil, 1 Slice Lemon, and 1 large Pot | 1 | cup | Water, 3 tbs Olive Oil, 1 Slic | 1.00 | regex | Y | |
| 5 | 1/4 cup Soy Sauce, 1/2 tsp Black Pepper, 2 Bay Leaves, and T | 0.25 | cup | Soy Sauce, 1/2 tsp Black Peppe | 1.00 | regex | Y | |

---

## messy-08-chicken-parmentier

**Category**: messy | **Lines**: 14 | **Ingredients found**: 3

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Parmentier | title | 0.70 | Y | |
| 2 | One of those comfort food classics that never gets old. Gather up | title | 0.30 | Y | |
| 3 | 1.5kg Potatoes, 30g Butter, 5 tblsp Double Cream, 2 Egg Yolks, and 30g Butter. | instruction | 0.70 | Y | |
| 4 | 7 Shallots, 3 chopped Carrots, 2 sticks Celery, 1 finely chopped Garlic Clove, a | ingredient | 0.85 | Y | |
| 5 | 1 tbls Tomato Puree, 400g Tinned Tomatos, 350ml Chicken Stock, 600g Chicken, and | ingredient | 0.50 | Y | |
| 6 | 2 tbs Parsley, and 50g Gruyere cheese. | ingredient | 0.95 | Y | |
| 7 | For the topping, boil the potatoes in salted water until tender. Drain and push  | sectionHeader | 0.90 | Y | |
| 8 | For the filling, melt the butter in a large pan. Add the shallots, carrots and c | sectionHeader | 0.90 | Y | |
| 9 | Preheat the oven to 180C/160C Fan/Gas 4. | instruction | 0.40 | Y | |
| 10 | Put the filling in a 20x30cm/8x12in ovenproof dish and top with the mashed potat | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 4 | 7 Shallots, 3 chopped Carrots, 2 sticks Celery, 1 finely cho | 7 | — | Shallots , 3 chopped Carrots,  | 0.92 | regex | Y | |
| 5 | 1 tbls Tomato Puree, 400g Tinned Tomatos, 350ml Chicken Stoc | 1 | — | tbls Tomato Puree, 400g Tinned | 0.92 | regex | Y | |
| 6 | 2 tbs Parsley, and 50g Gruyere cheese. | 2 | tbsp | Parsley, and 50g Gruyere chees | 1.00 | regex | Y | |

---

## messy-09-saltfish-and-ackee

**Category**: messy | **Lines**: 22 | **Ingredients found**: 7

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Saltfish and Ackee | title | 0.70 | Y | |
| 2 | A friend shared this recipe with me and I've been making it ever since. For this | unknown | 0.10 | Y | |
| 3 | 450g Salt Cod, 400g Ackee, 1 chopped Onion, 1 tsp Paprika, and 2 tsp Curry Powde | ingredient | 0.85 | Y | |
| 4 | 2 tsp Jerusalem Artichokes, 1 tsp Hotsauce, 1 sliced Red Pepper, 1 sliced Yellow | ingredient | 0.85 | Y | |
| 5 | to taste Salt, to taste Pepper, 250g Self-raising Flour, 30g Suet, and pinch Sal | ingredient | 0.35 | Y | |
| 6 | for frying Olive Oil. | unknown | 0.10 | Y | |
| 7 | For the saltfish, soak the salt cod overnight, changing the water a couple of ti | sectionHeader | 0.90 | Y | |
| 8 | Drain, then put the cod in a large pan of fresh water and bring to the boil. Dra | ingredient | 0.30 | Y | |
| 9 | Simmer for about five minutes, or until cooked through, then drain and flake the | instruction | 0.60 | Y | |
| 10 | For the dumplings, mix the flour and suet with a pinch of salt and 250ml/9fl oz  | sectionHeader | 0.90 | Y | |
| 11 | Wrap the mixture in clingfilm and leave in the fridge to rest. | instruction | 0.60 | Y | |
| 12 | Open the can of ackee, drain and rinse, then set aside. | ingredient | 0.45 | Y | |
| 13 | Heat a tablespoon of olive oil in a pan and fry the onion until softened but not | instruction | 0.60 | Y | |
| 14 | Add the spices, seasoning, pepper sauce and sliced peppers and continue to fry u | instruction | 0.60 | Y | |
| 15 | Add the chopped tomatoes, then the salt cod and mix together. Lastly stir in the | instruction | 0.60 | Y | |
| 16 | When you’re almost ready to eat, heat about 1cm/½in vegetable oil in a frying pa | ingredient | 0.30 | Y | |
| 17 | Shape the dumpling mix into plum-size balls and shallow-fry until golden-brown.  | ingredient | 0.30 | Y | |
| 18 | Drain the dumplings on kitchen paper and serve with the saltfish and ackee. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 450g Salt Cod, 400g Ackee, 1 chopped Onion, 1 tsp Paprika, a | 450 | g | Salt Cod, 400g Ackee, 1 choppe | 1.00 | regex | Y | |
| 4 | 2 tsp Jerusalem Artichokes, 1 tsp Hotsauce, 1 sliced Red Pep | 2 | tsp | Jerusalem Artichokes, 1 tsp Ho | 1.00 | regex | Y | |
| 5 | to taste Salt, to taste Pepper, 250g Self-raising Flour, 30g | — | — | to taste Salt, to taste Pepper | 0.94 | ml | Y | |
| 8 | Drain, then put the cod in a large pan of fresh water and br | — | — | drain | 0.78 | ml | Y | |
| 12 | Open the can of ackee, drain and rinse, then set aside. | — | the can | ackee | 0.83 | ml | Y | |
| 16 | When you’re almost ready to eat, heat about 1cm/½in vegetabl | — | — | when you’re almost ready | 0.66 | ml | Y | |
| 17 | Shape the dumpling mix into plum-size balls and shallow-fry  | — | — | shape the dumpling mix | 0.76 | ml | Y | |

---

## messy-10-shrimp-chow-fun

**Category**: messy | **Lines**: 25 | **Ingredients found**: 6

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Shrimp Chow Fun | title | 0.70 | Y | |
| 2 | This dish takes a bit of time but it's absolutely worth the effort. The ingredie | unknown | 0.10 | Y | |
| 3 | 1/2 bag Rice Stick Noodles, 8 oz Prawns, 1/2 Egg, pinch Pepper, and 2 tsp Sesame | ingredient | 0.85 | Y | |
| 4 | 2 tbs Cornstarch, 4 tbs Oil, 1 tsp Minced Garlic, 1 tsp Ginger, and 1/2 cup Onio | ingredient | 0.85 | Y | |
| 5 | 1 cup Bean Sprouts, 1/2 cup Spring Onions, 1 tbs Cooking wine, 1 tbs Oyster Sauc | ingredient | 0.85 | Y | |
| 6 | 1/2 tbs Vinegar, and 1 tbs Soy Sauce. | ingredient | 0.95 | Y | |
| 7 | STEP 1 - SOAK THE RICE NOODLES | title | 0.30 | Y | |
| 8 | Soak the rice noodles overnight untill they are soft | unknown | 0.10 | Y | |
| 9 | STEP 2 - BOIL THE RICE NOODLES | title | 0.30 | Y | |
| 10 | Boil the noodles for 10-15 minutes and then rinse with cold water to stop the co | instruction | 0.70 | Y | |
| 11 | STEP 3 -MARINATING THE SHRIMP | title | 0.30 | Y | |
| 12 | In a bowl add the shrimp, egg, 1 pinch of white pepper, 1 Teaspoon of sesame see | unknown | 0.10 | Y | |
| 13 | Mix together well | instruction | 0.40 | Y | |
| 14 | STEP 4 - STIR FRY | title | 0.30 | Y | |
| 15 | In a wok add 2 Tablespoons of oil, shrimp and stir fry them until it is golden b | ingredient | 0.35 | Y | |
| 16 | Set the shrimp aside | instruction | 0.40 | Y | |
| 17 | Add 1 Tablespoon of oil to the work and then add minced garlic, ginger and all o | instruction | 0.60 | Y | |
| 18 | Add the noodles to the wok | instruction | 0.40 | Y | |
| 19 | Next add sherry cooking wine, oyster sauce, sugar, vinegar, sesame seed oil, 1 p | ingredient | 0.35 | Y | |
| 20 | Add back in the shrimp | instruction | 0.40 | Y | |
| 21 | To thicken the sauce, whisk together 1 Tablespoon of corn starch and 2 Tablespoo | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 1/2 bag Rice Stick Noodles, 8 oz Prawns, 1/2 Egg, pinch Pepp | 0.5 | bag | Rice Stick Noodles, 8 oz Prawn | 1.00 | regex | Y | |
| 4 | 2 tbs Cornstarch, 4 tbs Oil, 1 tsp Minced Garlic, 1 tsp Ging | 2 | tbsp | Cornstarch, 4 tbs Oil, 1 tsp M | 1.00 | regex | Y | |
| 5 | 1 cup Bean Sprouts, 1/2 cup Spring Onions, 1 tbs Cooking win | 1 | cup | Bean Sprouts, 1/2 cup Spring O | 1.00 | regex | Y | |
| 6 | 1/2 tbs Vinegar, and 1 tbs Soy Sauce. | 0.5 | tbsp | Vinegar, and 1 tbs Soy Sauce. | 1.00 | regex | Y | |
| 15 | In a wok add 2 Tablespoons of oil, shrimp and stir fry them  | — | — | In a wok add 2 Tablespoons of  | 0.57 | ml | Y | |
| 19 | Next add sherry cooking wine, oyster sauce, sugar, vinegar,  | — | — | next add sherry cooking wine o | 0.94 | ml | Y | |

---

## international-01-callaloo-and-saltfish

**Category**: international | **Lines**: 26 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Callaloo and SaltFish | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Jamaican | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1/2 lb Salt Cod | ingredient | 0.95 | Y | |
| 8 | - 4 Bacon | ingredient | 0.60 | Y | |
| 9 | - 525g Callaloo | ingredient | 0.60 | Y | |
| 10 | - 1 chopped Onion | ingredient | 0.60 | Y | |
| 11 | - 2 chopped Spring Onions | ingredient | 0.60 | Y | |
| 12 | - 2 cloves minced Garlic | ingredient | 0.95 | Y | |
| 13 | - 1 chopped Scotch Bonnet | ingredient | 0.60 | Y | |
| 14 | - 2 chopped Plum Tomatoes | ingredient | 0.60 | Y | |
| 15 | - 2 sprigs Thyme | ingredient | 0.95 | Y | |
| 16 | - 1/4 tsp Black Pepper | ingredient | 0.95 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. Soak salted fish in water overnight. Next, heat salted fish in water on stove | instruction | 0.30 | Y | |
| 19 | 2. Cook bacon in skillet over medium heat until crispy. Remove bacon from heat a | instruction | 0.60 | Y | |
| 20 | 3. Add yellow onion, green onion, scotch bonnet pepper, and garlic to the skille | instruction | 0.70 | Y | |
| 21 | 4. Next, add callaloo, roma tomatoes, thyme, and black pepper. Stir to combine a | instruction | 0.30 | Y | |
| 22 | 5. Enjoy | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1/2 lb Salt Cod | 0.5 | lb | Salt Cod | 1.00 | regex | Y | |
| 8 | - 4 Bacon | 4 | — | Baco n | 0.92 | regex | Y | |
| 9 | - 525g Callaloo | 525 | g | Callaloo | 1.00 | regex | Y | |
| 10 | - 1 chopped Onion | 1 | — | chopped Onion | 0.92 | regex | Y | |
| 11 | - 2 chopped Spring Onions | 2 | — | chopped Spring Onions | 0.92 | regex | Y | |
| 12 | - 2 cloves minced Garlic | 2 | clove | minced Garlic | 1.00 | regex | Y | |
| 13 | - 1 chopped Scotch Bonnet | 1 | — | chopped Scotch Bonnet | 0.92 | regex | Y | |
| 14 | - 2 chopped Plum Tomatoes | 2 | — | chopped Plum Tomatoes | 0.92 | regex | Y | |
| 15 | - 2 sprigs Thyme | 2 | sprig | Thyme | 1.00 | regex | Y | |
| 16 | - 1/4 tsp Black Pepper | 0.25 | tsp | Black Pepper | 1.00 | regex | Y | |

---

## international-02-shawarma-bread

**Category**: international | **Lines**: 31 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Shawarma bread | title | 0.50 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Saudi Arabian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1 cup Flour | ingredient | 0.95 | Y | |
| 8 | - 1 tsp Salt | ingredient | 0.95 | Y | |
| 9 | - 1/2 tsp Sugar | ingredient | 0.95 | Y | |
| 10 | - 1/2 tsp Baking Powder | ingredient | 0.95 | Y | |
| 11 | - 1 tablespoon Oil | ingredient | 0.95 | Y | |
| 12 | - Splash Water | title | 0.30 | Y | |
| 13 | Instructions: | sectionHeader | 0.90 | Y | |
| 14 | 1. 1 | ingredient | 0.60 | Y | |
| 15 | 2. Sieve flour and add baking powder,salt,sugar,oil nd mix together | instruction | 0.30 | Y | |
| 16 | 3. 2 | ingredient | 0.60 | Y | |
| 17 | 4. Add water nd knead the dough for like 10mins | instruction | 0.50 | Y | |
| 18 | 5. 3 | ingredient | 0.60 | Y | |
| 19 | 6. Cover the mixture and allow it to rise | instruction | 0.40 | Y | |
| 20 | 7. 4 | ingredient | 0.60 | Y | |
| 21 | 8. After it rised transfer it to a work surface and form a round (you can use a  | ingredient | 0.35 | Y | |
| 22 | 9. 5 | ingredient | 0.60 | Y | |
| 23 | 10. Heat ur pan and put it | instruction | 0.40 | Y | |
| 24 | 11. 6 | ingredient | 0.60 | Y | |
| 25 | 12. It'll start puffing then you turn it | instruction | 0.30 | Y | |
| 26 | 13. 7 | ingredient | 0.60 | Y | |
| 27 | 14. And lastly put it in in a warm place, then you'll see it has pocket | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1 cup Flour | 1 | cup | Flour | 1.00 | regex | Y | |
| 8 | - 1 tsp Salt | 1 | tsp | Salt | 1.00 | regex | Y | |
| 9 | - 1/2 tsp Sugar | 0.5 | tsp | Sugar | 1.00 | regex | Y | |
| 10 | - 1/2 tsp Baking Powder | 0.5 | tsp | Baking Powder | 1.00 | regex | Y | |
| 11 | - 1 tablespoon Oil | 1 | tbsp | Oil | 1.00 | regex | Y | |
| 14 | 1. 1 | — | — | 1. 1 | 0.99 | ml | Y | |
| 16 | 3. 2 | — | — | 3. 2 | 1.00 | ml | Y | |
| 18 | 5. 3 | — | — | 5. 3 | 1.00 | ml | Y | |
| 20 | 7. 4 | — | — | 7. 4 | 0.99 | ml | Y | |
| 21 | 8. After it rised transfer it to a work surface and form a r | 8 | — | after it rised transfer it to  | 0.68 | ml | Y | |
| 22 | 9. 5 | — | — | 9. 5 | 1.00 | ml | Y | |
| 24 | 11. 6 | — | — | 11. 6 | 0.99 | ml | Y | |
| 26 | 13. 7 | — | — | 13. 7 | 0.96 | ml | Y | |

---

## international-03-jamaican-pepper-shrimp

**Category**: international | **Lines**: 26 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Jamaican Pepper Shrimp | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Jamaican | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1 lb Shrimp | ingredient | 0.95 | Y | |
| 8 | - 2 chopped Scotch Bonnet | ingredient | 0.60 | Y | |
| 9 | - 1 tablespoon All-purpose Seasoning | ingredient | 0.95 | Y | |
| 10 | - 2 tsp Ground Annatto | ingredient | 0.95 | Y | |
| 11 | - 2 tsp Allspice | ingredient | 0.95 | Y | |
| 12 | - 3/4 cup Shrimp Stock | ingredient | 0.95 | Y | |
| 13 | - 1/4 cup Onion | ingredient | 0.95 | Y | |
| 14 | - 2 cloves minced Garlic | ingredient | 0.95 | Y | |
| 15 | - 2 tablespoons White Vinegar | ingredient | 0.95 | Y | |
| 16 | - 3 sprigs Thyme | ingredient | 0.95 | Y | |
| 17 | - To taste Salt | title | 0.30 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. In a medium bowl, combine shrimp with minced Scotch Bonnet peppers, all-purpo | instruction | 0.30 | Y | |
| 20 | 2. Heat a large pan over medium heat. Add the shrimp stock and bring to a gentle | instruction | 0.70 | Y | |
| 21 | 3. Add the seasoned shrimp and thyme sprigs, spreading the shrimp in the pan. Co | instruction | 0.70 | Y | |
| 22 | 4. Add the white vinegar, stir, and cook for another minute. Taste; add salt to  | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1 lb Shrimp | 1 | lb | Shrimp | 1.00 | regex | Y | |
| 8 | - 2 chopped Scotch Bonnet | 2 | — | chopped Scotch Bonnet | 0.92 | regex | Y | |
| 9 | - 1 tablespoon All-purpose Seasoning | 1 | tbsp | All-purpose Seasoning | 1.00 | regex | Y | |
| 10 | - 2 tsp Ground Annatto | 2 | tsp | Ground Annatto | 1.00 | regex | Y | |
| 11 | - 2 tsp Allspice | 2 | tsp | Allspice | 1.00 | regex | Y | |
| 12 | - 3/4 cup Shrimp Stock | 0.75 | cup | Shrimp Stock | 1.00 | regex | Y | |
| 13 | - 1/4 cup Onion | 0.25 | cup | Onion | 1.00 | regex | Y | |
| 14 | - 2 cloves minced Garlic | 2 | clove | minced Garlic | 1.00 | regex | Y | |
| 15 | - 2 tablespoons White Vinegar | 2 | tbsp | White Vinegar | 1.00 | regex | Y | |
| 16 | - 3 sprigs Thyme | 3 | sprig | Thyme | 1.00 | regex | Y | |

---

## international-04-recheado-masala-fish

**Category**: international | **Lines**: 41 | **Ingredients found**: 15

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Recheado Masala Fish | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Indian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 4 Mackerel | ingredient | 0.60 | Y | |
| 8 | - 18 dried Red Chilli | ingredient | 0.60 | Y | |
| 9 | - 1 inch Ginger | ingredient | 0.60 | Y | |
| 10 | - 8 cloves Garlic | ingredient | 0.95 | Y | |
| 11 | - 1.5 tsp Pepper | ingredient | 0.55 | Y | |
| 12 | - 1 tsp Cumin | ingredient | 0.95 | Y | |
| 13 | - ½ tsp Turmeric | ingredient | 1.00 | Y | |
| 14 | - Cinnamon stick | ingredient | 0.75 | Y | |
| 15 | - 4 Cloves | ingredient | 0.95 | Y | |
| 16 | - 2 Cardamom | ingredient | 0.60 | Y | |
| 17 | - 1 tbsp Sugar | ingredient | 0.95 | Y | |
| 18 | - 2 marble sized Tamarind ball | ingredient | 0.60 | Y | |
| 19 | - 2.5 tbsp Vinegar | ingredient | 0.55 | Y | |
| 20 | - for frying Oil | ingredient | 0.30 | Y | |
| 21 | Instructions: | sectionHeader | 0.90 | Y | |
| 22 | 1. Soak all the spices, ginger, garlic, tamarind pulp and kashmiri chilies excep | instruction | 0.30 | Y | |
| 23 | 2. Add sugar and salt. | instruction | 0.40 | Y | |
| 24 | 3. Also add turmeric powder. | instruction | 0.30 | Y | |
| 25 | 4. Combine all nicely and marinate for 35-40 mins. | instruction | 0.50 | Y | |
| 26 | 5. Grind the mixture until soft and smooth. Add more vinegar if required but ens | instruction | 0.30 | Y | |
| 27 | 6. Rinse the fish slit from the center and give some incision from the top. You  | instruction | 0.60 | Y | |
| 28 | 7. Now stuff the paste into the center and into the incision. Coat the entire fi | instruction | 0.30 | Y | |
| 29 | 8. Place oil in a shallow pan, once oil is quite hot shallow fry the stuffed mac | instruction | 0.60 | Y | |
| 30 | 9. Fry until golden brown from both sides | instruction | 0.40 | Y | |
| 31 | 10. Serve the recheado mackerels hot with salad, lime wedges, rice and curry. | instruction | 0.60 | Y | |
| 32 | 11. Notes | sectionHeader | 0.90 | Y | |
| 33 | 12. Ensure the masala paste is thick else the result won't be good. | metadata | 0.30 | Y | |
| 34 | 13. If you aren't able to find kashmiri chilies then use bedgi chilies or kashmi | metadata | 0.30 | Y | |
| 35 | 14. You could use white vinegar or coconut vinegar. | metadata | 0.30 | Y | |
| 36 | 15. Any left over paste could be stored in the fridge for future use. | metadata | 0.30 | Y | |
| 37 | 16. Cinnamon could be avoided as it's a strong spice used generally for meat or  | ingredient | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 4 Mackerel | 4 | — | Mackere l | 0.92 | regex | Y | |
| 8 | - 18 dried Red Chilli | 18 | — | dried Red Chilli | 0.92 | regex | Y | |
| 9 | - 1 inch Ginger | 1 | — | inch Ginger | 0.92 | regex | Y | |
| 10 | - 8 cloves Garlic | 8 | clove | Garlic | 1.00 | regex | Y | |
| 11 | - 1.5 tsp Pepper | 1.5 | tsp | Pepper | 1.00 | regex | Y | |
| 12 | - 1 tsp Cumin | 1 | tsp | Cumin | 1.00 | regex | Y | |
| 13 | - ½ tsp Turmeric | 0.5 | tsp | Turmeric | 1.00 | regex | Y | |
| 14 | - Cinnamon stick | — | — | cinnamon stick | 0.97 | ml | Y | |
| 15 | - 4 Cloves | 4 | clove | s | 1.00 | regex | Y | |
| 16 | - 2 Cardamom | 2 | — | Cardamo m | 0.92 | regex | Y | |
| 17 | - 1 tbsp Sugar | 1 | tbsp | Sugar | 1.00 | regex | Y | |
| 18 | - 2 marble sized Tamarind ball | 2 | — | marble sized Tamarind ball | 0.92 | regex | Y | |
| 19 | - 2.5 tbsp Vinegar | 2.5 | tbsp | Vinegar | 1.00 | regex | Y | |
| 20 | - for frying Oil | — | — | - for frying Oil | 0.99 | ml | Y | |
| 37 | 16. Cinnamon could be avoided as it's a strong spice used ge | 16 | — | cinnamon could be avoided | 0.77 | ml | Y | |

---

## international-05-kidney-bean-curry

**Category**: international | **Lines**: 25 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Kidney Bean Curry | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Indian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1 tbls Vegetable Oil | ingredient | 0.60 | Y | |
| 8 | - 1 finely chopped Onion | ingredient | 0.60 | Y | |
| 9 | - 2 cloves chopped Garlic | ingredient | 0.95 | Y | |
| 10 | - 1 part Ginger | ingredient | 0.60 | Y | |
| 11 | - 1 Packet Coriander | ingredient | 0.60 | Y | |
| 12 | - 1 tsp Cumin | ingredient | 0.95 | Y | |
| 13 | - 1 tsp Paprika | ingredient | 0.95 | Y | |
| 14 | - 2 tsp Garam Masala | ingredient | 0.95 | Y | |
| 15 | - 400g Chopped Tomatoes | ingredient | 0.60 | Y | |
| 16 | - 400g Kidney Beans | ingredient | 0.60 | Y | |
| 17 | - to serve Basmati Rice | ingredient | 0.30 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Heat the oil in a large frying pan over a low-medium heat. Add the onion and  | instruction | 0.70 | Y | |
| 20 | 2. Add the spices to the pan and cook for another 1 min, by which point everythi | instruction | 0.70 | Y | |
| 21 | 3. Turn down the heat and simmer for 15 mins until the curry is nice and thick.  | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1 tbls Vegetable Oil | 1 | — | tbls Vegetable Oil | 0.92 | regex | Y | |
| 8 | - 1 finely chopped Onion | 1 | — | finely chopped Onion | 0.92 | regex | Y | |
| 9 | - 2 cloves chopped Garlic | 2 | clove | chopped Garlic | 1.00 | regex | Y | |
| 10 | - 1 part Ginger | 1 | — | part Ginger | 0.92 | regex | Y | |
| 11 | - 1 Packet Coriander | 1 | — | Packet Coriander | 0.92 | regex | Y | |
| 12 | - 1 tsp Cumin | 1 | tsp | Cumin | 1.00 | regex | Y | |
| 13 | - 1 tsp Paprika | 1 | tsp | Paprika | 1.00 | regex | Y | |
| 14 | - 2 tsp Garam Masala | 2 | tsp | Garam Masala | 1.00 | regex | Y | |
| 15 | - 400g Chopped Tomatoes | 400 | g | Chopped Tomatoes | 1.00 | regex | Y | |
| 16 | - 400g Kidney Beans | 400 | g | Kidney Beans | 1.00 | regex | Y | |
| 17 | - to serve Basmati Rice | — | — | - to serve Basmati Rice | 0.86 | ml | Y | |

---

## international-06-khobz-el-dar-algerian-semolina-bread

**Category**: international | **Lines**: 32 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Khobz el Dar (Algerian Semolina Bread) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Algerian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 1/2 cup Semolina Flour | ingredient | 0.95 | Y | |
| 8 | - 2 tablespoons Semolina Flour | ingredient | 0.95 | Y | |
| 9 | - 3  tablespoons Sesame Seed | ingredient | 0.95 | Y | |
| 10 | - 1 tablespoon Sugar | ingredient | 0.95 | Y | |
| 11 | - 1 tsp Yeast | ingredient | 0.95 | Y | |
| 12 | - 3/4 teaspoon Salt | ingredient | 0.95 | Y | |
| 13 | - 1/4 cup Vegetable Oil | ingredient | 0.95 | Y | |
| 14 | - 1 Egg | ingredient | 0.60 | Y | |
| 15 | - 1 Egg | ingredient | 0.60 | Y | |
| 16 | - 1 cup Milk | ingredient | 0.95 | Y | |
| 17 | - 3 Cups All purpose flour | ingredient | 0.95 | Y | |
| 18 | - 2 tablespoons All purpose flour | ingredient | 0.95 | Y | |
| 19 | - 1 tsp Water | ingredient | 0.95 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Mix 1/2 cup plus 2 tablespoons semolina, 2 tablespoons sesame seeds, sugar, y | instruction | 0.60 | Y | |
| 22 | 2. Cover the bowl with a plate or plastic wrap; let stand at room temperature un | instruction | 0.70 | Y | |
| 23 | 3. Stir in 2 3/4 cups flour with a wooden spoon until a sticky dough forms. Cove | instruction | 0.70 | Y | |
| 24 | 4. Line a baking sheet with parchment paper or a baking mat. | instruction | 0.30 | Y | |
| 25 | 5. Sprinkle 1 tablespoon flour over the dough and your hands. Mix dough, adding  | instruction | 0.70 | Y | |
| 26 | 6. Preheat oven to 400 degrees F (200 degrees C). | instruction | 0.55 | Y | |
| 27 | 7. Beat egg yolk and water in a bowl with a fork; brush over the entire surface  | instruction | 0.60 | Y | |
| 28 | 8. Bake in the preheated oven until loaf is golden brown, about 20 to 25 minutes | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1/2 cup Semolina Flour | 0.5 | cup | Semolina Flour | 1.00 | regex | Y | |
| 8 | - 2 tablespoons Semolina Flour | 2 | tbsp | Semolina Flour | 1.00 | regex | Y | |
| 9 | - 3  tablespoons Sesame Seed | 3 | tbsp | Sesame Seed | 1.00 | regex | Y | |
| 10 | - 1 tablespoon Sugar | 1 | tbsp | Sugar | 1.00 | regex | Y | |
| 11 | - 1 tsp Yeast | 1 | tsp | Yeast | 1.00 | regex | Y | |
| 12 | - 3/4 teaspoon Salt | 0.75 | tsp | Salt | 1.00 | regex | Y | |
| 13 | - 1/4 cup Vegetable Oil | 0.25 | cup | Vegetable Oil | 1.00 | regex | Y | |
| 14 | - 1 Egg | 1 | — | Eg g | 0.92 | regex | Y | |
| 14 | - 1 Egg | 1 | — | Eg g | 0.92 | regex | Y | |
| 16 | - 1 cup Milk | 1 | cup | Milk | 1.00 | regex | Y | |
| 17 | - 3 Cups All purpose flour | 3 | cup | All purpose flour | 1.00 | regex | Y | |
| 18 | - 2 tablespoons All purpose flour | 2 | tbsp | All purpose flour | 1.00 | regex | Y | |
| 19 | - 1 tsp Water | 1 | tsp | Water | 1.00 | regex | Y | |

---

## international-07-chtitha-batata-algerian-potato-stew

**Category**: international | **Lines**: 26 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chtitha Batata (Algerian Potato Stew) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Algerian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 4 cloves Garlic | ingredient | 0.95 | Y | |
| 8 | - 1 small Red Chilli | ingredient | 0.60 | Y | |
| 9 | - 1 tsp Ground Cumin | ingredient | 0.95 | Y | |
| 10 | - 1 teaspoon Paprika | ingredient | 0.95 | Y | |
| 11 | - 1/2 teaspoon Black Pepper | ingredient | 0.95 | Y | |
| 12 | - 1/2 teaspoon Cayenne Pepper | ingredient | 0.95 | Y | |
| 13 | - 1/2 teaspoon Salt | ingredient | 0.95 | Y | |
| 14 | - 2 tablespoons Olive Oil | ingredient | 0.95 | Y | |
| 15 | - 2 Lbs New Potatoes | ingredient | 0.95 | Y | |
| 16 | - 1 tablespoon Tomato Puree | ingredient | 0.95 | Y | |
| 17 | - Boiled Water | title | 0.30 | Y | |
| 18 | - To taste Salt | title | 0.30 | Y | |
| 19 | Instructions: | sectionHeader | 0.90 | Y | |
| 20 | 1. Combine garlic, chile pepper, cumin, paprika, black pepper, cayenne, and salt | instruction | 0.60 | Y | |
| 21 | 2. Heat a large saucepan over medium heat and stir-fry dersa until fragrant, 2 t | instruction | 0.70 | Y | |
| 22 | 3. Ladle potatoes into a serving bowl. Spoon any remaining sauce over the potato | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 4 cloves Garlic | 4 | clove | Garlic | 1.00 | regex | Y | |
| 8 | - 1 small Red Chilli | 1 | — | small Red Chilli | 0.92 | regex | Y | |
| 9 | - 1 tsp Ground Cumin | 1 | tsp | Ground Cumin | 1.00 | regex | Y | |
| 10 | - 1 teaspoon Paprika | 1 | tsp | Paprika | 1.00 | regex | Y | |
| 11 | - 1/2 teaspoon Black Pepper | 0.5 | tsp | Black Pepper | 1.00 | regex | Y | |
| 12 | - 1/2 teaspoon Cayenne Pepper | 0.5 | tsp | Cayenne Pepper | 1.00 | regex | Y | |
| 13 | - 1/2 teaspoon Salt | 0.5 | tsp | Salt | 1.00 | regex | Y | |
| 14 | - 2 tablespoons Olive Oil | 2 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 15 | - 2 Lbs New Potatoes | 2 | lb | New Potatoes | 1.00 | regex | Y | |
| 16 | - 1 tablespoon Tomato Puree | 1 | tbsp | Tomato Puree | 1.00 | regex | Y | |

---

## international-08-lamb-tagine

**Category**: international | **Lines**: 30 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Lamb Tagine | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Moroccan | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 2 tblsp Olive Oil | ingredient | 0.60 | Y | |
| 8 | - 1 finely sliced Onion | ingredient | 0.60 | Y | |
| 9 | - 2 chopped Carrots | ingredient | 0.60 | Y | |
| 10 | - 500g Lamb Leg | ingredient | 0.60 | Y | |
| 11 | - 2 cloves minced Garlic | ingredient | 0.95 | Y | |
| 12 | - ½ tsp Cumin | ingredient | 1.00 | Y | |
| 13 | - ½ tsp Ginger | ingredient | 1.00 | Y | |
| 14 | - ¼ tsp Saffron | ingredient | 1.00 | Y | |
| 15 | - 1 tsp Cinnamon | ingredient | 0.95 | Y | |
| 16 | - 1 tblsp Honey | ingredient | 0.60 | Y | |
| 17 | - 100g Apricot | ingredient | 0.60 | Y | |
| 18 | - 1 Vegetable Stock Cube | ingredient | 0.60 | Y | |
| 19 | - 1 medium chopped Butternut Squash | ingredient | 0.60 | Y | |
| 20 | - Steamed Couscous | title | 0.30 | Y | |
| 21 | - Chopped Parsley | title | 0.30 | Y | |
| 22 | Instructions: | sectionHeader | 0.90 | Y | |
| 23 | 1. Heat the olive oil in a heavy-based pan and add the onion and carrot. Cook fo | instruction | 0.70 | Y | |
| 24 | 2. Add the diced lamb and brown all over. Stir in the garlic and all the spices  | instruction | 0.60 | Y | |
| 25 | 3. Add the honey and apricots, crumble in the stock cube and pour over roughly 5 | instruction | 0.70 | Y | |
| 26 | 4. Remove the lid and cook for a further 30 mins, then stir in the squash. Cook  | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 2 tblsp Olive Oil | 2 | — | tblsp Olive Oil | 0.92 | regex | Y | |
| 8 | - 1 finely sliced Onion | 1 | — | finely sliced Onion | 0.92 | regex | Y | |
| 9 | - 2 chopped Carrots | 2 | — | chopped Carrots | 0.92 | regex | Y | |
| 10 | - 500g Lamb Leg | 500 | g | Lamb Leg | 1.00 | regex | Y | |
| 11 | - 2 cloves minced Garlic | 2 | clove | minced Garlic | 1.00 | regex | Y | |
| 12 | - ½ tsp Cumin | 0.5 | tsp | Cumin | 1.00 | regex | Y | |
| 13 | - ½ tsp Ginger | 0.5 | tsp | Ginger | 1.00 | regex | Y | |
| 14 | - ¼ tsp Saffron | 0.25 | tsp | Saffron | 1.00 | regex | Y | |
| 15 | - 1 tsp Cinnamon | 1 | tsp | Cinnamon | 1.00 | regex | Y | |
| 16 | - 1 tblsp Honey | 1 | — | tblsp Honey | 0.92 | regex | Y | |
| 17 | - 100g Apricot | 100 | g | Apricot | 1.00 | regex | Y | |
| 18 | - 1 Vegetable Stock Cube | 1 | — | Vegetable Stock Cube | 0.92 | regex | Y | |
| 19 | - 1 medium chopped Butternut Squash | 1 | — | medium chopped Butternut Squas | 0.92 | regex | Y | |

---

## international-09-algerian-flafla-bell-pepper-salad

**Category**: international | **Lines**: 21 | **Ingredients found**: 5

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Algerian Flafla (Bell Pepper Salad) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Algerian | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 3 Green Pepper | ingredient | 0.60 | Y | |
| 8 | - 1 tablespoon Olive Oil | ingredient | 0.95 | Y | |
| 9 | - 1 tablespoon chopped Red Onions | ingredient | 0.95 | Y | |
| 10 | - 1 clove peeled crushed Garlic | ingredient | 0.95 | Y | |
| 11 | - To taste Salt | title | 0.30 | Y | |
| 12 | - To taste Pepper | title | 0.30 | Y | |
| 13 | - 1 Diced Plum Tomatoes | ingredient | 0.60 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Preheat an oven to 450 degrees F (230 degrees C). Place the whole peppers on  | instruction | 0.85 | Y | |
| 16 | 2. Remove peppers from the oven and set aside to cool for 10 minutes. Peel off t | instruction | 0.70 | Y | |
| 17 | 3. Heat the olive oil in a skillet over medium heat. Stir in the onion and cook, | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 3 Green Pepper | 3 | — | Green Pepper | 0.92 | regex | Y | |
| 8 | - 1 tablespoon Olive Oil | 1 | tbsp | Olive Oil | 1.00 | regex | Y | |
| 9 | - 1 tablespoon chopped Red Onions | 1 | tbsp | chopped Red Onions | 1.00 | regex | Y | |
| 10 | - 1 clove peeled crushed Garlic | 1 | clove | peeled crushed Garlic | 1.00 | regex | Y | |
| 13 | - 1 Diced Plum Tomatoes | 1 | — | Diced Plum Tomatoes | 0.92 | regex | Y | |

---

## international-10-spicy-north-african-potato-salad

**Category**: international | **Lines**: 30 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Spicy North African Potato Salad | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Cuisine: Moroccan | metadata | 0.60 | Y | |
| 4 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Cook Time: 40 minutes | metadata | 0.70 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 650g/1lb 8 oz Small Potatoes | ingredient | 0.95 | Y | |
| 8 | - 1 tsp Harissa Spice | ingredient | 0.95 | Y | |
| 9 | - 2 tsp olive oil | ingredient | 0.95 | Y | |
| 10 | - juice of half Lemon | ingredient | 0.30 | Y | |
| 11 | - 4 Spring onions | ingredient | 0.60 | Y | |
| 12 | - 150g/6oz Rocket | ingredient | 0.60 | Y | |
| 13 | - 80g/3oz Feta | ingredient | 0.60 | Y | |
| 14 | - 20 chopped Mint | ingredient | 0.60 | Y | |
| 15 | - 2 tablespoons Pine nuts | ingredient | 0.95 | Y | |
| 16 | - Pinch Salt | ingredient | 0.45 | Y | |
| 17 | - Pinch Pepper | ingredient | 0.45 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Cook potatoes - place potatoes in a pot of cold water, and bring to the boil. | instruction | 0.70 | Y | |
| 20 | 2. Combine harissa spice, olive oil, salt and pepper and lemon juice in a small  | instruction | 0.60 | Y | |
| 21 | 3. Once potatoes are cooked, drain water and roughly chop potatoes in half. | instruction | 0.30 | Y | |
| 22 | 4. Add harissa mix and spring onions/green onions to potatoes and stir. | instruction | 0.60 | Y | |
| 23 | 5. In a large salad bowl, lay out arugula/rocket. | instruction | 0.30 | Y | |
| 24 | 6. Top with potato mix and toss. | instruction | 0.30 | Y | |
| 25 | 7. Add fetta, mint and sprinkle over pine nuts. | instruction | 0.40 | Y | |
| 26 | 8. Adjust salt and pepper to taste. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 650g/1lb 8 oz Small Potatoes | 650 | g | /1lb 8 oz Small Potatoes | 1.00 | regex | Y | |
| 8 | - 1 tsp Harissa Spice | 1 | tsp | Harissa Spice | 1.00 | regex | Y | |
| 9 | - 2 tsp olive oil | 2 | tsp | olive oil | 1.00 | regex | Y | |
| 10 | - juice of half Lemon | — | — | lemon | 0.93 | ml | Y | |
| 11 | - 4 Spring onions | 4 | — | Spring onions | 0.92 | regex | Y | |
| 12 | - 150g/6oz Rocket | 150 | g | /6oz Rocket | 1.00 | regex | Y | |
| 13 | - 80g/3oz Feta | 80 | g | /3oz Feta | 1.00 | regex | Y | |
| 14 | - 20 chopped Mint | 20 | — | chopped Mint | 0.92 | regex | Y | |
| 15 | - 2 tablespoons Pine nuts | 2 | tbsp | Pine nuts | 1.00 | regex | Y | |
| 16 | - Pinch Salt | 0.12 | — | salt | 0.95 | regex | Y | |
| 17 | - Pinch Pepper | 0.12 | — | pepper | 0.95 | regex | Y | |

---

