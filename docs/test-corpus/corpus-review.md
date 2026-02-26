# Recipe Corpus Review File

**Generated**: 2026-02-26T15:33:59Z
**Total Recipes**: 50
**Purpose**: Review classifier and parser predictions. Change `Y` to `N` in the Correct? column and fill Correction for any errors.

## How to Review

1. Scan each recipe's Classification table — is every line classified correctly?
2. Scan the Parsing table — for ingredient lines, are qty/unit/name correct?
3. For incorrect predictions: change `Y` to `N` and describe the fix in the Correction column
4. Examples of corrections:
   - Classification: `N` | `should be: ingredient` (line was misclassified)
   - Parsing: `N` | `qty=14.5 unit=oz name=diced tomatoes` (wrong parse)

---

## Summary Statistics

| Category | Recipes | Lines | Ingredients |
|----------|---------|-------|-------------|
| clean | 10 | 224 | 106 |
| no-headers | 10 | 137 | 77 |
| unusual-metadata | 10 | 291 | 129 |
| messy | 10 | 129 | 51 |
| international | 10 | 238 | 113 |

### Classification Distribution

| Type | Count | % |
|------|-------|---|
| title | 59 | 5.8% |
| ingredient | 476 | 46.7% |
| instruction | 239 | 23.5% |
| metadata | 115 | 11.3% |
| sectionHeader | 68 | 6.7% |
| unknown | 62 | 6.1% |

### Parser Usage

| Parser | Count | % |
|--------|-------|---|
| regex | 442 | 92.9% |
| ml | 34 | 7.1% |
| nlp | 0 | 0.0% |

---

## clean-01-chicken-handi

**Category**: clean | **Lines**: 35 | **Ingredients found**: 16

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Handi | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 30 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 1.2 kg chicken | ingredient | 0.55 | Y | |
| 7 | - 5 thinly sliced onion | ingredient | 0.60 | Y | |
| 8 | - 2 finely chopped tomatoes | ingredient | 0.60 | Y | |
| 9 | - 8 cloves chopped garlic | ingredient | 0.95 | Y | |
| 10 | - 1 tbsp ginger paste | ingredient | 0.95 | Y | |
| 11 | - 1/4 cup vegetable oil | ingredient | 0.95 | Y | |
| 12 | - 2 tsp cumin seeds | ingredient | 0.95 | Y | |
| 13 | - 3 tsp coriander seeds | ingredient | 0.95 | Y | |
| 14 | - 1 tsp turmeric powder | ingredient | 0.95 | Y | |
| 15 | - 1 tsp chilli powder | ingredient | 0.95 | Y | |
| 16 | - 2 green chilli | ingredient | 0.60 | Y | |
| 17 | - 1 cup yogurt | ingredient | 0.95 | Y | |
| 18 | - 3/4 cup cream | ingredient | 0.95 | Y | |
| 19 | - 3 tsp dried fenugreek | ingredient | 0.95 | Y | |
| 20 | - 1 tsp garam masala | ingredient | 0.95 | Y | |
| 21 | - Salt to taste | ingredient | 0.40 | Y | |
| 22 | Instructions: | sectionHeader | 0.90 | Y | |
| 23 | 1. Heat oil in a large pot. Fry sliced onion until deep golden brown, then set a | instruction | 0.60 | Y | |
| 24 | 2. In the same pot, add chopped garlic and saute for a minute. Add chopped tomat | instruction | 0.30 | Y | |
| 25 | 3. Return fried onion to pot. Add ginger paste and saute well. | instruction | 0.30 | Y | |
| 26 | 4. Add cumin seeds, half the coriander seeds, and chopped green chillies. Stir q | instruction | 0.60 | Y | |
| 27 | 5. Add turmeric and red chilli powder. Saute for a couple of minutes. | instruction | 0.60 | Y | |
| 28 | 6. Add chicken pieces, season with salt, and cook covered on medium-low for 15 m | instruction | 0.70 | Y | |
| 29 | 7. When oil separates from spices, add beaten yogurt on lowest heat. Sprinkle re | instruction | 0.30 | Y | |
| 30 | 8. Add cream and mix well. | instruction | 0.40 | Y | |
| 31 | 9. Sprinkle remaining kasuri methi and garam masala. Serve hot with naan. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 1.2 kg chicken | 1.2 | kg | chicken | 1.00 | regex | Y | |
| 7 | - 5 thinly sliced onion | 5 | — | thinly sliced onion | 0.92 | regex | Y | |
| 8 | - 2 finely chopped tomatoes | 2 | — | finely chopped tomatoes | 0.92 | regex | Y | |
| 9 | - 8 cloves chopped garlic | 8 | clove | chopped garlic | 1.00 | regex | Y | |
| 10 | - 1 tbsp ginger paste | 1 | tbsp | ginger paste | 1.00 | regex | Y | |
| 11 | - 1/4 cup vegetable oil | 0.25 | cup | vegetable oil | 1.00 | regex | Y | |
| 12 | - 2 tsp cumin seeds | 2 | tsp | cumin seeds | 1.00 | regex | Y | |
| 13 | - 3 tsp coriander seeds | 3 | tsp | coriander seeds | 1.00 | regex | Y | |
| 14 | - 1 tsp turmeric powder | 1 | tsp | turmeric powder | 1.00 | regex | Y | |
| 15 | - 1 tsp chilli powder | 1 | tsp | chilli powder | 1.00 | regex | Y | |
| 16 | - 2 green chilli | 2 | — | green chilli | 0.92 | regex | Y | |
| 17 | - 1 cup yogurt | 1 | cup | yogurt | 1.00 | regex | Y | |
| 18 | - 3/4 cup cream | 0.75 | cup | cream | 1.00 | regex | Y | |
| 19 | - 3 tsp dried fenugreek | 3 | tsp | dried fenugreek | 1.00 | regex | Y | |
| 20 | - 1 tsp garam masala | 1 | tsp | garam masala | 1.00 | regex | Y | |
| 21 | - Salt to taste | — | — | salt | 1.00 | ml | Y | |

---

## clean-02-beef-wellington

**Category**: clean | **Lines**: 25 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Wellington | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 30 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 35 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 400g mushrooms | ingredient | 0.60 | Y | |
| 7 | - 1-2 tbsp English mustard | ingredient | 0.95 | Y | |
| 8 | - Dash of olive oil | ingredient | 0.45 | Y | |
| 9 | - 750g piece beef fillet | ingredient | 0.95 | Y | |
| 10 | - 6-8 slices Parma ham | ingredient | 0.95 | Y | |
| 11 | - 500g puff pastry | ingredient | 0.60 | Y | |
| 12 | - Flour for dusting | ingredient | 0.40 | Y | |
| 13 | - 2 beaten egg yolks | ingredient | 0.60 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Put mushrooms into a food processor with seasoning and pulse to a rough paste | instruction | 0.30 | Y | |
| 16 | 2. Heat a frying pan and add a little olive oil. Season the beef and sear for 30 | instruction | 0.70 | Y | |
| 17 | 3. Lay cling film on a work surface and arrange Parma ham slices in slightly ove | instruction | 0.30 | Y | |
| 18 | 4. Roll out puff pastry to a large rectangle. Remove cling film from beef and la | instruction | 0.70 | Y | |
| 19 | 5. Heat oven to 200C/400F/gas 6. Score pastry at 1cm intervals and glaze again w | instruction | 0.60 | Y | |
| 20 | 6. Bake for 20 minutes, then lower to 180C/350F/gas 4 and cook for another 15 mi | instruction | 0.70 | Y | |
| 21 | 7. Rest for 10-15 mins before slicing and serving. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 400g mushrooms | 400 | g | mushrooms | 1.00 | regex | Y | |
| 7 | - 1-2 tbsp English mustard | 2 | tbsp | English mustard | 0.95 | regex | Y | |
| 8 | - Dash of olive oil | 0.12 | — | olive oil | 0.95 | regex | Y | |
| 9 | - 750g piece beef fillet | 750 | g | piece beef fillet | 1.00 | regex | Y | |
| 10 | - 6-8 slices Parma ham | 8 | slice | Parma ham | 0.95 | regex | Y | |
| 11 | - 500g puff pastry | 500 | g | puff pastry | 1.00 | regex | Y | |
| 12 | - Flour for dusting | — | — | flour | 1.00 | ml | Y | |
| 13 | - 2 beaten egg yolks | 2 | — | beaten egg yolks | 0.92 | regex | Y | |

---

## clean-03-leblebi-soup

**Category**: clean | **Lines**: 25 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Leblebi Soup | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 60 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 tablespoons olive oil | ingredient | 0.95 | Y | |
| 7 | - 1 medium finely diced onion | ingredient | 0.60 | Y | |
| 8 | - 250g chickpeas | ingredient | 0.60 | Y | |
| 9 | - 1.5L vegetable stock | instruction | 0.50 | Y | |
| 10 | - 1 tsp cumin | ingredient | 0.95 | Y | |
| 11 | - 5 cloves garlic | ingredient | 0.95 | Y | |
| 12 | - 1/2 tsp salt | ingredient | 0.95 | Y | |
| 13 | - 1 tsp harissa spice | ingredient | 0.95 | Y | |
| 14 | - Pinch of pepper | ingredient | 0.45 | Y | |
| 15 | - 1/2 lime | ingredient | 0.60 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Heat the oil in a large pot. Add the onion and cook until translucent. | instruction | 0.60 | Y | |
| 18 | 2. Drain the soaked chickpeas and add them to the pot together with the vegetabl | instruction | 0.70 | Y | |
| 19 | 3. In the meantime toast the cumin in a small ungreased frying pan, then grind t | instruction | 0.30 | Y | |
| 20 | 4. Add the paste and the harissa to the soup and simmer until the chickpeas are  | instruction | 0.70 | Y | |
| 21 | 5. Season to taste with salt, pepper and lemon juice and serve hot. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 tablespoons olive oil | 2 | tbsp | olive oil | 1.00 | regex | Y | |
| 7 | - 1 medium finely diced onion | 1 | — | medium finely diced onion | 0.92 | regex | Y | |
| 8 | - 250g chickpeas | 250 | g | chickpeas | 1.00 | regex | Y | |
| 10 | - 1 tsp cumin | 1 | tsp | cumin | 1.00 | regex | Y | |
| 11 | - 5 cloves garlic | 5 | clove | garlic | 1.00 | regex | Y | |
| 12 | - 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex | Y | |
| 13 | - 1 tsp harissa spice | 1 | tsp | harissa spice | 1.00 | regex | Y | |
| 14 | - Pinch of pepper | 0.12 | — | pepper | 0.95 | regex | Y | |
| 15 | - 1/2 lime | 0.5 | — | lim e | 0.92 | regex | Y | |

---

## clean-04-carrot-cake

**Category**: clean | **Lines**: 28 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Carrot Cake | title | 0.70 | Y | |
| 2 | Servings: 10 | metadata | 0.70 | Y | |
| 3 | Prep Time: 20 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 75 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 450ml vegetable oil | ingredient | 0.60 | Y | |
| 7 | - 400g plain flour | ingredient | 0.60 | Y | |
| 8 | - 2 tsp bicarbonate of soda | ingredient | 0.95 | Y | |
| 9 | - 550ml sugar | ingredient | 0.60 | Y | |
| 10 | - 5 eggs | ingredient | 0.60 | Y | |
| 11 | - 1/2 tsp salt | ingredient | 0.95 | Y | |
| 12 | - 2 tsp cinnamon | ingredient | 0.95 | Y | |
| 13 | - 500g grated carrots | ingredient | 0.60 | Y | |
| 14 | - 150g walnuts | ingredient | 0.60 | Y | |
| 15 | - 200g cream cheese | ingredient | 0.60 | Y | |
| 16 | - 150g caster sugar | ingredient | 0.60 | Y | |
| 17 | - 100g butter | ingredient | 0.60 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Preheat the oven to 160C/325F/Gas 3. Grease and line a 26cm/10in springform c | instruction | 0.60 | Y | |
| 20 | 2. Mix all of the ingredients for the carrot cake, except the carrots and walnut | instruction | 0.60 | Y | |
| 21 | 3. Spoon the mixture into the cake tin and bake for 1 hour 15 minutes, or until  | instruction | 0.30 | Y | |
| 22 | 4. Remove from the oven and set aside to cool for 10 minutes, then carefully rem | instruction | 0.70 | Y | |
| 23 | 5. For the icing, beat the cream cheese, caster sugar and butter together in a b | sectionHeader | 0.90 | Y | |
| 24 | 6. Spread the icing over the top of the cake with a palette knife. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 450ml vegetable oil | 450 | ml | vegetable oil | 1.00 | regex | Y | |
| 7 | - 400g plain flour | 400 | g | plain flour | 1.00 | regex | Y | |
| 8 | - 2 tsp bicarbonate of soda | 2 | tsp | bicarbonate of soda | 1.00 | regex | Y | |
| 9 | - 550ml sugar | 550 | ml | sugar | 1.00 | regex | Y | |
| 10 | - 5 eggs | 5 | — | egg s | 0.92 | regex | Y | |
| 11 | - 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex | Y | |
| 12 | - 2 tsp cinnamon | 2 | tsp | cinnamon | 1.00 | regex | Y | |
| 13 | - 500g grated carrots | 500 | g | grated carrots | 1.00 | regex | Y | |
| 14 | - 150g walnuts | 150 | g | walnuts | 1.00 | regex | Y | |
| 15 | - 200g cream cheese | 200 | g | cream cheese | 1.00 | regex | Y | |
| 16 | - 150g caster sugar | 150 | g | caster sugar | 1.00 | regex | Y | |
| 17 | - 100g butter | 100 | g | butter | 1.00 | regex | Y | |

---

## clean-05-french-onion-soup

**Category**: clean | **Lines**: 26 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | French Onion Soup | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 45 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 50g butter | ingredient | 0.60 | Y | |
| 7 | - 1 tablespoon olive oil | ingredient | 0.95 | Y | |
| 8 | - 1 kg onion | ingredient | 0.95 | Y | |
| 9 | - 1 tsp sugar | ingredient | 0.95 | Y | |
| 10 | - 4 sliced garlic cloves | ingredient | 0.95 | Y | |
| 11 | - 2 tablespoons plain flour | ingredient | 0.95 | Y | |
| 12 | - 250ml dry white wine | ingredient | 0.60 | Y | |
| 13 | - 1L beef stock | ingredient | 0.60 | Y | |
| 14 | - 4 slices bread | ingredient | 0.95 | Y | |
| 15 | - 140g Gruyere cheese | ingredient | 0.60 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Melt the butter with the oil in a large heavy-based pan. Add the onions and f | instruction | 0.70 | Y | |
| 18 | 2. Sprinkle in the sugar and cook for 20 mins more, stirring frequently, until c | instruction | 0.70 | Y | |
| 19 | 3. Add the garlic for the final few mins, then sprinkle in the flour and stir we | instruction | 0.60 | Y | |
| 20 | 4. Increase the heat and gradually add the wine, followed by the hot stock. Cove | instruction | 0.30 | Y | |
| 21 | 5. Turn on the grill and toast the bread. Ladle the soup into heatproof bowls. | instruction | 0.60 | Y | |
| 22 | 6. Put a slice or two of toast on top and pile on the cheese. Grill until melted | ingredient | 0.45 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 50g butter | 50 | g | butter | 1.00 | regex | Y | |
| 7 | - 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 8 | - 1 kg onion | 1 | kg | onion | 1.00 | regex | Y | |
| 9 | - 1 tsp sugar | 1 | tsp | sugar | 1.00 | regex | Y | |
| 10 | - 4 sliced garlic cloves | 4 | — | sliced garlic cloves | 0.92 | regex | Y | |
| 11 | - 2 tablespoons plain flour | 2 | tbsp | plain flour | 1.00 | regex | Y | |
| 12 | - 250ml dry white wine | 250 | ml | dry white wine | 1.00 | regex | Y | |
| 13 | - 1L beef stock | 1 | l | beef stock | 1.00 | regex | Y | |
| 14 | - 4 slices bread | 4 | slice | bread | 1.00 | regex | Y | |
| 15 | - 140g Gruyere cheese | 140 | g | Gruyere cheese | 1.00 | regex | Y | |
| 22 | 6. Put a slice or two of toast on top and pile on the cheese | 6 | slice | 6. Put a slice or two of toast | 0.68 | ml | Y | |

---

## clean-06-beef-stroganoff

**Category**: clean | **Lines**: 27 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Stroganoff | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 25 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 1 tablespoon olive oil | ingredient | 0.95 | Y | |
| 7 | - 1 onion | ingredient | 0.60 | Y | |
| 8 | - 1 clove garlic | ingredient | 0.95 | Y | |
| 9 | - 1 tbsp butter | ingredient | 0.95 | Y | |
| 10 | - 250g mushrooms | ingredient | 0.60 | Y | |
| 11 | - 500g beef fillet | ingredient | 0.60 | Y | |
| 12 | - 1 tbsp plain flour | ingredient | 0.95 | Y | |
| 13 | - 150g creme fraiche | ingredient | 0.60 | Y | |
| 14 | - 1 tbsp English mustard | ingredient | 0.95 | Y | |
| 15 | - 100ml beef stock | ingredient | 0.60 | Y | |
| 16 | - Parsley for topping | ingredient | 0.40 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. Heat the olive oil in a non-stick frying pan. Add the sliced onion and cook o | instruction | 0.70 | Y | |
| 19 | 2. Once the butter is foaming, add the mushrooms and cook for around 5 mins unti | instruction | 0.30 | Y | |
| 20 | 3. Tip the flour into a bowl with a big pinch of salt and pepper, then toss the  | ingredient | 0.35 | Y | |
| 21 | 4. Add the steak pieces to the pan and fry for 3-4 mins, until well coloured. Ti | instruction | 0.70 | Y | |
| 22 | 5. Whisk the creme fraiche, mustard and beef stock together, then pour into the  | instruction | 0.70 | Y | |
| 23 | 6. Scatter with parsley, then serve with pappardelle or rice. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 7 | - 1 onion | 1 | — | onio n | 0.92 | regex | Y | |
| 8 | - 1 clove garlic | 1 | clove | garlic | 1.00 | regex | Y | |
| 9 | - 1 tbsp butter | 1 | tbsp | butter | 1.00 | regex | Y | |
| 10 | - 250g mushrooms | 250 | g | mushrooms | 1.00 | regex | Y | |
| 11 | - 500g beef fillet | 500 | g | beef fillet | 1.00 | regex | Y | |
| 12 | - 1 tbsp plain flour | 1 | tbsp | plain flour | 1.00 | regex | Y | |
| 13 | - 150g creme fraiche | 150 | g | creme fraiche | 1.00 | regex | Y | |
| 14 | - 1 tbsp English mustard | 1 | tbsp | English mustard | 1.00 | regex | Y | |
| 15 | - 100ml beef stock | 100 | ml | beef stock | 1.00 | regex | Y | |
| 16 | - Parsley for topping | — | — | parsley | 0.99 | ml | Y | |
| 20 | 3. Tip the flour into a bowl with a big pinch of salt and pe | 3 | — | tip the flour | 0.61 | ml | Y | |

---

## clean-07-mediterranean-pasta-salad

**Category**: clean | **Lines**: 24 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Mediterranean Pasta Salad | title | 0.70 | Y | |
| 2 | Servings: 6 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 10 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 500g fusilli pasta | ingredient | 0.60 | Y | |
| 7 | - 200g cherry tomatoes, halved | ingredient | 0.60 | Y | |
| 8 | - 1 cucumber, diced | ingredient | 0.60 | Y | |
| 9 | - 150g Kalamata olives | ingredient | 0.60 | Y | |
| 10 | - 200g feta cheese, crumbled | ingredient | 0.60 | Y | |
| 11 | - 1 red onion, thinly sliced | ingredient | 0.60 | Y | |
| 12 | - 1/4 cup extra virgin olive oil | ingredient | 0.95 | Y | |
| 13 | - 2 tablespoons red wine vinegar | ingredient | 0.95 | Y | |
| 14 | - 1 teaspoon dried oregano | ingredient | 0.95 | Y | |
| 15 | Instructions: | sectionHeader | 0.90 | Y | |
| 16 | 1. Cook the fusilli pasta in a large pot of salted boiling water according to pa | instruction | 0.60 | Y | |
| 17 | 2. In a large serving bowl, combine the cooled pasta with cherry tomatoes, cucum | instruction | 0.30 | Y | |
| 18 | 3. Whisk together the olive oil, red wine vinegar and dried oregano in a small b | instruction | 0.60 | Y | |
| 19 | 4. Pour the dressing over the pasta salad and toss to combine. | instruction | 0.40 | Y | |
| 20 | 5. Season with salt and pepper to taste. Serve immediately or refrigerate for up | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 500g fusilli pasta | 500 | g | fusilli pasta | 1.00 | regex | Y | |
| 7 | - 200g cherry tomatoes, halved | 200 | g | cherry tomatoes, halved | 1.00 | regex | Y | |
| 8 | - 1 cucumber, diced | 1 | — | cucumber , diced | 0.92 | regex | Y | |
| 9 | - 150g Kalamata olives | 150 | g | Kalamata olives | 1.00 | regex | Y | |
| 10 | - 200g feta cheese, crumbled | 200 | g | feta cheese, crumbled | 1.00 | regex | Y | |
| 11 | - 1 red onion, thinly sliced | 1 | — | red onion, thinly sliced | 0.92 | regex | Y | |
| 12 | - 1/4 cup extra virgin olive oil | 0.25 | cup | extra virgin olive oil | 1.00 | regex | Y | |
| 13 | - 2 tablespoons red wine vinegar | 2 | tbsp | red wine vinegar | 1.00 | regex | Y | |
| 14 | - 1 teaspoon dried oregano | 1 | tsp | dried oregano | 1.00 | regex | Y | |

---

## clean-08-pancakes

**Category**: clean | **Lines**: 22 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Pancakes | title | 0.50 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 5 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 15 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 100g flour | ingredient | 0.60 | Y | |
| 7 | - 2 large eggs | ingredient | 0.60 | Y | |
| 8 | - 300ml milk | ingredient | 0.60 | Y | |
| 9 | - 1 tablespoon sunflower oil | ingredient | 0.95 | Y | |
| 10 | - Sugar to serve | ingredient | 0.40 | Y | |
| 11 | - Raspberries to serve | ingredient | 0.30 | Y | |
| 12 | - Blueberries to serve | ingredient | 0.30 | Y | |
| 13 | Instructions: | sectionHeader | 0.90 | Y | |
| 14 | 1. Put the flour, eggs, milk, 1 tbsp oil and a pinch of salt into a bowl or larg | ingredient | 0.35 | Y | |
| 15 | 2. Set aside for 30 mins to rest if you have time, or start cooking straight awa | instruction | 0.70 | Y | |
| 16 | 3. Set a medium frying pan over a medium heat and carefully wipe it with some oi | instruction | 0.60 | Y | |
| 17 | 4. When hot, cook your pancakes for 1 min on each side until golden, keeping the | instruction | 0.30 | Y | |
| 18 | 5. Serve with lemon wedges and sugar, or your favourite filling. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 100g flour | 100 | g | flour | 1.00 | regex | Y | |
| 7 | - 2 large eggs | 2 | — | large eggs | 0.92 | regex | Y | |
| 8 | - 300ml milk | 300 | ml | milk | 1.00 | regex | Y | |
| 9 | - 1 tablespoon sunflower oil | 1 | tbsp | sunflower oil | 1.00 | regex | Y | |
| 10 | - Sugar to serve | — | — | sugar | 0.99 | ml | Y | |
| 11 | - Raspberries to serve | — | — | raspberries | 0.99 | ml | Y | |
| 12 | - Blueberries to serve | — | — | blueberries | 0.98 | ml | Y | |
| 14 | 1. Put the flour, eggs, milk, 1 tbsp oil and a pinch of salt | 1 | — | put the flour eggs milk | 0.60 | ml | Y | |

---

## clean-09-kung-pao-chicken

**Category**: clean | **Lines**: 29 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Kung Pao Chicken | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 20 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 tablespoons sake | ingredient | 0.95 | Y | |
| 7 | - 2 tablespoons soy sauce | ingredient | 0.95 | Y | |
| 8 | - 2 tablespoons sesame seed oil | ingredient | 0.95 | Y | |
| 9 | - 2 tablespoons corn flour | ingredient | 0.95 | Y | |
| 10 | - 2 tablespoons water | ingredient | 0.95 | Y | |
| 11 | - 500g chicken | ingredient | 0.60 | Y | |
| 12 | - 1 tablespoon chilli powder | ingredient | 0.95 | Y | |
| 13 | - 1 tsp rice vinegar | ingredient | 0.95 | Y | |
| 14 | - 1 tablespoon brown sugar | ingredient | 0.95 | Y | |
| 15 | - 4 chopped spring onions | ingredient | 0.60 | Y | |
| 16 | - 6 cloves garlic | ingredient | 0.95 | Y | |
| 17 | - 220g water chestnuts | ingredient | 0.60 | Y | |
| 18 | - 100g peanuts | ingredient | 0.60 | Y | |
| 19 | Instructions: | sectionHeader | 0.90 | Y | |
| 20 | 1. Combine the sake, soy sauce, sesame oil and cornflour dissolved in water. Div | instruction | 0.60 | Y | |
| 21 | 2. Combine half the mixture with chicken pieces and toss to coat. Refrigerate fo | instruction | 0.70 | Y | |
| 22 | 3. In a medium frying pan, combine remaining sauce with chillies, vinegar and su | instruction | 0.30 | Y | |
| 23 | 4. Remove chicken from marinade and saute until juices run clear. | instruction | 0.60 | Y | |
| 24 | 5. When sauce is aromatic, add sauteed chicken and let simmer until sauce thicke | instruction | 0.30 | Y | |
| 25 | 6. Serve immediately with steamed rice. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 tablespoons sake | 2 | tbsp | sake | 1.00 | regex | Y | |
| 7 | - 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 1.00 | regex | Y | |
| 8 | - 2 tablespoons sesame seed oil | 2 | tbsp | sesame seed oil | 1.00 | regex | Y | |
| 9 | - 2 tablespoons corn flour | 2 | tbsp | corn flour | 1.00 | regex | Y | |
| 10 | - 2 tablespoons water | 2 | tbsp | water | 1.00 | regex | Y | |
| 11 | - 500g chicken | 500 | g | chicken | 1.00 | regex | Y | |
| 12 | - 1 tablespoon chilli powder | 1 | tbsp | chilli powder | 1.00 | regex | Y | |
| 13 | - 1 tsp rice vinegar | 1 | tsp | rice vinegar | 1.00 | regex | Y | |
| 14 | - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1.00 | regex | Y | |
| 15 | - 4 chopped spring onions | 4 | — | chopped spring onions | 0.92 | regex | Y | |
| 16 | - 6 cloves garlic | 6 | clove | garlic | 1.00 | regex | Y | |
| 17 | - 220g water chestnuts | 220 | g | water chestnuts | 1.00 | regex | Y | |
| 18 | - 100g peanuts | 100 | g | peanuts | 1.00 | regex | Y | |

---

## clean-10-split-pea-soup

**Category**: clean | **Lines**: 23 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Split Pea Soup | title | 0.70 | Y | |
| 2 | Servings: 8 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 150 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 1kg ham | ingredient | 0.60 | Y | |
| 7 | - 200g peas, soaked overnight | ingredient | 0.60 | Y | |
| 8 | - 2 chopped onions | ingredient | 0.60 | Y | |
| 9 | - 2 chopped carrots | ingredient | 0.60 | Y | |
| 10 | - 2 bay leaves | ingredient | 0.60 | Y | |
| 11 | - 1 chopped celery stalk | ingredient | 0.60 | Y | |
| 12 | - 300g frozen peas | ingredient | 0.60 | Y | |
| 13 | - Bread to serve | ingredient | 0.40 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Put the gammon in a very large pan with 2 litres water and bring to the boil. | instruction | 0.30 | Y | |
| 16 | 2. Put everything except the frozen peas into the pan and bring to the boil. Red | instruction | 0.30 | Y | |
| 17 | 3. When the ham is tender enough to shred, lift it out, peel off and discard the | instruction | 0.30 | Y | |
| 18 | 4. Remove bay from the soup and stir in the frozen peas. Simmer for 1 min, then  | instruction | 0.70 | Y | |
| 19 | 5. Mix the hot soup with most of the ham. Serve in bowls with remaining ham scat | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 1kg ham | 1 | kg | ham | 1.00 | regex | Y | |
| 7 | - 200g peas, soaked overnight | 200 | g | peas, soaked overnight | 1.00 | regex | Y | |
| 8 | - 2 chopped onions | 2 | — | chopped onions | 0.92 | regex | Y | |
| 9 | - 2 chopped carrots | 2 | — | chopped carrots | 0.92 | regex | Y | |
| 10 | - 2 bay leaves | 2 | — | bay leaves | 0.92 | regex | Y | |
| 11 | - 1 chopped celery stalk | 1 | — | chopped celery stalk | 0.92 | regex | Y | |
| 12 | - 300g frozen peas | 300 | g | frozen peas | 1.00 | regex | Y | |
| 13 | - Bread to serve | — | — | bread | 1.00 | ml | Y | |

---

## no-headers-01-honey-teriyaki-salmon

**Category**: no-headers | **Lines**: 13 | **Ingredients found**: 5

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Honey Teriyaki Salmon | title | 0.70 | Y | |
| 2 | 1 lb salmon | ingredient | 0.95 | Y | |
| 3 | 1 tablespoon olive oil | ingredient | 0.95 | Y | |
| 4 | 2 tablespoons soy sauce | ingredient | 0.95 | Y | |
| 5 | 2 tablespoons sake | ingredient | 0.95 | Y | |
| 6 | 4 tablespoons sesame seeds | ingredient | 0.95 | Y | |
| 7 | Mix all the ingredients in the glaze together. | instruction | 0.40 | Y | |
| 8 | Heat up a skillet on medium-low heat. | instruction | 0.40 | Y | |
| 9 | Pan-fry the salmon on both sides until cooked through. | unknown | 0.10 | Y | |
| 10 | Garnish with sesame seeds and serve immediately. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1 lb salmon | 1 | lb | salmon | 1.00 | regex | Y | |
| 3 | 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 4 | 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 1.00 | regex | Y | |
| 5 | 2 tablespoons sake | 2 | tbsp | sake | 1.00 | regex | Y | |
| 6 | 4 tablespoons sesame seeds | 4 | tbsp | sesame seeds | 1.00 | regex | Y | |

---

## no-headers-02-chicken-karaage

**Category**: no-headers | **Lines**: 18 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Karaage | title | 0.70 | Y | |
| 2 | 450 grams boneless skin-on chicken | ingredient | 0.95 | Y | |
| 3 | 1 tablespoon ginger | ingredient | 0.95 | Y | |
| 4 | 1 clove garlic | ingredient | 0.95 | Y | |
| 5 | 2 tablespoons soy sauce | ingredient | 0.95 | Y | |
| 6 | 1 tablespoon sake | ingredient | 0.95 | Y | |
| 7 | 2 teaspoons granulated sugar | ingredient | 0.95 | Y | |
| 8 | 1/3 cup potato starch | ingredient | 0.95 | Y | |
| 9 | 1/3 cup vegetable oil | ingredient | 0.95 | Y | |
| 10 | 1/3 cup lemon wedges | ingredient | 0.95 | Y | |
| 11 | Add the ginger, garlic, soy sauce, sake and sugar to a bowl and whisk to combine | instruction | 0.70 | Y | |
| 12 | Add 1 inch of vegetable oil to a heavy bottomed pot and heat until the oil reach | instruction | 0.75 | Y | |
| 13 | Add a handful of chicken to the potato starch and toss to coat each piece evenly | instruction | 0.60 | Y | |
| 14 | Fry the karaage in batches until the exterior is a medium brown and the chicken  | instruction | 0.60 | Y | |
| 15 | Serve with lemon wedges. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 450 grams boneless skin-on chicken | 450 | g | boneless skin-on chicken | 1.00 | regex | Y | |
| 3 | 1 tablespoon ginger | 1 | tbsp | ginger | 1.00 | regex | Y | |
| 4 | 1 clove garlic | 1 | clove | garlic | 1.00 | regex | Y | |
| 5 | 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 1.00 | regex | Y | |
| 6 | 1 tablespoon sake | 1 | tbsp | sake | 1.00 | regex | Y | |
| 7 | 2 teaspoons granulated sugar | 2 | tsp | granulated sugar | 1.00 | regex | Y | |
| 8 | 1/3 cup potato starch | 0.33 | cup | potato starch | 1.00 | regex | Y | |
| 9 | 1/3 cup vegetable oil | 0.33 | cup | vegetable oil | 1.00 | regex | Y | |
| 10 | 1/3 cup lemon wedges | 0.33 | cup | lemon wedges | 1.00 | regex | Y | |

---

## no-headers-03-beef-pho

**Category**: no-headers | **Lines**: 24 | **Ingredients found**: 15

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Pho | title | 0.70 | Y | |
| 2 | 1 L beef stock | ingredient | 0.95 | Y | |
| 3 | 1 large onion | ingredient | 0.60 | Y | |
| 4 | 1 large chopped ginger | ingredient | 0.60 | Y | |
| 5 | 1 cinnamon stick | ingredient | 0.95 | Y | |
| 6 | 2 star anise | ingredient | 0.60 | Y | |
| 7 | 1 tsp coriander seeds | ingredient | 0.95 | Y | |
| 8 | 1/2 teaspoon cloves | ingredient | 0.95 | Y | |
| 9 | 225g sirloin steak | ingredient | 0.60 | Y | |
| 10 | 1 tsp palm sugar | ingredient | 0.95 | Y | |
| 11 | 1 tablespoon fish sauce | ingredient | 0.95 | Y | |
| 12 | 1 1/2 tbsp soy sauce | ingredient | 0.95 | Y | |
| 13 | 200g rice noodles | ingredient | 0.60 | Y | |
| 14 | 2 sliced spring onions | ingredient | 0.60 | Y | |
| 15 | 1 small birds-eye chilli | ingredient | 0.60 | Y | |
| 16 | Handful of basil | unknown | 0.10 | Y | |
| 17 | Handful of coriander | unknown | 0.10 | Y | |
| 18 | 1 lime | ingredient | 0.60 | Y | |
| 19 | Tip the beef stock along with 500ml of water into a large saucepan. Sit the onio | instruction | 0.30 | Y | |
| 20 | Meanwhile, cut the fat from the steak and wrap in cling film, then put into the  | instruction | 0.30 | Y | |
| 21 | Taste the beef stock and use the palm sugar, fish sauce and soy to season. Cook  | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1 L beef stock | 1 | l | beef stock | 1.00 | regex | Y | |
| 3 | 1 large onion | 1 | — | large onion | 0.92 | regex | Y | |
| 4 | 1 large chopped ginger | 1 | — | large chopped ginger | 0.92 | regex | Y | |
| 5 | 1 cinnamon stick | 1 | — | cinnamon stick | 0.92 | regex | Y | |
| 6 | 2 star anise | 2 | — | star anise | 0.92 | regex | Y | |
| 7 | 1 tsp coriander seeds | 1 | tsp | coriander seeds | 1.00 | regex | Y | |
| 8 | 1/2 teaspoon cloves | 0.5 | tsp | cloves | 1.00 | regex | Y | |
| 9 | 225g sirloin steak | 225 | g | sirloin steak | 1.00 | regex | Y | |
| 10 | 1 tsp palm sugar | 1 | tsp | palm sugar | 1.00 | regex | Y | |
| 11 | 1 tablespoon fish sauce | 1 | tbsp | fish sauce | 1.00 | regex | Y | |
| 12 | 1 1/2 tbsp soy sauce | 1.5 | tbsp | soy sauce | 1.00 | regex | Y | |
| 13 | 200g rice noodles | 200 | g | rice noodles | 1.00 | regex | Y | |
| 14 | 2 sliced spring onions | 2 | — | sliced spring onions | 0.92 | regex | Y | |
| 15 | 1 small birds-eye chilli | 1 | — | small birds-eye chilli | 0.92 | regex | Y | |
| 18 | 1 lime | 1 | — | lim e | 0.92 | regex | Y | |

---

## no-headers-04-chicken-marengo

**Category**: no-headers | **Lines**: 15 | **Ingredients found**: 6

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Marengo | title | 0.70 | Y | |
| 2 | 1 tablespoon olive oil | ingredient | 0.95 | Y | |
| 3 | 300g mushrooms | ingredient | 0.60 | Y | |
| 4 | 4 chicken legs | ingredient | 0.60 | Y | |
| 5 | 500g passata | ingredient | 0.60 | Y | |
| 6 | 1 chicken stock cube | ingredient | 0.60 | Y | |
| 7 | 100g black olives | ingredient | 0.60 | Y | |
| 8 | Chopped parsley | unknown | 0.10 | Y | |
| 9 | Heat the oil in a large flameproof casserole dish and stir-fry the mushrooms unt | instruction | 0.60 | Y | |
| 10 | Pour in the passata, crumble in the stock cube and stir in the olives. Season wi | instruction | 0.60 | Y | |
| 11 | Cover and simmer for 40 mins until the chicken is tender. | instruction | 0.50 | Y | |
| 12 | Sprinkle with parsley and serve with pasta and a salad, or mash and green veg. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 3 | 300g mushrooms | 300 | g | mushrooms | 1.00 | regex | Y | |
| 4 | 4 chicken legs | 4 | — | chicken legs | 0.92 | regex | Y | |
| 5 | 500g passata | 500 | g | passata | 1.00 | regex | Y | |
| 6 | 1 chicken stock cube | 1 | — | chicken stock cube | 0.92 | regex | Y | |
| 7 | 100g black olives | 100 | g | black olives | 1.00 | regex | Y | |

---

## no-headers-05-rock-cakes

**Category**: no-headers | **Lines**: 18 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Rock Cakes | title | 0.70 | Y | |
| 2 | 225g self-raising flour | ingredient | 0.60 | Y | |
| 3 | 75g caster sugar | ingredient | 0.60 | Y | |
| 4 | 1 tsp baking powder | ingredient | 0.95 | Y | |
| 5 | 125g butter | ingredient | 0.60 | Y | |
| 6 | 150g dried fruit | ingredient | 0.60 | Y | |
| 7 | 1 egg | ingredient | 0.60 | Y | |
| 8 | 1 tablespoon milk | ingredient | 0.95 | Y | |
| 9 | 2 tsp vanilla extract | ingredient | 0.95 | Y | |
| 10 | Preheat oven to 180C/350F/Gas 4 and line a baking tray with baking parchment. | instruction | 0.60 | Y | |
| 11 | Mix the flour, sugar and baking powder in a bowl and rub in the cubed butter unt | instruction | 0.60 | Y | |
| 12 | In a clean bowl, beat the egg and milk together with the vanilla extract. | unknown | 0.10 | Y | |
| 13 | Add the egg mixture to the dry ingredients and stir with a spoon until the mixtu | instruction | 0.60 | Y | |
| 14 | Place golfball-sized spoons of the mixture onto the prepared baking tray. | instruction | 0.60 | Y | |
| 15 | Bake for 15-20 minutes, until golden-brown. Remove from the oven, allow to cool  | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 225g self-raising flour | 225 | g | self-raising flour | 1.00 | regex | Y | |
| 3 | 75g caster sugar | 75 | g | caster sugar | 1.00 | regex | Y | |
| 4 | 1 tsp baking powder | 1 | tsp | baking powder | 1.00 | regex | Y | |
| 5 | 125g butter | 125 | g | butter | 1.00 | regex | Y | |
| 6 | 150g dried fruit | 150 | g | dried fruit | 1.00 | regex | Y | |
| 7 | 1 egg | 1 | — | eg g | 0.92 | regex | Y | |
| 8 | 1 tablespoon milk | 1 | tbsp | milk | 1.00 | regex | Y | |
| 9 | 2 tsp vanilla extract | 2 | tsp | vanilla extract | 1.00 | regex | Y | |

---

## no-headers-06-egg-drop-soup

**Category**: no-headers | **Lines**: 20 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Egg Drop Soup | title | 0.70 | Y | |
| 2 | 3 cups chicken stock | ingredient | 0.95 | Y | |
| 3 | 1/4 tsp salt | ingredient | 0.95 | Y | |
| 4 | 1/4 tsp sugar | ingredient | 0.95 | Y | |
| 5 | Pinch of pepper | ingredient | 0.45 | Y | |
| 6 | 1 tsp sesame seed oil | ingredient | 0.95 | Y | |
| 7 | 1/3 cup peas | ingredient | 0.95 | Y | |
| 8 | 1/3 cup mushrooms | ingredient | 0.95 | Y | |
| 9 | 1 tablespoon cornstarch | ingredient | 0.95 | Y | |
| 10 | 2 tablespoons water | ingredient | 0.95 | Y | |
| 11 | 1/4 cup spring onions | ingredient | 0.95 | Y | |
| 12 | In a wok add chicken broth and wait for it to boil. | unknown | 0.10 | Y | |
| 13 | Next add salt, sugar, white pepper, sesame seed oil. | unknown | 0.10 | Y | |
| 14 | When the chicken broth is boiling add the vegetables to the wok. | unknown | 0.10 | Y | |
| 15 | To thicken the sauce, whisk together 1 tablespoon of cornstarch and 2 tablespoon | unknown | 0.10 | Y | |
| 16 | Next add 1 egg slightly beaten with a knife or fork and add it to the soup slowl | instruction | 0.30 | Y | |
| 17 | Serve the soup in a bowl and add the green onions on top. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 3 cups chicken stock | 3 | cup | chicken stock | 1.00 | regex | Y | |
| 3 | 1/4 tsp salt | 0.25 | tsp | salt | 1.00 | regex | Y | |
| 4 | 1/4 tsp sugar | 0.25 | tsp | sugar | 1.00 | regex | Y | |
| 5 | Pinch of pepper | 0.12 | — | pepper | 0.95 | regex | Y | |
| 6 | 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1.00 | regex | Y | |
| 7 | 1/3 cup peas | 0.33 | cup | peas | 1.00 | regex | Y | |
| 8 | 1/3 cup mushrooms | 0.33 | cup | mushrooms | 1.00 | regex | Y | |
| 9 | 1 tablespoon cornstarch | 1 | tbsp | cornstarch | 1.00 | regex | Y | |
| 10 | 2 tablespoons water | 2 | tbsp | water | 1.00 | regex | Y | |
| 11 | 1/4 cup spring onions | 0.25 | cup | spring onions | 1.00 | regex | Y | |

---

## no-headers-07-salmon-avocado-salad

**Category**: no-headers | **Lines**: 16 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Salmon Avocado Salad | title | 0.70 | Y | |
| 2 | 2 salmon fillets | ingredient | 0.60 | Y | |
| 3 | 1 large avocado, sliced | ingredient | 0.60 | Y | |
| 4 | 100g mixed salad leaves | ingredient | 0.60 | Y | |
| 5 | 1/2 cucumber, sliced | ingredient | 0.60 | Y | |
| 6 | 10 cherry tomatoes, halved | ingredient | 0.60 | Y | |
| 7 | 2 tablespoons extra virgin olive oil | ingredient | 0.95 | Y | |
| 8 | 1 tablespoon lemon juice | ingredient | 0.95 | Y | |
| 9 | Salt and pepper to taste | ingredient | 0.40 | Y | |
| 10 | Season the salmon fillets with salt and pepper. Pan-fry in a hot skillet with a  | instruction | 0.70 | Y | |
| 11 | Arrange the mixed salad leaves on two plates. Top with avocado slices, cucumber  | instruction | 0.60 | Y | |
| 12 | Scatter the flaked salmon over the salad. | unknown | 0.10 | Y | |
| 13 | Drizzle with olive oil and lemon juice. Season with salt and pepper and serve im | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 salmon fillets | 2 | — | salmon fillets | 0.92 | regex | Y | |
| 3 | 1 large avocado, sliced | 1 | — | large avocado, sliced | 0.92 | regex | Y | |
| 4 | 100g mixed salad leaves | 100 | g | mixed salad leaves | 1.00 | regex | Y | |
| 5 | 1/2 cucumber, sliced | 0.5 | — | cucumber , sliced | 0.92 | regex | Y | |
| 6 | 10 cherry tomatoes, halved | 10 | — | cherry tomatoes, halved | 0.92 | regex | Y | |
| 7 | 2 tablespoons extra virgin olive oil | 2 | tbsp | extra virgin olive oil | 1.00 | regex | Y | |
| 8 | 1 tablespoon lemon juice | 1 | tbsp | lemon juice | 1.00 | regex | Y | |
| 9 | Salt and pepper to taste | — | — | salt and pepper | 0.96 | ml | Y | |

---

## no-headers-08-sticky-chicken

**Category**: no-headers | **Lines**: 12 | **Ingredients found**: 6

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Sticky Chicken | title | 0.70 | Y | |
| 2 | 8 chicken drumsticks | ingredient | 0.60 | Y | |
| 3 | 2 tablespoons soy sauce | ingredient | 0.95 | Y | |
| 4 | 1 tablespoon honey | ingredient | 0.95 | Y | |
| 5 | 1 tablespoon olive oil | ingredient | 0.95 | Y | |
| 6 | 1 teaspoon tomato puree | ingredient | 0.95 | Y | |
| 7 | 1 tablespoon Dijon mustard | ingredient | 0.95 | Y | |
| 8 | Make 3 slashes on each of the drumsticks. Mix together the soy, honey, oil, toma | metadata | 1.00 | Y | |
| 9 | Tip the chicken into a shallow roasting tray and cook for 35 mins, turning occas | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 8 chicken drumsticks | 8 | — | chicken drumsticks | 0.92 | regex | Y | |
| 3 | 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 1.00 | regex | Y | |
| 4 | 1 tablespoon honey | 1 | tbsp | honey | 1.00 | regex | Y | |
| 5 | 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 6 | 1 teaspoon tomato puree | 1 | tsp | tomato puree | 1.00 | regex | Y | |
| 7 | 1 tablespoon Dijon mustard | 1 | tbsp | Dijon mustard | 1.00 | regex | Y | |

---

## no-headers-09-corned-beef-hash

**Category**: no-headers | **Lines**: 16 | **Ingredients found**: 6

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Corned Beef Hash | title | 0.70 | Y | |
| 2 | 3 tablespoons unsalted butter | ingredient | 0.95 | Y | |
| 3 | 1 medium chopped onion | ingredient | 0.60 | Y | |
| 4 | 3 cups corned beef | ingredient | 0.95 | Y | |
| 5 | 3 chopped potatoes | ingredient | 0.60 | Y | |
| 6 | Dash of kosher salt | ingredient | 0.45 | Y | |
| 7 | Dash of black pepper | ingredient | 0.45 | Y | |
| 8 | Chopped fresh parsley | unknown | 0.10 | Y | |
| 9 | Heat butter in a large skillet on medium heat. Add the onion and cook a few minu | instruction | 0.60 | Y | |
| 10 | Mix in the chopped corned beef and potatoes. Spread out evenly over the pan. Inc | instruction | 0.60 | Y | |
| 11 | Do not stir, but let them brown. Use a metal spatula to peek underneath and see  | unknown | 0.10 | Y | |
| 12 | Continue to cook until the potatoes and the corned beef are nicely browned. | unknown | 0.10 | Y | |
| 13 | Remove from heat, stir in chopped parsley. Add plenty of freshly ground black pe | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 3 tablespoons unsalted butter | 3 | tbsp | unsalted butter | 1.00 | regex | Y | |
| 3 | 1 medium chopped onion | 1 | — | medium chopped onion | 0.92 | regex | Y | |
| 4 | 3 cups corned beef | 3 | cup | corned beef | 1.00 | regex | Y | |
| 5 | 3 chopped potatoes | 3 | — | chopped potatoes | 0.92 | regex | Y | |
| 6 | Dash of kosher salt | 0.12 | — | kosher salt | 0.95 | regex | Y | |
| 7 | Dash of black pepper | 0.12 | — | black pepper | 0.95 | regex | Y | |

---

## no-headers-10-thai-beef-stir-fry

**Category**: no-headers | **Lines**: 15 | **Ingredients found**: 4

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Thai Beef Stir-Fry | title | 0.70 | Y | |
| 2 | 2 tablespoons vegetable oil | ingredient | 0.95 | Y | |
| 3 | 400g beef strips | ingredient | 0.60 | Y | |
| 4 | 1 sliced red chilli | ingredient | 0.60 | Y | |
| 5 | 2 tablespoons oyster sauce | ingredient | 0.95 | Y | |
| 6 | Handful of basil leaves | unknown | 0.10 | Y | |
| 7 | Heat a wok or large frying pan until smoking hot. | instruction | 0.40 | Y | |
| 8 | Pour in the oil and swirl around the pan, then tip in the beef strips and chilli | instruction | 0.60 | Y | |
| 9 | Cook, stirring all the time, until the meat is lightly browned, about 3 mins. | instruction | 0.30 | Y | |
| 10 | Pour over the oyster sauce. | instruction | 0.40 | Y | |
| 11 | Cook until heated through and the sauce coats the meat. | instruction | 0.40 | Y | |
| 12 | Stir in the basil leaves and serve with plain rice. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 2 tablespoons vegetable oil | 2 | tbsp | vegetable oil | 1.00 | regex | Y | |
| 3 | 400g beef strips | 400 | g | beef strips | 1.00 | regex | Y | |
| 4 | 1 sliced red chilli | 1 | — | sliced red chilli | 0.92 | regex | Y | |
| 5 | 2 tablespoons oyster sauce | 2 | tbsp | oyster sauce | 1.00 | regex | Y | |

---

## unusual-metadata-01-beef-empanadas

**Category**: unusual-metadata | **Lines**: 35 | **Ingredients found**: 17

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Empanadas | title | 0.70 | Y | |
| 2 | Yield: 2 dozen | metadata | 0.60 | Y | |
| 3 | Active time: 30 minutes | metadata | 0.60 | Y | |
| 4 | Total: 1 hour 30 minutes | metadata | 0.70 | Y | |
| 5 | Difficulty: Medium | metadata | 0.60 | Y | |
| 6 | Oven: 200C / 400F | metadata | 0.60 | Y | |
| 7 | Ingredients: | sectionHeader | 0.90 | Y | |
| 8 | - 60g lard | ingredient | 0.60 | Y | |
| 9 | - 340g warm water | ingredient | 0.60 | Y | |
| 10 | - 1 tsp salt | ingredient | 0.95 | Y | |
| 11 | - 600g all purpose flour | ingredient | 0.60 | Y | |
| 12 | - 3 tomatoes | ingredient | 0.60 | Y | |
| 13 | - 1 clove garlic | ingredient | 0.95 | Y | |
| 14 | - 1 large red onion | ingredient | 0.60 | Y | |
| 15 | - Bunch of spring onions | ingredient | 0.45 | Y | |
| 16 | - 750g sirloin steak | ingredient | 0.60 | Y | |
| 17 | - 1 tablespoon dried oregano | ingredient | 0.95 | Y | |
| 18 | - 1 tsp paprika | ingredient | 0.95 | Y | |
| 19 | - 1 tsp red pepper flakes | ingredient | 0.95 | Y | |
| 20 | - 1 tsp parsley | ingredient | 0.95 | Y | |
| 21 | - Salt to taste | ingredient | 0.40 | Y | |
| 22 | - Pepper to taste | ingredient | 0.40 | Y | |
| 23 | - 3 eggs | ingredient | 0.60 | Y | |
| 24 | - Splash of egg wash | ingredient | 0.30 | Y | |
| 25 | - Drizzle of chimichurri sauce | instruction | 0.40 | Y | |
| 26 | Instructions: | sectionHeader | 0.90 | Y | |
| 27 | 1. For the dough, place lard, warm water and salt in a large kneading bowl and s | sectionHeader | 0.90 | Y | |
| 28 | 2. For the filling, blanch tomatoes, peel and cube. Saute garlic and onions unti | sectionHeader | 0.90 | Y | |
| 29 | 3. Roll out dough, cut circles 12-15cm in diameter. Place filling in each, fold  | instruction | 0.60 | Y | |
| 30 | 4. Brush empanadas with egg wash and bake for about 25 min or until golden. | instruction | 0.70 | Y | |
| 31 | 5. Serve warm with chimichurri sauce. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 8 | - 60g lard | 60 | g | lard | 1.00 | regex | Y | |
| 9 | - 340g warm water | 340 | g | warm water | 1.00 | regex | Y | |
| 10 | - 1 tsp salt | 1 | tsp | salt | 1.00 | regex | Y | |
| 11 | - 600g all purpose flour | 600 | g | all purpose flour | 1.00 | regex | Y | |
| 12 | - 3 tomatoes | 3 | — | tomatoe s | 0.92 | regex | Y | |
| 13 | - 1 clove garlic | 1 | clove | garlic | 1.00 | regex | Y | |
| 14 | - 1 large red onion | 1 | — | large red onion | 0.92 | regex | Y | |
| 15 | - Bunch of spring onions | 1 | — | spring onions | 0.95 | regex | Y | |
| 16 | - 750g sirloin steak | 750 | g | sirloin steak | 1.00 | regex | Y | |
| 17 | - 1 tablespoon dried oregano | 1 | tbsp | dried oregano | 1.00 | regex | Y | |
| 18 | - 1 tsp paprika | 1 | tsp | paprika | 1.00 | regex | Y | |
| 19 | - 1 tsp red pepper flakes | 1 | tsp | red pepper flakes | 1.00 | regex | Y | |
| 20 | - 1 tsp parsley | 1 | tsp | parsley | 1.00 | regex | Y | |
| 21 | - Salt to taste | — | — | salt | 1.00 | ml | Y | |
| 22 | - Pepper to taste | — | — | pepper | 1.00 | ml | Y | |
| 23 | - 3 eggs | 3 | — | egg s | 0.92 | regex | Y | |
| 24 | - Splash of egg wash | 0.5 | — | egg wash | 0.95 | regex | Y | |

---

## unusual-metadata-02-chicken-basquaise

**Category**: unusual-metadata | **Lines**: 37 | **Ingredients found**: 17

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Basquaise | title | 0.70 | Y | |
| 2 | Serves 4-6 | metadata | 0.70 | Y | |
| 3 | Hands-on: 30 minutes | unknown | 0.10 | Y | |
| 4 | Total: 1 hour 20 minutes | metadata | 0.70 | Y | |
| 5 | Course: Main dish | metadata | 0.60 | Y | |
| 6 | Cuisine: French Basque | metadata | 0.60 | Y | |
| 7 | Ingredients: | sectionHeader | 0.90 | Y | |
| 8 | - 1.5kg chicken | instruction | 0.50 | Y | |
| 9 | - 25g butter | ingredient | 0.60 | Y | |
| 10 | - 6 tablespoons olive oil | ingredient | 0.95 | Y | |
| 11 | - 2 sliced red onions | ingredient | 0.60 | Y | |
| 12 | - 3 large red peppers | ingredient | 0.60 | Y | |
| 13 | - 130g chorizo | ingredient | 0.60 | Y | |
| 14 | - 8 sun-dried tomatoes | ingredient | 0.60 | Y | |
| 15 | - 6 cloves sliced garlic | ingredient | 0.95 | Y | |
| 16 | - 300g basmati rice | ingredient | 0.60 | Y | |
| 17 | - Drizzle of tomato puree | instruction | 0.40 | Y | |
| 18 | - 1/2 tsp paprika | ingredient | 0.95 | Y | |
| 19 | - 4 bay leaves | ingredient | 0.60 | Y | |
| 20 | - Handful of thyme | ingredient | 0.30 | Y | |
| 21 | - 350ml chicken stock | ingredient | 0.60 | Y | |
| 22 | - 180g dry white wine | ingredient | 0.60 | Y | |
| 23 | - 2 lemons | ingredient | 0.60 | Y | |
| 24 | - 100g black olives | ingredient | 0.60 | Y | |
| 25 | - Salt to serve | ingredient | 0.40 | Y | |
| 26 | - Pepper to serve | ingredient | 0.40 | Y | |
| 27 | Instructions: | sectionHeader | 0.90 | Y | |
| 28 | 1. Preheat the oven to 180C/Gas mark 4. Brown the chicken pieces in batches in b | instruction | 0.60 | Y | |
| 29 | 2. Fry the onions for 10 minutes until softened. Add the peppers and cook for an | instruction | 0.70 | Y | |
| 30 | 3. Add the chorizo, sun-dried tomatoes and garlic and cook for 2-3 minutes. | instruction | 0.70 | Y | |
| 31 | 4. Add the rice, stirring to coat in oil. Stir in the tomato paste, paprika, bay | instruction | 0.60 | Y | |
| 32 | 5. Press the rice down, place the chicken on top. Add the lemon wedges and olive | instruction | 0.60 | Y | |
| 33 | 6. Cover and cook in the oven for 50 minutes until rice is cooked and chicken ju | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 9 | - 25g butter | 25 | g | butter | 1.00 | regex | Y | |
| 10 | - 6 tablespoons olive oil | 6 | tbsp | olive oil | 1.00 | regex | Y | |
| 11 | - 2 sliced red onions | 2 | — | sliced red onions | 0.92 | regex | Y | |
| 12 | - 3 large red peppers | 3 | — | large red peppers | 0.92 | regex | Y | |
| 13 | - 130g chorizo | 130 | g | chorizo | 1.00 | regex | Y | |
| 14 | - 8 sun-dried tomatoes | 8 | — | sun -dried tomatoes | 0.92 | regex | Y | |
| 15 | - 6 cloves sliced garlic | 6 | clove | sliced garlic | 1.00 | regex | Y | |
| 16 | - 300g basmati rice | 300 | g | basmati rice | 1.00 | regex | Y | |
| 18 | - 1/2 tsp paprika | 0.5 | tsp | paprika | 1.00 | regex | Y | |
| 19 | - 4 bay leaves | 4 | — | bay leaves | 0.92 | regex | Y | |
| 20 | - Handful of thyme | 0.5 | — | thyme | 0.95 | regex | Y | |
| 21 | - 350ml chicken stock | 350 | ml | chicken stock | 1.00 | regex | Y | |
| 22 | - 180g dry white wine | 180 | g | dry white wine | 1.00 | regex | Y | |
| 23 | - 2 lemons | 2 | — | lemon s | 0.92 | regex | Y | |
| 24 | - 100g black olives | 100 | g | black olives | 1.00 | regex | Y | |
| 25 | - Salt to serve | — | — | salt | 1.00 | ml | Y | |
| 26 | - Pepper to serve | — | — | pepper | 1.00 | ml | Y | |

---

## unusual-metadata-03-apple-cake

**Category**: unusual-metadata | **Lines**: 31 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Apple Cake | title | 0.70 | Y | |
| 2 | Makes about 8 servings | metadata | 0.60 | Y | |
| 3 | Hands-on: 20m | unknown | 0.10 | Y | |
| 4 | Bake time: 45-50 minutes | instruction | 0.50 | Y | |
| 5 | Oven: 350F / 180C | metadata | 0.60 | Y | |
| 6 | Difficulty: Easy | metadata | 0.60 | Y | |
| 7 | Course: Dessert | metadata | 0.60 | Y | |
| 8 | Ingredients: | sectionHeader | 0.90 | Y | |
| 9 | - 4 eggs | ingredient | 0.60 | Y | |
| 10 | - 200g sugar | ingredient | 0.60 | Y | |
| 11 | - 200g self-raising flour | ingredient | 0.60 | Y | |
| 12 | - 200g melted butter | ingredient | 0.60 | Y | |
| 13 | - 1 tsp vanilla extract | ingredient | 0.95 | Y | |
| 14 | - 1 tsp ground cinnamon | ingredient | 0.95 | Y | |
| 15 | - 3 apples | ingredient | 0.60 | Y | |
| 16 | - Pinch of salt | ingredient | 0.45 | Y | |
| 17 | - Sprinkling of powdered sugar | ingredient | 0.30 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Preheat the oven to 180C (350F). Grease a cake pan and line it with baking pa | instruction | 0.60 | Y | |
| 20 | 2. Break the four eggs with the sugar and beat until they have tripled in volume | instruction | 0.30 | Y | |
| 21 | 3. Sift the flour and fold into the egg mixture, preserving as much air as possi | instruction | 0.30 | Y | |
| 22 | 4. Add cinnamon, pinch of salt and vanilla extract. | ingredient | 0.45 | Y | |
| 23 | 5. Add the diced apple to the batter and gently fold them in so evenly distribut | instruction | 0.60 | Y | |
| 24 | 6. Pour the batter into the prepared cake pan and smooth the top. | instruction | 0.60 | Y | |
| 25 | 7. Place apple slices on top and press lightly. Sprinkle with almond shavings if | instruction | 0.60 | Y | |
| 26 | 8. Bake for about 45-50 minutes, or until a wooden skewer comes out clean. | instruction | 0.70 | Y | |
| 27 | 9. Cool in the mold, then remove and cool completely. Sprinkle with powdered sug | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 9 | - 4 eggs | 4 | — | egg s | 0.92 | regex | Y | |
| 10 | - 200g sugar | 200 | g | sugar | 1.00 | regex | Y | |
| 11 | - 200g self-raising flour | 200 | g | self-raising flour | 1.00 | regex | Y | |
| 12 | - 200g melted butter | 200 | g | melted butter | 1.00 | regex | Y | |
| 13 | - 1 tsp vanilla extract | 1 | tsp | vanilla extract | 1.00 | regex | Y | |
| 14 | - 1 tsp ground cinnamon | 1 | tsp | ground cinnamon | 1.00 | regex | Y | |
| 15 | - 3 apples | 3 | — | apple s | 0.92 | regex | Y | |
| 16 | - Pinch of salt | 0.12 | — | salt | 0.95 | regex | Y | |
| 17 | - Sprinkling of powdered sugar | 0.12 | — | powdered sugar | 0.95 | regex | Y | |
| 22 | 4. Add cinnamon, pinch of salt and vanilla extract. | 4 | pinch | add cinnamon | 0.71 | ml | Y | |

---

## unusual-metadata-04-thai-pumpkin-soup

**Category**: unusual-metadata | **Lines**: 30 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Thai Pumpkin Soup | title | 0.70 | Y | |
| 2 | Serves 6 | metadata | 0.70 | Y | |
| 3 | Active time: 15m | metadata | 0.60 | Y | |
| 4 | Roasting: 30 minutes | unknown | 0.10 | Y | |
| 5 | Simmering: 15 minutes | unknown | 0.10 | Y | |
| 6 | Total: 1 hour | metadata | 0.70 | Y | |
| 7 | Cuisine: Thai | metadata | 0.60 | Y | |
| 8 | Diet: Vegan | metadata | 0.60 | Y | |
| 9 | Ingredients: | sectionHeader | 0.90 | Y | |
| 10 | - 1.5kg pumpkin | instruction | 0.50 | Y | |
| 11 | - 4 tsp sunflower oil | ingredient | 0.95 | Y | |
| 12 | - 1 sliced onion | ingredient | 0.60 | Y | |
| 13 | - 1 tbsp grated ginger | ingredient | 0.95 | Y | |
| 14 | - 1 stalk lemongrass | ingredient | 0.60 | Y | |
| 15 | - 4 tablespoons Thai red curry paste | ingredient | 0.95 | Y | |
| 16 | - 400ml coconut milk | ingredient | 0.60 | Y | |
| 17 | - 800ml vegetable stock | ingredient | 0.60 | Y | |
| 18 | - Lime juice to taste | ingredient | 0.30 | Y | |
| 19 | - Sugar to taste | ingredient | 0.40 | Y | |
| 20 | - Red chilli to serve | ingredient | 0.30 | Y | |
| 21 | Instructions: | sectionHeader | 0.90 | Y | |
| 22 | 1. Heat oven to 200C/180C fan/gas 6. Toss the pumpkin in a roasting tin with hal | instruction | 0.70 | Y | |
| 23 | 2. Put the remaining oil in a pan with the onion, ginger and lemongrass. Gently  | instruction | 0.30 | Y | |
| 24 | 3. Bring to a simmer, cook for 5 mins, then fish out the lemongrass. Cool for a  | instruction | 0.30 | Y | |
| 25 | 4. Return to the pan to heat through, seasoning with salt, pepper, lime juice an | instruction | 0.30 | Y | |
| 26 | 5. Serve drizzled with the remaining coconut milk and scattered with chilli. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 11 | - 4 tsp sunflower oil | 4 | tsp | sunflower oil | 1.00 | regex | Y | |
| 12 | - 1 sliced onion | 1 | — | sliced onion | 0.92 | regex | Y | |
| 13 | - 1 tbsp grated ginger | 1 | tbsp | grated ginger | 1.00 | regex | Y | |
| 14 | - 1 stalk lemongrass | 1 | — | stalk lemongrass | 0.92 | regex | Y | |
| 15 | - 4 tablespoons Thai red curry paste | 4 | tbsp | Thai red curry paste | 1.00 | regex | Y | |
| 16 | - 400ml coconut milk | 400 | ml | coconut milk | 1.00 | regex | Y | |
| 17 | - 800ml vegetable stock | 800 | ml | vegetable stock | 1.00 | regex | Y | |
| 18 | - Lime juice to taste | — | — | lime juice | 1.00 | ml | Y | |
| 19 | - Sugar to taste | — | — | sugar | 1.00 | ml | Y | |
| 20 | - Red chilli to serve | — | — | red chilli | 1.00 | ml | Y | |

---

## unusual-metadata-05-kentucky-fried-chicken

**Category**: unusual-metadata | **Lines**: 35 | **Ingredients found**: 17

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Kentucky Fried Chicken | title | 0.70 | Y | |
| 2 | Serves 4 | metadata | 0.70 | Y | |
| 3 | Difficulty: Hard | metadata | 0.60 | Y | |
| 4 | Active time: 20 minutes | metadata | 0.60 | Y | |
| 5 | Frying time: 12-14 minutes per batch | unknown | 0.10 | Y | |
| 6 | Oil temperature: 350F / 175C | metadata | 0.60 | Y | |
| 7 | Ingredients: | sectionHeader | 0.90 | Y | |
| 8 | - 1 whole chicken, cut up | ingredient | 0.60 | Y | |
| 9 | - 2 quarts neutral frying oil | ingredient | 0.95 | Y | |
| 10 | - 1 egg white | ingredient | 0.60 | Y | |
| 11 | - 1 1/2 cups flour | ingredient | 0.95 | Y | |
| 12 | - 1 tablespoon brown sugar | ingredient | 0.95 | Y | |
| 13 | - 1 tablespoon salt | ingredient | 0.95 | Y | |
| 14 | - 1 tablespoon paprika | ingredient | 0.95 | Y | |
| 15 | - 2 teaspoons onion salt | ingredient | 0.95 | Y | |
| 16 | - 1 teaspoon chili powder | ingredient | 0.95 | Y | |
| 17 | - 1 teaspoon black pepper | ingredient | 0.95 | Y | |
| 18 | - 1/2 teaspoon celery salt | ingredient | 0.95 | Y | |
| 19 | - 1/2 teaspoon sage | ingredient | 0.95 | Y | |
| 20 | - 1/2 teaspoon garlic powder | ingredient | 0.95 | Y | |
| 21 | - 1/2 teaspoon allspice | ingredient | 0.95 | Y | |
| 22 | - 1/2 teaspoon oregano | ingredient | 0.95 | Y | |
| 23 | - 1/2 teaspoon basil | ingredient | 0.95 | Y | |
| 24 | - 1/2 teaspoon marjoram | ingredient | 0.95 | Y | |
| 25 | Instructions: | sectionHeader | 0.90 | Y | |
| 26 | 1. Preheat fryer to 350F. Thoroughly mix together all the spice mix ingredients. | instruction | 0.60 | Y | |
| 27 | 2. Combine spice mix with flour, brown sugar and salt. | instruction | 0.40 | Y | |
| 28 | 3. Dip chicken pieces in egg white to lightly coat them, then transfer to flour  | instruction | 0.30 | Y | |
| 29 | 4. Let chicken pieces rest for 5 minutes so crust has a chance to dry a bit. | instruction | 0.70 | Y | |
| 30 | 5. Fry chicken in batches. Breasts and wings should take 12-14 minutes, and legs | instruction | 0.70 | Y | |
| 31 | 6. Let chicken drain on paper towels when it comes out of the fryer. Serve hot. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 8 | - 1 whole chicken, cut up | 1 | — | whole chicken, cut up | 0.92 | regex | Y | |
| 9 | - 2 quarts neutral frying oil | 2 | quart | neutral frying oil | 1.00 | regex | Y | |
| 10 | - 1 egg white | 1 | — | egg white | 0.92 | regex | Y | |
| 11 | - 1 1/2 cups flour | 1.5 | cup | flour | 1.00 | regex | Y | |
| 12 | - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1.00 | regex | Y | |
| 13 | - 1 tablespoon salt | 1 | tbsp | salt | 1.00 | regex | Y | |
| 14 | - 1 tablespoon paprika | 1 | tbsp | paprika | 1.00 | regex | Y | |
| 15 | - 2 teaspoons onion salt | 2 | tsp | onion salt | 1.00 | regex | Y | |
| 16 | - 1 teaspoon chili powder | 1 | tsp | chili powder | 1.00 | regex | Y | |
| 17 | - 1 teaspoon black pepper | 1 | tsp | black pepper | 1.00 | regex | Y | |
| 18 | - 1/2 teaspoon celery salt | 0.5 | tsp | celery salt | 1.00 | regex | Y | |
| 19 | - 1/2 teaspoon sage | 0.5 | tsp | sage | 1.00 | regex | Y | |
| 20 | - 1/2 teaspoon garlic powder | 0.5 | tsp | garlic powder | 1.00 | regex | Y | |
| 21 | - 1/2 teaspoon allspice | 0.5 | tsp | allspice | 1.00 | regex | Y | |
| 22 | - 1/2 teaspoon oregano | 0.5 | tsp | oregano | 1.00 | regex | Y | |
| 23 | - 1/2 teaspoon basil | 0.5 | tsp | basil | 1.00 | regex | Y | |
| 24 | - 1/2 teaspoon marjoram | 0.5 | tsp | marjoram | 1.00 | regex | Y | |

---

## unusual-metadata-06-beef-rendang

**Category**: unusual-metadata | **Lines**: 33 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Rendang | title | 0.70 | Y | |
| 2 | Cuisine: Malaysian | metadata | 0.60 | Y | |
| 3 | Course: Main dish | metadata | 0.60 | Y | |
| 4 | Serves 4 | metadata | 0.70 | Y | |
| 5 | Total: 2 hours 30 minutes | metadata | 0.70 | Y | |
| 6 | Active time: 20 minutes | metadata | 0.60 | Y | |
| 7 | Braising: 1.5-2 hours | unknown | 0.10 | Y | |
| 8 | Difficulty: Medium | metadata | 0.60 | Y | |
| 9 | Spice level: Hot | title | 0.30 | Y | |
| 10 | Ingredients: | sectionHeader | 0.90 | Y | |
| 11 | - 1 lb beef | ingredient | 0.95 | Y | |
| 12 | - 5 tablespoons vegetable oil | ingredient | 0.95 | Y | |
| 13 | - 1 cinnamon stick | ingredient | 0.95 | Y | |
| 14 | - 3 cloves | ingredient | 0.95 | Y | |
| 15 | - 3 star anise | ingredient | 0.60 | Y | |
| 16 | - 3 cardamom pods | ingredient | 0.60 | Y | |
| 17 | - 1 cup coconut cream | ingredient | 0.95 | Y | |
| 18 | - 1 cup water | ingredient | 0.95 | Y | |
| 19 | - 2 tablespoons tamarind paste | ingredient | 0.95 | Y | |
| 20 | - 6 lime leaves | ingredient | 0.60 | Y | |
| 21 | - 1 tablespoon sugar | ingredient | 0.95 | Y | |
| 22 | - 5 shallots | ingredient | 0.60 | Y | |
| 23 | Instructions: | sectionHeader | 0.90 | Y | |
| 24 | 1. Chop the spice paste ingredients and blend in a food processor until fine. | instruction | 0.60 | Y | |
| 25 | 2. Heat the oil in a stew pot, add the spice paste, cinnamon, cloves, star anise | instruction | 0.60 | Y | |
| 26 | 3. Add the beef and pounded lemongrass and stir for 1 minute. Add the coconut mi | instruction | 0.70 | Y | |
| 27 | 4. Add the kaffir lime leaves, toasted coconut, sugar, stirring to blend well wi | instruction | 0.60 | Y | |
| 28 | 5. Lower the heat to low, cover and simmer for 1 to 1.5 hours or until the meat  | instruction | 0.30 | Y | |
| 29 | 6. Add more salt and sugar to taste. Serve immediately with steamed rice. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 11 | - 1 lb beef | 1 | lb | beef | 1.00 | regex | Y | |
| 12 | - 5 tablespoons vegetable oil | 5 | tbsp | vegetable oil | 1.00 | regex | Y | |
| 13 | - 1 cinnamon stick | 1 | — | cinnamon stick | 0.92 | regex | Y | |
| 14 | - 3 cloves | 3 | clove | s | 1.00 | regex | Y | |
| 15 | - 3 star anise | 3 | — | star anise | 0.92 | regex | Y | |
| 16 | - 3 cardamom pods | 3 | — | cardamom pods | 0.92 | regex | Y | |
| 17 | - 1 cup coconut cream | 1 | cup | coconut cream | 1.00 | regex | Y | |
| 18 | - 1 cup water | 1 | cup | water | 1.00 | regex | Y | |
| 19 | - 2 tablespoons tamarind paste | 2 | tbsp | tamarind paste | 1.00 | regex | Y | |
| 20 | - 6 lime leaves | 6 | — | lime leaves | 0.92 | regex | Y | |
| 21 | - 1 tablespoon sugar | 1 | tbsp | sugar | 1.00 | regex | Y | |
| 22 | - 5 shallots | 5 | — | shallot s | 0.92 | regex | Y | |

---

## unusual-metadata-07-eccles-cakes

**Category**: unusual-metadata | **Lines**: 33 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Eccles Cakes | title | 0.70 | Y | |
| 2 | Yield: 8 cakes | metadata | 0.60 | Y | |
| 3 | Hands-on: 45 minutes | unknown | 0.10 | Y | |
| 4 | Chilling: 1 hour (pastry) | unknown | 0.10 | Y | |
| 5 | Bake: 15-20 minutes | unknown | 0.10 | Y | |
| 6 | Oven: 220C / 200C fan / gas 8 | metadata | 0.60 | Y | |
| 7 | Difficulty: Advanced | metadata | 0.60 | Y | |
| 8 | Course: Teatime | metadata | 0.60 | Y | |
| 9 | Ingredients: | sectionHeader | 0.90 | Y | |
| 10 | - 250g butter (for pastry) | ingredient | 0.60 | Y | |
| 11 | - 350g plain flour | ingredient | 0.60 | Y | |
| 12 | - Juice of 1/2 lemon | ingredient | 0.30 | Y | |
| 13 | - 25g butter (for filling) | ingredient | 0.60 | Y | |
| 14 | - 200g currants | ingredient | 0.60 | Y | |
| 15 | - 50g mixed peel | ingredient | 0.60 | Y | |
| 16 | - 100g muscovado sugar | ingredient | 0.60 | Y | |
| 17 | - 1 tsp cinnamon | ingredient | 0.95 | Y | |
| 18 | - 1 tsp ginger | ingredient | 0.95 | Y | |
| 19 | - 1 tsp allspice | ingredient | 0.95 | Y | |
| 20 | - Zest of 1 lemon | ingredient | 0.30 | Y | |
| 21 | - 1 beaten egg | ingredient | 0.60 | Y | |
| 22 | - Sprinkling of sugar | ingredient | 0.30 | Y | |
| 23 | Instructions: | sectionHeader | 0.90 | Y | |
| 24 | 1. For the pastry: dice butter and freeze until hard. Pulse flour with half the  | sectionHeader | 0.90 | Y | |
| 25 | 2. Roll out to a rectangle, fold ends into middle, then fold in half. Repeat 3 m | instruction | 0.70 | Y | |
| 26 | 3. For the filling: melt butter and stir in all other filling ingredients. | sectionHeader | 0.90 | Y | |
| 27 | 4. Roll pastry slightly thicker than a coin, cut 8 rounds about 12cm across. Pla | instruction | 0.60 | Y | |
| 28 | 5. Cut 2 slits in each cake, brush with egg white and sprinkle with sugar. | instruction | 0.60 | Y | |
| 29 | 6. Bake for 15-20 mins until golden brown and sticky. Cool on a rack. | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 10 | - 250g butter (for pastry) | 250 | g | butter (for pastry) | 1.00 | regex | Y | |
| 11 | - 350g plain flour | 350 | g | plain flour | 1.00 | regex | Y | |
| 12 | - Juice of 1/2 lemon | 0.5 | — | lemon | 0.95 | regex | Y | |
| 13 | - 25g butter (for filling) | 25 | g | butter (for filling) | 1.00 | regex | Y | |
| 14 | - 200g currants | 200 | g | currants | 1.00 | regex | Y | |
| 15 | - 50g mixed peel | 50 | g | mixed peel | 1.00 | regex | Y | |
| 16 | - 100g muscovado sugar | 100 | g | muscovado sugar | 1.00 | regex | Y | |
| 17 | - 1 tsp cinnamon | 1 | tsp | cinnamon | 1.00 | regex | Y | |
| 18 | - 1 tsp ginger | 1 | tsp | ginger | 1.00 | regex | Y | |
| 19 | - 1 tsp allspice | 1 | tsp | allspice | 1.00 | regex | Y | |
| 20 | - Zest of 1 lemon | 1 | — | lemon | 0.95 | regex | Y | |
| 21 | - 1 beaten egg | 1 | — | beaten egg | 0.92 | regex | Y | |
| 22 | - Sprinkling of sugar | 0.12 | — | sugar | 0.95 | regex | Y | |

---

## unusual-metadata-08-salmon-eggs-benedict

**Category**: unusual-metadata | **Lines**: 28 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Salmon Eggs Benedict | title | 0.70 | Y | |
| 2 | Serves 2 | metadata | 0.70 | Y | |
| 3 | Difficulty: Medium | metadata | 0.60 | Y | |
| 4 | Prep: 10 minutes | metadata | 0.70 | Y | |
| 5 | Cook: 15 minutes | metadata | 0.70 | Y | |
| 6 | Total: 25 minutes | metadata | 0.70 | Y | |
| 7 | Course: Brunch | metadata | 0.60 | Y | |
| 8 | Cuisine: American | metadata | 0.60 | Y | |
| 9 | Ingredients: | sectionHeader | 0.90 | Y | |
| 10 | - 2 salmon fillets | ingredient | 0.60 | Y | |
| 11 | - 2 English muffins, split and toasted | ingredient | 0.60 | Y | |
| 12 | - 4 eggs | ingredient | 0.60 | Y | |
| 13 | - 1 tablespoon white vinegar | ingredient | 0.95 | Y | |
| 14 | - 3 egg yolks | ingredient | 0.60 | Y | |
| 15 | - 150g unsalted butter, melted | ingredient | 0.60 | Y | |
| 16 | - 1 tablespoon lemon juice | ingredient | 0.95 | Y | |
| 17 | - Salt and pepper to taste | ingredient | 0.40 | Y | |
| 18 | - Fresh dill for garnish | ingredient | 0.30 | Y | |
| 19 | Instructions: | sectionHeader | 0.90 | Y | |
| 20 | 1. Season the salmon fillets and pan-fry in a skillet over medium heat for 3-4 m | instruction | 0.70 | Y | |
| 21 | 2. For hollandaise, whisk egg yolks with lemon juice in a heatproof bowl set ove | instruction | 0.30 | Y | |
| 22 | 3. Bring a pot of water to a gentle simmer with white vinegar. Crack each egg in | instruction | 0.30 | Y | |
| 23 | 4. Place toasted muffin halves on plates. Top each with a salmon fillet, then a  | instruction | 0.60 | Y | |
| 24 | 5. Spoon hollandaise over the top. Garnish with fresh dill and serve immediately | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 10 | - 2 salmon fillets | 2 | — | salmon fillets | 0.92 | regex | Y | |
| 11 | - 2 English muffins, split and toasted | 2 | — | English muffins, split and toa | 0.92 | regex | Y | |
| 12 | - 4 eggs | 4 | — | egg s | 0.92 | regex | Y | |
| 13 | - 1 tablespoon white vinegar | 1 | tbsp | white vinegar | 1.00 | regex | Y | |
| 14 | - 3 egg yolks | 3 | — | egg yolks | 0.92 | regex | Y | |
| 15 | - 150g unsalted butter, melted | 150 | g | unsalted butter, melted | 1.00 | regex | Y | |
| 16 | - 1 tablespoon lemon juice | 1 | tbsp | lemon juice | 1.00 | regex | Y | |
| 17 | - Salt and pepper to taste | — | — | salt and pepper | 0.95 | ml | Y | |
| 18 | - Fresh dill for garnish | — | — | fresh dill | 0.98 | ml | Y | |

---

## unusual-metadata-09-chicken-couscous

**Category**: unusual-metadata | **Lines**: 31 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Couscous | title | 0.70 | Y | |
| 2 | Serves 2 | metadata | 0.70 | Y | |
| 3 | Active time: 15 minutes | metadata | 0.60 | Y | |
| 4 | Resting time: 5 minutes (couscous) | unknown | 0.10 | Y | |
| 5 | Total: 25 minutes | metadata | 0.70 | Y | |
| 6 | Cuisine: Moroccan | metadata | 0.60 | Y | |
| 7 | Course: Main dish | metadata | 0.60 | Y | |
| 8 | Difficulty: Easy | metadata | 0.60 | Y | |
| 9 | Calories: Approx 450 per serving | unknown | 0.10 | Y | |
| 10 | Ingredients: | sectionHeader | 0.90 | Y | |
| 11 | - 1 tbsp olive oil | ingredient | 0.95 | Y | |
| 12 | - 1 chopped onion | ingredient | 0.60 | Y | |
| 13 | - 200g chicken breast | ingredient | 0.60 | Y | |
| 14 | - Pinch of ginger | ingredient | 0.45 | Y | |
| 15 | - 2 tablespoons harissa spice | ingredient | 0.95 | Y | |
| 16 | - 10 dried apricots | ingredient | 0.60 | Y | |
| 17 | - 220g chickpeas | ingredient | 0.60 | Y | |
| 18 | - 200g couscous | ingredient | 0.60 | Y | |
| 19 | - 200ml chicken stock | ingredient | 0.60 | Y | |
| 20 | - Handful of coriander | ingredient | 0.30 | Y | |
| 21 | Instructions: | sectionHeader | 0.90 | Y | |
| 22 | 1. Heat the olive oil in a large frying pan and cook the onion for 1-2 mins just | instruction | 0.70 | Y | |
| 23 | 2. Add the chicken and fry for 7-10 mins until cooked through and the onions hav | instruction | 0.70 | Y | |
| 24 | 3. Grate over the ginger, stir through the harissa to coat everything and cook f | instruction | 0.70 | Y | |
| 25 | 4. Tip in the apricots, chickpeas and couscous, then pour over the stock and sti | instruction | 0.30 | Y | |
| 26 | 5. Cover with a lid or foil and leave for about 5 mins until the couscous has so | instruction | 0.70 | Y | |
| 27 | 6. Fluff up the couscous with a fork and scatter over the coriander to serve. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 11 | - 1 tbsp olive oil | 1 | tbsp | olive oil | 1.00 | regex | Y | |
| 12 | - 1 chopped onion | 1 | — | chopped onion | 0.92 | regex | Y | |
| 13 | - 200g chicken breast | 200 | g | chicken breast | 1.00 | regex | Y | |
| 14 | - Pinch of ginger | 0.12 | — | ginger | 0.95 | regex | Y | |
| 15 | - 2 tablespoons harissa spice | 2 | tbsp | harissa spice | 1.00 | regex | Y | |
| 16 | - 10 dried apricots | 10 | — | dried apricots | 0.92 | regex | Y | |
| 17 | - 220g chickpeas | 220 | g | chickpeas | 1.00 | regex | Y | |
| 18 | - 200g couscous | 200 | g | couscous | 1.00 | regex | Y | |
| 19 | - 200ml chicken stock | 200 | ml | chicken stock | 1.00 | regex | Y | |
| 20 | - Handful of coriander | 0.5 | — | coriander | 0.95 | regex | Y | |

---

## unusual-metadata-10-dundee-cake

**Category**: unusual-metadata | **Lines**: 38 | **Ingredients found**: 14

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Dundee Cake | title | 0.70 | Y | |
| 2 | Makes 1 cake (12 slices) | metadata | 1.00 | Y | |
| 3 | Difficulty: Medium-Hard | metadata | 0.60 | Y | |
| 4 | Prep: 25 minutes | metadata | 0.70 | Y | |
| 5 | Bake: 1 hour 45 minutes to 2 hours 5 minutes | metadata | 0.70 | Y | |
| 6 | Oven: Start at 180C / 160C fan / Gas 4, reduce to 160C / 140C fan / Gas 3 | metadata | 0.60 | Y | |
| 7 | Resting: 2 days minimum before cutting | unknown | 0.10 | Y | |
| 8 | Course: Afternoon tea | metadata | 0.60 | Y | |
| 9 | Cuisine: Scottish | metadata | 0.60 | Y | |
| 10 | Ingredients: | sectionHeader | 0.90 | Y | |
| 11 | - 100g whole almonds | ingredient | 0.60 | Y | |
| 12 | - 180g butter | ingredient | 0.60 | Y | |
| 13 | - 180g muscovado sugar | ingredient | 0.60 | Y | |
| 14 | - Zest of 1 orange | ingredient | 0.30 | Y | |
| 15 | - 3 tablespoons apricot jam | ingredient | 0.95 | Y | |
| 16 | - 225g plain flour | ingredient | 0.60 | Y | |
| 17 | - 1 tsp baking powder | ingredient | 0.95 | Y | |
| 18 | - 3 large eggs | ingredient | 0.60 | Y | |
| 19 | - 100g ground almonds | ingredient | 0.60 | Y | |
| 20 | - 2 tablespoons milk | ingredient | 0.95 | Y | |
| 21 | - 500g dried fruit | ingredient | 0.60 | Y | |
| 22 | - 100g glace cherries | ingredient | 0.60 | Y | |
| 23 | - 1 tablespoon milk (for glaze) | ingredient | 0.95 | Y | |
| 24 | - 2 tsp caster sugar (for glaze) | ingredient | 0.95 | Y | |
| 25 | Instructions: | sectionHeader | 0.90 | Y | |
| 26 | 1. Put almonds in a small bowl and pour over boiling water to cover. Leave for 5 | instruction | 0.30 | Y | |
| 27 | 2. Preheat oven to 180C/160C fan/Gas 4. Line a deep 20cm cake tin with baking pa | instruction | 0.60 | Y | |
| 28 | 3. Beat butter until soft. Add sugar and beat until light and fluffy. Stir in or | instruction | 0.60 | Y | |
| 29 | 4. Sieve flour and baking powder together. Add eggs to creamed butter and sugar  | instruction | 0.30 | Y | |
| 30 | 5. Add remaining flour and ground almonds and mix well. Mix in milk, then add dr | instruction | 0.60 | Y | |
| 31 | 6. Spoon into prepared tin and spread level. Arrange whole almonds in neat circl | instruction | 0.30 | Y | |
| 32 | 7. Bake for 45 mins. Lower oven to 160C/140C fan/Gas 3 and cook for a further 60 | instruction | 0.70 | Y | |
| 33 | 8. Heat milk and sugar until dissolved, brush over hot cake, return to oven for  | instruction | 0.70 | Y | |
| 34 | 9. Cool in tin. When cold, wrap in foil and keep for at least 2 days before cutt | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 11 | - 100g whole almonds | 100 | g | whole almonds | 1.00 | regex | Y | |
| 12 | - 180g butter | 180 | g | butter | 1.00 | regex | Y | |
| 13 | - 180g muscovado sugar | 180 | g | muscovado sugar | 1.00 | regex | Y | |
| 14 | - Zest of 1 orange | 1 | — | orange | 0.95 | regex | Y | |
| 15 | - 3 tablespoons apricot jam | 3 | tbsp | apricot jam | 1.00 | regex | Y | |
| 16 | - 225g plain flour | 225 | g | plain flour | 1.00 | regex | Y | |
| 17 | - 1 tsp baking powder | 1 | tsp | baking powder | 1.00 | regex | Y | |
| 18 | - 3 large eggs | 3 | — | large eggs | 0.92 | regex | Y | |
| 19 | - 100g ground almonds | 100 | g | ground almonds | 1.00 | regex | Y | |
| 20 | - 2 tablespoons milk | 2 | tbsp | milk | 1.00 | regex | Y | |
| 21 | - 500g dried fruit | 500 | g | dried fruit | 1.00 | regex | Y | |
| 22 | - 100g glace cherries | 100 | g | glace cherries | 1.00 | regex | Y | |
| 23 | - 1 tablespoon milk (for glaze) | 1 | tbsp | milk (for glaze) | 1.00 | regex | Y | |
| 24 | - 2 tsp caster sugar (for glaze) | 2 | tsp | caster sugar (for glaze) | 1.00 | regex | Y | |

---

## messy-01-beef-bourguignon

**Category**: messy | **Lines**: 15 | **Ingredients found**: 0

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Bourguignon | title | 0.70 | Y | |
| 2 | So my mom used to make this all the time when I was growing up and I finally got | unknown | 0.10 | Y | |
| 3 | You'll need about 3 tsp goose fat (or butter works too), 600g beef shin cut into | unknown | 0.10 | Y | |
| 4 | Heat a large casserole pan and add the goose fat. Season the beef and fry until  | instruction | 0.70 | Y | |
| 5 | In the same pan, fry the bacon, shallots, mushrooms, garlic and bouquet garni un | unknown | 0.10 | Y | |
| 6 | Mix in the tomato puree and cook for a few mins. | instruction | 0.40 | Y | |
| 7 | Return the beef and any juices to the pan. | unknown | 0.10 | Y | |
| 8 | Pour over the wine and about 100ml water. Bring to the boil and scrape the botto | instruction | 0.60 | Y | |
| 9 | Heat oven to 150C/fan 130C/gas 2. Cover and cook for 3 hrs. | instruction | 0.50 | Y | |
| 10 | For the celeriac mash, peel and cube the celeriac, fry in olive oil for 5 mins. | sectionHeader | 0.90 | Y | |
| 11 | Add herbs and 200ml water, simmer 25-30 mins. Crush with a potato masher and fin | instruction | 0.70 | Y | |

---

## messy-02-general-tsos-chicken

**Category**: messy | **Lines**: 21 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | General Tso's Chicken | title | 0.70 | Y | |
| 2 | 1 1/2 chicken breast | ingredient | 0.60 | Y | |
| 3 | 3/4 cup plain flour | ingredient | 0.95 | Y | |
| 4 | 1 egg | ingredient | 0.60 | Y | |
| 5 | 2 tbs starch | ingredient | 0.95 | Y | |
| 6 | 1 tbs baking powder | ingredient | 0.95 | Y | |
| 7 | 1 tsp salt | ingredient | 0.95 | Y | |
| 8 | 1/2 tsp onion salt | ingredient | 0.95 | Y | |
| 9 | 1/4 tsp garlic powder | ingredient | 0.95 | Y | |
| 10 | For the sauce: 3/4 cup water, 1/2 cup chicken stock, 1/4 cup duck sauce, 3 tbs s | sectionHeader | 0.90 | Y | |
| 11 | DIRECTIONS: | sectionHeader | 0.90 | Y | |
| 12 | STEP 1 - SAUCE | instruction | 0.30 | Y | |
| 13 | In a bowl, add 2 Cups of water, 2 Tablespoon soy sauce, 2 Tablespoon white vineg | instruction | 0.30 | Y | |
| 14 | STEP 2 - MARINATING THE CHICKEN | title | 0.30 | Y | |
| 15 | In a bowl, add the chicken, 1 pinch of salt, 1 pinch of white pepper, 2 egg whit | ingredient | 0.35 | Y | |
| 16 | STEP 3 - DEEP FRY THE CHICKEN | title | 0.30 | Y | |
| 17 | Deep fry the chicken at 350 degrees for 3-4 minutes or until it is golden brown | instruction | 0.45 | Y | |
| 18 | STEP 4 - STIR FRY | title | 0.30 | Y | |
| 19 | Add the sauce to the wok and then the broccoli and wait until it is boiling. Thi | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1 1/2 chicken breast | 1.5 | — | chicken breast | 0.92 | regex | Y | |
| 3 | 3/4 cup plain flour | 0.75 | cup | plain flour | 1.00 | regex | Y | |
| 4 | 1 egg | 1 | — | eg g | 0.92 | regex | Y | |
| 5 | 2 tbs starch | 2 | tbsp | starch | 1.00 | regex | Y | |
| 6 | 1 tbs baking powder | 1 | tbsp | baking powder | 1.00 | regex | Y | |
| 7 | 1 tsp salt | 1 | tsp | salt | 1.00 | regex | Y | |
| 8 | 1/2 tsp onion salt | 0.5 | tsp | onion salt | 1.00 | regex | Y | |
| 9 | 1/4 tsp garlic powder | 0.25 | tsp | garlic powder | 1.00 | regex | Y | |
| 15 | In a bowl, add the chicken, 1 pinch of salt, 1 pinch of whit | — | — | In a bowl, add the chicken, 1  | 0.75 | ml | Y | |

---

## messy-03-beef-lo-mein

**Category**: messy | **Lines**: 16 | **Ingredients found**: 0

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | beef lo mein | title | 0.50 | Y | |
| 2 | ok so you need 1/2 lb beef, pinch salt, pinch pepper, 2 tsp sesame seed oil, 1/2 | unknown | 0.10 | Y | |
| 3 | STEP 1 MARINATING THE BEEF | title | 0.30 | Y | |
| 4 | In a bowl, add the beef, salt, 1 pinch white pepper, 1 Teaspoon sesame seed oil, | unknown | 0.10 | Y | |
| 5 | STEP 2 BOILING THE NOODLES | title | 0.30 | Y | |
| 6 | In a 6 qt pot add your noodles to boiling water until the noodles are submerged  | instruction | 0.30 | Y | |
| 7 | STEP 3 STIR FRY | title | 0.30 | Y | |
| 8 | Add 2 Tablespoons of oil, beef and cook on high heat untill beef is medium cooke | instruction | 0.60 | Y | |
| 9 | Set the cooked beef aside | instruction | 0.40 | Y | |
| 10 | In a wok add 2 Tablespoon of oil, onions, minced garlic, minced ginger, bean spr | unknown | 0.10 | Y | |
| 11 | Add the noodles to wok | instruction | 0.40 | Y | |
| 12 | To make the sauce, add oyster sauce, 1 pinch white pepper, 1 teaspoon sesame see | unknown | 0.10 | Y | |
| 13 | Next add the beef to wok and stir-fry | unknown | 0.10 | Y | |

---

## messy-04-irish-stew

**Category**: messy | **Lines**: 19 | **Ingredients found**: 11

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Irish Stew | title | 0.70 | Y | |
| 2 | This is a classic one-pot recipe thats been in my family for generations. The tr | unknown | 0.10 | Y | |
| 3 | You need about 2 lbs lamb shoulder (or mutton if you can find it), cut into chun | ingredient | 0.35 | Y | |
| 4 | 4-5 medium potatoes peeled and quartered | ingredient | 0.60 | Y | |
| 5 | 3 carrots sliced thick | ingredient | 0.60 | Y | |
| 6 | 2 onions roughly chopped | ingredient | 0.60 | Y | |
| 7 | 2 cups beef stock | ingredient | 0.95 | Y | |
| 8 | 1 tablespoon butter | ingredient | 0.95 | Y | |
| 9 | a sprig of thyme | ingredient | 0.45 | Y | |
| 10 | 2 bay leaves | ingredient | 0.60 | Y | |
| 11 | 1 tablespoon Worcestershire sauce | ingredient | 0.95 | Y | |
| 12 | 1 tablespoon tomato paste | ingredient | 0.95 | Y | |
| 13 | salt and pepper | ingredient | 0.40 | Y | |
| 14 | handful of chopped parsley for serving | unknown | 0.10 | Y | |
| 15 | Melt butter in a heavy dutch oven over medium-high heat. Brown the lamb in batch | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | You need about 2 lbs lamb shoulder (or mutton if you can fin | — | — | you need | 0.80 | ml | Y | |
| 4 | 4-5 medium potatoes peeled and quartered | 5 | — | medium potatoes peeled and qua | 0.92 | regex | Y | |
| 5 | 3 carrots sliced thick | 3 | — | carrots sliced thick | 0.92 | regex | Y | |
| 6 | 2 onions roughly chopped | 2 | — | onions roughly chopped | 0.92 | regex | Y | |
| 7 | 2 cups beef stock | 2 | cup | beef stock | 1.00 | regex | Y | |
| 8 | 1 tablespoon butter | 1 | tbsp | butter | 1.00 | regex | Y | |
| 9 | a sprig of thyme | 1 | — | thyme | 0.95 | regex | Y | |
| 10 | 2 bay leaves | 2 | — | bay leaves | 0.92 | regex | Y | |
| 11 | 1 tablespoon Worcestershire sauce | 1 | tbsp | Worcestershire sauce | 1.00 | regex | Y | |
| 12 | 1 tablespoon tomato paste | 1 | tbsp | tomato paste | 1.00 | regex | Y | |
| 13 | salt and pepper | — | — | salt and pepper | 0.96 | ml | Y | |

---

## messy-05-spanish-chicken-pie

**Category**: messy | **Lines**: 21 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | spanish chicken pie | title | 0.50 | Y | |
| 2 | 1 kg potatoes | ingredient | 0.95 | Y | |
| 3 | 3 tsp paprika | ingredient | 0.95 | Y | |
| 4 | 2 teaspoons olive oil | ingredient | 0.95 | Y | |
| 5 | 2 sliced onion | ingredient | 0.60 | Y | |
| 6 | 2 cloves minced garlic | ingredient | 0.95 | Y | |
| 7 | 800g tinned tomatoes | ingredient | 0.60 | Y | |
| 8 | 300g chicken | ingredient | 0.60 | Y | |
| 9 | 140g roasted pepper | ingredient | 0.60 | Y | |
| 10 | Handful green olives | unknown | 0.10 | Y | |
| 11 | step 1 | unknown | 0.10 | Y | |
| 12 | Heat oven to 200C/fan 180C/gas 6. Boil the potatoes for 15-20 mins until tender. | instruction | 0.70 | Y | |
| 13 | step 2 | unknown | 0.10 | Y | |
| 14 | Meanwhile, heat the oil in a large pan, then fry the onions and garlic for a few | instruction | 0.30 | Y | |
| 15 | step 3 | unknown | 0.10 | Y | |
| 16 | Spoon over the mash, then bake for 15 mins until the mash is golden on top and t | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1 kg potatoes | 1 | kg | potatoes | 1.00 | regex | Y | |
| 3 | 3 tsp paprika | 3 | tsp | paprika | 1.00 | regex | Y | |
| 4 | 2 teaspoons olive oil | 2 | tsp | olive oil | 1.00 | regex | Y | |
| 5 | 2 sliced onion | 2 | — | sliced onion | 0.92 | regex | Y | |
| 6 | 2 cloves minced garlic | 2 | clove | minced garlic | 1.00 | regex | Y | |
| 7 | 800g tinned tomatoes | 800 | g | tinned tomatoes | 1.00 | regex | Y | |
| 8 | 300g chicken | 300 | g | chicken | 1.00 | regex | Y | |
| 9 | 140g roasted pepper | 140 | g | roasted pepper | 1.00 | regex | Y | |

---

## messy-06-hot-and-sour-soup

**Category**: messy | **Lines**: 19 | **Ingredients found**: 15

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Hot and Sour Soup | title | 0.70 | Y | |
| 2 | 1/3 cup mushrooms | ingredient | 0.95 | Y | |
| 3 | 1/3 cup wood ear mushrooms | ingredient | 0.95 | Y | |
| 4 | 2/3 cup tofu (cubed) | ingredient | 0.95 | Y | |
| 5 | 1/2 cup bbq pork (sliced) | ingredient | 0.95 | Y | |
| 6 | 2-1/2 cups chicken stock | ingredient | 0.95 | Y | |
| 7 | 1/2 tsp salt | ingredient | 0.95 | Y | |
| 8 | 1/4 tsp sugar | ingredient | 0.95 | Y | |
| 9 | 1 tsp sesame seed oil | ingredient | 0.95 | Y | |
| 10 | 1/4 tsp white pepper | ingredient | 0.95 | Y | |
| 11 | 1/2 tsp hot sauce | ingredient | 0.95 | Y | |
| 12 | 1-1/2 cups vinegar | ingredient | 0.95 | Y | |
| 13 | 1 tsp soy sauce | ingredient | 0.95 | Y | |
| 14 | 1 tbs cornstarch | ingredient | 0.95 | Y | |
| 15 | 2 tbs water | ingredient | 0.95 | Y | |
| 16 | 1/4 cup spring onions | ingredient | 0.95 | Y | |
| 17 | In a wok add chicken broth and wait for it to boil. Next add salt, sugar, sesame | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | 1/3 cup mushrooms | 0.33 | cup | mushrooms | 1.00 | regex | Y | |
| 3 | 1/3 cup wood ear mushrooms | 0.33 | cup | wood ear mushrooms | 1.00 | regex | Y | |
| 4 | 2/3 cup tofu (cubed) | 0.67 | cup | tofu | 1.00 | regex | Y | |
| 5 | 1/2 cup bbq pork (sliced) | 0.5 | cup | bbq pork | 1.00 | regex | Y | |
| 6 | 2-1/2 cups chicken stock | 2.5 | cup | chicken stock | 1.00 | regex | Y | |
| 7 | 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex | Y | |
| 8 | 1/4 tsp sugar | 0.25 | tsp | sugar | 1.00 | regex | Y | |
| 9 | 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1.00 | regex | Y | |
| 10 | 1/4 tsp white pepper | 0.25 | tsp | white pepper | 1.00 | regex | Y | |
| 11 | 1/2 tsp hot sauce | 0.5 | tsp | hot sauce | 1.00 | regex | Y | |
| 12 | 1-1/2 cups vinegar | 1.5 | cup | vinegar | 1.00 | regex | Y | |
| 13 | 1 tsp soy sauce | 1 | tsp | soy sauce | 1.00 | regex | Y | |
| 14 | 1 tbs cornstarch | 1 | tbsp | cornstarch | 1.00 | regex | Y | |
| 15 | 2 tbs water | 2 | tbsp | water | 1.00 | regex | Y | |
| 16 | 1/4 cup spring onions | 0.25 | cup | spring onions | 1.00 | regex | Y | |

---

## messy-07-chicken-fried-rice

**Category**: messy | **Lines**: 11 | **Ingredients found**: 1

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Fried Rice | title | 0.70 | Y | |
| 2 | So the key to good fried rice is using DAY OLD rice. Seriously, don't skip this  | unknown | 0.10 | Y | |
| 3 | Here's what you need: | unknown | 0.10 | Y | |
| 4 | 1 lb chicken thighs (boneless), 1 tsp salt, 3 tablespoons canola oil, 3 large eg | ingredient | 0.55 | Y | |
| 5 | First chop the chicken into small cubes and sprinkle with salt. Set aside 10 min | metadata | 0.70 | Y | |
| 6 | Now here's where it gets good - add the rice on top of the vegetables and smash  | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 4 | 1 lb chicken thighs (boneless), 1 tsp salt, 3 tablespoons ca | 1 | lb | chicken thighs (boneless), 1 t | 1.00 | regex | Y | |

---

## messy-08-creamy-tomato-soup

**Category**: messy | **Lines**: 19 | **Ingredients found**: 5

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | creamy tomato soup | title | 0.50 | Y | |
| 2 | olive oil | ingredient | 0.40 | Y | |
| 3 | 2 onions | ingredient | 0.60 | Y | |
| 4 | celery | ingredient | 0.40 | Y | |
| 5 | carrots | unknown | 0.10 | Y | |
| 6 | potatoes | unknown | 0.10 | Y | |
| 7 | bay leaves | unknown | 0.10 | Y | |
| 8 | tomato puree | unknown | 0.10 | Y | |
| 9 | sugar | ingredient | 0.40 | Y | |
| 10 | white vinegar | unknown | 0.10 | Y | |
| 11 | chopped tomatoes (tin) | unknown | 0.10 | Y | |
| 12 | passata | ingredient | 0.40 | Y | |
| 13 | vegetable stock cubes | unknown | 0.10 | Y | |
| 14 | whole milk | unknown | 0.10 | Y | |
| 15 | Put the oil, onions, celery, carrots, potatoes and bay leaves in a big casserole | instruction | 0.30 | Y | |
| 16 | To serve, reheat the soup, stirring in the milk – try not to let it boil. Serve  | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 2 | olive oil | — | — | olive oil | 1.00 | ml | Y | |
| 3 | 2 onions | 2 | — | onion s | 0.92 | regex | Y | |
| 4 | celery | — | — | celery | 1.00 | ml | Y | |
| 9 | sugar | — | — | sugar | 1.00 | ml | Y | |
| 12 | passata | — | — | passata | 0.99 | ml | Y | |

---

## messy-09-szechuan-beef

**Category**: messy | **Lines**: 12 | **Ingredients found**: 1

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Szechuan Beef | title | 0.70 | Y | |
| 2 | You need: 1/2 lb beef, 1/2 tsp salt, 1 tsp sesame seed oil, 1 pinch pepper, 1 eg | unknown | 0.10 | Y | |
| 3 | STEP 1 - MARINATING THE BEEF | title | 0.30 | Y | |
| 4 | In a bowl, add the beef, salt, sesame seed oil, white pepper, egg white, 2 Table | unknown | 0.10 | Y | |
| 5 | STEP 2 - STIR FRY | title | 0.30 | Y | |
| 6 | First Cook the beef by adding 2 Tablespoon of oil until the beef is golden brown | ingredient | 0.35 | Y | |
| 7 | In a wok add 1 Tablespoon of oil, minced ginger, minced garlic and stir-fry for  | unknown | 0.10 | Y | |
| 8 | To make the sauce add oyster sauce, hot pepper sauce, and sugar. add the cooked  | unknown | 0.10 | Y | |
| 9 | To thicken the sauce, whisk together 1 Tablespoon of cornstarch and 2 Tablespoon | unknown | 0.10 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | First Cook the beef by adding 2 Tablespoon of oil until the  | — | — | first cook | 0.55 | ml | Y | |

---

## messy-10-sweet-and-sour-chicken

**Category**: messy | **Lines**: 14 | **Ingredients found**: 1

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Sweet and Sour Chicken | title | 0.70 | Y | |
| 2 | I've been making this recipe for years and it's always a crowd pleaser. Way bett | unknown | 0.10 | Y | |
| 3 | 1 lb chicken thighs cut into 1-inch pieces, 1 large egg white, 1 tsp kosher salt | ingredient | 0.55 | Y | |
| 4 | Coat chicken with egg white, salt and cornstarch. Let sit 15 minutes. | instruction | 0.70 | Y | |
| 5 | Make the sauce by whisking pineapple juice vinegar ketchup salt and brown sugar  | unknown | 0.10 | Y | |
| 6 | Heat pan SUPER hot - this is key. Add 1 tbsp oil, spread chicken in one layer, d | instruction | 0.70 | Y | |
| 7 | Turn heat to medium, add remaining oil. Fry peppers and ginger 1 minute. Add pin | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 3 | 1 lb chicken thighs cut into 1-inch pieces, 1 large egg whit | 1 | lb | chicken thighs cut into 1-inch | 1.00 | regex | Y | |

---

## international-01-tandoori-chicken

**Category**: international | **Lines**: 25 | **Ingredients found**: 12

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Tandoori Chicken | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes plus marinating | metadata | 0.70 | Y | |
| 4 | Cook Time: 16 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - Juice of 2 lemons | ingredient | 0.30 | Y | |
| 7 | - 4 tsp paprika | ingredient | 0.95 | Y | |
| 8 | - 2 finely chopped red onions | ingredient | 0.60 | Y | |
| 9 | - 16 skinless chicken thighs | ingredient | 0.60 | Y | |
| 10 | - Vegetable oil for brushing | ingredient | 0.40 | Y | |
| 11 | - 300ml Greek yoghurt | ingredient | 0.60 | Y | |
| 12 | - 1 large piece ginger, grated | ingredient | 0.95 | Y | |
| 13 | - 4 garlic cloves, crushed | ingredient | 0.60 | Y | |
| 14 | - 3/4 tsp garam masala | ingredient | 0.95 | Y | |
| 15 | - 3/4 tsp ground cumin | ingredient | 0.95 | Y | |
| 16 | - 1/2 tsp chilli powder | ingredient | 0.95 | Y | |
| 17 | - 1/4 tsp turmeric | ingredient | 0.95 | Y | |
| 18 | Instructions: | sectionHeader | 0.90 | Y | |
| 19 | 1. Mix the lemon juice with the paprika and red onions in a large shallow dish.  | instruction | 0.70 | Y | |
| 20 | 2. Mix all of the marinade ingredients together and pour over the chicken. Give  | instruction | 0.70 | Y | |
| 21 | 3. Heat the grill. Lift the chicken pieces onto a rack over a baking tray. Brush | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - Juice of 2 lemons | 2 | — | lemons | 0.95 | regex | Y | |
| 7 | - 4 tsp paprika | 4 | tsp | paprika | 1.00 | regex | Y | |
| 8 | - 2 finely chopped red onions | 2 | — | finely chopped red onions | 0.92 | regex | Y | |
| 9 | - 16 skinless chicken thighs | 16 | — | skinless chicken thighs | 0.92 | regex | Y | |
| 10 | - Vegetable oil for brushing | — | — | vegetable oil | 1.00 | ml | Y | |
| 11 | - 300ml Greek yoghurt | 300 | ml | Greek yoghurt | 1.00 | regex | Y | |
| 12 | - 1 large piece ginger, grated | 1 | — | large piece ginger, grated | 0.92 | regex | Y | |
| 13 | - 4 garlic cloves, crushed | 4 | — | garlic cloves, crushed | 0.92 | regex | Y | |
| 14 | - 3/4 tsp garam masala | 0.75 | tsp | garam masala | 1.00 | regex | Y | |
| 15 | - 3/4 tsp ground cumin | 0.75 | tsp | ground cumin | 1.00 | regex | Y | |
| 16 | - 1/2 tsp chilli powder | 0.5 | tsp | chilli powder | 1.00 | regex | Y | |
| 17 | - 1/4 tsp turmeric | 0.25 | tsp | turmeric | 1.00 | regex | Y | |

---

## international-02-chicken-congee

**Category**: international | **Lines**: 26 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Chicken Congee | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 45 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 225g chicken | ingredient | 0.60 | Y | |
| 7 | - Pinch of salt | ingredient | 0.45 | Y | |
| 8 | - Pinch of white pepper | ingredient | 0.45 | Y | |
| 9 | - 1 tsp ginger cordial | ingredient | 0.95 | Y | |
| 10 | - 1 tsp fresh ginger, sliced | ingredient | 0.95 | Y | |
| 11 | - 1 tbs spring onions, chopped | ingredient | 0.95 | Y | |
| 12 | - 110g rice | ingredient | 0.60 | Y | |
| 13 | - 2L water | ingredient | 0.60 | Y | |
| 14 | - 55g fresh coriander | ingredient | 0.60 | Y | |
| 15 | Instructions: | sectionHeader | 0.90 | Y | |
| 16 | 1. In a bowl, add chicken, salt, white pepper, ginger juice and mix well. Set as | instruction | 0.30 | Y | |
| 17 | 2. Rinse the rice a couple of times and drain. | instruction | 0.40 | Y | |
| 18 | 3. Add 2 litres of water to a large pot and bring to the boil on high heat. Once | instruction | 0.70 | Y | |
| 19 | 4. After 25 minutes, add a little more water if needed to adjust thickness. | instruction | 0.30 | Y | |
| 20 | 5. Add the marinated chicken and leave on low heat for another 10 minutes. | instruction | 0.70 | Y | |
| 21 | 6. Add spring onions, sliced ginger, a pinch of salt and white pepper. Stir for  | instruction | 0.70 | Y | |
| 22 | 7. Serve in bowls. Garnish with fresh coriander. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 225g chicken | 225 | g | chicken | 1.00 | regex | Y | |
| 7 | - Pinch of salt | 0.12 | — | salt | 0.95 | regex | Y | |
| 8 | - Pinch of white pepper | 0.12 | — | white pepper | 0.95 | regex | Y | |
| 9 | - 1 tsp ginger cordial | 1 | tsp | ginger cordial | 1.00 | regex | Y | |
| 10 | - 1 tsp fresh ginger, sliced | 1 | tsp | fresh ginger, sliced | 1.00 | regex | Y | |
| 11 | - 1 tbs spring onions, chopped | 1 | tbsp | spring onions, chopped | 1.00 | regex | Y | |
| 12 | - 110g rice | 110 | g | rice | 1.00 | regex | Y | |
| 13 | - 2L water | 2 | l | water | 1.00 | regex | Y | |
| 14 | - 55g fresh coriander | 55 | g | fresh coriander | 1.00 | regex | Y | |

---

## international-03-beef-asado

**Category**: international | **Lines**: 32 | **Ingredients found**: 14

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Beef Asado | title | 0.70 | Y | |
| 2 | Servings: 6 | metadata | 0.70 | Y | |
| 3 | Prep Time: 40 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 60 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 1.5kg beef | instruction | 0.50 | Y | |
| 7 | - 1 beef stock concentrate | ingredient | 0.60 | Y | |
| 8 | - 225g tomato puree | ingredient | 0.60 | Y | |
| 9 | - 750ml water | ingredient | 0.60 | Y | |
| 10 | - 6 tablespoons soy sauce | ingredient | 0.95 | Y | |
| 11 | - 1 tbs white wine vinegar | ingredient | 0.95 | Y | |
| 12 | - 2 tbs crushed pepper | ingredient | 0.95 | Y | |
| 13 | - 4 bay leaves | ingredient | 0.60 | Y | |
| 14 | - 1/2 lemon | ingredient | 0.60 | Y | |
| 15 | - 2 tbs tomato sauce | ingredient | 0.95 | Y | |
| 16 | - 3 tbs butter | ingredient | 0.95 | Y | |
| 17 | - 120ml olive oil | ingredient | 0.60 | Y | |
| 18 | - 1 chopped onion | ingredient | 0.60 | Y | |
| 19 | - 4 cloves garlic | ingredient | 0.95 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Combine beef, crushed peppercorn, soy sauce, vinegar, bay leaves, lemon, and  | instruction | 0.70 | Y | |
| 22 | 2. Put the marinated beef in a cooking pot with remaining marinade. Add water. B | instruction | 0.30 | Y | |
| 23 | 3. Add beef stock cube. Stir. Cover and cook for 40 minutes on low heat. | instruction | 0.70 | Y | |
| 24 | 4. Turn the beef over. Add tomato paste. Continue cooking until beef is tender.  | instruction | 0.60 | Y | |
| 25 | 5. Heat oil in a pan. Fry the potato until browned on both sides. Do the same wi | instruction | 0.60 | Y | |
| 26 | 6. In 3 tablespoons of the cooking oil, saute onion and garlic until softened. | ingredient | 0.45 | Y | |
| 27 | 7. Pour in the sauce from the beef stew. Bring to the boil. Add the beef. Cook f | instruction | 0.70 | Y | |
| 28 | 8. Add butter and let it melt. Continue cooking until the sauce reduces by half. | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 1 beef stock concentrate | 1 | — | beef stock concentrate | 0.92 | regex | Y | |
| 8 | - 225g tomato puree | 225 | g | tomato puree | 1.00 | regex | Y | |
| 9 | - 750ml water | 750 | ml | water | 1.00 | regex | Y | |
| 10 | - 6 tablespoons soy sauce | 6 | tbsp | soy sauce | 1.00 | regex | Y | |
| 11 | - 1 tbs white wine vinegar | 1 | tbsp | white wine vinegar | 1.00 | regex | Y | |
| 12 | - 2 tbs crushed pepper | 2 | tbsp | crushed pepper | 1.00 | regex | Y | |
| 13 | - 4 bay leaves | 4 | — | bay leaves | 0.92 | regex | Y | |
| 14 | - 1/2 lemon | 0.5 | — | lemo n | 0.92 | regex | Y | |
| 15 | - 2 tbs tomato sauce | 2 | tbsp | tomato sauce | 1.00 | regex | Y | |
| 16 | - 3 tbs butter | 3 | tbsp | butter | 1.00 | regex | Y | |
| 17 | - 120ml olive oil | 120 | ml | olive oil | 1.00 | regex | Y | |
| 18 | - 1 chopped onion | 1 | — | chopped onion | 0.92 | regex | Y | |
| 19 | - 4 cloves garlic | 4 | clove | garlic | 1.00 | regex | Y | |
| 26 | 6. In 3 tablespoons of the cooking oil, saute onion and garl | 6 | — | cooking oil | 0.71 | ml | Y | |

---

## international-04-parkin-cake

**Category**: international | **Lines**: 26 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Parkin Cake | title | 0.70 | Y | |
| 2 | Servings: 12 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 50-60 minutes | instruction | 0.50 | Y | |
| 5 | Oven: 160C / 140C fan / Gas 3 | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 200g butter | ingredient | 0.60 | Y | |
| 8 | - 1 large egg | ingredient | 0.60 | Y | |
| 9 | - 4 tbs milk | ingredient | 0.95 | Y | |
| 10 | - 200g golden syrup | ingredient | 0.60 | Y | |
| 11 | - 85g black treacle | ingredient | 0.60 | Y | |
| 12 | - 85g brown sugar | ingredient | 0.60 | Y | |
| 13 | - 100g oatmeal | ingredient | 0.60 | Y | |
| 14 | - 250g self-raising flour | ingredient | 0.60 | Y | |
| 15 | - 1 tbs ground ginger | ingredient | 0.95 | Y | |
| 16 | Instructions: | sectionHeader | 0.90 | Y | |
| 17 | 1. Heat oven to 160C/140C fan/gas 3. Grease a deep 22cm square cake tin and line | instruction | 0.60 | Y | |
| 18 | 2. Beat the egg and milk together with a fork. | instruction | 0.40 | Y | |
| 19 | 3. Gently melt the syrup, treacle, sugar and butter together in a large pan unti | instruction | 0.30 | Y | |
| 20 | 4. Mix together the oatmeal, flour and ginger and stir into the syrup mixture, f | instruction | 0.60 | Y | |
| 21 | 5. Pour the mixture into the tin and bake for 50 mins to 1 hr until the cake fee | instruction | 0.70 | Y | |
| 22 | 6. Cool in the tin then wrap in parchment and foil. Keep for 3-5 days before eat | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 200g butter | 200 | g | butter | 1.00 | regex | Y | |
| 8 | - 1 large egg | 1 | — | large egg | 0.92 | regex | Y | |
| 9 | - 4 tbs milk | 4 | tbsp | milk | 1.00 | regex | Y | |
| 10 | - 200g golden syrup | 200 | g | golden syrup | 1.00 | regex | Y | |
| 11 | - 85g black treacle | 85 | g | black treacle | 1.00 | regex | Y | |
| 12 | - 85g brown sugar | 85 | g | brown sugar | 1.00 | regex | Y | |
| 13 | - 100g oatmeal | 100 | g | oatmeal | 1.00 | regex | Y | |
| 14 | - 250g self-raising flour | 250 | g | self-raising flour | 1.00 | regex | Y | |
| 15 | - 1 tbs ground ginger | 1 | tbsp | ground ginger | 1.00 | regex | Y | |

---

## international-05-minced-beef-pie

**Category**: international | **Lines**: 29 | **Ingredients found**: 10

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Minced Beef Pie | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 45 minutes | metadata | 0.70 | Y | |
| 5 | Oven: 200C / 400F / Gas 6 | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 2 tbs vegetable oil | ingredient | 0.95 | Y | |
| 8 | - 500g minced beef | ingredient | 0.60 | Y | |
| 9 | - 1 chopped onion | ingredient | 0.60 | Y | |
| 10 | - 1 tbs tomato puree | ingredient | 0.95 | Y | |
| 11 | - 1 1/2 tbsp plain flour | ingredient | 0.95 | Y | |
| 12 | - 75g mushrooms | ingredient | 0.60 | Y | |
| 13 | - 250ml beef stock | ingredient | 0.60 | Y | |
| 14 | - Dash of Worcestershire sauce | ingredient | 0.45 | Y | |
| 15 | - 400g shortcrust pastry | ingredient | 0.60 | Y | |
| 16 | - 1 egg yolk | ingredient | 0.60 | Y | |
| 17 | Instructions: | sectionHeader | 0.90 | Y | |
| 18 | 1. Preheat the oven to 200C/400F/Gas 6. | instruction | 0.40 | Y | |
| 19 | 2. Heat the oil in a deep frying pan and fry the beef mince for 4-5 minutes, bre | instruction | 0.70 | Y | |
| 20 | 3. Add the onion and cook for 2-3 minutes, then stir in the tomato puree and coo | instruction | 0.70 | Y | |
| 21 | 4. Stir in the flour and cook for a further minute, then add the chopped mushroo | instruction | 0.60 | Y | |
| 22 | 5. Bring to the boil, then reduce the heat, cover and simmer for 20 minutes. Set | instruction | 0.30 | Y | |
| 23 | 6. Roll out the pastry to slightly larger than the pie dish. Drape over the dish | instruction | 0.60 | Y | |
| 24 | 7. Cut leaf shapes from trimmings for decoration. Make slits for steam. Brush wi | instruction | 0.60 | Y | |
| 25 | 8. Bake for 20-25 minutes, or until golden-brown. Slice into wedges to serve. | instruction | 0.70 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 2 tbs vegetable oil | 2 | tbsp | vegetable oil | 1.00 | regex | Y | |
| 8 | - 500g minced beef | 500 | g | minced beef | 1.00 | regex | Y | |
| 9 | - 1 chopped onion | 1 | — | chopped onion | 0.92 | regex | Y | |
| 10 | - 1 tbs tomato puree | 1 | tbsp | tomato puree | 1.00 | regex | Y | |
| 11 | - 1 1/2 tbsp plain flour | 1.5 | tbsp | plain flour | 1.00 | regex | Y | |
| 12 | - 75g mushrooms | 75 | g | mushrooms | 1.00 | regex | Y | |
| 13 | - 250ml beef stock | 250 | ml | beef stock | 1.00 | regex | Y | |
| 14 | - Dash of Worcestershire sauce | 0.12 | — | worcestershire sauce | 0.95 | regex | Y | |
| 15 | - 400g shortcrust pastry | 400 | g | shortcrust pastry | 1.00 | regex | Y | |
| 16 | - 1 egg yolk | 1 | — | egg yolk | 0.92 | regex | Y | |

---

## international-06-massaman-beef-curry

**Category**: international | **Lines**: 29 | **Ingredients found**: 13

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Massaman Beef Curry | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 2 hours 10 minutes | metadata | 0.70 | Y | |
| 5 | Oven: 180C / 160C fan / Gas 4 | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 85g peanuts | ingredient | 0.60 | Y | |
| 8 | - 400ml tin coconut cream | ingredient | 0.60 | Y | |
| 9 | - 4 tbsp massaman curry paste | ingredient | 0.95 | Y | |
| 10 | - 600g stewing beef, cut into strips | ingredient | 0.60 | Y | |
| 11 | - 450g waxy potatoes | ingredient | 0.60 | Y | |
| 12 | - 1 onion, cut in thin wedges | ingredient | 0.60 | Y | |
| 13 | - 4 lime leaves | ingredient | 0.60 | Y | |
| 14 | - 1 cinnamon stick | ingredient | 0.95 | Y | |
| 15 | - 1 tbsp tamarind paste | ingredient | 0.95 | Y | |
| 16 | - 1 tbsp palm or soft light brown sugar | ingredient | 0.95 | Y | |
| 17 | - 1 tbsp fish sauce | ingredient | 0.95 | Y | |
| 18 | - 1 red chilli, deseeded and finely sliced | ingredient | 0.60 | Y | |
| 19 | - Jasmine rice to serve | ingredient | 0.30 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Heat oven to 200C/180C fan/gas 6. Roast the peanuts on a baking tray for 5 mi | instruction | 0.70 | Y | |
| 22 | 2. Heat 2 tbsp coconut cream in a large casserole dish with a lid. Add the curry | instruction | 0.70 | Y | |
| 23 | 3. Stir in the rest of the coconut with half a tin of water, the potatoes, onion | instruction | 0.60 | Y | |
| 24 | 4. Bring to a simmer, then cover and cook for 2 hrs in the oven until the beef i | instruction | 0.30 | Y | |
| 25 | 5. Sprinkle with sliced chilli and the remaining peanuts, then serve straight fr | instruction | 0.60 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 85g peanuts | 85 | g | peanuts | 1.00 | regex | Y | |
| 8 | - 400ml tin coconut cream | 400 | ml | tin coconut cream | 1.00 | regex | Y | |
| 9 | - 4 tbsp massaman curry paste | 4 | tbsp | massaman curry paste | 1.00 | regex | Y | |
| 10 | - 600g stewing beef, cut into strips | 600 | g | stewing beef, cut into strips | 1.00 | regex | Y | |
| 11 | - 450g waxy potatoes | 450 | g | waxy potatoes | 1.00 | regex | Y | |
| 12 | - 1 onion, cut in thin wedges | 1 | — | onion , cut in thin wedges | 0.92 | regex | Y | |
| 13 | - 4 lime leaves | 4 | — | lime leaves | 0.92 | regex | Y | |
| 14 | - 1 cinnamon stick | 1 | — | cinnamon stick | 0.92 | regex | Y | |
| 15 | - 1 tbsp tamarind paste | 1 | tbsp | tamarind paste | 1.00 | regex | Y | |
| 16 | - 1 tbsp palm or soft light brown sugar | 1 | tbsp | palm or soft light brown sugar | 1.00 | regex | Y | |
| 17 | - 1 tbsp fish sauce | 1 | tbsp | fish sauce | 1.00 | regex | Y | |
| 18 | - 1 red chilli, deseeded and finely sliced | 1 | — | red chilli, deseeded and finel | 0.92 | regex | Y | |
| 19 | - Jasmine rice to serve | — | — | jasmine rice | 0.99 | ml | Y | |

---

## international-07-madeira-cake

**Category**: international | **Lines**: 26 | **Ingredients found**: 8

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Madeira Cake | title | 0.70 | Y | |
| 2 | Servings: 8 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 30-40 minutes | instruction | 0.50 | Y | |
| 5 | Oven: 180C / 350F / Gas 4 | metadata | 0.60 | Y | |
| 6 | Ingredients: | sectionHeader | 0.90 | Y | |
| 7 | - 175g butter | ingredient | 0.60 | Y | |
| 8 | - 175g caster sugar | ingredient | 0.60 | Y | |
| 9 | - 3 eggs | ingredient | 0.60 | Y | |
| 10 | - 250g self-raising flour | ingredient | 0.60 | Y | |
| 11 | - 3 tbs milk | ingredient | 0.95 | Y | |
| 12 | - Zest of 1 lemon | ingredient | 0.30 | Y | |
| 13 | - Mixed peel to glaze | ingredient | 0.30 | Y | |
| 14 | Instructions: | sectionHeader | 0.90 | Y | |
| 15 | 1. Pre-heat the oven to 180C/350F/Gas 4. Grease an 18cm round cake tin, line the | instruction | 0.30 | Y | |
| 16 | 2. Cream the butter and sugar together in a bowl until pale and fluffy. | ingredient | 0.40 | Y | |
| 17 | 3. Beat in the eggs, one at a time, beating the mixture well between each one an | instruction | 0.60 | Y | |
| 18 | 4. Sift the flour and gently fold in, with enough milk to give a mixture that fa | instruction | 0.30 | Y | |
| 19 | 5. Spoon the mixture into the prepared tin and lightly level the top. | instruction | 0.30 | Y | |
| 20 | 6. Bake on the middle shelf for 30-40 minutes, or until golden-brown on top and  | instruction | 0.70 | Y | |
| 21 | 7. Remove and set aside to cool in the tin for 10 minutes, then turn out onto a  | instruction | 0.70 | Y | |
| 22 | 8. Decorate with the candied peel. | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 7 | - 175g butter | 175 | g | butter | 1.00 | regex | Y | |
| 8 | - 175g caster sugar | 175 | g | caster sugar | 1.00 | regex | Y | |
| 9 | - 3 eggs | 3 | — | egg s | 0.92 | regex | Y | |
| 10 | - 250g self-raising flour | 250 | g | self-raising flour | 1.00 | regex | Y | |
| 11 | - 3 tbs milk | 3 | tbsp | milk | 1.00 | regex | Y | |
| 12 | - Zest of 1 lemon | 1 | — | lemon | 0.95 | regex | Y | |
| 13 | - Mixed peel to glaze | — | — | mixed peel | 0.93 | ml | Y | |
| 16 | 2. Cream the butter and sugar together in a bowl until pale  | 2 | — | cream the butter and sugar | 0.59 | ml | Y | |

---

## international-08-thai-green-chicken-soup

**Category**: international | **Lines**: 30 | **Ingredients found**: 14

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Thai Green Chicken Soup | title | 0.70 | Y | |
| 2 | Servings: 6 | metadata | 0.70 | Y | |
| 3 | Prep Time: 10 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 25 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 tbs sunflower oil | ingredient | 0.95 | Y | |
| 7 | - 1 chopped onion | ingredient | 0.60 | Y | |
| 8 | - 500g chicken thighs | ingredient | 0.60 | Y | |
| 9 | - 4 sliced garlic cloves | ingredient | 0.95 | Y | |
| 10 | - 280g Thai green curry paste | ingredient | 0.60 | Y | |
| 11 | - 400ml coconut milk | ingredient | 0.60 | Y | |
| 12 | - 2 litres chicken stock | ingredient | 0.60 | Y | |
| 13 | - 5 lime leaves | ingredient | 0.60 | Y | |
| 14 | - 2 tbs fish sauce | ingredient | 0.95 | Y | |
| 15 | - 1 bunch spring onions | ingredient | 0.95 | Y | |
| 16 | - 280g green beans | ingredient | 0.60 | Y | |
| 17 | - 150g bamboo shoots | ingredient | 0.60 | Y | |
| 18 | - Juice of 2 limes | ingredient | 0.30 | Y | |
| 19 | - Bunch of basil | ingredient | 0.45 | Y | |
| 20 | Instructions: | sectionHeader | 0.90 | Y | |
| 21 | 1. Heat the oil in your largest pan, add the onion and fry for 3 mins to soften. | instruction | 0.70 | Y | |
| 22 | 2. Add the curry paste, coconut milk, stock, lime leaves and fish sauce, then si | instruction | 0.70 | Y | |
| 23 | 3. Add the chopped onion tops, green beans and bamboo shoots and cook for 4-6 mi | instruction | 0.70 | Y | |
| 24 | 4. Put the lime juice and basil in a narrow jug and blitz with a hand blender to | instruction | 0.30 | Y | |
| 25 | 5. Pour into the soup with the sliced spring onion and heat through. | instruction | 0.60 | Y | |
| 26 | 6. Serve with lime wedges for a light lunch or supper. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 tbs sunflower oil | 2 | tbsp | sunflower oil | 1.00 | regex | Y | |
| 7 | - 1 chopped onion | 1 | — | chopped onion | 0.92 | regex | Y | |
| 8 | - 500g chicken thighs | 500 | g | chicken thighs | 1.00 | regex | Y | |
| 9 | - 4 sliced garlic cloves | 4 | — | sliced garlic cloves | 0.92 | regex | Y | |
| 10 | - 280g Thai green curry paste | 280 | g | Thai green curry paste | 1.00 | regex | Y | |
| 11 | - 400ml coconut milk | 400 | ml | coconut milk | 1.00 | regex | Y | |
| 12 | - 2 litres chicken stock | 2 | — | litres chicken stock | 0.92 | regex | Y | |
| 13 | - 5 lime leaves | 5 | — | lime leaves | 0.92 | regex | Y | |
| 14 | - 2 tbs fish sauce | 2 | tbsp | fish sauce | 1.00 | regex | Y | |
| 15 | - 1 bunch spring onions | 1 | bunch | spring onions | 1.00 | regex | Y | |
| 16 | - 280g green beans | 280 | g | green beans | 1.00 | regex | Y | |
| 17 | - 150g bamboo shoots | 150 | g | bamboo shoots | 1.00 | regex | Y | |
| 18 | - Juice of 2 limes | 2 | — | limes | 0.95 | regex | Y | |
| 19 | - Bunch of basil | 1 | — | basil | 0.95 | regex | Y | |

---

## international-09-red-peas-soup

**Category**: international | **Lines**: 31 | **Ingredients found**: 15

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Red Peas Soup | title | 0.70 | Y | |
| 2 | Servings: 8 | metadata | 0.70 | Y | |
| 3 | Prep Time: Overnight soaking plus 20 minutes | unknown | 0.10 | Y | |
| 4 | Cook Time: 2 hours | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 cups kidney beans | ingredient | 0.95 | Y | |
| 7 | - 1 large carrot | ingredient | 0.60 | Y | |
| 8 | - 2 chopped spring onions | ingredient | 0.60 | Y | |
| 9 | - 4 sprigs thyme | ingredient | 0.95 | Y | |
| 10 | - 1 diced onion | ingredient | 0.60 | Y | |
| 11 | - 1/2 tsp black pepper | ingredient | 0.95 | Y | |
| 12 | - 2 chopped red peppers | ingredient | 0.60 | Y | |
| 13 | - 4 mashed garlic cloves | ingredient | 0.95 | Y | |
| 14 | - 1 tbs allspice | ingredient | 0.95 | Y | |
| 15 | - 900g beef | ingredient | 0.60 | Y | |
| 16 | - 2L water | ingredient | 0.60 | Y | |
| 17 | - 4 potatoes | ingredient | 0.60 | Y | |
| 18 | - 1 cup plain flour | ingredient | 0.95 | Y | |
| 19 | - 1/4 cup water | ingredient | 0.95 | Y | |
| 20 | - 1 cup coconut milk | ingredient | 0.95 | Y | |
| 21 | Instructions: | sectionHeader | 0.90 | Y | |
| 22 | 1. Wash and soak the kidney beans overnight in plenty of water. Drain. | instruction | 0.60 | Y | |
| 23 | 2. Place everything except the flour, potato and coconut milk in a large pot. Co | instruction | 0.70 | Y | |
| 24 | 3. Add the potato and coconut milk and continue cooking for 15 minutes. | instruction | 0.70 | Y | |
| 25 | 4. Make basic dough for spinner dumplings: mix the flour and water with a pinch  | instruction | 0.30 | Y | |
| 26 | 5. Add dumplings to the pot, stir well and continue cooking for another 15 minut | instruction | 0.70 | Y | |
| 27 | 6. Taste and adjust seasoning. The salt from the pigtails should season the dish | instruction | 0.30 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 cups kidney beans | 2 | cup | kidney beans | 1.00 | regex | Y | |
| 7 | - 1 large carrot | 1 | — | large carrot | 0.92 | regex | Y | |
| 8 | - 2 chopped spring onions | 2 | — | chopped spring onions | 0.92 | regex | Y | |
| 9 | - 4 sprigs thyme | 4 | sprig | thyme | 1.00 | regex | Y | |
| 10 | - 1 diced onion | 1 | — | diced onion | 0.92 | regex | Y | |
| 11 | - 1/2 tsp black pepper | 0.5 | tsp | black pepper | 1.00 | regex | Y | |
| 12 | - 2 chopped red peppers | 2 | — | chopped red peppers | 0.92 | regex | Y | |
| 13 | - 4 mashed garlic cloves | 4 | — | mashed garlic cloves | 0.92 | regex | Y | |
| 14 | - 1 tbs allspice | 1 | tbsp | allspice | 1.00 | regex | Y | |
| 15 | - 900g beef | 900 | g | beef | 1.00 | regex | Y | |
| 16 | - 2L water | 2 | l | water | 1.00 | regex | Y | |
| 17 | - 4 potatoes | 4 | — | potatoe s | 0.92 | regex | Y | |
| 18 | - 1 cup plain flour | 1 | cup | plain flour | 1.00 | regex | Y | |
| 19 | - 1/4 cup water | 0.25 | cup | water | 1.00 | regex | Y | |
| 20 | - 1 cup coconut milk | 1 | cup | coconut milk | 1.00 | regex | Y | |

---

## international-10-fish-soup-ukha

**Category**: international | **Lines**: 24 | **Ingredients found**: 9

### Classification

| # | Text | Classified | Conf | Correct? | Correction |
|---|------|-----------|------|----------|------------|
| 1 | Fish Soup (Ukha) | title | 0.70 | Y | |
| 2 | Servings: 4 | metadata | 0.70 | Y | |
| 3 | Prep Time: 15 minutes | metadata | 0.70 | Y | |
| 4 | Cook Time: 30 minutes | metadata | 0.70 | Y | |
| 5 | Ingredients: | sectionHeader | 0.90 | Y | |
| 6 | - 2 tbs olive oil | ingredient | 0.95 | Y | |
| 7 | - 1 sliced onion | ingredient | 0.60 | Y | |
| 8 | - 2 medium carrots | ingredient | 0.60 | Y | |
| 9 | - 750ml fish stock | ingredient | 0.60 | Y | |
| 10 | - 750ml water | ingredient | 0.60 | Y | |
| 11 | - 4 large potatoes | ingredient | 0.60 | Y | |
| 12 | - 3 bay leaves | ingredient | 0.60 | Y | |
| 13 | - 1 whole cod fillet | ingredient | 0.60 | Y | |
| 14 | - 1 whole salmon fillet | ingredient | 0.60 | Y | |
| 15 | Instructions: | sectionHeader | 0.90 | Y | |
| 16 | 1. In a medium pot, heat the olive oil over medium-high heat. Add the onions and | instruction | 0.30 | Y | |
| 17 | 2. Add the stock, water, potatoes, bay leaves, and black peppercorns. Season wit | instruction | 0.70 | Y | |
| 18 | 3. Add the millet and cook for 15 more minutes until millet and potatoes are coo | instruction | 0.60 | Y | |
| 19 | 4. Gently add the fish cubes. Stir and bring the soup to a simmer. The fish will | instruction | 0.30 | Y | |
| 20 | 5. Garnish with chopped fresh dill or parsley before serving. | instruction | 0.40 | Y | |

### Parsing (ingredient lines)

| # | Text | Qty | Unit | Name | Conf | Parser | Correct? | Correction |
|---|------|-----|------|------|------|--------|----------|------------|
| 6 | - 2 tbs olive oil | 2 | tbsp | olive oil | 1.00 | regex | Y | |
| 7 | - 1 sliced onion | 1 | — | sliced onion | 0.92 | regex | Y | |
| 8 | - 2 medium carrots | 2 | — | medium carrots | 0.92 | regex | Y | |
| 9 | - 750ml fish stock | 750 | ml | fish stock | 1.00 | regex | Y | |
| 10 | - 750ml water | 750 | ml | water | 1.00 | regex | Y | |
| 11 | - 4 large potatoes | 4 | — | large potatoes | 0.92 | regex | Y | |
| 12 | - 3 bay leaves | 3 | — | bay leaves | 0.92 | regex | Y | |
| 13 | - 1 whole cod fillet | 1 | — | whole cod fillet | 0.92 | regex | Y | |
| 14 | - 1 whole salmon fillet | 1 | — | whole salmon fillet | 0.92 | regex | Y | |

---

