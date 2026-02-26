# FM vs Pipeline — Ingredient Parsing Comparison

**Generated**: 2026-02-26T13:23:35Z
**FM Available**: true
**Recipes**: 50
**Ingredient Lines**: 477

---

## Summary

| Metric | Pipeline | Foundation Models |
|--------|----------|-------------------|
| Qty extracted | 421/477 (88.3%) | 303/477 (63.5%) |
| Disagreements | — | 210 lines |
| FM fixes pipeline gaps | — | 33 lines |

## Disagreements — FM ≠ Pipeline

These lines had different results. Review to determine which parser is correct.

| Input | Pipeline | FM |
|-------|----------|----|
| - 1-2 tbsp English mustard | qty=nil unit=tbsp name=english mustard | qty=1.5 unit=tbsp name=English mustard |
| - Dash of olive oil | qty=nil unit=dash name=olive oil | qty=0.5 unit=tbsp name=olive oil |
| - 750g piece beef fillet | qty=750 unit=g name=piece beef fillet | qty=750 unit=g name=beef fillet |
| - 6-8 slices Parma ham | qty=nil unit=slice name=parma ham | qty=6 unit=slices name=Parma ham |
| - Flour for dusting | qty=nil unit=nil name=flour | qty=0 unit=tbsp name=flour |
| - 2 beaten egg yolks | qty=2 unit=nil name=egg yolks | qty=2 unit=eggs name=egg yolks |
| - 1 onion | qty=1 unit=nil name=onion | qty=1 unit=none name=onion |
| 3. Tip the flour into a bowl with a big pinch of salt a | qty=3 unit=nil name=tip the flour | qty=nil unit=nil name=salt and pepper |
| - 200g cherry tomatoes, halved | qty=200 unit=g name=cherry tomatoes, hal | qty=200 unit=g name=cherry tomatoes |
| - 1 cucumber, diced | qty=1 unit=nil name=cucumber | qty=1 unit=piece name=cucumber |
| - 200g feta cheese, crumbled | qty=200 unit=g name=feta cheese, crumble | qty=200 unit=g name=feta cheese |
| - 1 red onion, thinly sliced | qty=1 unit=nil name=red onion | qty=1 unit=piece name=red onion |
| - 2 large eggs | qty=2 unit=nil name=large eggs | qty=2 unit=eggs name=eggs |
| - Sugar to serve | qty=nil unit=nil name=sugar | qty=0 unit=none name=sugar |
| - Raspberries to serve | qty=nil unit=nil name=raspberries | qty=0 unit=none name=raspberries |
| - Blueberries to serve | qty=nil unit=nil name=blueberries | qty=0 unit=none name=blueberries |
| 1. Put the flour, eggs, milk, 1 tbsp oil and a pinch of | qty=1 unit=nil name=put the flour eggs m | qty=0 unit=none name=salt |
| - 1 tablespoon chilli powder | qty=1 unit=tbsp name=chilli powder | qty=1 unit=tsp name=chilli powder |
| - 4 chopped spring onions | qty=4 unit=nil name=spring onions | qty=4 unit=clove name=spring onions |
| - 200g peas, soaked overnight | qty=200 unit=g name=peas, soaked overnig | qty=0.2 unit=g name=peas |
| - 2 chopped onions | qty=2 unit=nil name=onions | qty=0.2 unit=g name=onions |
| - 2 chopped carrots | qty=2 unit=nil name=carrots | qty=0.2 unit=g name=carrots |
| - 2 bay leaves | qty=2 unit=nil name=bay leaves | qty=0 unit=leaf name=bay leaves |
| - 1 chopped celery stalk | qty=1 unit=stalk name=celery | qty=0.1 unit=stalk name=celery |
| - 300g frozen peas | qty=300 unit=g name=frozen peas | qty=0.3 unit=g name=frozen peas |
| - Bread to serve | qty=nil unit=nil name=bread | qty=0 unit=unit name=bread |
| 1 lb salmon | qty=1 unit=lb name=salmon | qty=0.453592 unit=lb name=salmon |
| 1 tablespoon olive oil | qty=1 unit=tbsp name=olive oil | qty=1.5 unit=tbsp name=olive oil |
| 450 grams boneless skin-on chicken | qty=450 unit=g name=boneless skin-on chi | qty=450 unit=g name=chicken |
| 2 teaspoons granulated sugar | qty=2 unit=tsp name=granulated sugar | qty=2 unit=tsp name=sugar |
| 1 L beef stock | qty=1 unit=l name=beef stock | qty=nil unit=nil name=beef stock |
| 1 large onion | qty=1 unit=nil name=large onion | qty=nil unit=nil name=onion |
| 1 large chopped ginger | qty=1 unit=nil name=large ginger | qty=nil unit=nil name=ginger |
| 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=nil unit=nil name=cinnamon stick |
| 2 star anise | qty=2 unit=nil name=star anise | qty=nil unit=nil name=star anise |
| 1 tsp coriander seeds | qty=1 unit=tsp name=coriander seeds | qty=nil unit=nil name=coriander seeds |
| 1/2 teaspoon cloves | qty=0.5 unit=tsp name=cloves | qty=nil unit=nil name=cloves |
| 225g sirloin steak | qty=225 unit=g name=sirloin steak | qty=nil unit=nil name=sirloin steak |
| 1 tsp palm sugar | qty=1 unit=tsp name=palm sugar | qty=nil unit=nil name=palm sugar |
| 1 tablespoon fish sauce | qty=1 unit=tbsp name=fish sauce | qty=nil unit=nil name=fish sauce |
| 1 1/2 tbsp soy sauce | qty=1.5 unit=tbsp name=soy sauce | qty=nil unit=nil name=soy sauce |
| 200g rice noodles | qty=200 unit=g name=rice noodles | qty=nil unit=nil name=rice noodles |
| 2 sliced spring onions | qty=2 unit=nil name=spring onions | qty=nil unit=nil name=spring onions |
| 1 small birds-eye chilli | qty=1 unit=nil name=small birds-eye chil | qty=nil unit=nil name=birds-eye chilli |
| 1 lime | qty=1 unit=nil name=lime | qty=nil unit=nil name=lime |
| 4 chicken legs | qty=4 unit=nil name=chicken legs | qty=4 unit=chicken legs name=chicken |
| 1 chicken stock cube | qty=1 unit=nil name=chicken stock cube | qty=1 unit=stock cube name=chicken stock |
| Pinch of pepper | qty=nil unit=pinch name=pepper | qty=0.5 unit=pinch name=pepper |
| 1/3 cup peas | qty=0.333333 unit=cup name=peas | qty=0.25 unit=cup name=peas |
| 1/3 cup mushrooms | qty=0.333333 unit=cup name=mushrooms | qty=0.25 unit=cup name=mushrooms |
| 2 salmon fillets | qty=2 unit=nil name=salmon fillets | qty=nil unit=nil name=salmon fillets |
| 1 large avocado, sliced | qty=1 unit=nil name=large avocado | qty=nil unit=nil name=avocado |
| 100g mixed salad leaves | qty=100 unit=g name=mixed salad leaves | qty=nil unit=nil name=mixed salad leaves |
| 1/2 cucumber, sliced | qty=nil unit=nil name=1/2 cucumber | qty=nil unit=nil name=cucumber |
| 10 cherry tomatoes, halved | qty=10 unit=nil name=cherry tomatoes | qty=nil unit=nil name=cherry tomatoes |
| 2 tablespoons extra virgin olive oil | qty=2 unit=tbsp name=extra virgin olive o | qty=nil unit=nil name=extra virgin olive o |
| 1 tablespoon lemon juice | qty=1 unit=tbsp name=lemon juice | qty=nil unit=nil name=lemon juice |
| 8 chicken drumsticks | qty=8 unit=nil name=chicken drumsticks | qty=nil unit=nil name=chicken drumsticks |
| 1 tablespoon honey | qty=1 unit=tbsp name=honey | qty=1 unit=tsp name=honey |
| 3 tablespoons unsalted butter | qty=3 unit=tbsp name=unsalted butter | qty=3 unit=tbsp name=butter |
| 1 medium chopped onion | qty=1 unit=nil name=medium onion | qty=1 unit=medium name=onion |
| 3 chopped potatoes | qty=3 unit=nil name=potatoes | qty=3 unit=tbsp name=potatoes |
| Dash of kosher salt | qty=nil unit=dash name=kosher salt | qty=1 unit=dash name=kosher salt |
| Dash of black pepper | qty=nil unit=dash name=black pepper | qty=1 unit=dash name=black pepper |
| 2 tablespoons vegetable oil | qty=2 unit=tbsp name=vegetable oil | qty=nil unit=nil name=vegetable oil |
| 400g beef strips | qty=400 unit=g name=beef strips | qty=nil unit=nil name=beef strips |
| 1 sliced red chilli | qty=1 unit=nil name=red chilli | qty=nil unit=nil name=sliced red chilli |
| 2 tablespoons oyster sauce | qty=2 unit=tbsp name=oyster sauce | qty=nil unit=nil name=oyster sauce |
| - 60g lard | qty=60 unit=g name=lard | qty=0.6 unit=g name=lard |
| - 340g warm water | qty=340 unit=g name=warm water | qty=0.34 unit=L name=warm water |
| - 1 tsp salt | qty=1 unit=tsp name=salt | qty=0.005 unit=tsp name=salt |
| - 600g all purpose flour | qty=600 unit=g name=all purpose flour | qty=0.6 unit=g name=all purpose flour |
| - 3 tomatoes | qty=3 unit=nil name=tomatoes | qty=3 unit=tomatoes name=tomatoes |
| - 1 large red onion | qty=1 unit=nil name=large red onion | qty=1 unit=large red onion name=red onion |
| - Bunch of spring onions | qty=nil unit=bunch name=spring onions | qty=1 unit=bunch of spring onions name=spring onions |
| - 750g sirloin steak | qty=750 unit=g name=sirloin steak | qty=0.75 unit=g name=sirloin steak |
| - 1 tsp paprika | qty=1 unit=tsp name=paprika | qty=0.5 unit=tsp name=paprika |
| - 1 tsp red pepper flakes | qty=1 unit=tsp name=red pepper flakes | qty=0.5 unit=tsp name=red pepper flakes |
| - Salt to taste | qty=nil unit=nil name=salt | qty=0 unit=nil name=salt |
| - Pepper to taste | qty=nil unit=nil name=pepper | qty=0 unit=nil name=pepper |
| - 3 eggs | qty=3 unit=nil name=eggs | qty=2 unit=eggs name=eggs |
| - Splash of egg wash | qty=nil unit=splash name=egg wash | qty=0.15 unit=tbsp name=egg wash |
| - 25g butter | qty=25 unit=g name=butter | qty=0.25 unit=g name=butter |
| - 6 tablespoons olive oil | qty=6 unit=tbsp name=olive oil | qty=0.4 unit=tbsp name=olive oil |
| - 2 sliced red onions | qty=2 unit=nil name=red onions | qty=2 unit=eggs name=red onions |
| - 3 large red peppers | qty=3 unit=nil name=large red peppers | qty=3 unit=large name=red peppers |
| - 130g chorizo | qty=130 unit=g name=chorizo | qty=0.36 unit=g name=chorizo |
| - 8 sun-dried tomatoes | qty=8 unit=nil name=sun-dried tomatoes | qty=0.8 unit=sun-dried tomatoes name=sun-dried tomatoes |
| - 6 cloves sliced garlic | qty=6 unit=clove name=sliced garlic | qty=0.83 unit=cloves name=garlic |
| - 300g basmati rice | qty=300 unit=g name=basmati rice | qty=0.3 unit=cup name=basmati rice |
| - 1/2 tsp paprika | qty=0.5 unit=tsp name=paprika | qty=0.25 unit=tsp name=paprika |
| - 4 bay leaves | qty=4 unit=nil name=bay leaves | qty=4 unit=bay leaves name=bay leaves |
| - Handful of thyme | qty=nil unit=handful name=thyme | qty=1 unit=handful name=thyme |
| - 350ml chicken stock | qty=350 unit=ml name=chicken stock | qty=0.35 unit=cup name=chicken stock |
| - 180g dry white wine | qty=180 unit=g name=dry white wine | qty=0.18 unit=g name=dry white wine |
| - 2 lemons | qty=2 unit=nil name=lemons | qty=2 unit=lemons name=lemons |
| - 100g black olives | qty=100 unit=g name=black olives | qty=0.1 unit=g name=black olives |
| - Salt to serve | qty=nil unit=nil name=salt | qty=0 unit= name=salt |
| - Pepper to serve | qty=nil unit=nil name=pepper | qty=0 unit= name=pepper |
| Oil temperature: 350F / 175C | qty=nil unit=nil name=oil temperature 350f | qty=350 unit=F name=oil |
| - 1 whole chicken, cut up | qty=1 unit=nil name=whole chicken | qty=1 unit=whole chicken name=chicken |
| - 2 quarts neutral frying oil | qty=2 unit=quart name=neutral frying oil | qty=2 unit=quarts name=oil |
| - 1 egg white | qty=1 unit=nil name=egg white | qty=1 unit=egg white name=egg white |
| - 1 1/2 cups flour | qty=1.5 unit=cup name=flour | qty=1.5 unit=cups name=flour |
| - 1 lb beef | qty=1 unit=lb name=beef | qty=0.453592 unit=lb name=beef |
| - 5 tablespoons vegetable oil | qty=5 unit=tbsp name=vegetable oil | qty=0.78125 unit=tbsp name=vegetable oil |
| - 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=0.05 unit=clove name=cinnamon stick |
| - 3 cloves | qty=3 unit=clove name=s | qty=0.05 unit=clove name=clove |
| - 3 star anise | qty=3 unit=nil name=star anise | qty=0.075 unit=clove name=star anise |
| - 3 cardamom pods | qty=3 unit=nil name=cardamom pods | qty=0.075 unit=clove name=cardamom pods |
| - 1 cup coconut cream | qty=1 unit=cup name=coconut cream | qty=0.25 unit=cup name=coconut cream |
| - 1 cup water | qty=1 unit=cup name=water | qty=0.25 unit=cup name=water |
| - 2 tablespoons tamarind paste | qty=2 unit=tbsp name=tamarind paste | qty=0.375 unit=tbsp name=tamarind paste |
| - 6 lime leaves | qty=6 unit=nil name=lime leaves | qty=0.06 unit=clove name=lime leaves |
| - 1 tablespoon sugar | qty=1 unit=tbsp name=sugar | qty=0.15 unit=tsp name=sugar |
| - 5 shallots | qty=5 unit=nil name=shallots | qty=2 unit=egg name=shallots |
| - 250g butter (for pastry) | qty=250 unit=g name=butter (for pastry) | qty=250 unit=g name=butter |
| - Juice of 1/2 lemon | qty=nil unit=nil name=lemon | qty=0.5 unit= name=lemon juice |
| - 25g butter (for filling) | qty=25 unit=g name=butter (for filling) | qty=25 unit=g name=butter |
| - Zest of 1 lemon | qty=1 unit=nil name=lemon | qty=1 unit= name=lemon zest |
| - 1 beaten egg | qty=1 unit=nil name=egg | qty=1 unit= name=egg |
| - Sprinkling of sugar | qty=nil unit=nil name=sprinkling of sugar | qty=1 unit= name=sugar |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit= name=onion |
| - 200g chicken breast | qty=200 unit=g name=chicken breast | qty=400 unit=g name=chicken breast |
| - Pinch of ginger | qty=nil unit=pinch name=ginger | qty=0.5 unit=pinch name=ginger |
| - 10 dried apricots | qty=10 unit=nil name=dried apricots | qty=10 unit= name=dried apricots |
| - Handful of coriander | qty=nil unit=handful name=coriander | qty=1.5 unit=handful name=coriander |
| - Zest of 1 orange | qty=1 unit=nil name=orange | qty=1 unit=orange name=orange |
| - 3 large eggs | qty=3 unit=nil name=large eggs | qty=2 unit=eggs name=eggs |
| - 1 tablespoon milk (for glaze) | qty=1 unit=tbsp name=milk (for glaze) | qty=1 unit=tbsp name=milk |
| - 2 tsp caster sugar (for glaze) | qty=2 unit=tsp name=caster sugar (for gl | qty=2 unit=tsp name=caster sugar |
| You need about 2 lbs lamb shoulder (or mutton if you ca | qty=nil unit=nil name=you need | qty=2 unit=lb name=lamb shoulder |
| 4-5 medium potatoes peeled and quartered | qty=nil unit=nil name=medium potatoes | qty=4 unit=p name=potatoes |
| 3 carrots sliced thick | qty=3 unit=nil name=carrots | qty=3 unit=c name=carrots |
| 2 onions roughly chopped | qty=2 unit=nil name=onions | qty=2 unit=onions name=onions |
| 2 cups beef stock | qty=2 unit=cup name=beef stock | qty=2 unit=c name=beef stock |
| a sprig of thyme | qty=nil unit=sprig name=thyme | qty=1 unit=sprig name=thyme |
| 2 bay leaves | qty=2 unit=nil name=bay leaves | qty=2 unit=bay leaves name=bay leaves |
| salt and pepper | qty=nil unit=nil name=salt and pepper | qty=0 unit= name=salt and pepper |
| 2 sliced onion | qty=2 unit=nil name=onion | qty=2 unit= name=onion |
| 2 cloves minced garlic | qty=2 unit=clove name=minced garlic | qty=2 unit=clove name=garlic |
| 2 onions | qty=2 unit=nil name=onions | qty=nil unit=nil name=2 onions |
| - Juice of 2 lemons | qty=2 unit=nil name=lemons | qty=nil unit=nil name=lemon juice |
| - 4 tsp paprika | qty=4 unit=tsp name=paprika | qty=nil unit=nil name=paprika |
| - 2 finely chopped red onions | qty=2 unit=nil name=red onions | qty=nil unit=nil name=red onion |
| - 16 skinless chicken thighs | qty=16 unit=nil name=skinless chicken thi | qty=nil unit=nil name=skinless chicken thi |
| - 300ml Greek yoghurt | qty=300 unit=ml name=Greek yoghurt | qty=nil unit=nil name=Greek yogurt |
| - 1 large piece ginger, grated | qty=1 unit=large piece name=ginger | qty=nil unit=nil name=ginger |
| - 4 garlic cloves, crushed | qty=4 unit=nil name=garlic cloves | qty=nil unit=nil name=garlic clove |
| - 3/4 tsp garam masala | qty=0.75 unit=tsp name=garam masala | qty=nil unit=nil name=garam masala |
| - 3/4 tsp ground cumin | qty=0.75 unit=tsp name=ground cumin | qty=nil unit=nil name=ground cumin |
| - 1/2 tsp chilli powder | qty=0.5 unit=tsp name=chilli powder | qty=nil unit=nil name=chilli powder |
| - 1/4 tsp turmeric | qty=0.25 unit=tsp name=turmeric | qty=nil unit=nil name=turmeric |
| - Pinch of salt | qty=nil unit=pinch name=salt | qty=0 unit=pinch name=salt |
| - Pinch of white pepper | qty=nil unit=pinch name=white pepper | qty=0 unit=pinch name=white pepper |
| - 1 tsp fresh ginger, sliced | qty=1 unit=tsp name=fresh ginger, sliced | qty=1 unit=tsp name=fresh ginger |
| - 1 tbs spring onions, chopped | qty=1 unit=tbsp name=spring onions, chopp | qty=1 unit=tbsp name=spring onions |
| - 55g fresh coriander | qty=55 unit=g name=fresh coriander | qty=55 unit=g name=coriander |
| - 1 large egg | qty=1 unit=nil name=large egg | qty=1 unit=large egg name=egg |
| - 4 tbs milk | qty=4 unit=tbsp name=milk | qty=4 unit=tbs name=milk |
| - 1 tbs ground ginger | qty=1 unit=tbsp name=ground ginger | qty=1 unit=tbs name=ground ginger |
| - 2 tbs vegetable oil | qty=2 unit=tbsp name=vegetable oil | qty=2 unit=tbs name=vegetable oil |
| - 500g minced beef | qty=500 unit=g name=minced beef | qty=5 unit=g name=minced beef |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit= name=onion |
| - 1 tbs tomato puree | qty=1 unit=tbsp name=tomato puree | qty=1 unit=tbs name=tomato puree |
| - 75g mushrooms | qty=75 unit=g name=mushrooms | qty=0.075 unit=g name=mushrooms |
| - 250ml beef stock | qty=250 unit=ml name=beef stock | qty=0.25 unit=ml name=beef stock |
| - Dash of Worcestershire sauce | qty=nil unit=dash name=worcestershire sauce | qty=0.05 unit= name=Worcestershire sauce |
| - 400g shortcrust pastry | qty=400 unit=g name=shortcrust pastry | qty=4 unit=g name=shortcrust pastry |
| - 1 egg yolk | qty=1 unit=nil name=egg yolk | qty=1 unit=egg yolk name=egg yolk |
| - 85g peanuts | qty=85 unit=g name=peanuts | qty=0.85 unit=g name=peanuts |
| - 400ml tin coconut cream | qty=400 unit=ml name=tin coconut cream | qty=0.4 unit=L name=coconut cream |
| - 600g stewing beef, cut into strips | qty=600 unit=g name=stewing beef, cut in | qty=0.6 unit=g name=beef shin |
| - 450g waxy potatoes | qty=450 unit=g name=waxy potatoes | qty=0.45 unit=g name=waxy potatoes |
| - 1 onion, cut in thin wedges | qty=1 unit=nil name=onion | qty=1 unit=onion name=onion |
| - 4 lime leaves | qty=4 unit=nil name=lime leaves | qty=4 unit=leaves name=lime leaves |
| - 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=1 unit=stick name=cinnamon |
| - 1 red chilli, deseeded and finely sliced | qty=1 unit=nil name=red chilli | qty=1 unit=red chili name=red chili |
| - Jasmine rice to serve | qty=nil unit=nil name=jasmine rice | qty=1 unit=cup name=Jasmine rice |
| - 3 eggs | qty=3 unit=nil name=eggs | qty=3 unit=eggs name=eggs |
| - 3 tbs milk | qty=3 unit=tbsp name=milk | qty=3 unit=tbs name=milk |
| - Zest of 1 lemon | qty=1 unit=nil name=lemon | qty=1 unit=lemon name=lemon |
| - Mixed peel to glaze | qty=nil unit=nil name=mixed peel | qty=1 unit=peel name=peel |
| 2. Cream the butter and sugar together in a bowl until  | qty=2 unit=nil name=cream the butter and | qty=nil unit=nil name=cream |
| - 2 tbs sunflower oil | qty=2 unit=tbsp name=sunflower oil | qty=2 unit=tbs name=sunflower oil |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit=chopped name=onion |
| - 4 sliced garlic cloves | qty=4 unit=nil name=garlic cloves | qty=4 unit=sliced name=garlic cloves |
| - 2 litres chicken stock | qty=2 unit=litres name=chicken stock | qty=2 unit=L name=chicken stock |
| - 5 lime leaves | qty=5 unit=nil name=lime leaves | qty=5 unit=leaves name=lime leaves |
| - 2 tbs fish sauce | qty=2 unit=tbsp name=fish sauce | qty=2 unit=tbs name=fish sauce |
| - 1 bunch spring onions | qty=1 unit=bunch name=spring onions | qty=1 unit=bunches name=spring onions |
| - Juice of 2 limes | qty=2 unit=nil name=limes | qty=2 unit=juice name=limes |
| - Bunch of basil | qty=nil unit=bunch name=basil | qty=1 unit=bunches name=basil |
| - 1 large carrot | qty=1 unit=nil name=large carrot | qty=1 unit=large name=carrot |
| - 2 chopped spring onions | qty=2 unit=nil name=spring onions | qty=2 unit=sprig name=spring onions |
| - 1 diced onion | qty=1 unit=nil name=onion | qty=1 unit=tbsp name=onion |
| - 2 chopped red peppers | qty=2 unit=nil name=red peppers | qty=2 unit=sprig name=red peppers |
| - 4 mashed garlic cloves | qty=4 unit=nil name=garlic cloves | qty=4 unit=clove name=garlic |
| - 900g beef | qty=900 unit=g name=beef | qty=9 unit=g name=beef |
| - 4 potatoes | qty=4 unit=nil name=potatoes | qty=4 unit=pcs name=potatoes |
| - 1 cup plain flour | qty=1 unit=cup name=plain flour | qty=1 unit=cup name=flour |
| - 2 tbs olive oil | qty=2 unit=tbsp name=olive oil | qty=2 unit=tbs name=olive oil |
| - 1 sliced onion | qty=1 unit=nil name=onion | qty=1 unit=sliced name=onion |
| - 2 medium carrots | qty=2 unit=nil name=medium carrots | qty=2 unit=medium name=carrots |
| - 750ml fish stock | qty=750 unit=ml name=fish stock | qty=7.5 unit=ml name=fish stock |
| - 750ml water | qty=750 unit=ml name=water | qty=7.5 unit=ml name=water |
| - 4 large potatoes | qty=4 unit=nil name=large potatoes | qty=4 unit=large name=potatoes |
| - 3 bay leaves | qty=3 unit=nil name=bay leaves | qty=3 unit=bay leaves name=bay leaves |
| - 1 whole cod fillet | qty=1 unit=nil name=whole cod fillet | qty=1 unit=whole name=cod fillet |
| - 1 whole salmon fillet | qty=1 unit=nil name=whole salmon fillet | qty=1 unit=whole name=salmon fillet |

## FM Fixes Pipeline Gaps

Lines where pipeline returned qty=nil but FM extracted a quantity.

| Input | Pipeline Name | FM Qty | FM Unit | FM Name |
|-------|---------------|--------|---------|--------|
| - 1-2 tbsp English mustard | english mustard | 1.5 | tbsp | English mustard |
| - Dash of olive oil | olive oil | 0.5 | tbsp | olive oil |
| - 6-8 slices Parma ham | parma ham | 6 | slices | Parma ham |
| - Flour for dusting | flour | 0 | tbsp | flour |
| - Sugar to serve | sugar | 0 | none | sugar |
| - Raspberries to serve | raspberries | 0 | none | raspberries |
| - Blueberries to serve | blueberries | 0 | none | blueberries |
| - Bread to serve | bread | 0 | unit | bread |
| Pinch of pepper | pepper | 0.5 | pinch | pepper |
| Dash of kosher salt | kosher salt | 1 | dash | kosher salt |
| Dash of black pepper | black pepper | 1 | dash | black pepper |
| - Bunch of spring onions | spring onions | 1 | bunch of spring onions | spring onions |
| - Salt to taste | salt | 0 | nil | salt |
| - Pepper to taste | pepper | 0 | nil | pepper |
| - Splash of egg wash | egg wash | 0.15 | tbsp | egg wash |
| - Handful of thyme | thyme | 1 | handful | thyme |
| - Salt to serve | salt | 0 |  | salt |
| - Pepper to serve | pepper | 0 |  | pepper |
| Oil temperature: 350F / 175C | oil temperature 350f 175c | 350 | F | oil |
| - Juice of 1/2 lemon | lemon | 0.5 |  | lemon juice |
| - Sprinkling of sugar | sprinkling of sugar | 1 |  | sugar |
| - Pinch of ginger | ginger | 0.5 | pinch | ginger |
| - Handful of coriander | coriander | 1.5 | handful | coriander |
| You need about 2 lbs lamb shoulder (or mutton if y | you need | 2 | lb | lamb shoulder |
| 4-5 medium potatoes peeled and quartered | medium potatoes | 4 | p | potatoes |
| a sprig of thyme | thyme | 1 | sprig | thyme |
| salt and pepper | salt and pepper | 0 |  | salt and pepper |
| - Pinch of salt | salt | 0 | pinch | salt |
| - Pinch of white pepper | white pepper | 0 | pinch | white pepper |
| - Dash of Worcestershire sauce | worcestershire sauce | 0.05 |  | Worcestershire sauce |
| - Jasmine rice to serve | jasmine rice | 1 | cup | Jasmine rice |
| - Mixed peel to glaze | mixed peel | 1 | peel | peel |
| - Bunch of basil | basil | 1 | bunches | basil |

## Known Pipeline Issues Detected

| Pattern | Input | Pipeline | FM |
|---------|-------|----------|----|
| unit-abbreviation | In a bowl, add the chicken, 1 pinch of salt,  | qty=nil unit=nil name=In a bowl, add the c | — |
| mixed-fraction | 2-1/2 cups chicken stock | qty=nil unit=nil name=2-1/2 cups chicken s | — |
| mixed-fraction | 1-1/2 cups vinegar | qty=nil unit=nil name=1-1/2 cups vinegar | — |
| unit-abbreviation | First Cook the beef by adding 2 Tablespoon of | qty=nil unit=nil name=first cook | — |
| unit-abbreviation | 6. In 3 tablespoons of the cooking oil, saute | qty=6 unit=nil name=cooking oil | — |

---

## Per-Recipe Details

### clean-01-chicken-handi (clean)

**16 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1.2 kg chicken | 1.2 | kg | chicken | 1.00 | regex |  |
| - 5 thinly sliced onion | 5 | — | onion | 0.99 | ml |  |
| - 2 finely chopped tomatoes | 2 | — | tomatoes | 0.97 | ml |  |
| - 8 cloves chopped garlic | 8 | clove | chopped garlic | 1.00 | regex |  |
| - 1 tbsp ginger paste | 1 | tbsp | ginger paste | 1.00 | regex |  |
| - 1/4 cup vegetable oil | 0.25 | cup | vegetable oil | 1.00 | regex |  |
| - 2 tsp cumin seeds | 2 | tsp | cumin seeds | 1.00 | regex |  |
| - 3 tsp coriander seeds | 3 | tsp | coriander seeds | 1.00 | regex |  |
| - 1 tsp turmeric powder | 1 | tsp | turmeric powder | 1.00 | regex |  |
| - 1 tsp chilli powder | 1 | tsp | chilli powder | 1.00 | regex |  |
| - 2 green chilli | 2 | — | green chilli | 0.98 | ml |  |
| - 1 cup yogurt | 1 | cup | yogurt | 1.00 | regex |  |
| - 3/4 cup cream | 0.75 | cup | cream | 1.00 | regex |  |
| - 3 tsp dried fenugreek | 3 | tsp | dried fenugreek | 1.00 | regex |  |
| - 1 tsp garam masala | 1 | tsp | garam masala | 1.00 | regex |  |
| - Salt to taste | — | — | salt | 1.00 | ml |  |

### clean-02-beef-wellington (clean)

**8 ingredients** | 6 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 400g mushrooms | 400 | g | mushrooms | 400 | g | mushrooms | ✓ |
| - 1-2 tbsp English mustard | — | tbsp | english mustard | 1.5 | tbsp | English mustard | ≠ |
| - Dash of olive oil | — | dash | olive oil | 0.5 | tbsp | olive oil | ≠ |
| - 750g piece beef fillet | 750 | g | piece beef fillet | 750 | g | beef fillet | ≠ |
| - 6-8 slices Parma ham | — | slice | parma ham | 6 | slices | Parma ham | ≠ |
| - 500g puff pastry | 500 | g | puff pastry | 500 | g | puff pastry | ✓ |
| - Flour for dusting | — | — | flour | 0 | tbsp | flour | ≠ |
| - 2 beaten egg yolks | 2 | — | egg yolks | 2 | eggs | egg yolks | ≠ |

### clean-03-leblebi-soup (clean)

**9 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tablespoons olive oil | 2 | tbsp | olive oil | 1.00 | regex |  |
| - 1 medium finely diced onion | 1 | — | medium onion | 0.99 | ml |  |
| - 250g chickpeas | 250 | g | chickpeas | 1.00 | regex |  |
| - 1 tsp cumin | 1 | tsp | cumin | 1.00 | regex |  |
| - 5 cloves garlic | 5 | clove | garlic | 1.00 | regex |  |
| - 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex |  |
| - 1 tsp harissa spice | 1 | tsp | harissa spice | 1.00 | regex |  |
| - Pinch of pepper | — | pinch | pepper | 0.99 | ml |  |
| - 1/2 lime | — | — | 1/2 lime | 0.79 | ml |  |

### clean-04-carrot-cake (clean)

**12 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 450ml vegetable oil | 450 | ml | vegetable oil | 1.00 | regex |  |
| - 400g plain flour | 400 | g | plain flour | 1.00 | regex |  |
| - 2 tsp bicarbonate of soda | 2 | tsp | bicarbonate of soda | 1.00 | regex |  |
| - 550ml sugar | 550 | ml | sugar | 1.00 | regex |  |
| - 5 eggs | 5 | — | eggs | 0.99 | ml |  |
| - 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex |  |
| - 2 tsp cinnamon | 2 | tsp | cinnamon | 1.00 | regex |  |
| - 500g grated carrots | 500 | g | grated carrots | 1.00 | regex |  |
| - 150g walnuts | 150 | g | walnuts | 1.00 | regex |  |
| - 200g cream cheese | 200 | g | cream cheese | 1.00 | regex |  |
| - 150g caster sugar | 150 | g | caster sugar | 1.00 | regex |  |
| - 100g butter | 100 | g | butter | 1.00 | regex |  |

### clean-05-french-onion-soup (clean)

**11 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 50g butter | 50 | g | butter | 1.00 | regex |  |
| - 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.00 | regex |  |
| - 1 kg onion | 1 | kg | onion | 1.00 | regex |  |
| - 1 tsp sugar | 1 | tsp | sugar | 1.00 | regex |  |
| - 4 sliced garlic cloves | 4 | — | garlic cloves | 0.95 | ml |  |
| - 2 tablespoons plain flour | 2 | tbsp | plain flour | 1.00 | regex |  |
| - 250ml dry white wine | 250 | ml | dry white wine | 1.00 | regex |  |
| - 1L beef stock | 1 | l | beef stock | 1.00 | regex |  |
| - 4 slices bread | 4 | slice | bread | 1.00 | regex |  |
| - 140g Gruyere cheese | 140 | g | Gruyere cheese | 1.00 | regex |  |
| 6. Put a slice or two of toast on top an | 6 | slice | 6. Put a slice or tw | 0.68 | ml |  |

### clean-06-beef-stroganoff (clean)

**12 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| - 1 onion | 1 | — | onion | 1 | none | onion | ≠ |
| - 1 clove garlic | 1 | clove | garlic | 1 | clove | garlic | ✓ |
| - 1 tbsp butter | 1 | tbsp | butter | 1 | tbsp | butter | ✓ |
| - 250g mushrooms | 250 | g | mushrooms | 250 | g | mushrooms | ✓ |
| - 500g beef fillet | 500 | g | beef fillet | 500 | g | beef fillet | ✓ |
| - 1 tbsp plain flour | 1 | tbsp | plain flour | 1 | tbsp | plain flour | ✓ |
| - 150g creme fraiche | 150 | g | creme fraiche | 150 | g | creme fraiche | ✓ |
| - 1 tbsp English mustard | 1 | tbsp | English mustard | 1 | tbsp | English mustard | ✓ |
| - 100ml beef stock | 100 | ml | beef stock | 100 | ml | beef stock | ✓ |
| - Parsley for topping | — | — | parsley | — | — | Parsley | ✓ |
| 3. Tip the flour into a bowl with a big  | 3 | — | tip the flour | — | — | salt and pepper | ≠ |

### clean-07-mediterranean-pasta-salad (clean)

**9 ingredients** | 4 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 500g fusilli pasta | 500 | g | fusilli pasta | 500 | g | fusilli pasta | ✓ |
| - 200g cherry tomatoes, halved | 200 | g | cherry tomatoes, hal | 200 | g | cherry tomatoes | ≠ |
| - 1 cucumber, diced | 1 | — | cucumber | 1 | piece | cucumber | ≠ |
| - 150g Kalamata olives | 150 | g | Kalamata olives | 150 | g | Kalamata olives | ✓ |
| - 200g feta cheese, crumbled | 200 | g | feta cheese, crumble | 200 | g | feta cheese | ≠ |
| - 1 red onion, thinly sliced | 1 | — | red onion | 1 | piece | red onion | ≠ |
| - 1/4 cup extra virgin olive oil | 0.25 | cup | extra virgin olive o | 0.25 | cup | extra virgin olive o | ✓ |
| - 2 tablespoons red wine vinegar | 2 | tbsp | red wine vinegar | 2 | tbsp | red wine vinegar | ✓ |
| - 1 teaspoon dried oregano | 1 | tsp | dried oregano | 1 | tsp | dried oregano | ✓ |

### clean-08-pancakes (clean)

**8 ingredients** | 5 disagreements | 3 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 100g flour | 100 | g | flour | 100 | g | flour | ✓ |
| - 2 large eggs | 2 | — | large eggs | 2 | eggs | eggs | ≠ |
| - 300ml milk | 300 | ml | milk | 300 | ml | milk | ✓ |
| - 1 tablespoon sunflower oil | 1 | tbsp | sunflower oil | 1 | tbsp | sunflower oil | ✓ |
| - Sugar to serve | — | — | sugar | 0 | none | sugar | ≠ |
| - Raspberries to serve | — | — | raspberries | 0 | none | raspberries | ≠ |
| - Blueberries to serve | — | — | blueberries | 0 | none | blueberries | ≠ |
| 1. Put the flour, eggs, milk, 1 tbsp oil | 1 | — | put the flour eggs m | 0 | none | salt | ≠ |

### clean-09-kung-pao-chicken (clean)

**13 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tablespoons sake | 2 | tbsp | sake | 2 | tbsp | sake | ✓ |
| - 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tbsp | soy sauce | ✓ |
| - 2 tablespoons sesame seed oil | 2 | tbsp | sesame seed oil | 2 | tbsp | sesame seed oil | ✓ |
| - 2 tablespoons corn flour | 2 | tbsp | corn flour | 2 | tbsp | corn flour | ✓ |
| - 2 tablespoons water | 2 | tbsp | water | 2 | tbsp | water | ✓ |
| - 500g chicken | 500 | g | chicken | 500 | g | chicken | ✓ |
| - 1 tablespoon chilli powder | 1 | tbsp | chilli powder | 1 | tsp | chilli powder | ≠ |
| - 1 tsp rice vinegar | 1 | tsp | rice vinegar | 1 | tsp | rice vinegar | ✓ |
| - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1 | tbsp | brown sugar | ✓ |
| - 4 chopped spring onions | 4 | — | spring onions | 4 | clove | spring onions | ≠ |
| - 6 cloves garlic | 6 | clove | garlic | 6 | clove | garlic | ✓ |
| - 220g water chestnuts | 220 | g | water chestnuts | 220 | g | water chestnuts | ✓ |
| - 100g peanuts | 100 | g | peanuts | 100 | g | peanuts | ✓ |

### clean-10-split-pea-soup (clean)

**8 ingredients** | 7 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1kg ham | 1 | kg | ham | 1 | kg | ham | ✓ |
| - 200g peas, soaked overnight | 200 | g | peas, soaked overnig | 0.2 | g | peas | ≠ |
| - 2 chopped onions | 2 | — | onions | 0.2 | g | onions | ≠ |
| - 2 chopped carrots | 2 | — | carrots | 0.2 | g | carrots | ≠ |
| - 2 bay leaves | 2 | — | bay leaves | 0 | leaf | bay leaves | ≠ |
| - 1 chopped celery stalk | 1 | stalk | celery | 0.1 | stalk | celery | ≠ |
| - 300g frozen peas | 300 | g | frozen peas | 0.3 | g | frozen peas | ≠ |
| - Bread to serve | — | — | bread | 0 | unit | bread | ≠ |

### no-headers-01-honey-teriyaki-salmon (no-headers)

**5 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 lb salmon | 1 | lb | salmon | 0.453592 | lb | salmon | ≠ |
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.5 | tbsp | olive oil | ≠ |
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tbsp | soy sauce | ✓ |
| 2 tablespoons sake | 2 | tbsp | sake | 2 | tbsp | sake | ✓ |
| 4 tablespoons sesame seeds | 4 | tbsp | sesame seeds | 4 | tbsp | sesame seeds | ✓ |

### no-headers-02-chicken-karaage (no-headers)

**9 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 450 grams boneless skin-on chicken | 450 | g | boneless skin-on chi | 450 | g | chicken | ≠ |
| 1 tablespoon ginger | 1 | tbsp | ginger | 1 | tbsp | ginger | ✓ |
| 1 clove garlic | 1 | clove | garlic | 1 | clove | garlic | ✓ |
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tbsp | soy sauce | ✓ |
| 1 tablespoon sake | 1 | tbsp | sake | 1 | tbsp | sake | ✓ |
| 2 teaspoons granulated sugar | 2 | tsp | granulated sugar | 2 | tsp | sugar | ≠ |
| 1/3 cup potato starch | 0.333333 | cup | potato starch | 0.333333 | cup | potato starch | ✓ |
| 1/3 cup vegetable oil | 0.333333 | cup | vegetable oil | 0.333333 | cup | vegetable oil | ✓ |
| 1/3 cup lemon wedges | 0.333333 | cup | lemon wedges | 0.333333 | cup | lemon wedges | ✓ |

### no-headers-03-beef-pho (no-headers)

**15 ingredients** | 15 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 L beef stock | 1 | l | beef stock | — | — | beef stock | ≠ |
| 1 large onion | 1 | — | large onion | — | — | onion | ≠ |
| 1 large chopped ginger | 1 | — | large ginger | — | — | ginger | ≠ |
| 1 cinnamon stick | 1 | — | cinnamon stick | — | — | cinnamon stick | ≠ |
| 2 star anise | 2 | — | star anise | — | — | star anise | ≠ |
| 1 tsp coriander seeds | 1 | tsp | coriander seeds | — | — | coriander seeds | ≠ |
| 1/2 teaspoon cloves | 0.5 | tsp | cloves | — | — | cloves | ≠ |
| 225g sirloin steak | 225 | g | sirloin steak | — | — | sirloin steak | ≠ |
| 1 tsp palm sugar | 1 | tsp | palm sugar | — | — | palm sugar | ≠ |
| 1 tablespoon fish sauce | 1 | tbsp | fish sauce | — | — | fish sauce | ≠ |
| 1 1/2 tbsp soy sauce | 1.5 | tbsp | soy sauce | — | — | soy sauce | ≠ |
| 200g rice noodles | 200 | g | rice noodles | — | — | rice noodles | ≠ |
| 2 sliced spring onions | 2 | — | spring onions | — | — | spring onions | ≠ |
| 1 small birds-eye chilli | 1 | — | small birds-eye chil | — | — | birds-eye chilli | ≠ |
| 1 lime | 1 | — | lime | — | — | lime | ≠ |

### no-headers-04-chicken-marengo (no-headers)

**6 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| 300g mushrooms | 300 | g | mushrooms | 300 | g | mushrooms | ✓ |
| 4 chicken legs | 4 | — | chicken legs | 4 | chicken legs | chicken | ≠ |
| 500g passata | 500 | g | passata | 500 | g | passata | ✓ |
| 1 chicken stock cube | 1 | — | chicken stock cube | 1 | stock cube | chicken stock | ≠ |
| 100g black olives | 100 | g | black olives | 100 | g | black olives | ✓ |

### no-headers-05-rock-cakes (no-headers)

**8 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 225g self-raising flour | 225 | g | self-raising flour | 1.00 | regex |  |
| 75g caster sugar | 75 | g | caster sugar | 1.00 | regex |  |
| 1 tsp baking powder | 1 | tsp | baking powder | 1.00 | regex |  |
| 125g butter | 125 | g | butter | 1.00 | regex |  |
| 150g dried fruit | 150 | g | dried fruit | 1.00 | regex |  |
| 1 egg | 1 | — | egg | 1.00 | ml |  |
| 1 tablespoon milk | 1 | tbsp | milk | 1.00 | regex |  |
| 2 tsp vanilla extract | 2 | tsp | vanilla extract | 1.00 | regex |  |

### no-headers-06-egg-drop-soup (no-headers)

**10 ingredients** | 3 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 3 cups chicken stock | 3 | cup | chicken stock | 3 | cup | chicken stock | ✓ |
| 1/4 tsp salt | 0.25 | tsp | salt | 0.25 | tsp | salt | ✓ |
| 1/4 tsp sugar | 0.25 | tsp | sugar | 0.25 | tsp | sugar | ✓ |
| Pinch of pepper | — | pinch | pepper | 0.5 | pinch | pepper | ≠ |
| 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1 | tsp | sesame seed oil | ✓ |
| 1/3 cup peas | 0.333333 | cup | peas | 0.25 | cup | peas | ≠ |
| 1/3 cup mushrooms | 0.333333 | cup | mushrooms | 0.25 | cup | mushrooms | ≠ |
| 1 tablespoon cornstarch | 1 | tbsp | cornstarch | 1 | tbsp | cornstarch | ✓ |
| 2 tablespoons water | 2 | tbsp | water | 2 | tbsp | water | ✓ |
| 1/4 cup spring onions | 0.25 | cup | spring onions | 0.25 | cup | spring onions | ✓ |

### no-headers-07-salmon-avocado-salad (no-headers)

**8 ingredients** | 7 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 2 salmon fillets | 2 | — | salmon fillets | — | — | salmon fillets | ≠ |
| 1 large avocado, sliced | 1 | — | large avocado | — | — | avocado | ≠ |
| 100g mixed salad leaves | 100 | g | mixed salad leaves | — | — | mixed salad leaves | ≠ |
| 1/2 cucumber, sliced | — | — | 1/2 cucumber | — | — | cucumber | ≠ |
| 10 cherry tomatoes, halved | 10 | — | cherry tomatoes | — | — | cherry tomatoes | ≠ |
| 2 tablespoons extra virgin olive oil | 2 | tbsp | extra virgin olive o | — | — | extra virgin olive o | ≠ |
| 1 tablespoon lemon juice | 1 | tbsp | lemon juice | — | — | lemon juice | ≠ |
| Salt and pepper to taste | — | — | salt and pepper | — | — | salt and pepper | ✓ |

### no-headers-08-sticky-chicken (no-headers)

**6 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 8 chicken drumsticks | 8 | — | chicken drumsticks | — | — | chicken drumsticks | ≠ |
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tbsp | soy sauce | ✓ |
| 1 tablespoon honey | 1 | tbsp | honey | 1 | tsp | honey | ≠ |
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| 1 teaspoon tomato puree | 1 | tsp | tomato puree | 1 | tsp | tomato puree | ✓ |
| 1 tablespoon Dijon mustard | 1 | tbsp | Dijon mustard | 1 | tbsp | Dijon mustard | ✓ |

### no-headers-09-corned-beef-hash (no-headers)

**6 ingredients** | 5 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 3 tablespoons unsalted butter | 3 | tbsp | unsalted butter | 3 | tbsp | butter | ≠ |
| 1 medium chopped onion | 1 | — | medium onion | 1 | medium | onion | ≠ |
| 3 cups corned beef | 3 | cup | corned beef | 3 | cup | corned beef | ✓ |
| 3 chopped potatoes | 3 | — | potatoes | 3 | tbsp | potatoes | ≠ |
| Dash of kosher salt | — | dash | kosher salt | 1 | dash | kosher salt | ≠ |
| Dash of black pepper | — | dash | black pepper | 1 | dash | black pepper | ≠ |

### no-headers-10-thai-beef-stir-fry (no-headers)

**4 ingredients** | 4 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 2 tablespoons vegetable oil | 2 | tbsp | vegetable oil | — | — | vegetable oil | ≠ |
| 400g beef strips | 400 | g | beef strips | — | — | beef strips | ≠ |
| 1 sliced red chilli | 1 | — | red chilli | — | — | sliced red chilli | ≠ |
| 2 tablespoons oyster sauce | 2 | tbsp | oyster sauce | — | — | oyster sauce | ≠ |

### unusual-metadata-01-beef-empanadas (unusual-metadata)

**17 ingredients** | 14 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 60g lard | 60 | g | lard | 0.6 | g | lard | ≠ |
| - 340g warm water | 340 | g | warm water | 0.34 | L | warm water | ≠ |
| - 1 tsp salt | 1 | tsp | salt | 0.005 | tsp | salt | ≠ |
| - 600g all purpose flour | 600 | g | all purpose flour | 0.6 | g | all purpose flour | ≠ |
| - 3 tomatoes | 3 | — | tomatoes | 3 | tomatoes | tomatoes | ≠ |
| - 1 clove garlic | 1 | clove | garlic | 1 | clove | garlic | ✓ |
| - 1 large red onion | 1 | — | large red onion | 1 | large red onion | red onion | ≠ |
| - Bunch of spring onions | — | bunch | spring onions | 1 | bunch of spring onions | spring onions | ≠ |
| - 750g sirloin steak | 750 | g | sirloin steak | 0.75 | g | sirloin steak | ≠ |
| - 1 tablespoon dried oregano | 1 | tbsp | dried oregano | 1 | tbsp | dried oregano | ✓ |
| - 1 tsp paprika | 1 | tsp | paprika | 0.5 | tsp | paprika | ≠ |
| - 1 tsp red pepper flakes | 1 | tsp | red pepper flakes | 0.5 | tsp | red pepper flakes | ≠ |
| - 1 tsp parsley | 1 | tsp | parsley | 1 | tsp | parsley | ✓ |
| - Salt to taste | — | — | salt | 0 | nil | salt | ≠ |
| - Pepper to taste | — | — | pepper | 0 | nil | pepper | ≠ |
| - 3 eggs | 3 | — | eggs | 2 | eggs | eggs | ≠ |
| - Splash of egg wash | — | splash | egg wash | 0.15 | tbsp | egg wash | ≠ |

### unusual-metadata-02-chicken-basquaise (unusual-metadata)

**17 ingredients** | 17 disagreements | 3 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 25g butter | 25 | g | butter | 0.25 | g | butter | ≠ |
| - 6 tablespoons olive oil | 6 | tbsp | olive oil | 0.4 | tbsp | olive oil | ≠ |
| - 2 sliced red onions | 2 | — | red onions | 2 | eggs | red onions | ≠ |
| - 3 large red peppers | 3 | — | large red peppers | 3 | large | red peppers | ≠ |
| - 130g chorizo | 130 | g | chorizo | 0.36 | g | chorizo | ≠ |
| - 8 sun-dried tomatoes | 8 | — | sun-dried tomatoes | 0.8 | sun-dried tomatoes | sun-dried tomatoes | ≠ |
| - 6 cloves sliced garlic | 6 | clove | sliced garlic | 0.83 | cloves | garlic | ≠ |
| - 300g basmati rice | 300 | g | basmati rice | 0.3 | cup | basmati rice | ≠ |
| - 1/2 tsp paprika | 0.5 | tsp | paprika | 0.25 | tsp | paprika | ≠ |
| - 4 bay leaves | 4 | — | bay leaves | 4 | bay leaves | bay leaves | ≠ |
| - Handful of thyme | — | handful | thyme | 1 | handful | thyme | ≠ |
| - 350ml chicken stock | 350 | ml | chicken stock | 0.35 | cup | chicken stock | ≠ |
| - 180g dry white wine | 180 | g | dry white wine | 0.18 | g | dry white wine | ≠ |
| - 2 lemons | 2 | — | lemons | 2 | lemons | lemons | ≠ |
| - 100g black olives | 100 | g | black olives | 0.1 | g | black olives | ≠ |
| - Salt to serve | — | — | salt | 0 |  | salt | ≠ |
| - Pepper to serve | — | — | pepper | 0 |  | pepper | ≠ |

### unusual-metadata-03-apple-cake (unusual-metadata)

**10 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 4 eggs | 4 | — | eggs | 0.99 | ml |  |
| - 200g sugar | 200 | g | sugar | 1.00 | regex |  |
| - 200g self-raising flour | 200 | g | self-raising flour | 1.00 | regex |  |
| - 200g melted butter | 200 | g | melted butter | 1.00 | regex |  |
| - 1 tsp vanilla extract | 1 | tsp | vanilla extract | 1.00 | regex |  |
| - 1 tsp ground cinnamon | 1 | tsp | ground cinnamon | 1.00 | regex |  |
| - 3 apples | 3 | — | apples | 1.00 | ml |  |
| - Pinch of salt | — | pinch | salt | 0.99 | ml |  |
| - Sprinkling of powdered sugar | — | — | sprinkling of powder | 0.80 | ml |  |
| 4. Add cinnamon, pinch of salt and vanil | 4 | pinch | add cinnamon | 0.71 | ml |  |

### unusual-metadata-04-thai-pumpkin-soup (unusual-metadata)

**10 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 4 tsp sunflower oil | 4 | tsp | sunflower oil | 1.00 | regex |  |
| - 1 sliced onion | 1 | — | onion | 1.00 | ml |  |
| - 1 tbsp grated ginger | 1 | tbsp | grated ginger | 1.00 | regex |  |
| - 1 stalk lemongrass | 1 | stalk | lemongrass | 0.97 | ml |  |
| - 4 tablespoons Thai red curry paste | 4 | tbsp | Thai red curry paste | 1.00 | regex |  |
| - 400ml coconut milk | 400 | ml | coconut milk | 1.00 | regex |  |
| - 800ml vegetable stock | 800 | ml | vegetable stock | 1.00 | regex |  |
| - Lime juice to taste | — | — | lime juice | 1.00 | ml |  |
| - Sugar to taste | — | — | sugar | 1.00 | ml |  |
| - Red chilli to serve | — | — | red chilli | 1.00 | ml |  |

### unusual-metadata-05-kentucky-fried-chicken (unusual-metadata)

**18 ingredients** | 5 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| Oil temperature: 350F / 175C | — | — | oil temperature 350f | 350 | F | oil | ≠ |
| - 1 whole chicken, cut up | 1 | — | whole chicken | 1 | whole chicken | chicken | ≠ |
| - 2 quarts neutral frying oil | 2 | quart | neutral frying oil | 2 | quarts | oil | ≠ |
| - 1 egg white | 1 | — | egg white | 1 | egg white | egg white | ≠ |
| - 1 1/2 cups flour | 1.5 | cup | flour | 1.5 | cups | flour | ≠ |
| - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1 | tbsp | brown sugar | ✓ |
| - 1 tablespoon salt | 1 | tbsp | salt | 1 | tbsp | salt | ✓ |
| - 1 tablespoon paprika | 1 | tbsp | paprika | 1 | tbsp | paprika | ✓ |
| - 2 teaspoons onion salt | 2 | tsp | onion salt | 2 | tsp | onion salt | ✓ |
| - 1 teaspoon chili powder | 1 | tsp | chili powder | 1 | tsp | chili powder | ✓ |
| - 1 teaspoon black pepper | 1 | tsp | black pepper | 1 | tsp | black pepper | ✓ |
| - 1/2 teaspoon celery salt | 0.5 | tsp | celery salt | 0.5 | tsp | celery salt | ✓ |
| - 1/2 teaspoon sage | 0.5 | tsp | sage | 0.5 | tsp | sage | ✓ |
| - 1/2 teaspoon garlic powder | 0.5 | tsp | garlic powder | 0.5 | tsp | garlic powder | ✓ |
| - 1/2 teaspoon allspice | 0.5 | tsp | allspice | 0.5 | tsp | allspice | ✓ |
| - 1/2 teaspoon oregano | 0.5 | tsp | oregano | 0.5 | tsp | oregano | ✓ |
| - 1/2 teaspoon basil | 0.5 | tsp | basil | 0.5 | tsp | basil | ✓ |
| - 1/2 teaspoon marjoram | 0.5 | tsp | marjoram | 0.5 | tsp | marjoram | ✓ |

### unusual-metadata-06-beef-rendang (unusual-metadata)

**12 ingredients** | 12 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 lb beef | 1 | lb | beef | 0.453592 | lb | beef | ≠ |
| - 5 tablespoons vegetable oil | 5 | tbsp | vegetable oil | 0.78125 | tbsp | vegetable oil | ≠ |
| - 1 cinnamon stick | 1 | — | cinnamon stick | 0.05 | clove | cinnamon stick | ≠ |
| - 3 cloves | 3 | clove | s | 0.05 | clove | clove | ≠ |
| - 3 star anise | 3 | — | star anise | 0.075 | clove | star anise | ≠ |
| - 3 cardamom pods | 3 | — | cardamom pods | 0.075 | clove | cardamom pods | ≠ |
| - 1 cup coconut cream | 1 | cup | coconut cream | 0.25 | cup | coconut cream | ≠ |
| - 1 cup water | 1 | cup | water | 0.25 | cup | water | ≠ |
| - 2 tablespoons tamarind paste | 2 | tbsp | tamarind paste | 0.375 | tbsp | tamarind paste | ≠ |
| - 6 lime leaves | 6 | — | lime leaves | 0.06 | clove | lime leaves | ≠ |
| - 1 tablespoon sugar | 1 | tbsp | sugar | 0.15 | tsp | sugar | ≠ |
| - 5 shallots | 5 | — | shallots | 2 | egg | shallots | ≠ |

### unusual-metadata-07-eccles-cakes (unusual-metadata)

**13 ingredients** | 6 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 250g butter (for pastry) | 250 | g | butter (for pastry) | 250 | g | butter | ≠ |
| - 350g plain flour | 350 | g | plain flour | 350 | g | plain flour | ✓ |
| - Juice of 1/2 lemon | — | — | lemon | 0.5 |  | lemon juice | ≠ |
| - 25g butter (for filling) | 25 | g | butter (for filling) | 25 | g | butter | ≠ |
| - 200g currants | 200 | g | currants | 200 | g | currants | ✓ |
| - 50g mixed peel | 50 | g | mixed peel | 50 | g | mixed peel | ✓ |
| - 100g muscovado sugar | 100 | g | muscovado sugar | 100 | g | muscovado sugar | ✓ |
| - 1 tsp cinnamon | 1 | tsp | cinnamon | 1 | tsp | cinnamon | ✓ |
| - 1 tsp ginger | 1 | tsp | ginger | 1 | tsp | ginger | ✓ |
| - 1 tsp allspice | 1 | tsp | allspice | 1 | tsp | allspice | ✓ |
| - Zest of 1 lemon | 1 | — | lemon | 1 |  | lemon zest | ≠ |
| - 1 beaten egg | 1 | — | egg | 1 |  | egg | ≠ |
| - Sprinkling of sugar | — | — | sprinkling of sugar | 1 |  | sugar | ≠ |

### unusual-metadata-08-salmon-eggs-benedict (unusual-metadata)

**9 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 salmon fillets | 2 | — | salmon fillets | 0.99 | ml |  |
| - 2 English muffins, split and toasted | 2 | — | english muffins | 0.97 | ml |  |
| - 4 eggs | 4 | — | eggs | 0.99 | ml |  |
| - 1 tablespoon white vinegar | 1 | tbsp | white vinegar | 1.00 | regex |  |
| - 3 egg yolks | 3 | — | egg yolks | 0.99 | ml |  |
| - 150g unsalted butter, melted | 150 | g | unsalted butter, mel | 1.00 | regex |  |
| - 1 tablespoon lemon juice | 1 | tbsp | lemon juice | 1.00 | regex |  |
| - Salt and pepper to taste | — | — | salt and pepper | 0.95 | ml |  |
| - Fresh dill for garnish | — | — | fresh dill | 0.98 | ml |  |

### unusual-metadata-09-chicken-couscous (unusual-metadata)

**10 ingredients** | 5 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 tbsp olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| - 1 chopped onion | 1 | — | onion | 1 |  | onion | ≠ |
| - 200g chicken breast | 200 | g | chicken breast | 400 | g | chicken breast | ≠ |
| - Pinch of ginger | — | pinch | ginger | 0.5 | pinch | ginger | ≠ |
| - 2 tablespoons harissa spice | 2 | tbsp | harissa spice | 2 | tbsp | harissa spice | ✓ |
| - 10 dried apricots | 10 | — | dried apricots | 10 |  | dried apricots | ≠ |
| - 220g chickpeas | 220 | g | chickpeas | 220 | g | chickpeas | ✓ |
| - 200g couscous | 200 | g | couscous | 200 | g | couscous | ✓ |
| - 200ml chicken stock | 200 | ml | chicken stock | 200 | ml | chicken stock | ✓ |
| - Handful of coriander | — | handful | coriander | 1.5 | handful | coriander | ≠ |

### unusual-metadata-10-dundee-cake (unusual-metadata)

**14 ingredients** | 4 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 100g whole almonds | 100 | g | whole almonds | 100 | g | whole almonds | ✓ |
| - 180g butter | 180 | g | butter | 180 | g | butter | ✓ |
| - 180g muscovado sugar | 180 | g | muscovado sugar | 180 | g | muscovado sugar | ✓ |
| - Zest of 1 orange | 1 | — | orange | 1 | orange | orange | ≠ |
| - 3 tablespoons apricot jam | 3 | tbsp | apricot jam | 3 | tbsp | apricot jam | ✓ |
| - 225g plain flour | 225 | g | plain flour | 225 | g | plain flour | ✓ |
| - 1 tsp baking powder | 1 | tsp | baking powder | 1 | tsp | baking powder | ✓ |
| - 3 large eggs | 3 | — | large eggs | 2 | eggs | eggs | ≠ |
| - 100g ground almonds | 100 | g | ground almonds | 100 | g | ground almonds | ✓ |
| - 2 tablespoons milk | 2 | tbsp | milk | 2 | tbsp | milk | ✓ |
| - 500g dried fruit | 500 | g | dried fruit | 500 | g | dried fruit | ✓ |
| - 100g glace cherries | 100 | g | glace cherries | 100 | g | glace cherries | ✓ |
| - 1 tablespoon milk (for glaze) | 1 | tbsp | milk (for glaze) | 1 | tbsp | milk | ≠ |
| - 2 tsp caster sugar (for glaze) | 2 | tsp | caster sugar (for gl | 2 | tsp | caster sugar | ≠ |

### messy-01-beef-bourguignon (messy)

*No ingredients classified by OCRLineClassifier*

### messy-02-general-tsos-chicken (messy)

**9 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 1/2 chicken breast | 1 | — | 1/2 chicken breast | 0.87 | ml |  |
| 3/4 cup plain flour | 0.75 | cup | plain flour | 1.00 | regex |  |
| 1 egg | 1 | — | egg | 1.00 | ml |  |
| 2 tbs starch | 2 | tbsp | starch | 1.00 | regex |  |
| 1 tbs baking powder | 1 | tbsp | baking powder | 1.00 | regex |  |
| 1 tsp salt | 1 | tsp | salt | 1.00 | regex |  |
| 1/2 tsp onion salt | 0.5 | tsp | onion salt | 1.00 | regex |  |
| 1/4 tsp garlic powder | 0.25 | tsp | garlic powder | 1.00 | regex |  |
| In a bowl, add the chicken, 1 pinch of s | — | — | In a bowl, add the c | 0.75 | ml | unit-abbreviation |

### messy-03-beef-lo-mein (messy)

*No ingredients classified by OCRLineClassifier*

### messy-04-irish-stew (messy)

**11 ingredients** | 8 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| You need about 2 lbs lamb shoulder (or m | — | — | you need | 2 | lb | lamb shoulder | ≠ |
| 4-5 medium potatoes peeled and quartered | — | — | medium potatoes | 4 | p | potatoes | ≠ |
| 3 carrots sliced thick | 3 | — | carrots | 3 | c | carrots | ≠ |
| 2 onions roughly chopped | 2 | — | onions | 2 | onions | onions | ≠ |
| 2 cups beef stock | 2 | cup | beef stock | 2 | c | beef stock | ≠ |
| 1 tablespoon butter | 1 | tbsp | butter | 1 | tbsp | butter | ✓ |
| a sprig of thyme | — | sprig | thyme | 1 | sprig | thyme | ≠ |
| 2 bay leaves | 2 | — | bay leaves | 2 | bay leaves | bay leaves | ≠ |
| 1 tablespoon Worcestershire sauce | 1 | tbsp | Worcestershire sauce | 1 | tbsp | Worcestershire sauce | ✓ |
| 1 tablespoon tomato paste | 1 | tbsp | tomato paste | 1 | tbsp | tomato paste | ✓ |
| salt and pepper | — | — | salt and pepper | 0 |  | salt and pepper | ≠ |

### messy-05-spanish-chicken-pie (messy)

**8 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 kg potatoes | 1 | kg | potatoes | 1 | kg | potatoes | ✓ |
| 3 tsp paprika | 3 | tsp | paprika | 3 | tsp | paprika | ✓ |
| 2 teaspoons olive oil | 2 | tsp | olive oil | 2 | tsp | olive oil | ✓ |
| 2 sliced onion | 2 | — | onion | 2 |  | onion | ≠ |
| 2 cloves minced garlic | 2 | clove | minced garlic | 2 | clove | garlic | ≠ |
| 800g tinned tomatoes | 800 | g | tinned tomatoes | 800 | g | tinned tomatoes | ✓ |
| 300g chicken | 300 | g | chicken | 300 | g | chicken | ✓ |
| 140g roasted pepper | 140 | g | roasted pepper | 140 | g | roasted pepper | ✓ |

### messy-06-hot-and-sour-soup (messy)

**15 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1/3 cup mushrooms | 0.333333 | cup | mushrooms | 1.00 | regex |  |
| 1/3 cup wood ear mushrooms | 0.333333 | cup | wood ear mushrooms | 1.00 | regex |  |
| 2/3 cup tofu (cubed) | 0.666667 | cup | tofu | 1.00 | regex |  |
| 1/2 cup bbq pork (sliced) | 0.5 | cup | bbq pork | 1.00 | regex |  |
| 2-1/2 cups chicken stock | — | — | 2-1/2 cups chicken s | 0.81 | ml | mixed-fraction |
| 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex |  |
| 1/4 tsp sugar | 0.25 | tsp | sugar | 1.00 | regex |  |
| 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1.00 | regex |  |
| 1/4 tsp white pepper | 0.25 | tsp | white pepper | 1.00 | regex |  |
| 1/2 tsp hot sauce | 0.5 | tsp | hot sauce | 1.00 | regex |  |
| 1-1/2 cups vinegar | — | — | 1-1/2 cups vinegar | 0.88 | ml | mixed-fraction |
| 1 tsp soy sauce | 1 | tsp | soy sauce | 1.00 | regex |  |
| 1 tbs cornstarch | 1 | tbsp | cornstarch | 1.00 | regex |  |
| 2 tbs water | 2 | tbsp | water | 1.00 | regex |  |
| 1/4 cup spring onions | 0.25 | cup | spring onions | 1.00 | regex |  |

### messy-07-chicken-fried-rice (messy)

**1 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 lb chicken thighs (boneless), 1 tsp sa | 1 | lb | chicken thighs (bone | 1.00 | regex |  |

### messy-08-creamy-tomato-soup (messy)

**5 ingredients** | 1 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| olive oil | — | — | olive oil | — | — | olive oil | ✓ |
| 2 onions | 2 | — | onions | — | — | 2 onions | ≠ |
| celery | — | — | celery | — | — | celery | ✓ |
| sugar | — | — | sugar | — | — | sugar | ✓ |
| passata | — | — | passata | — | — | passata | ✓ |

### messy-09-szechuan-beef (messy)

**1 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| First Cook the beef by adding 2 Tablespo | — | — | first cook | 0.55 | ml | unit-abbreviation |

### messy-10-sweet-and-sour-chicken (messy)

**1 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 lb chicken thighs cut into 1-inch piec | 1 | lb | chicken thighs cut i | 1.00 | regex |  |

### international-01-tandoori-chicken (international)

**12 ingredients** | 11 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - Juice of 2 lemons | 2 | — | lemons | — | — | lemon juice | ≠ |
| - 4 tsp paprika | 4 | tsp | paprika | — | — | paprika | ≠ |
| - 2 finely chopped red onions | 2 | — | red onions | — | — | red onion | ≠ |
| - 16 skinless chicken thighs | 16 | — | skinless chicken thi | — | — | skinless chicken thi | ≠ |
| - Vegetable oil for brushing | — | — | vegetable oil | — | — | vegetable oil | ✓ |
| - 300ml Greek yoghurt | 300 | ml | Greek yoghurt | — | — | Greek yogurt | ≠ |
| - 1 large piece ginger, grated | 1 | large piece | ginger | — | — | ginger | ≠ |
| - 4 garlic cloves, crushed | 4 | — | garlic cloves | — | — | garlic clove | ≠ |
| - 3/4 tsp garam masala | 0.75 | tsp | garam masala | — | — | garam masala | ≠ |
| - 3/4 tsp ground cumin | 0.75 | tsp | ground cumin | — | — | ground cumin | ≠ |
| - 1/2 tsp chilli powder | 0.5 | tsp | chilli powder | — | — | chilli powder | ≠ |
| - 1/4 tsp turmeric | 0.25 | tsp | turmeric | — | — | turmeric | ≠ |

### international-02-chicken-congee (international)

**9 ingredients** | 5 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 225g chicken | 225 | g | chicken | 225 | g | chicken | ✓ |
| - Pinch of salt | — | pinch | salt | 0 | pinch | salt | ≠ |
| - Pinch of white pepper | — | pinch | white pepper | 0 | pinch | white pepper | ≠ |
| - 1 tsp ginger cordial | 1 | tsp | ginger cordial | 1 | tsp | ginger cordial | ✓ |
| - 1 tsp fresh ginger, sliced | 1 | tsp | fresh ginger, sliced | 1 | tsp | fresh ginger | ≠ |
| - 1 tbs spring onions, chopped | 1 | tbsp | spring onions, chopp | 1 | tbsp | spring onions | ≠ |
| - 110g rice | 110 | g | rice | 110 | g | rice | ✓ |
| - 2L water | 2 | l | water | 2 | L | water | ✓ |
| - 55g fresh coriander | 55 | g | fresh coriander | 55 | g | coriander | ≠ |

### international-03-beef-asado (international)

**14 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 beef stock concentrate | 1 | — | beef stock concentra | 0.95 | ml |  |
| - 225g tomato puree | 225 | g | tomato puree | 1.00 | regex |  |
| - 750ml water | 750 | ml | water | 1.00 | regex |  |
| - 6 tablespoons soy sauce | 6 | tbsp | soy sauce | 1.00 | regex |  |
| - 1 tbs white wine vinegar | 1 | tbsp | white wine vinegar | 1.00 | regex |  |
| - 2 tbs crushed pepper | 2 | tbsp | crushed pepper | 1.00 | regex |  |
| - 4 bay leaves | 4 | — | bay leaves | 0.91 | ml |  |
| - 1/2 lemon | — | — | 1/2 lemon | 0.83 | ml |  |
| - 2 tbs tomato sauce | 2 | tbsp | tomato sauce | 1.00 | regex |  |
| - 3 tbs butter | 3 | tbsp | butter | 1.00 | regex |  |
| - 120ml olive oil | 120 | ml | olive oil | 1.00 | regex |  |
| - 1 chopped onion | 1 | — | onion | 1.00 | ml |  |
| - 4 cloves garlic | 4 | clove | garlic | 1.00 | regex |  |
| 6. In 3 tablespoons of the cooking oil,  | 6 | — | cooking oil | 0.71 | ml | unit-abbreviation |

### international-04-parkin-cake (international)

**9 ingredients** | 3 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 200g butter | 200 | g | butter | 200 | g | butter | ✓ |
| - 1 large egg | 1 | — | large egg | 1 | large egg | egg | ≠ |
| - 4 tbs milk | 4 | tbsp | milk | 4 | tbs | milk | ≠ |
| - 200g golden syrup | 200 | g | golden syrup | 200 | g | golden syrup | ✓ |
| - 85g black treacle | 85 | g | black treacle | 85 | g | black treacle | ✓ |
| - 85g brown sugar | 85 | g | brown sugar | 85 | g | brown sugar | ✓ |
| - 100g oatmeal | 100 | g | oatmeal | 100 | g | oatmeal | ✓ |
| - 250g self-raising flour | 250 | g | self-raising flour | 250 | g | self-raising flour | ✓ |
| - 1 tbs ground ginger | 1 | tbsp | ground ginger | 1 | tbs | ground ginger | ≠ |

### international-05-minced-beef-pie (international)

**10 ingredients** | 9 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs vegetable oil | 2 | tbsp | vegetable oil | 2 | tbs | vegetable oil | ≠ |
| - 500g minced beef | 500 | g | minced beef | 5 | g | minced beef | ≠ |
| - 1 chopped onion | 1 | — | onion | 1 |  | onion | ≠ |
| - 1 tbs tomato puree | 1 | tbsp | tomato puree | 1 | tbs | tomato puree | ≠ |
| - 1 1/2 tbsp plain flour | 1.5 | tbsp | plain flour | 1.5 | tbsp | plain flour | ✓ |
| - 75g mushrooms | 75 | g | mushrooms | 0.075 | g | mushrooms | ≠ |
| - 250ml beef stock | 250 | ml | beef stock | 0.25 | ml | beef stock | ≠ |
| - Dash of Worcestershire sauce | — | dash | worcestershire sauce | 0.05 |  | Worcestershire sauce | ≠ |
| - 400g shortcrust pastry | 400 | g | shortcrust pastry | 4 | g | shortcrust pastry | ≠ |
| - 1 egg yolk | 1 | — | egg yolk | 1 | egg yolk | egg yolk | ≠ |

### international-06-massaman-beef-curry (international)

**13 ingredients** | 9 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 85g peanuts | 85 | g | peanuts | 0.85 | g | peanuts | ≠ |
| - 400ml tin coconut cream | 400 | ml | tin coconut cream | 0.4 | L | coconut cream | ≠ |
| - 4 tbsp massaman curry paste | 4 | tbsp | massaman curry paste | 4 | tbsp | massaman curry paste | ✓ |
| - 600g stewing beef, cut into strips | 600 | g | stewing beef, cut in | 0.6 | g | beef shin | ≠ |
| - 450g waxy potatoes | 450 | g | waxy potatoes | 0.45 | g | waxy potatoes | ≠ |
| - 1 onion, cut in thin wedges | 1 | — | onion | 1 | onion | onion | ≠ |
| - 4 lime leaves | 4 | — | lime leaves | 4 | leaves | lime leaves | ≠ |
| - 1 cinnamon stick | 1 | — | cinnamon stick | 1 | stick | cinnamon | ≠ |
| - 1 tbsp tamarind paste | 1 | tbsp | tamarind paste | 1 | tbsp | tamarind paste | ✓ |
| - 1 tbsp palm or soft light brown sugar | 1 | tbsp | palm or soft light b | 1 | tbsp | palm or soft light b | ✓ |
| - 1 tbsp fish sauce | 1 | tbsp | fish sauce | 1 | tbsp | fish sauce | ✓ |
| - 1 red chilli, deseeded and finely slic | 1 | — | red chilli | 1 | red chili | red chili | ≠ |
| - Jasmine rice to serve | — | — | jasmine rice | 1 | cup | Jasmine rice | ≠ |

### international-07-madeira-cake (international)

**8 ingredients** | 5 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 175g butter | 175 | g | butter | 175 | g | butter | ✓ |
| - 175g caster sugar | 175 | g | caster sugar | 175 | g | caster sugar | ✓ |
| - 3 eggs | 3 | — | eggs | 3 | eggs | eggs | ≠ |
| - 250g self-raising flour | 250 | g | self-raising flour | 250 | g | self-raising flour | ✓ |
| - 3 tbs milk | 3 | tbsp | milk | 3 | tbs | milk | ≠ |
| - Zest of 1 lemon | 1 | — | lemon | 1 | lemon | lemon | ≠ |
| - Mixed peel to glaze | — | — | mixed peel | 1 | peel | peel | ≠ |
| 2. Cream the butter and sugar together i | 2 | — | cream the butter and | — | — | cream | ≠ |

### international-08-thai-green-chicken-soup (international)

**14 ingredients** | 9 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs sunflower oil | 2 | tbsp | sunflower oil | 2 | tbs | sunflower oil | ≠ |
| - 1 chopped onion | 1 | — | onion | 1 | chopped | onion | ≠ |
| - 500g chicken thighs | 500 | g | chicken thighs | 500 | g | chicken thighs | ✓ |
| - 4 sliced garlic cloves | 4 | — | garlic cloves | 4 | sliced | garlic cloves | ≠ |
| - 280g Thai green curry paste | 280 | g | Thai green curry pas | 280 | g | Thai green curry pas | ✓ |
| - 400ml coconut milk | 400 | ml | coconut milk | 400 | ml | coconut milk | ✓ |
| - 2 litres chicken stock | 2 | litres | chicken stock | 2 | L | chicken stock | ≠ |
| - 5 lime leaves | 5 | — | lime leaves | 5 | leaves | lime leaves | ≠ |
| - 2 tbs fish sauce | 2 | tbsp | fish sauce | 2 | tbs | fish sauce | ≠ |
| - 1 bunch spring onions | 1 | bunch | spring onions | 1 | bunches | spring onions | ≠ |
| - 280g green beans | 280 | g | green beans | 280 | g | green beans | ✓ |
| - 150g bamboo shoots | 150 | g | bamboo shoots | 150 | g | bamboo shoots | ✓ |
| - Juice of 2 limes | 2 | — | limes | 2 | juice | limes | ≠ |
| - Bunch of basil | — | bunch | basil | 1 | bunches | basil | ≠ |

### international-09-red-peas-soup (international)

**15 ingredients** | 8 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 cups kidney beans | 2 | cup | kidney beans | 2 | cup | kidney beans | ✓ |
| - 1 large carrot | 1 | — | large carrot | 1 | large | carrot | ≠ |
| - 2 chopped spring onions | 2 | — | spring onions | 2 | sprig | spring onions | ≠ |
| - 4 sprigs thyme | 4 | sprig | thyme | 4 | sprig | thyme | ✓ |
| - 1 diced onion | 1 | — | onion | 1 | tbsp | onion | ≠ |
| - 1/2 tsp black pepper | 0.5 | tsp | black pepper | 0.5 | tsp | black pepper | ✓ |
| - 2 chopped red peppers | 2 | — | red peppers | 2 | sprig | red peppers | ≠ |
| - 4 mashed garlic cloves | 4 | — | garlic cloves | 4 | clove | garlic | ≠ |
| - 1 tbs allspice | 1 | tbsp | allspice | 1 | tbsp | allspice | ✓ |
| - 900g beef | 900 | g | beef | 9 | g | beef | ≠ |
| - 2L water | 2 | l | water | 2 | L | water | ✓ |
| - 4 potatoes | 4 | — | potatoes | 4 | pcs | potatoes | ≠ |
| - 1 cup plain flour | 1 | cup | plain flour | 1 | cup | flour | ≠ |
| - 1/4 cup water | 0.25 | cup | water | 0.25 | cup | water | ✓ |
| - 1 cup coconut milk | 1 | cup | coconut milk | 1 | cup | coconut milk | ✓ |

### international-10-fish-soup-ukha (international)

**9 ingredients** | 9 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs olive oil | 2 | tbsp | olive oil | 2 | tbs | olive oil | ≠ |
| - 1 sliced onion | 1 | — | onion | 1 | sliced | onion | ≠ |
| - 2 medium carrots | 2 | — | medium carrots | 2 | medium | carrots | ≠ |
| - 750ml fish stock | 750 | ml | fish stock | 7.5 | ml | fish stock | ≠ |
| - 750ml water | 750 | ml | water | 7.5 | ml | water | ≠ |
| - 4 large potatoes | 4 | — | large potatoes | 4 | large | potatoes | ≠ |
| - 3 bay leaves | 3 | — | bay leaves | 3 | bay leaves | bay leaves | ≠ |
| - 1 whole cod fillet | 1 | — | whole cod fillet | 1 | whole | cod fillet | ≠ |
| - 1 whole salmon fillet | 1 | — | whole salmon fillet | 1 | whole | salmon fillet | ≠ |

