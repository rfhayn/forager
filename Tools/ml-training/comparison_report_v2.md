# M16.9.4: Model Comparison Report — v1.0 vs v2.0

**Generated**: 2026-03-27 17:44
**v1 vocabulary**: 5,372 words
**v2 vocabulary**: 5,454 words (+82)

## Overview

| Metric | v1.0 | v2.0 | Delta | Status |
|--------|------|------|-------|--------|
| Strangetom token accuracy | 98.49% | 98.54% | +0.05% | stable |
| Strangetom sentence accuracy | 95.40% | 95.34% | -0.06% | stable |
| Harness token accuracy | 65.77% | 79.22% | +13.45% | improved |
| Harness sentence accuracy | 15.91% | 49.24% | +33.33% | improved |

## Per-Class F1 Comparison

### Strangetom Test Set

| Label | v1.0 F1 | v2.0 F1 | Delta | Status |
|-------|---------|---------|-------|--------|
| QTY | 0.9968 | 0.9970 | +0.0002 | stable |
| UNIT | 0.9939 | 0.9942 | +0.0003 | stable |
| NAME | 0.9869 | 0.9872 | +0.0003 | stable |
| MODIFIER | 0.9261 | 0.9283 | +0.0022 | improved |
| PREP | 0.9789 | 0.9790 | +0.0000 | stable |
| COMMENT | 0.9463 | 0.9486 | +0.0023 | improved |
| OTHER | 0.9997 | 0.9994 | -0.0004 | stable |

### Harness Test Set

| Label | v1.0 F1 | v2.0 F1 | Delta | Status |
|-------|---------|---------|-------|--------|
| QTY | 0.8453 | 0.9622 | +0.1169 | improved |
| UNIT | 0.7857 | 0.9352 | +0.1495 | improved |
| NAME | 0.8445 | 0.9082 | +0.0637 | improved |
| MODIFIER | 0.3929 | 0.7164 | +0.3236 | improved |
| PREP | 0.3422 | 0.4103 | +0.0680 | improved |
| COMMENT | 0.1695 | 0.3226 | +0.1531 | improved |
| OTHER | 0.5517 | 0.7084 | +0.1567 | improved |

## Sentence-Level Comparison — Strangetom Test

| Category | Count | % |
|----------|-------|---|
| Both correct | 621 | 9.0% |
| v2 improved (v1 wrong, v2 better) | 46 | 0.7% |
| v2 regressed (v1 right, v2 wrong) | 33 | 0.5% |
| Both wrong | 6185 | 89.8% |

### Per-Label Token Changes — Strangetom

| Label | Improved | Regressed | Unchanged | Net |
|-------|----------|-----------|-----------|-----|
| QTY | 5 | 3 | 7731 | +2 |
| UNIT | 4 | 6 | 6481 | -2 |
| NAME | 49 | 23 | 12840 | +26 |
| MODIFIER | 0 | 0 | 539 | 0 |
| PREP | 5 | 3 | 4471 | +2 |
| COMMENT | 5 | 9 | 2198 | -4 |
| OTHER | 0 | 0 | 4518 | 0 |

## Sentence-Level Comparison — Harness Test

| Category | Count | % |
|----------|-------|---|
| Both correct | 6 | 4.5% |
| v2 improved (v1 wrong, v2 better) | 31 | 23.5% |
| v2 regressed (v1 right, v2 wrong) | 9 | 6.8% |
| Both wrong | 86 | 65.2% |

### Per-Label Token Changes — Harness

| Label | Improved | Regressed | Unchanged | Net |
|-------|----------|-----------|-----------|-----|
| QTY | 17 | 0 | 170 | +17 |
| UNIT | 13 | 0 | 84 | +13 |
| NAME | 2 | 13 | 224 | -11 |
| MODIFIER | 2 | 0 | 37 | +2 |
| PREP | 3 | 0 | 54 | +3 |
| COMMENT | 0 | 0 | 5 | 0 |
| OTHER | 19 | 4 | 133 | +15 |

## Regressions — Strangetom (33 sentences)

### Regression 1: 5/11 -> 4/11
```
Tokens: 1 12 ounce can or jar imported tuna in olive oil
True:   QTY QTY UNIT UNIT COMMENT COMMENT NAME NAME NAME NAME NAME
v1:     QTY UNIT OTHER COMMENT COMMENT COMMENT OTHER NAME NAME
v2:     QTY UNIT OTHER COMMENT COMMENT UNIT OTHER NAME NAME
Diffs at positions: [5]
```

### Regression 2: 2/12 -> 1/12
```
Tokens: Enough fresh or frozen ginger to yield 1 tablespoon , coarsely grated
True:   MODIFIER NAME NAME NAME NAME COMMENT COMMENT QTY UNIT OTHER PREP PREP
v1:     QTY UNIT COMMENT NAME NAME NAME NAME NAME NAME NAME
v2:     QTY UNIT COMMENT PREP NAME NAME NAME NAME NAME NAME
Diffs at positions: [3]
```

### Regression 3: 9/16 -> 8/16
```
Tokens: 3 cm / 1.25 in piece fresh root ginger , peeled and cut into thin matchsticks
True:   QTY UNIT OTHER QTY UNIT UNIT NAME NAME NAME OTHER PREP PREP PREP PREP PREP PREP
v1:     QTY UNIT OTHER QTY UNIT OTHER NAME NAME OTHER PREP PREP PREP
v2:     QTY UNIT OTHER QTY UNIT OTHER NAME NAME OTHER QTY UNIT PREP
Diffs at positions: [9, 10]
```

### Regression 4: 9/9 -> 8/9
```
Tokens: 20-24 oven ready lasagna noodles ( 2 box )
True:   QTY NAME NAME NAME NAME OTHER QTY UNIT OTHER
v1:     QTY NAME NAME NAME NAME OTHER QTY UNIT OTHER
v2:     QTY UNIT NAME NAME NAME OTHER QTY UNIT OTHER
Diffs at positions: [1]
```

### Regression 5: 4/4 -> 3/4
```
Tokens: 2 tbsp canned sweetcorn
True:   QTY UNIT NAME NAME
v1:     QTY UNIT NAME NAME NAME
v2:     QTY UNIT PREP NAME NAME
Diffs at positions: [2]
```

### Regression 6: 6/6 -> 5/6
```
Tokens: 1 ( generous ) cup buttermilk
True:   QTY OTHER COMMENT OTHER UNIT NAME
v1:     QTY OTHER COMMENT OTHER UNIT NAME
v2:     QTY OTHER UNIT OTHER UNIT NAME
Diffs at positions: [2]
```

### Regression 7: 7/7 -> 6/7
```
Tokens: 0.5 cup Triple Sec or orange liqueur
True:   QTY UNIT NAME NAME NAME NAME NAME
v1:     QTY UNIT NAME NAME NAME NAME NAME
v2:     QTY UNIT MODIFIER NAME NAME NAME NAME
Diffs at positions: [2]
```

### Regression 8: 3/9 -> 2/9
```
Tokens: 15 g / 0.5 oz fresh sorrel or basil
True:   QTY UNIT OTHER QTY UNIT MODIFIER NAME NAME NAME
v1:     QTY UNIT NAME NAME NAME NAME OTHER NAME OTHER COMMENT COMMENT COMMENT
v2:     QTY UNIT NAME NAME NAME NAME OTHER COMMENT OTHER COMMENT COMMENT COMMENT
Diffs at positions: [7]
```

### Regression 9: 2/7 -> 0/7
```
Tokens: a lightly heaped teaspoon Chinese five-spice powder
True:   COMMENT COMMENT COMMENT UNIT NAME NAME NAME
v1:     QTY UNIT NAME NAME OTHER NAME NAME NAME NAME OTHER COMMENT COMMENT COMMENT
v2:     QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT OTHER COMMENT COMMENT COMMENT
Diffs at positions: [5, 6]
```

### Regression 10: 2/13 -> 1/13
```
Tokens: 3 cup Chinese chives or scallion greens , cut into 1 inch section
True:   QTY UNIT NAME NAME NAME NAME NAME OTHER PREP PREP PREP PREP PREP
v1:     QTY QTY QTY UNIT UNIT NAME OTHER PREP
v2:     COMMENT QTY QTY UNIT UNIT NAME OTHER PREP
Diffs at positions: [0]
```

### Regression 11: 1/5 -> 0/5
```
Tokens: 4 slice smoked mozzarella cheese
True:   QTY UNIT NAME NAME NAME
v1:     QTY NAME OTHER COMMENT COMMENT OTHER OTHER PREP PREP PREP OTHER PREP PREP PREP PREP PREP PREP PREP OTHER PREP PREP OTHER PREP PREP PREP PREP
v2:     NAME NAME OTHER COMMENT COMMENT OTHER OTHER PREP PREP PREP OTHER PREP PREP PREP PREP PREP PREP PREP OTHER PREP PREP OTHER PREP PREP PREP PREP
Diffs at positions: [0]
```

### Regression 12: 4/22 -> 3/22
```
Tokens: 1 7 pound breast of veal ( have the butcher cut across the breast to make six strip of equal width )
True:   QTY QTY UNIT NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT OTHER
v1:     QTY UNIT NAME NAME NAME NAME NAME
v2:     QTY UNIT MODIFIER MODIFIER NAME NAME NAME
Diffs at positions: [2, 3]
```

### Regression 13: 4/11 -> 2/11
```
Tokens: Fresh or frozen ginger to yield 1 tablespoon , coarsely grated
True:   NAME NAME NAME NAME COMMENT COMMENT QTY UNIT OTHER PREP PREP
v1:     QTY UNIT NAME NAME COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT
v2:     QTY UNIT NAME NAME NAME NAME COMMENT COMMENT COMMENT COMMENT COMMENT
Diffs at positions: [4, 5]
```

### Regression 14: 3/4 -> 1/4
```
Tokens: 0.25 cup apple-cider vinegar
True:   QTY UNIT NAME NAME
v1:     QTY UNIT COMMENT NAME NAME NAME OTHER PREP PREP PREP
v2:     OTHER OTHER OTHER NAME NAME NAME OTHER OTHER OTHER OTHER
Diffs at positions: [0, 1, 2]
```

### Regression 15: 2/14 -> 1/14
```
Tokens: 75 g / 2.5 oz coarse dried white breadcrumbs , preferably Japanese panko breadcrumbs
True:   QTY UNIT OTHER QTY UNIT NAME NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT
v1:     QTY UNIT NAME UNIT OTHER PREP PREP PREP PREP PREP
v2:     QTY MODIFIER NAME UNIT OTHER PREP PREP PREP PREP PREP
Diffs at positions: [1]
```

### Regression 16: 2/3 -> 1/3
```
Tokens: 0.5 cup cilantro
True:   QTY UNIT NAME
v1:     QTY UNIT UNIT COMMENT NAME NAME OTHER COMMENT QTY UNIT COMMENT
v2:     QTY NAME UNIT COMMENT NAME NAME OTHER COMMENT QTY UNIT COMMENT
Diffs at positions: [1]
```

### Regression 17: 3/6 -> 1/6
```
Tokens: 2 large overripe bananas , mashed
True:   QTY MODIFIER NAME NAME OTHER PREP
v1:     QTY UNIT NAME NAME NAME NAME NAME NAME NAME NAME
v2:     QTY UNIT MODIFIER MODIFIER NAME NAME NAME NAME NAME NAME
Diffs at positions: [2, 3]
```

### Regression 18: 3/12 -> 1/12
```
Tokens: 4 ripe plum tomatoes , cored and cut into 0.5 inch cube
True:   QTY NAME NAME NAME OTHER PREP PREP PREP PREP PREP PREP PREP
v1:     QTY UNIT NAME NAME NAME NAME
v2:     QTY UNIT PREP PREP NAME NAME
Diffs at positions: [2, 3]
```

### Regression 19: 3/4 -> 2/4
```
Tokens: 2 teaspoon sesame oil
True:   QTY UNIT NAME NAME
v1:     QTY UNIT COMMENT NAME
v2:     QTY COMMENT COMMENT NAME
Diffs at positions: [1]
```

### Regression 20: 4/9 -> 3/9
```
Tokens: 0.25 pound mushrooms , cut in very small cube
True:   QTY UNIT NAME OTHER PREP PREP PREP PREP PREP
v1:     QTY NAME NAME OTHER PREP OTHER COMMENT COMMENT COMMENT OTHER
v2:     QTY NAME NAME OTHER NAME OTHER COMMENT COMMENT COMMENT OTHER
Diffs at positions: [4]
```


## Regressions — Harness (9 sentences)

### Regression 1: 1/1 -> 0/1
```
Tokens: salt
True:   NAME
v1:     NAME NAME OTHER NAME NAME NAME OTHER NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT OTHER
v2:     QTY NAME OTHER NAME NAME NAME OTHER NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT OTHER
Diffs at positions: [0]
```

### Regression 2: 4/8 -> 2/8
```
Tokens: 1 tokyo negi ( long green onion )
True:   QTY NAME NAME OTHER PREP PREP PREP OTHER
v1:     QTY NAME NAME NAME NAME OTHER QTY OTHER QTY UNIT OTHER COMMENT OTHER OTHER COMMENT COMMENT
v2:     QTY UNIT MODIFIER NAME NAME OTHER PREP PREP PREP PREP OTHER OTHER OTHER OTHER PREP PREP
Diffs at positions: [1, 2, 6, 7]
```

### Regression 3: 2/4 -> 1/4
```
Tokens: pinch red pepper flakes
True:   PREP NAME NAME NAME
v1:     QTY UNIT NAME NAME COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT
v2:     QTY UNIT MODIFIER NAME NAME OTHER OTHER OTHER MODIFIER NAME
Diffs at positions: [2]
```

### Regression 4: 4/6 -> 3/6
```
Tokens: 2 heaping cups halved cherry tomatoes
True:   QTY OTHER UNIT OTHER NAME NAME
v1:     QTY OTHER QTY UNIT NAME NAME
v2:     QTY QTY QTY UNIT NAME NAME
Diffs at positions: [1]
```

### Regression 5: 4/6 -> 3/6
```
Tokens: 0 . 5 teaspoon ground cinnamon
True:   OTHER OTHER OTHER UNIT NAME NAME
v1:     COMMENT OTHER QTY UNIT NAME NAME
v2:     QTY QTY QTY UNIT NAME NAME
Diffs at positions: [0, 1]
```

### Regression 6: 2/10 -> 1/10
```
Tokens: yogurt , avocado , and green onion , for serving
True:   NAME NAME NAME NAME NAME NAME NAME OTHER COMMENT PREP
v1:     QTY MODIFIER NAME NAME OTHER PREP
v2:     QTY MODIFIER NAME OTHER OTHER PREP
Diffs at positions: [3]
```

### Regression 7: 3/10 -> 2/10
```
Tokens: red radish or jicama slices for garnish ( optional )
True:   NAME NAME NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER
v1:     QTY NAME NAME NAME
v2:     QTY UNIT NAME NAME
Diffs at positions: [1]
```

### Regression 8: 2/6 -> 1/6
```
Tokens: 3 garlic cloves ( minced )
True:   QTY NAME OTHER OTHER PREP OTHER
v1:     QTY NAME NAME NAME
v2:     QTY UNIT NAME NAME
Diffs at positions: [1]
```

### Regression 9: 3/10 -> 2/10
```
Tokens: 2 15oz . cans cannellini beans , drained and rinsed
True:   QTY UNIT OTHER OTHER NAME NAME OTHER OTHER OTHER OTHER
v1:     QTY QTY OTHER QTY UNIT NAME
v2:     QTY QTY QTY QTY UNIT NAME
Diffs at positions: [2]
```


## Improvements — Strangetom (showing 15 of 46)

### Improvement 1: 4/12 -> 7/12
```
Tokens: 1 red pepper , core and seeds removed and sliced into strip
True:   QTY NAME NAME OTHER PREP PREP PREP PREP PREP PREP PREP PREP
v1:     QTY NAME NAME NAME NAME NAME OTHER PREP OTHER COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT OTHER
v2:     QTY NAME NAME NAME NAME NAME OTHER PREP OTHER PREP PREP PREP PREP PREP PREP OTHER
```

### Improvement 2: 4/5 -> 5/5
```
Tokens: 3 cup quick baking mix
True:   QTY UNIT NAME NAME NAME
v1:     QTY UNIT NAME NAME PREP PREP PREP PREP PREP PREP PREP
v2:     QTY UNIT NAME NAME NAME NAME NAME NAME NAME NAME NAME
```

### Improvement 3: 0/8 -> 3/8
```
Tokens: Heaped 0.5 cup barley or brown whole-grain barley
True:   UNIT QTY UNIT NAME NAME NAME NAME NAME
v1:     QTY UNIT NAME OTHER COMMENT COMMENT COMMENT OTHER NAME
v2:     QTY UNIT NAME OTHER NAME NAME NAME OTHER NAME
```

### Improvement 4: 0/12 -> 1/12
```
Tokens: 1 large handful chopped fresh coriander or flatleaf parsley , to garnish
True:   QTY UNIT UNIT PREP MODIFIER NAME NAME NAME NAME OTHER COMMENT COMMENT
v1:     NAME NAME NAME OTHER COMMENT COMMENT COMMENT
v2:     QTY NAME NAME OTHER COMMENT COMMENT COMMENT
```

### Improvement 5: 3/16 -> 5/16
```
Tokens: 0.5 medium green bell pepper , stemmed , seeded , deribbed and cut in small dice
True:   QTY MODIFIER NAME NAME NAME OTHER PREP OTHER PREP OTHER PREP PREP PREP PREP PREP PREP
v1:     QTY UNIT COMMENT COMMENT NAME OTHER COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT
v2:     QTY UNIT NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT
```

### Improvement 6: 5/16 -> 8/16
```
Tokens: 0.3333333333333333 cup ( 83 ml ) crème fraïche or sour cream thinned with a little milk
True:   QTY UNIT OTHER QTY UNIT OTHER NAME NAME NAME NAME NAME PREP PREP PREP PREP PREP
v1:     QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT OTHER OTHER PREP PREP PREP
v2:     QTY UNIT NAME NAME OTHER NAME NAME NAME NAME OTHER OTHER PREP PREP PREP
```

### Improvement 7: 4/9 -> 6/9
```
Tokens: 1 tablespoon granulated sugar , for caramelizing the top
True:   QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT
v1:     QTY UNIT UNIT NAME OTHER NAME NAME OTHER PREP PREP
v2:     QTY UNIT UNIT NAME OTHER COMMENT COMMENT OTHER PREP PREP
```

### Improvement 8: 6/9 -> 9/9
```
Tokens: 2 tablespoon raspberry eau-de-vie ( white raspberry brandy )
True:   QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT OTHER
v1:     QTY UNIT NAME NAME OTHER NAME NAME NAME OTHER
v2:     QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT OTHER
```

### Improvement 9: 1/16 -> 2/16
```
Tokens: 1 ( 2.1 ounce ) bar chocolate-covered crispy peanut-buttery candy , unwrapped , finely crushed *
True:   QTY OTHER QTY UNIT OTHER UNIT NAME NAME NAME NAME OTHER PREP OTHER PREP PREP OTHER
v1:     QTY NAME NAME OTHER COMMENT COMMENT COMMENT OTHER COMMENT COMMENT COMMENT OTHER COMMENT COMMENT COMMENT COMMENT
v2:     QTY NAME NAME OTHER QTY NAME NAME OTHER COMMENT COMMENT COMMENT OTHER COMMENT COMMENT COMMENT COMMENT
```

### Improvement 10: 4/5 -> 5/5
```
Tokens: 4 cup dry red wine
True:   QTY UNIT NAME NAME NAME
v1:     QTY UNIT MODIFIER NAME NAME NAME OTHER COMMENT QTY UNIT OTHER OTHER PREP PREP PREP
v2:     QTY UNIT NAME NAME NAME NAME OTHER COMMENT QTY UNIT OTHER OTHER PREP PREP PREP
```

### Improvement 11: 3/11 -> 6/11
```
Tokens: 2 Maui , Vidalia or other sweet onions , coarsely chopped
True:   QTY NAME OTHER NAME NAME NAME NAME NAME OTHER PREP PREP
v1:     NAME NAME OTHER PREP NAME OTHER COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT COMMENT
v2:     NAME NAME OTHER NAME NAME OTHER NAME NAME NAME NAME COMMENT COMMENT COMMENT COMMENT COMMENT
```

### Improvement 12: 2/7 -> 5/7
```
Tokens: 3 cup hot cooked regular brown rice
True:   QTY UNIT PREP PREP NAME NAME NAME
v1:     QTY UNIT NAME NAME PREP PREP PREP PREP PREP PREP PREP
v2:     QTY UNIT NAME NAME NAME NAME NAME NAME NAME NAME NAME
```

### Improvement 13: 1/11 -> 2/11
```
Tokens: Enough fresh or frozen ginger to make 2 teaspoon coarsely grated
True:   COMMENT NAME NAME NAME NAME COMMENT COMMENT QTY UNIT PREP PREP
v1:     QTY PREP NAME
v2:     QTY NAME NAME
```

### Improvement 14: 2/9 -> 4/9
```
Tokens: 1.25 tsp sea salt , plus more if needed
True:   QTY UNIT NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT
v1:     QTY UNIT PREP PREP NAME
v2:     QTY UNIT NAME NAME NAME
```

### Improvement 15: 2/5 -> 3/5
```
Tokens: 2 tbsp finely chopped carrot
True:   QTY UNIT PREP PREP NAME
v1:     QTY UNIT MODIFIER MODIFIER MODIFIER NAME OTHER NAME NAME OTHER NAME NAME NAME
v2:     QTY UNIT NAME NAME NAME NAME OTHER NAME NAME OTHER NAME NAME NAME
```


## Improvements — Harness (showing 15 of 31)

### Improvement 1: 7/29 -> 8/29
```
Tokens: 4-5 ears of sweet corn , kernels removed from the cobs ( about 3 cups ) , cobs reserved ( see steps for taking corn off the cob )
True:   QTY UNIT OTHER NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
v1:     QTY UNIT MODIFIER NAME OTHER NAME NAME OTHER NAME NAME NAME OTHER OTHER PREP PREP PREP OTHER PREP PREP
v2:     QTY UNIT MODIFIER NAME OTHER NAME NAME OTHER NAME NAME NAME OTHER OTHER PREP PREP PREP OTHER OTHER PREP
```

### Improvement 2: 2/9 -> 4/9
```
Tokens: 1 teaspoon coarse salt ( more to taste )
True:   QTY UNIT OTHER NAME OTHER OTHER OTHER OTHER OTHER
v1:     QTY PREP PREP PREP NAME NAME NAME NAME OTHER COMMENT QTY OTHER QTY UNIT UNIT COMMENT COMMENT OTHER
v2:     QTY UNIT OTHER OTHER NAME NAME NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
```

### Improvement 3: 5/18 -> 7/18
```
Tokens: 1 small red onion , root and tip ends removed and cut into 1 / 4-inch thick wedges
True:   QTY MODIFIER NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER UNIT OTHER OTHER
v1:     QTY OTHER QTY UNIT OTHER QTY UNIT OTHER COMMENT OTHER NAME NAME OTHER PREP PREP PREP PREP
v2:     QTY QTY QTY UNIT OTHER OTHER OTHER OTHER UNIT OTHER MODIFIER NAME OTHER PREP PREP PREP PREP
```

### Improvement 4: 2/3 -> 3/3
```
Tokens: 3 cups milk
True:   QTY UNIT NAME
v1:     QTY NAME NAME OTHER COMMENT COMMENT COMMENT OTHER COMMENT COMMENT COMMENT COMMENT COMMENT OTHER
v2:     QTY UNIT NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
```

### Improvement 5: 4/13 -> 7/13
```
Tokens: 2-3 tablespoons gochujang sauce ( like this one ( affiliate link ) )
True:   QTY UNIT NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
v1:     QTY OTHER QTY UNIT MODIFIER NAME NAME OTHER PREP OTHER COMMENT OTHER COMMENT OTHER
v2:     QTY QTY QTY UNIT MODIFIER NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER
```

### Improvement 6: 5/6 -> 6/6
```
Tokens: 1 / 4 cup worcestershire sauce
True:   QTY QTY QTY UNIT NAME NAME
v1:     QTY OTHER QTY UNIT NAME NAME NAME OTHER COMMENT COMMENT COMMENT COMMENT COMMENT OTHER
v2:     QTY QTY QTY UNIT NAME NAME NAME OTHER PREP PREP PREP PREP PREP OTHER
```

### Improvement 7: 3/12 -> 6/12
```
Tokens: 2 cups ( packed ) cooked white rice ( day old )
True:   QTY UNIT OTHER OTHER OTHER MODIFIER NAME NAME OTHER OTHER OTHER OTHER
v1:     QTY NAME OTHER NAME NAME NAME OTHER COMMENT QTY OTHER QTY UNIT OTHER
v2:     QTY MODIFIER OTHER MODIFIER NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER
```

### Improvement 8: 1/8 -> 2/8
```
Tokens: 1 medium yellow or white onion , chopped
True:   QTY MODIFIER PREP PREP PREP NAME OTHER PREP
v1:     QTY NAME NAME NAME OTHER COMMENT COMMENT COMMENT OTHER COMMENT COMMENT OTHER OTHER
v2:     QTY UNIT NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
```

### Improvement 9: 6/18 -> 10/18
```
Tokens: 3 cups finely sliced red or green cabbage ( about 1 / 2 medium head of cabbage )
True:   QTY UNIT OTHER OTHER NAME NAME NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
v1:     QTY NAME OTHER COMMENT OTHER PREP NAME NAME OTHER COMMENT COMMENT OTHER
v2:     QTY UNIT OTHER OTHER OTHER OTHER NAME NAME OTHER OTHER OTHER OTHER
```

### Improvement 10: 4/6 -> 5/6
```
Tokens: 1 / 3 cup heavy cream
True:   QTY QTY QTY UNIT NAME NAME
v1:     QTY OTHER QTY UNIT COMMENT NAME NAME OTHER PREP PREP PREP
v2:     QTY QTY QTY UNIT OTHER NAME NAME OTHER PREP PREP PREP
```

### Improvement 11: 1/15 -> 3/15
```
Tokens: 1 / 4 teaspoon almond extract , optional , or the flavor of your choice
True:   QTY QTY QTY UNIT NAME NAME OTHER COMMENT OTHER PREP PREP PREP PREP PREP PREP
v1:     QTY NAME NAME OTHER PREP OTHER COMMENT OTHER COMMENT OTHER
v2:     QTY NAME NAME OTHER PREP OTHER OTHER OTHER OTHER OTHER
```

### Improvement 12: 3/8 -> 4/8
```
Tokens: 1 / 4 cup chopped cilantro for serving
True:   QTY QTY QTY UNIT OTHER NAME OTHER OTHER
v1:     QTY OTHER QTY UNIT NAME OTHER COMMENT COMMENT COMMENT COMMENT
v2:     QTY QTY QTY UNIT NAME OTHER PREP PREP PREP PREP
```

### Improvement 13: 4/19 -> 5/19
```
Tokens: 1 pound beef tenderloin , top sirloin , or skirt steak ) , slice into 1 / 8-inch-thick slices
True:   QTY UNIT NAME NAME NAME NAME NAME NAME NAME NAME NAME OTHER OTHER OTHER OTHER OTHER OTHER OTHER OTHER
v1:     QTY NAME NAME NAME NAME COMMENT COMMENT COMMENT COMMENT
v2:     QTY UNIT NAME NAME NAME PREP PREP PREP PREP
```

### Improvement 14: 3/9 -> 5/9
```
Tokens: 1-2 cups broth or water for thinning the sauce
True:   QTY UNIT NAME NAME NAME OTHER OTHER OTHER OTHER
v1:     QTY NAME NAME OTHER COMMENT COMMENT COMMENT OTHER
v2:     QTY NAME NAME OTHER OTHER OTHER OTHER OTHER
```

### Improvement 15: 4/8 -> 5/8
```
Tokens: 1 / 2 cup tamari or soy sauce
True:   QTY QTY QTY UNIT NAME NAME NAME NAME
v1:     QTY QTY OTHER QTY UNIT NAME NAME
v2:     QTY QTY QTY QTY UNIT NAME NAME
```


## Newsletter Summary

### Key Numbers

- **Training data**: strangetom (55,076) + harness (1,319 AI-labeled entries from 19 recipe sites, 4x oversampled)
- **Vocabulary**: 5,372 -> 5,454 (+82 new ingredient words)
- **Strangetom test**: 98.54% token accuracy (+0.05%), 95.34% sentence accuracy (-0.06%)
- **Sentence comparison**: 46 improved, 33 regressed, 621 both correct, 6185 both wrong
- **Net**: +13 sentences on strangetom test
- **Zero critical regressions** on QTY/UNIT/NAME F1 (all improved or stable)