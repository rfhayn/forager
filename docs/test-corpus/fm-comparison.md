# FM vs Pipeline — Ingredient Parsing Comparison

**Generated**: 2026-02-26T12:08:35Z
**FM Available**: true
**Recipes**: 50
**Ingredient Lines**: 442

---

## Summary

| Metric | Pipeline | Foundation Models |
|--------|----------|-------------------|
| Qty extracted | 288/442 (65.2%) | 348/442 (78.7%) |
| Disagreements | — | 269 lines |
| FM fixes pipeline gaps | — | 126 lines |

## Disagreements — FM ≠ Pipeline

These lines had different results. Review to determine which parser is correct.

| Input | Pipeline | FM |
|-------|----------|----|
| - 5 thinly sliced onion | qty=5 unit=nil name=onion | qty=5 unit=onion name=onion |
| - 2 finely chopped tomatoes | qty=2 unit=nil name=tomatoes | qty=2 unit=tomatoes name=tomatoes |
| - 2 green chilli | qty=2 unit=nil name=green chilli | qty=2 unit=green chilli name=green chilli |
| - 3 tsp dried fenugreek | qty=3 unit=tsp name=dried fenugreek | qty=3 unit=tsp name=fenugreek |
| - Salt to taste | qty=nil unit=nil name=salt | qty=0 unit=nil name=Salt |
| - 400g mushrooms | qty=nil unit=nil name=400g mushrooms | qty=400 unit=g name=mushrooms |
| - 1-2 tbsp English mustard | qty=nil unit=tbsp name=english mustard | qty=1.5 unit=tbsp name=English mustard |
| - Dash of olive oil | qty=nil unit=dash name=olive oil | qty=0.5 unit=tbsp name=olive oil |
| - 750g piece beef fillet | qty=nil unit=piece name=beef fillet | qty=750 unit=g name=piece beef fillet |
| - 6-8 slices Parma ham | qty=nil unit=slice name=parma ham | qty=6.5 unit=slices name=Parma ham |
| - 500g puff pastry | qty=nil unit=nil name=500g puff pastry | qty=500 unit=g name=puff pastry |
| - Flour for dusting | qty=nil unit=nil name=flour | qty=0 unit= name=Flour |
| - 2 beaten egg yolks | qty=2 unit=nil name=egg yolks | qty=2 unit=egg yolks name=egg yolks |
| - 1 medium finely diced onion | qty=1 unit=nil name=medium onion | qty=1 unit=medium name=onion |
| - 250g chickpeas | qty=nil unit=nil name=250g chickpeas | qty=0.25 unit=g name=chickpeas |
| - 1.5L vegetable stock | qty=nil unit=nil name=1.5l vegetable stock | qty=1.5 unit=L name=vegetable stock |
| - 5 cloves garlic | qty=5 unit=clove name=garlic | qty=5 unit=cloves name=garlic |
| - Pinch of pepper | qty=nil unit=pinch name=pepper | qty=1 unit=pinch name=pepper |
| - 1/2 lime | qty=nil unit=nil name=1/2 lime | qty=0.5 unit=lime name=lime |
| - 450ml vegetable oil | qty=nil unit=nil name=450ml vegetable oil | qty=450 unit=ml name=vegetable oil |
| - 400g plain flour | qty=nil unit=nil name=400g plain flour | qty=400 unit=g name=plain flour |
| - 550ml sugar | qty=nil unit=nil name=550ml sugar | qty=550 unit=ml name=sugar |
| - 5 eggs | qty=5 unit=nil name=eggs | qty=2 unit=egg name=eggs |
| - 500g grated carrots | qty=nil unit=nil name=carrots | qty=500 unit=g name=grated carrots |
| - 150g walnuts | qty=nil unit=nil name=150g walnuts | qty=150 unit=g name=walnuts |
| - 200g cream cheese | qty=nil unit=nil name=200g cream cheese | qty=200 unit=g name=cream cheese |
| - 150g caster sugar | qty=nil unit=nil name=150g caster sugar | qty=150 unit=g name=caster sugar |
| - 100g butter | qty=nil unit=nil name=100g butter | qty=100 unit=g name=butter |
| - 50g butter | qty=nil unit=nil name=50g butter | qty=50 unit=g name=butter |
| - 4 sliced garlic cloves | qty=4 unit=nil name=garlic cloves | qty=4 unit=clove name=garlic cloves |
| - 250ml dry white wine | qty=nil unit=nil name=250ml dry white wine | qty=250 unit=ml name=dry white wine |
| - 1L beef stock | qty=nil unit=nil name=1l beef stock | qty=1 unit=L name=beef stock |
| - 4 slices bread | qty=4 unit=nil name=slices bread | qty=4 unit=clove name=bread |
| - 140g Gruyere cheese | qty=nil unit=nil name=140g gruyere cheese | qty=140 unit=g name=Gruyere cheese |
| - 1 tablespoon olive oil | qty=1 unit=tbsp name=olive oil | qty=nil unit=nil name=olive oil |
| - 1 onion | qty=1 unit=nil name=onion | qty=nil unit=nil name=onion |
| - 1 clove garlic | qty=1 unit=clove name=garlic | qty=nil unit=nil name=garlic |
| - 1 tbsp butter | qty=1 unit=tbsp name=butter | qty=nil unit=nil name=butter |
| - 250g mushrooms | qty=nil unit=nil name=250g mushrooms | qty=nil unit=nil name=mushrooms |
| - 500g beef fillet | qty=nil unit=nil name=500g beef fillet | qty=nil unit=nil name=beef fillet |
| - 1 tbsp plain flour | qty=1 unit=tbsp name=plain flour | qty=nil unit=nil name=plain flour |
| - 150g creme fraiche | qty=nil unit=nil name=150g creme fraiche | qty=nil unit=nil name=creme fraiche |
| - 1 tbsp English mustard | qty=1 unit=tbsp name=english mustard | qty=nil unit=nil name=English mustard |
| - 100ml beef stock | qty=nil unit=nil name=100ml beef stock | qty=nil unit=nil name=beef stock |
| - 500g fusilli pasta | qty=nil unit=nil name=500g fusilli pasta | qty=500 unit=g name=fusilli pasta |
| - 200g cherry tomatoes, halved | qty=nil unit=nil name=cherry tomatoes | qty=200 unit=g name=cherry tomatoes |
| - 1 cucumber, diced | qty=1 unit=nil name=cucumber | qty=1 unit=g name=cucumber |
| - 150g Kalamata olives | qty=nil unit=nil name=150g kalamata olives | qty=150 unit=g name=Kalamata olives |
| - 200g feta cheese, crumbled | qty=nil unit=nil name=200g feta cheese | qty=200 unit=g name=feta cheese |
| - 1 red onion, thinly sliced | qty=1 unit=nil name=red onion | qty=1 unit=g name=red onion |
| - 2 tablespoons red wine vinegar | qty=2 unit=nil name=tablespoons red wine | qty=2 unit=tbsp name=red wine vinegar |
| - 100g flour | qty=nil unit=nil name=100g flour | qty=100 unit=g name=flour |
| - 2 large eggs | qty=2 unit=nil name=large eggs | qty=2 unit=large eggs name=eggs |
| - 300ml milk | qty=nil unit=nil name=300ml milk | qty=300 unit=ml name=milk |
| - Sugar to serve | qty=nil unit=nil name=sugar | qty=0 unit=nil name=sugar |
| - Raspberries to serve | qty=nil unit=nil name=raspberries | qty=0 unit=nil name=raspberries |
| - Blueberries to serve | qty=nil unit=nil name=blueberries | qty=0 unit=nil name=blueberries |
| - 2 tablespoons sake | qty=2 unit=nil name=tablespoons sake | qty=2 unit=tbsp name=sake |
| - 2 tablespoons soy sauce | qty=2 unit=nil name=tablespoons soy sauc | qty=2 unit=tbsp name=soy sauce |
| - 2 tablespoons sesame seed oil | qty=2 unit=nil name=tablespoons sesame s | qty=2 unit=tbsp name=sesame seed oil |
| - 2 tablespoons water | qty=2 unit=nil name=tablespoons water | qty=2 unit=tbsp name=water |
| - 500g chicken | qty=nil unit=nil name=500g chicken | qty=500 unit=g name=chicken |
| - 1 tablespoon chilli powder | qty=1 unit=tbsp name=chilli powder | qty=1 unit=tsp name=chilli powder |
| - 4 chopped spring onions | qty=4 unit=nil name=spring onions | qty=4 unit=clove name=spring onions |
| - 220g water chestnuts | qty=nil unit=nil name=220g water chestnuts | qty=220 unit=g name=water chestnuts |
| - 100g peanuts | qty=nil unit=nil name=100g peanuts | qty=100 unit=g name=peanuts |
| - 1kg ham | qty=nil unit=nil name=1kg ham | qty=1 unit=kg name=ham |
| - 200g peas, soaked overnight | qty=nil unit=nil name=200g peas | qty=0.2 unit=g name=peas |
| - 2 chopped onions | qty=2 unit=nil name=onions | qty=0.2 unit=g name=onions |
| - 2 chopped carrots | qty=2 unit=nil name=carrots | qty=0.2 unit=g name=carrots |
| - 2 bay leaves | qty=2 unit=nil name=bay leaves | qty=2 unit=bay leaves name=bay leaves |
| - 1 chopped celery stalk | qty=1 unit=stalk name=celery | qty=0.3 unit=g name=celery |
| - 300g frozen peas | qty=nil unit=nil name=300g frozen peas | qty=0.3 unit=g name=frozen peas |
| - Bread to serve | qty=nil unit=nil name=bread | qty=0.5 unit=cup name=bread |
| 1 lb salmon | qty=1 unit=lb name=salmon | qty=0.453592 unit=lb name=salmon |
| 1 L beef stock | qty=1 unit=l name=beef stock | qty=nil unit=nil name=beef stock |
| 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=nil unit=nil name=cinnamon stick |
| 1 tsp coriander seeds | qty=1 unit=tsp name=coriander seeds | qty=nil unit=nil name=coriander seeds |
| 1/2 teaspoon cloves | qty=0.5 unit=tsp name=cloves | qty=nil unit=nil name=cloves |
| 225g sirloin steak | qty=225 unit=g name=sirloin steak | qty=nil unit=nil name=sirloin steak |
| 1 tsp palm sugar | qty=1 unit=tsp name=palm sugar | qty=nil unit=nil name=palm sugar |
| 1 tablespoon fish sauce | qty=1 unit=tbsp name=fish sauce | qty=nil unit=nil name=fish sauce |
| 1 1/2 tbsp soy sauce | qty=1.5 unit=tbsp name=soy sauce | qty=nil unit=nil name=soy sauce |
| 200g rice noodles | qty=200 unit=g name=rice noodles | qty=nil unit=nil name=rice noodles |
| 1 tablespoon olive oil | qty=1 unit=tbsp name=olive oil | qty=1.5 unit=tbsp name=olive oil |
| 3 cups chicken stock | qty=3 unit=cup name=chicken stock | qty=nil unit=nil name=chicken stock |
| 1/4 tsp salt | qty=0.25 unit=tsp name=salt | qty=0.75 unit=tsp name=salt |
| Pinch of pepper | qty=nil unit=pinch name=pepper | qty=0 unit=pinch name=pepper |
| 1/3 cup peas | qty=0.333333 unit=cup name=peas | qty=0.25 unit=cup name=peas |
| 1/3 cup mushrooms | qty=0.333333 unit=cup name=mushrooms | qty=0.25 unit=cup name=mushrooms |
| 1 tablespoon cornstarch | qty=1 unit=tbsp name=cornstarch | qty=1.25 unit=tbsp name=cornstarch |
| 100g mixed salad leaves | qty=100 unit=g name=mixed salad leaves | qty=0.1 unit=g name=salad leaves |
| 1/2 cucumber, sliced | qty=nil unit=nil name=1/2 cucumber | qty=0.5 unit= name=cucumber |
| 2 tablespoons extra virgin olive oil | qty=2 unit=tbsp name=extra virgin olive o | qty=3 unit=tbsp name=olive oil |
| 1 tablespoon lemon juice | qty=1 unit=tbsp name=lemon juice | qty=1 unit=tsp name=lemon juice |
| 2 tablespoons soy sauce | qty=2 unit=tbsp name=soy sauce | qty=2 unit=tablespoon name=soy sauce |
| 1 tablespoon honey | qty=1 unit=tbsp name=honey | qty=1 unit=tablespoon name=honey |
| 1 tablespoon olive oil | qty=1 unit=tbsp name=olive oil | qty=1 unit=tablespoon name=olive oil |
| 1 teaspoon tomato puree | qty=1 unit=tsp name=tomato puree | qty=1 unit=teaspoon name=tomato puree |
| 1 tablespoon Dijon mustard | qty=1 unit=tbsp name=Dijon mustard | qty=1 unit=tablespoon name=Dijon mustard |
| 3 tablespoons unsalted butter | qty=3 unit=tbsp name=unsalted butter | qty=45 unit=tbsp name=butter |
| 3 cups corned beef | qty=3 unit=cup name=corned beef | qty=375 unit=g name=corned beef |
| Dash of kosher salt | qty=nil unit=dash name=kosher salt | qty=0 unit=g name=kosher salt |
| Dash of black pepper | qty=nil unit=dash name=black pepper | qty=0 unit=g name=black pepper |
| 2 tablespoons vegetable oil | qty=2 unit=tbsp name=vegetable oil | qty=30 unit=tbsp name=vegetable oil |
| 2 tablespoons oyster sauce | qty=2 unit=tbsp name=oyster sauce | qty=30 unit=tbsp name=oyster sauce |
| - 60g lard | qty=nil unit=nil name=60g lard | qty=0.6 unit=g name=lard |
| - 340g warm water | qty=nil unit=nil name=340g warm water | qty=3.4 unit=g name=warm water |
| - 1 tsp salt | qty=1 unit=tsp name=salt | qty=0.5 unit=tsp name=salt |
| - 600g all purpose flour | qty=nil unit=nil name=600g all purpose flo | qty=0.6 unit=g name=all purpose flour |
| - 3 tomatoes | qty=3 unit=nil name=tomatoes | qty=3 unit=tomatoes name=tomatoes |
| - 1 large red onion | qty=1 unit=nil name=large red onion | qty=1 unit=clove name=garlic |
| - Bunch of spring onions | qty=nil unit=bunch name=spring onions | qty=1 unit=clove name=garlic |
| - 750g sirloin steak | qty=nil unit=nil name=750g sirloin steak | qty=0.75 unit=g name=sirloin steak |
| - Salt to taste | qty=nil unit=nil name=salt | qty=0 unit=nil name=salt |
| - Pepper to taste | qty=nil unit=nil name=pepper | qty=0 unit=nil name=pepper |
| - 3 eggs | qty=3 unit=nil name=eggs | qty=2 unit=eggs name=eggs |
| - Splash of egg wash | qty=nil unit=splash name=egg wash | qty=0 unit=nil name=egg wash |
| - Drizzle of chimichurri sauce | qty=nil unit=nil name=drizzle of chimichur | qty=0 unit=nil name=chimichurri sauce |
| - 4 eggs | qty=4 unit=nil name=eggs | qty=4 unit=egg name=egg |
| - 200g sugar | qty=nil unit=nil name=200g sugar | qty=2 unit=g name=sugar |
| - 200g self-raising flour | qty=nil unit=nil name=200g self-raising fl | qty=2 unit=g name=self-raising flour |
| - 200g melted butter | qty=nil unit=nil name=butter | qty=2 unit=g name=melted butter |
| - 3 apples | qty=3 unit=nil name=apples | qty=3 unit=egg name=apple |
| - Pinch of salt | qty=nil unit=pinch name=salt | qty=0 unit=pinch name=salt |
| - Sprinkling of powdered sugar | qty=nil unit=nil name=sprinkling of powder | qty=0 unit=sprinkle name=powdered sugar |
| 4. Add cinnamon, pinch of salt and vanilla extract. | qty=4 unit=pinch name=add cinnamon | qty=0 unit=none name=cinnamon |
| - 1 whole chicken, cut up | qty=1 unit=nil name=whole chicken | qty=1 unit=whole name=chicken |
| - 2 quarts neutral frying oil | qty=2 unit=nil name=quarts neutral fryin | qty=2 unit=qt name=frying oil |
| - 1 egg white | qty=1 unit=nil name=egg white | qty=1 unit=egg white name=egg white |
| - 1 1/2 cups flour | qty=1 unit=1/2 name=cups flour | qty=1 unit=1.5 name=cups flour |
| - 1 tablespoon salt | qty=1 unit=tbsp name=salt | qty=1 unit=tsp name=salt |
| - 1 tablespoon paprika | qty=1 unit=tbsp name=paprika | qty=1 unit=tsp name=paprika |
| - 1 lb beef | qty=1 unit=lb name=beef | qty=0.453592 unit=lb name=beef |
| - 5 tablespoons vegetable oil | qty=5 unit=nil name=tablespoons vegetabl | qty=7.8125 unit=tbsp name=vegetable oil |
| - 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=1 unit=stick name=cinnamon |
| - 3 cloves | qty=3 unit=nil name=cloves | qty=3 unit=clove name=clove |
| - 3 star anise | qty=3 unit=nil name=star anise | qty=3 unit=star anise name=star anise |
| - 3 cardamom pods | qty=3 unit=nil name=cardamom pods | qty=3 unit=cardamom pods name=cardamom pods |
| - 1 cup coconut cream | qty=1 unit=cup name=coconut cream | qty=240 unit=ml name=coconut cream |
| - 1 cup water | qty=1 unit=cup name=water | qty=240 unit=ml name=water |
| - 2 tablespoons tamarind paste | qty=2 unit=tbsp name=tamarind paste | qty=3 unit=tbsp name=tamarind paste |
| - 6 lime leaves | qty=6 unit=nil name=lime leaves | qty=6 unit=leaf name=lime |
| - 1 tablespoon sugar | qty=1 unit=tbsp name=sugar | qty=15 unit=tsp name=sugar |
| - 5 shallots | qty=5 unit=nil name=shallots | qty=5 unit=shallot name=shallot |
| - 250g butter (for pastry) | qty=nil unit=nil name=250g butter | qty=250 unit=g name=butter |
| - 350g plain flour | qty=nil unit=nil name=350g plain flour | qty=350 unit=g name=plain flour |
| - Juice of 1/2 lemon | qty=nil unit=nil name=lemon | qty=0.5 unit=lemon name=lemon |
| - 25g butter (for filling) | qty=nil unit=nil name=25g butter | qty=25 unit=g name=butter |
| - 200g currants | qty=nil unit=nil name=200g currants | qty=200 unit=g name=currants |
| - 50g mixed peel | qty=nil unit=nil name=50g mixed peel | qty=50 unit=g name=mixed peel |
| - 100g muscovado sugar | qty=nil unit=nil name=100g muscovado sugar | qty=100 unit=g name=muscovado sugar |
| - Zest of 1 lemon | qty=1 unit=nil name=lemon | qty=1 unit=lemon name=lemon |
| - 1 beaten egg | qty=1 unit=nil name=egg | qty=1 unit=egg name=egg |
| - Sprinkling of sugar | qty=nil unit=nil name=sprinkling of sugar | qty=1 unit=sprinkle name=sugar |
| - 2 salmon fillets | qty=2 unit=nil name=salmon fillets | qty=2 unit=fillet name=salmon |
| - 2 English muffins, split and toasted | qty=2 unit=nil name=english muffins | qty=2 unit=muffin name=English muffin |
| - 4 eggs | qty=4 unit=nil name=eggs | qty=4 unit=egg name=egg |
| - 1 tablespoon white vinegar | qty=1 unit=tbsp name=white vinegar | qty=1 unit=tbsp name=vinegar |
| - 3 egg yolks | qty=3 unit=nil name=egg yolks | qty=3 unit=egg name=egg yolk |
| - 150g unsalted butter, melted | qty=nil unit=nil name=unsalted butter | qty=150 unit=g name=butter |
| - Salt and pepper to taste | qty=nil unit=nil name=salt and pepper | qty=0 unit= name=salt and pepper |
| - Fresh dill for garnish | qty=nil unit=nil name=fresh dill | qty=0 unit= name=dill |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit=tbsp name=onion |
| - 200g chicken breast | qty=nil unit=nil name=200g chicken breast | qty=400 unit=g name=chicken breast |
| - Pinch of ginger | qty=nil unit=pinch name=ginger | qty=1 unit=pinch name=ginger |
| - 2 tablespoons harissa spice | qty=2 unit=nil name=tablespoons harissa  | qty=2 unit=tbsp name=harissa spice |
| - 10 dried apricots | qty=10 unit=nil name=dried apricots | qty=10 unit=piece name=dried apricots |
| - 220g chickpeas | qty=nil unit=nil name=220g chickpeas | qty=220 unit=g name=chickpeas |
| - 200g couscous | qty=nil unit=nil name=200g couscous | qty=200 unit=g name=couscous |
| - 200ml chicken stock | qty=nil unit=nil name=200ml chicken stock | qty=200 unit=ml name=chicken stock |
| - Handful of coriander | qty=nil unit=handful name=coriander | qty=1 unit=handful name=coriander |
| - 100g whole almonds | qty=nil unit=nil name=100g whole almonds | qty=100 unit=g name=almonds |
| - 180g butter | qty=nil unit=nil name=180g butter | qty=180 unit=g name=butter |
| - 180g muscovado sugar | qty=nil unit=nil name=180g muscovado sugar | qty=180 unit=g name=muscovado sugar |
| - Zest of 1 orange | qty=1 unit=nil name=orange | qty=1 unit=orange name=orange |
| - 225g plain flour | qty=nil unit=nil name=225g plain flour | qty=225 unit=g name=flour |
| - 3 large eggs | qty=3 unit=nil name=large eggs | qty=2 unit=eggs name=eggs |
| - 100g ground almonds | qty=nil unit=nil name=almonds | qty=100 unit=g name=almonds |
| - 500g dried fruit | qty=nil unit=nil name=500g dried fruit | qty=500 unit=g name=dried fruit |
| - 100g glace cherries | qty=nil unit=nil name=100g glace cherries | qty=100 unit=g name=glace cherries |
| You need about 2 lbs lamb shoulder (or mutton if you ca | qty=nil unit=nil name=you need | qty=2 unit=lb name=lamb shoulder |
| 4-5 medium potatoes peeled and quartered | qty=nil unit=nil name=medium potatoes | qty=4 unit=medium name=potatoes |
| a sprig of thyme | qty=nil unit=sprig name=thyme | qty=1 unit=sprig name=thyme |
| - Juice of 2 lemons | qty=2 unit=nil name=lemons | qty=2 unit=lemons name=lemon |
| - 2 finely chopped red onions | qty=2 unit=nil name=red onions | qty=2 unit=onions name=red onion |
| - 16 skinless chicken thighs | qty=16 unit=nil name=skinless chicken thi | qty=16 unit=thighs name=chicken |
| - Vegetable oil for brushing | qty=nil unit=nil name=vegetable oil | qty=0 unit=unknown name=vegetable oil |
| - 300ml Greek yoghurt | qty=nil unit=nil name=300ml greek yoghurt | qty=300 unit=ml name=Greek yoghurt |
| - 1 large piece ginger, grated | qty=1 unit=large piece name=ginger | qty=1 unit=ginger name=ginger |
| - 4 garlic cloves, crushed | qty=4 unit=nil name=garlic cloves | qty=4 unit=cloves name=garlic |
| - 225g chicken | qty=nil unit=nil name=225g chicken | qty=0.225 unit=g name=chicken |
| - Pinch of salt | qty=nil unit=pinch name=salt | qty=0 unit=pinch name=salt |
| - Pinch of white pepper | qty=nil unit=pinch name=white pepper | qty=0 unit=pinch name=white pepper |
| - 1 tsp ginger cordial | qty=1 unit=tsp name=ginger cordial | qty=0.049 unit=tsp name=ginger cordial |
| - 1 tsp fresh ginger, sliced | qty=1 unit=tsp name=fresh ginger | qty=0.049 unit=tsp name=fresh ginger |
| - 1 tbs spring onions, chopped | qty=1 unit=nil name=tbs spring onions | qty=0.042 unit=tbs name=spring onions |
| - 110g rice | qty=nil unit=nil name=110g rice | qty=0.11 unit=g name=rice |
| - 2L water | qty=nil unit=nil name=2l water | qty=0.055 unit=g name=coriander |
| - 55g fresh coriander | qty=nil unit=nil name=fresh coriander | qty=0 unit= name=water |
| - 1.5kg beef | qty=nil unit=nil name=1.5kg beef | qty=1.5 unit=kg name=beef |
| - 1 beef stock concentrate | qty=1 unit=nil name=beef stock concentra | qty=1 unit=stock concentrate name=beef stock concentra |
| - 225g tomato puree | qty=nil unit=nil name=225g tomato puree | qty=225 unit=g name=tomato puree |
| - 750ml water | qty=nil unit=nil name=750ml water | qty=750 unit=ml name=water |
| - 6 tablespoons soy sauce | qty=6 unit=nil name=tablespoons soy sauc | qty=6 unit=tbsp name=soy sauce |
| - 1 tbs white wine vinegar | qty=1 unit=tbsp name=white wine vinegar | qty=1 unit=tsp name=white wine vinegar |
| - 2 tbs crushed pepper | qty=2 unit=nil name=pepper | qty=2 unit=tbsp name=crushed pepper |
| - 4 bay leaves | qty=4 unit=nil name=bay leaves | qty=4 unit=bay leaves name=bay leaves |
| - 1/2 lemon | qty=nil unit=nil name=1/2 lemon | qty=0.5 unit=lemon name=lemon |
| - 120ml olive oil | qty=nil unit=nil name=120ml olive oil | qty=120 unit=ml name=olive oil |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit=chopped name=onion |
| - 4 cloves garlic | qty=4 unit=clove name=garlic | qty=4 unit=cloves name=garlic |
| - 200g butter | qty=nil unit=nil name=200g butter | qty=200 unit=g name=butter |
| - 1 large egg | qty=1 unit=nil name=large egg | qty=1 unit=large egg name=egg |
| - 4 tbs milk | qty=4 unit=nil name=tbs milk | qty=4 unit=tbs name=milk |
| - 200g golden syrup | qty=nil unit=nil name=200g golden syrup | qty=200 unit=g name=golden syrup |
| - 85g black treacle | qty=nil unit=nil name=black treacle | qty=85 unit=g name=black treacle |
| - 85g brown sugar | qty=nil unit=nil name=85g brown sugar | qty=85 unit=g name=brown sugar |
| - 100g oatmeal | qty=nil unit=nil name=100g oatmeal | qty=100 unit=g name=oatmeal |
| - 250g self-raising flour | qty=nil unit=nil name=250g self-raising fl | qty=250 unit=g name=self-raising flour |
| - 1 tbs ground ginger | qty=1 unit=tbsp name=ginger | qty=1 unit=tbs name=ground ginger |
| - 2 tbs vegetable oil | qty=2 unit=nil name=tbs vegetable oil | qty=2 unit=tbs name=vegetable oil |
| - 500g minced beef | qty=nil unit=nil name=beef | qty=5 unit=g name=minced beef |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit=chopped name=onion |
| - 1 tbs tomato puree | qty=1 unit=tbsp name=tomato puree | qty=1 unit=tbs name=tomato puree |
| - 75g mushrooms | qty=nil unit=nil name=75g mushrooms | qty=75 unit=g name=mushrooms |
| - 250ml beef stock | qty=nil unit=nil name=250ml beef stock | qty=250 unit=ml name=beef stock |
| - Dash of Worcestershire sauce | qty=nil unit=dash name=worcestershire sauce | qty=0.5 unit=dash name=Worcestershire sauce |
| - 400g shortcrust pastry | qty=nil unit=nil name=400g shortcrust past | qty=4 unit=g name=shortcrust pastry |
| - 1 egg yolk | qty=1 unit=nil name=egg yolk | qty=1 unit=egg yolk name=egg yolk |
| - 85g peanuts | qty=nil unit=nil name=85g peanuts | qty=0.4 unit=g name=peanuts |
| - 400ml tin coconut cream | qty=nil unit=tin name=coconut cream | qty=0.4 unit=l name=coconut cream |
| - 600g stewing beef, cut into strips | qty=nil unit=nil name=600g stewing beef | qty=0.6 unit=g name=beef shin |
| - 450g waxy potatoes | qty=nil unit=nil name=450g waxy potatoes | qty=0.45 unit=g name=waxy potatoes |
| - 1 onion, cut in thin wedges | qty=1 unit=nil name=onion | qty=1 unit=onion name=onion |
| - 4 lime leaves | qty=4 unit=nil name=lime leaves | qty=4 unit=leaves name=lime leaves |
| - 1 cinnamon stick | qty=1 unit=nil name=cinnamon stick | qty=1 unit=stick name=cinnamon stick |
| - 1 tbsp palm or soft light brown sugar | qty=1 unit=tbsp name=palm or soft light b | qty=1 unit=tbsp name=sugar |
| - 1 red chilli, deseeded and finely sliced | qty=1 unit=nil name=red chilli | qty=1 unit=chilli name=red chilli |
| - Jasmine rice to serve | qty=nil unit=nil name=jasmine rice | qty=1 unit=cup name=jasmine rice |
| - 175g butter | qty=nil unit=nil name=175g butter | qty=175 unit=g name=butter |
| - 175g caster sugar | qty=nil unit=nil name=175g caster sugar | qty=175 unit=g name=caster sugar |
| - 3 eggs | qty=3 unit=nil name=eggs | qty=2 unit=egg name=eggs |
| - 250g self-raising flour | qty=nil unit=nil name=250g self-raising fl | qty=250 unit=g name=self-raising flour |
| - 3 tbs milk | qty=3 unit=nil name=tbs milk | qty=3 unit=tbs name=milk |
| - Zest of 1 lemon | qty=1 unit=nil name=lemon | qty=1 unit=lemon name=lemon |
| - Mixed peel to glaze | qty=nil unit=nil name=mixed peel | qty=1 unit=mixed name=peel |
| - 2 tbs sunflower oil | qty=2 unit=tbsp name=sunflower oil | qty=2 unit=tbs name=sunflower oil |
| - 1 chopped onion | qty=1 unit=nil name=onion | qty=1 unit= name=onion |
| - 500g chicken thighs | qty=nil unit=nil name=500g chicken thighs | qty=500 unit=g name=chicken thighs |
| - 4 sliced garlic cloves | qty=4 unit=nil name=garlic cloves | qty=4 unit=tbs name=garlic cloves |
| - 280g Thai green curry paste | qty=nil unit=nil name=- 280g Thai green cu | qty=280 unit=g name=Thai green curry pas |
| - 400ml coconut milk | qty=nil unit=nil name=400ml coconut milk | qty=400 unit=ml name=coconut milk |
| - 2 litres chicken stock | qty=2 unit=litres name=chicken stock | qty=2 unit=L name=chicken stock |
| - 5 lime leaves | qty=5 unit=nil name=lime leaves | qty=5 unit= name=lime leaves |
| - 2 tbs fish sauce | qty=2 unit=nil name=tbs fish sauce | qty=2 unit=tbs name=fish sauce |
| - 280g green beans | qty=nil unit=nil name=280g green beans | qty=280 unit=g name=green beans |
| - 150g bamboo shoots | qty=nil unit=nil name=150g bamboo shoots | qty=150 unit=g name=bamboo shoots |
| - Juice of 2 limes | qty=2 unit=nil name=limes | qty=2 unit= name=limes |
| - Bunch of basil | qty=nil unit=bunch name=basil | qty=1 unit=bunch name=basil |
| - 2 tbs olive oil | qty=2 unit=tbsp name=olive oil | qty=2 unit=tbs name=olive oil |
| - 1 sliced onion | qty=1 unit=nil name=onion | qty=1 unit=sliced name=onion |
| - 2 medium carrots | qty=2 unit=nil name=medium carrots | qty=2 unit=medium name=carrots |
| - 750ml fish stock | qty=nil unit=nil name=750ml fish stock | qty=750 unit=ml name=fish stock |
| - 750ml water | qty=nil unit=nil name=750ml water | qty=750 unit=ml name=water |
| - 4 large potatoes | qty=4 unit=nil name=large potatoes | qty=4 unit=large name=potatoes |
| - 3 bay leaves | qty=3 unit=nil name=bay leaves | qty=3 unit=bay leaves name=bay leaves |
| - 1 whole cod fillet | qty=1 unit=nil name=whole cod fillet | qty=1 unit=whole name=cod fillet |
| - 1 whole salmon fillet | qty=1 unit=nil name=whole salmon fillet | qty=1 unit=whole name=salmon fillet |

## FM Fixes Pipeline Gaps

Lines where pipeline returned qty=nil but FM extracted a quantity.

| Input | Pipeline Name | FM Qty | FM Unit | FM Name |
|-------|---------------|--------|---------|--------|
| - Salt to taste | salt | 0 | nil | Salt |
| - 400g mushrooms | 400g mushrooms | 400 | g | mushrooms |
| - 1-2 tbsp English mustard | english mustard | 1.5 | tbsp | English mustard |
| - Dash of olive oil | olive oil | 0.5 | tbsp | olive oil |
| - 750g piece beef fillet | beef fillet | 750 | g | piece beef fillet |
| - 6-8 slices Parma ham | parma ham | 6.5 | slices | Parma ham |
| - 500g puff pastry | 500g puff pastry | 500 | g | puff pastry |
| - Flour for dusting | flour | 0 |  | Flour |
| - 250g chickpeas | 250g chickpeas | 0.25 | g | chickpeas |
| - 1.5L vegetable stock | 1.5l vegetable stock | 1.5 | L | vegetable stock |
| - Pinch of pepper | pepper | 1 | pinch | pepper |
| - 1/2 lime | 1/2 lime | 0.5 | lime | lime |
| - 450ml vegetable oil | 450ml vegetable oil | 450 | ml | vegetable oil |
| - 400g plain flour | 400g plain flour | 400 | g | plain flour |
| - 550ml sugar | 550ml sugar | 550 | ml | sugar |
| - 500g grated carrots | carrots | 500 | g | grated carrots |
| - 150g walnuts | 150g walnuts | 150 | g | walnuts |
| - 200g cream cheese | 200g cream cheese | 200 | g | cream cheese |
| - 150g caster sugar | 150g caster sugar | 150 | g | caster sugar |
| - 100g butter | 100g butter | 100 | g | butter |
| - 50g butter | 50g butter | 50 | g | butter |
| - 250ml dry white wine | 250ml dry white wine | 250 | ml | dry white wine |
| - 1L beef stock | 1l beef stock | 1 | L | beef stock |
| - 140g Gruyere cheese | 140g gruyere cheese | 140 | g | Gruyere cheese |
| - 500g fusilli pasta | 500g fusilli pasta | 500 | g | fusilli pasta |
| - 200g cherry tomatoes, halved | cherry tomatoes | 200 | g | cherry tomatoes |
| - 150g Kalamata olives | 150g kalamata olives | 150 | g | Kalamata olives |
| - 200g feta cheese, crumbled | 200g feta cheese | 200 | g | feta cheese |
| - 100g flour | 100g flour | 100 | g | flour |
| - 300ml milk | 300ml milk | 300 | ml | milk |
| - Sugar to serve | sugar | 0 | nil | sugar |
| - Raspberries to serve | raspberries | 0 | nil | raspberries |
| - Blueberries to serve | blueberries | 0 | nil | blueberries |
| - 500g chicken | 500g chicken | 500 | g | chicken |
| - 220g water chestnuts | 220g water chestnuts | 220 | g | water chestnuts |
| - 100g peanuts | 100g peanuts | 100 | g | peanuts |
| - 1kg ham | 1kg ham | 1 | kg | ham |
| - 200g peas, soaked overnight | 200g peas | 0.2 | g | peas |
| - 300g frozen peas | 300g frozen peas | 0.3 | g | frozen peas |
| - Bread to serve | bread | 0.5 | cup | bread |
| Pinch of pepper | pepper | 0 | pinch | pepper |
| 1/2 cucumber, sliced | 1/2 cucumber | 0.5 |  | cucumber |
| Dash of kosher salt | kosher salt | 0 | g | kosher salt |
| Dash of black pepper | black pepper | 0 | g | black pepper |
| - 60g lard | 60g lard | 0.6 | g | lard |
| - 340g warm water | 340g warm water | 3.4 | g | warm water |
| - 600g all purpose flour | 600g all purpose flour | 0.6 | g | all purpose flour |
| - Bunch of spring onions | spring onions | 1 | clove | garlic |
| - 750g sirloin steak | 750g sirloin steak | 0.75 | g | sirloin steak |
| - Salt to taste | salt | 0 | nil | salt |
| - Pepper to taste | pepper | 0 | nil | pepper |
| - Splash of egg wash | egg wash | 0 | nil | egg wash |
| - Drizzle of chimichurri sauce | drizzle of chimichurri sauce | 0 | nil | chimichurri sauce |
| - 200g sugar | 200g sugar | 2 | g | sugar |
| - 200g self-raising flour | 200g self-raising flour | 2 | g | self-raising flour |
| - 200g melted butter | butter | 2 | g | melted butter |
| - Pinch of salt | salt | 0 | pinch | salt |
| - Sprinkling of powdered sugar | sprinkling of powdered sugar | 0 | sprinkle | powdered sugar |
| - 250g butter (for pastry) | 250g butter | 250 | g | butter |
| - 350g plain flour | 350g plain flour | 350 | g | plain flour |
| - Juice of 1/2 lemon | lemon | 0.5 | lemon | lemon |
| - 25g butter (for filling) | 25g butter | 25 | g | butter |
| - 200g currants | 200g currants | 200 | g | currants |
| - 50g mixed peel | 50g mixed peel | 50 | g | mixed peel |
| - 100g muscovado sugar | 100g muscovado sugar | 100 | g | muscovado sugar |
| - Sprinkling of sugar | sprinkling of sugar | 1 | sprinkle | sugar |
| - 150g unsalted butter, melted | unsalted butter | 150 | g | butter |
| - Salt and pepper to taste | salt and pepper | 0 |  | salt and pepper |
| - Fresh dill for garnish | fresh dill | 0 |  | dill |
| - 200g chicken breast | 200g chicken breast | 400 | g | chicken breast |
| - Pinch of ginger | ginger | 1 | pinch | ginger |
| - 220g chickpeas | 220g chickpeas | 220 | g | chickpeas |
| - 200g couscous | 200g couscous | 200 | g | couscous |
| - 200ml chicken stock | 200ml chicken stock | 200 | ml | chicken stock |
| - Handful of coriander | coriander | 1 | handful | coriander |
| - 100g whole almonds | 100g whole almonds | 100 | g | almonds |
| - 180g butter | 180g butter | 180 | g | butter |
| - 180g muscovado sugar | 180g muscovado sugar | 180 | g | muscovado sugar |
| - 225g plain flour | 225g plain flour | 225 | g | flour |
| - 100g ground almonds | almonds | 100 | g | almonds |
| - 500g dried fruit | 500g dried fruit | 500 | g | dried fruit |
| - 100g glace cherries | 100g glace cherries | 100 | g | glace cherries |
| You need about 2 lbs lamb shoulder (or mutton if y | you need | 2 | lb | lamb shoulder |
| 4-5 medium potatoes peeled and quartered | medium potatoes | 4 | medium | potatoes |
| a sprig of thyme | thyme | 1 | sprig | thyme |
| - Vegetable oil for brushing | vegetable oil | 0 | unknown | vegetable oil |
| - 300ml Greek yoghurt | 300ml greek yoghurt | 300 | ml | Greek yoghurt |
| - 225g chicken | 225g chicken | 0.225 | g | chicken |
| - Pinch of salt | salt | 0 | pinch | salt |
| - Pinch of white pepper | white pepper | 0 | pinch | white pepper |
| - 110g rice | 110g rice | 0.11 | g | rice |
| - 2L water | 2l water | 0.055 | g | coriander |
| - 55g fresh coriander | fresh coriander | 0 |  | water |
| - 1.5kg beef | 1.5kg beef | 1.5 | kg | beef |
| - 225g tomato puree | 225g tomato puree | 225 | g | tomato puree |
| - 750ml water | 750ml water | 750 | ml | water |
| - 1/2 lemon | 1/2 lemon | 0.5 | lemon | lemon |
| - 120ml olive oil | 120ml olive oil | 120 | ml | olive oil |
| - 200g butter | 200g butter | 200 | g | butter |
| - 200g golden syrup | 200g golden syrup | 200 | g | golden syrup |
| - 85g black treacle | black treacle | 85 | g | black treacle |
| - 85g brown sugar | 85g brown sugar | 85 | g | brown sugar |
| - 100g oatmeal | 100g oatmeal | 100 | g | oatmeal |
| - 250g self-raising flour | 250g self-raising flour | 250 | g | self-raising flour |
| - 500g minced beef | beef | 5 | g | minced beef |
| - 75g mushrooms | 75g mushrooms | 75 | g | mushrooms |
| - 250ml beef stock | 250ml beef stock | 250 | ml | beef stock |
| - Dash of Worcestershire sauce | worcestershire sauce | 0.5 | dash | Worcestershire sauce |
| - 400g shortcrust pastry | 400g shortcrust pastry | 4 | g | shortcrust pastry |
| - 85g peanuts | 85g peanuts | 0.4 | g | peanuts |
| - 400ml tin coconut cream | coconut cream | 0.4 | l | coconut cream |
| - 600g stewing beef, cut into strips | 600g stewing beef | 0.6 | g | beef shin |
| - 450g waxy potatoes | 450g waxy potatoes | 0.45 | g | waxy potatoes |
| - Jasmine rice to serve | jasmine rice | 1 | cup | jasmine rice |
| - 175g butter | 175g butter | 175 | g | butter |
| - 175g caster sugar | 175g caster sugar | 175 | g | caster sugar |
| - 250g self-raising flour | 250g self-raising flour | 250 | g | self-raising flour |
| - Mixed peel to glaze | mixed peel | 1 | mixed | peel |
| - 500g chicken thighs | 500g chicken thighs | 500 | g | chicken thighs |
| - 280g Thai green curry paste | - 280g Thai green curry paste | 280 | g | Thai green curry paste |
| - 400ml coconut milk | 400ml coconut milk | 400 | ml | coconut milk |
| - 280g green beans | 280g green beans | 280 | g | green beans |
| - 150g bamboo shoots | 150g bamboo shoots | 150 | g | bamboo shoots |
| - Bunch of basil | basil | 1 | bunch | basil |
| - 750ml fish stock | 750ml fish stock | 750 | ml | fish stock |
| - 750ml water | 750ml water | 750 | ml | water |

## Known Pipeline Issues Detected

| Pattern | Input | Pipeline | FM |
|---------|-------|----------|----|
| unit-abbreviation | - 2 tablespoons red wine vinegar | qty=2 unit=nil name=tablespoons red wine | qty=2 unit=tbsp name=red wine vinegar |
| unit-abbreviation | - 2 tablespoons sake | qty=2 unit=nil name=tablespoons sake | qty=2 unit=tbsp name=sake |
| unit-abbreviation | - 2 tablespoons soy sauce | qty=2 unit=nil name=tablespoons soy sauc | qty=2 unit=tbsp name=soy sauce |
| unit-abbreviation | - 2 tablespoons sesame seed oil | qty=2 unit=nil name=tablespoons sesame s | qty=2 unit=tbsp name=sesame seed oil |
| unit-abbreviation | - 2 tablespoons water | qty=2 unit=nil name=tablespoons water | qty=2 unit=tbsp name=water |
| unit-abbreviation | - 6 tablespoons olive oil | qty=6 unit=nil name=tablespoons olive oi | — |
| unit-abbreviation | - 5 tablespoons vegetable oil | qty=5 unit=nil name=tablespoons vegetabl | qty=7.8125 unit=tbsp name=vegetable oil |
| unit-abbreviation | - 2 tablespoons harissa spice | qty=2 unit=nil name=tablespoons harissa  | qty=2 unit=tbsp name=harissa spice |
| unit-abbreviation | In a bowl, add the chicken, 1 pinch of salt,  | qty=nil unit=nil name=In a bowl, add the c | — |
| mixed-fraction | 2-1/2 cups chicken stock | qty=nil unit=nil name=2-1/2 cups chicken s | — |
| mixed-fraction | 1-1/2 cups vinegar | qty=nil unit=nil name=1-1/2 cups vinegar | — |
| unit-abbreviation | First Cook the beef by adding 2 Tablespoon of | qty=nil unit=nil name=first cook | — |
| unit-abbreviation | - 1 tbs spring onions, chopped | qty=1 unit=nil name=tbs spring onions | qty=0.042 unit=tbs name=spring onions |
| unit-abbreviation | - 6 tablespoons soy sauce | qty=6 unit=nil name=tablespoons soy sauc | qty=6 unit=tbsp name=soy sauce |
| unit-abbreviation | - 2 tbs crushed pepper | qty=2 unit=nil name=pepper | qty=2 unit=tbsp name=crushed pepper |
| unit-abbreviation | - 4 tbs milk | qty=4 unit=nil name=tbs milk | qty=4 unit=tbs name=milk |
| unit-abbreviation | - 2 tbs vegetable oil | qty=2 unit=nil name=tbs vegetable oil | qty=2 unit=tbs name=vegetable oil |
| unit-abbreviation | - 3 tbs milk | qty=3 unit=nil name=tbs milk | qty=3 unit=tbs name=milk |
| unit-abbreviation | - 2 tbs fish sauce | qty=2 unit=nil name=tbs fish sauce | qty=2 unit=tbs name=fish sauce |
| unit-abbreviation | - 1 tbs allspice | qty=1 unit=nil name=tbs allspice | — |

---

## Per-Recipe Details

### clean-01-chicken-handi (clean)

**16 ingredients** | 5 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1.2 kg chicken | 1.2 | kg | chicken | 1.2 | kg | chicken | ✓ |
| - 5 thinly sliced onion | 5 | — | onion | 5 | onion | onion | ≠ |
| - 2 finely chopped tomatoes | 2 | — | tomatoes | 2 | tomatoes | tomatoes | ≠ |
| - 8 cloves chopped garlic | 8 | clove | garlic | 8 | clove | garlic | ✓ |
| - 1 tbsp ginger paste | 1 | tbsp | ginger paste | 1 | tbsp | ginger paste | ✓ |
| - 1/4 cup vegetable oil | 0.25 | cup | vegetable oil | 0.25 | cup | vegetable oil | ✓ |
| - 2 tsp cumin seeds | 2 | tsp | cumin seeds | 2 | tsp | cumin seeds | ✓ |
| - 3 tsp coriander seeds | 3 | tsp | coriander seeds | 3 | tsp | coriander seeds | ✓ |
| - 1 tsp turmeric powder | 1 | tsp | turmeric powder | 1 | tsp | turmeric powder | ✓ |
| - 1 tsp chilli powder | 1 | tsp | chilli powder | 1 | tsp | chilli powder | ✓ |
| - 2 green chilli | 2 | — | green chilli | 2 | green chilli | green chilli | ≠ |
| - 1 cup yogurt | 1 | cup | yogurt | 1 | cup | yogurt | ✓ |
| - 3/4 cup cream | 0.75 | cup | cream | 0.75 | cup | cream | ✓ |
| - 3 tsp dried fenugreek | 3 | tsp | dried fenugreek | 3 | tsp | fenugreek | ≠ |
| - 1 tsp garam masala | 1 | tsp | garam masala | 1 | tsp | garam masala | ✓ |
| - Salt to taste | — | — | salt | 0 | nil | Salt | ≠ |

### clean-02-beef-wellington (clean)

**8 ingredients** | 8 disagreements | 7 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 400g mushrooms | — | — | 400g mushrooms | 400 | g | mushrooms | ≠ |
| - 1-2 tbsp English mustard | — | tbsp | english mustard | 1.5 | tbsp | English mustard | ≠ |
| - Dash of olive oil | — | dash | olive oil | 0.5 | tbsp | olive oil | ≠ |
| - 750g piece beef fillet | — | piece | beef fillet | 750 | g | piece beef fillet | ≠ |
| - 6-8 slices Parma ham | — | slice | parma ham | 6.5 | slices | Parma ham | ≠ |
| - 500g puff pastry | — | — | 500g puff pastry | 500 | g | puff pastry | ≠ |
| - Flour for dusting | — | — | flour | 0 |  | Flour | ≠ |
| - 2 beaten egg yolks | 2 | — | egg yolks | 2 | egg yolks | egg yolks | ≠ |

### clean-03-leblebi-soup (clean)

**10 ingredients** | 6 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tablespoons olive oil | 2 | tbsp | olive oil | 2 | tbsp | olive oil | ✓ |
| - 1 medium finely diced onion | 1 | — | medium onion | 1 | medium | onion | ≠ |
| - 250g chickpeas | — | — | 250g chickpeas | 0.25 | g | chickpeas | ≠ |
| - 1.5L vegetable stock | — | — | 1.5l vegetable stock | 1.5 | L | vegetable stock | ≠ |
| - 1 tsp cumin | 1 | tsp | cumin | 1 | tsp | cumin | ✓ |
| - 5 cloves garlic | 5 | clove | garlic | 5 | cloves | garlic | ≠ |
| - 1/2 tsp salt | 0.5 | tsp | salt | 0.5 | tsp | salt | ✓ |
| - 1 tsp harissa spice | 1 | tsp | harissa spice | 1 | tsp | harissa spice | ✓ |
| - Pinch of pepper | — | pinch | pepper | 1 | pinch | pepper | ≠ |
| - 1/2 lime | — | — | 1/2 lime | 0.5 | lime | lime | ≠ |

### clean-04-carrot-cake (clean)

**12 ingredients** | 9 disagreements | 8 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 450ml vegetable oil | — | — | 450ml vegetable oil | 450 | ml | vegetable oil | ≠ |
| - 400g plain flour | — | — | 400g plain flour | 400 | g | plain flour | ≠ |
| - 2 tsp bicarbonate of soda | 2 | tsp | bicarbonate of soda | 2 | tsp | bicarbonate of soda | ✓ |
| - 550ml sugar | — | — | 550ml sugar | 550 | ml | sugar | ≠ |
| - 5 eggs | 5 | — | eggs | 2 | egg | eggs | ≠ |
| - 1/2 tsp salt | 0.5 | tsp | salt | 0.5 | tsp | salt | ✓ |
| - 2 tsp cinnamon | 2 | tsp | cinnamon | 2 | tsp | cinnamon | ✓ |
| - 500g grated carrots | — | — | carrots | 500 | g | grated carrots | ≠ |
| - 150g walnuts | — | — | 150g walnuts | 150 | g | walnuts | ≠ |
| - 200g cream cheese | — | — | 200g cream cheese | 200 | g | cream cheese | ≠ |
| - 150g caster sugar | — | — | 150g caster sugar | 150 | g | caster sugar | ≠ |
| - 100g butter | — | — | 100g butter | 100 | g | butter | ≠ |

### clean-05-french-onion-soup (clean)

**10 ingredients** | 6 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 50g butter | — | — | 50g butter | 50 | g | butter | ≠ |
| - 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| - 1 kg onion | 1 | kg | onion | 1 | kg | onion | ✓ |
| - 1 tsp sugar | 1 | tsp | sugar | 1 | tsp | sugar | ✓ |
| - 4 sliced garlic cloves | 4 | — | garlic cloves | 4 | clove | garlic cloves | ≠ |
| - 2 tablespoons plain flour | 2 | tbsp | plain flour | 2 | tbsp | plain flour | ✓ |
| - 250ml dry white wine | — | — | 250ml dry white wine | 250 | ml | dry white wine | ≠ |
| - 1L beef stock | — | — | 1l beef stock | 1 | L | beef stock | ≠ |
| - 4 slices bread | 4 | — | slices bread | 4 | clove | bread | ≠ |
| - 140g Gruyere cheese | — | — | 140g gruyere cheese | 140 | g | Gruyere cheese | ≠ |

### clean-06-beef-stroganoff (clean)

**11 ingredients** | 10 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 tablespoon olive oil | 1 | tbsp | olive oil | — | — | olive oil | ≠ |
| - 1 onion | 1 | — | onion | — | — | onion | ≠ |
| - 1 clove garlic | 1 | clove | garlic | — | — | garlic | ≠ |
| - 1 tbsp butter | 1 | tbsp | butter | — | — | butter | ≠ |
| - 250g mushrooms | — | — | 250g mushrooms | — | — | mushrooms | ≠ |
| - 500g beef fillet | — | — | 500g beef fillet | — | — | beef fillet | ≠ |
| - 1 tbsp plain flour | 1 | tbsp | plain flour | — | — | plain flour | ≠ |
| - 150g creme fraiche | — | — | 150g creme fraiche | — | — | creme fraiche | ≠ |
| - 1 tbsp English mustard | 1 | tbsp | english mustard | — | — | English mustard | ≠ |
| - 100ml beef stock | — | — | 100ml beef stock | — | — | beef stock | ≠ |
| - Parsley for topping | — | — | parsley | — | — | parsley | ✓ |

### clean-07-mediterranean-pasta-salad (clean)

**9 ingredients** | 7 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 500g fusilli pasta | — | — | 500g fusilli pasta | 500 | g | fusilli pasta | ≠ |
| - 200g cherry tomatoes, halved | — | — | cherry tomatoes | 200 | g | cherry tomatoes | ≠ |
| - 1 cucumber, diced | 1 | — | cucumber | 1 | g | cucumber | ≠ |
| - 150g Kalamata olives | — | — | 150g kalamata olives | 150 | g | Kalamata olives | ≠ |
| - 200g feta cheese, crumbled | — | — | 200g feta cheese | 200 | g | feta cheese | ≠ |
| - 1 red onion, thinly sliced | 1 | — | red onion | 1 | g | red onion | ≠ |
| - 1/4 cup extra virgin olive oil | 0.25 | cup | extra virgin olive o | 0.25 | cup | extra virgin olive o | ✓ |
| - 2 tablespoons red wine vinegar | 2 | — | tablespoons red wine | 2 | tbsp | red wine vinegar | ≠ |
| - 1 teaspoon dried oregano | 1 | tsp | dried oregano | 1 | tsp | dried oregano | ✓ |

### clean-08-pancakes (clean)

**7 ingredients** | 6 disagreements | 5 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 100g flour | — | — | 100g flour | 100 | g | flour | ≠ |
| - 2 large eggs | 2 | — | large eggs | 2 | large eggs | eggs | ≠ |
| - 300ml milk | — | — | 300ml milk | 300 | ml | milk | ≠ |
| - 1 tablespoon sunflower oil | 1 | tbsp | sunflower oil | 1 | tbsp | sunflower oil | ✓ |
| - Sugar to serve | — | — | sugar | 0 | nil | sugar | ≠ |
| - Raspberries to serve | — | — | raspberries | 0 | nil | raspberries | ≠ |
| - Blueberries to serve | — | — | blueberries | 0 | nil | blueberries | ≠ |

### clean-09-kung-pao-chicken (clean)

**13 ingredients** | 9 disagreements | 3 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tablespoons sake | 2 | — | tablespoons sake | 2 | tbsp | sake | ≠ |
| - 2 tablespoons soy sauce | 2 | — | tablespoons soy sauc | 2 | tbsp | soy sauce | ≠ |
| - 2 tablespoons sesame seed oil | 2 | — | tablespoons sesame s | 2 | tbsp | sesame seed oil | ≠ |
| - 2 tablespoons corn flour | 2 | tbsp | corn flour | 2 | tbsp | corn flour | ✓ |
| - 2 tablespoons water | 2 | — | tablespoons water | 2 | tbsp | water | ≠ |
| - 500g chicken | — | — | 500g chicken | 500 | g | chicken | ≠ |
| - 1 tablespoon chilli powder | 1 | tbsp | chilli powder | 1 | tsp | chilli powder | ≠ |
| - 1 tsp rice vinegar | 1 | tsp | rice vinegar | 1 | tsp | rice vinegar | ✓ |
| - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1 | tbsp | brown sugar | ✓ |
| - 4 chopped spring onions | 4 | — | spring onions | 4 | clove | spring onions | ≠ |
| - 6 cloves garlic | 6 | clove | garlic | 6 | clove | garlic | ✓ |
| - 220g water chestnuts | — | — | 220g water chestnuts | 220 | g | water chestnuts | ≠ |
| - 100g peanuts | — | — | 100g peanuts | 100 | g | peanuts | ≠ |

### clean-10-split-pea-soup (clean)

**8 ingredients** | 8 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1kg ham | — | — | 1kg ham | 1 | kg | ham | ≠ |
| - 200g peas, soaked overnight | — | — | 200g peas | 0.2 | g | peas | ≠ |
| - 2 chopped onions | 2 | — | onions | 0.2 | g | onions | ≠ |
| - 2 chopped carrots | 2 | — | carrots | 0.2 | g | carrots | ≠ |
| - 2 bay leaves | 2 | — | bay leaves | 2 | bay leaves | bay leaves | ≠ |
| - 1 chopped celery stalk | 1 | stalk | celery | 0.3 | g | celery | ≠ |
| - 300g frozen peas | — | — | 300g frozen peas | 0.3 | g | frozen peas | ≠ |
| - Bread to serve | — | — | bread | 0.5 | cup | bread | ≠ |

### no-headers-01-honey-teriyaki-salmon (no-headers)

**5 ingredients** | 1 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 lb salmon | 1 | lb | salmon | 0.453592 | lb | salmon | ≠ |
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tbsp | soy sauce | ✓ |
| 2 tablespoons sake | 2 | tbsp | sake | 2 | tbsp | sake | ✓ |
| 4 tablespoons sesame seeds | 4 | tbsp | sesame seeds | 4 | tbsp | sesame seeds | ✓ |

### no-headers-02-chicken-karaage (no-headers)

**9 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 450 grams boneless skin-on chicken | 450 | g | boneless skin-on chi | 1.00 | regex |  |
| 1 tablespoon ginger | 1 | tbsp | ginger | 1.00 | regex |  |
| 1 clove garlic | 1 | clove | garlic | 1.00 | regex |  |
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 1.00 | regex |  |
| 1 tablespoon sake | 1 | tbsp | sake | 1.00 | regex |  |
| 2 teaspoons granulated sugar | 2 | tsp | granulated sugar | 1.00 | regex |  |
| 1/3 cup potato starch | 0.333333 | cup | potato starch | 1.00 | regex |  |
| 1/3 cup vegetable oil | 0.333333 | cup | vegetable oil | 1.00 | regex |  |
| 1/3 cup lemon wedges | 0.333333 | cup | lemon wedges | 1.00 | regex |  |

### no-headers-03-beef-pho (no-headers)

**9 ingredients** | 9 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 L beef stock | 1 | l | beef stock | — | — | beef stock | ≠ |
| 1 cinnamon stick | 1 | — | cinnamon stick | — | — | cinnamon stick | ≠ |
| 1 tsp coriander seeds | 1 | tsp | coriander seeds | — | — | coriander seeds | ≠ |
| 1/2 teaspoon cloves | 0.5 | tsp | cloves | — | — | cloves | ≠ |
| 225g sirloin steak | 225 | g | sirloin steak | — | — | sirloin steak | ≠ |
| 1 tsp palm sugar | 1 | tsp | palm sugar | — | — | palm sugar | ≠ |
| 1 tablespoon fish sauce | 1 | tbsp | fish sauce | — | — | fish sauce | ≠ |
| 1 1/2 tbsp soy sauce | 1.5 | tbsp | soy sauce | — | — | soy sauce | ≠ |
| 200g rice noodles | 200 | g | rice noodles | — | — | rice noodles | ≠ |

### no-headers-04-chicken-marengo (no-headers)

**4 ingredients** | 1 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1.5 | tbsp | olive oil | ≠ |
| 300g mushrooms | 300 | g | mushrooms | 300 | g | mushrooms | ✓ |
| 500g passata | 500 | g | passata | 500 | g | passata | ✓ |
| 100g black olives | 100 | g | black olives | 100 | g | black olives | ✓ |

### no-headers-05-rock-cakes (no-headers)

**7 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 225g self-raising flour | 225 | g | self-raising flour | 225 | g | self-raising flour | ✓ |
| 75g caster sugar | 75 | g | caster sugar | 75 | g | caster sugar | ✓ |
| 1 tsp baking powder | 1 | tsp | baking powder | 1 | tsp | baking powder | ✓ |
| 125g butter | 125 | g | butter | 125 | g | butter | ✓ |
| 150g dried fruit | 150 | g | dried fruit | 150 | g | dried fruit | ✓ |
| 1 tablespoon milk | 1 | tbsp | milk | 1 | tbsp | milk | ✓ |
| 2 tsp vanilla extract | 2 | tsp | vanilla extract | 2 | tsp | vanilla extract | ✓ |

### no-headers-06-egg-drop-soup (no-headers)

**10 ingredients** | 6 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 3 cups chicken stock | 3 | cup | chicken stock | — | — | chicken stock | ≠ |
| 1/4 tsp salt | 0.25 | tsp | salt | 0.75 | tsp | salt | ≠ |
| 1/4 tsp sugar | 0.25 | tsp | sugar | 0.25 | tsp | sugar | ✓ |
| Pinch of pepper | — | pinch | pepper | 0 | pinch | pepper | ≠ |
| 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1 | tsp | sesame seed oil | ✓ |
| 1/3 cup peas | 0.333333 | cup | peas | 0.25 | cup | peas | ≠ |
| 1/3 cup mushrooms | 0.333333 | cup | mushrooms | 0.25 | cup | mushrooms | ≠ |
| 1 tablespoon cornstarch | 1 | tbsp | cornstarch | 1.25 | tbsp | cornstarch | ≠ |
| 2 tablespoons water | 2 | tbsp | water | 2 | tbsp | water | ✓ |
| 1/4 cup spring onions | 0.25 | cup | spring onions | 0.25 | cup | spring onions | ✓ |

### no-headers-07-salmon-avocado-salad (no-headers)

**4 ingredients** | 4 disagreements | 1 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 100g mixed salad leaves | 100 | g | mixed salad leaves | 0.1 | g | salad leaves | ≠ |
| 1/2 cucumber, sliced | — | — | 1/2 cucumber | 0.5 |  | cucumber | ≠ |
| 2 tablespoons extra virgin olive oil | 2 | tbsp | extra virgin olive o | 3 | tbsp | olive oil | ≠ |
| 1 tablespoon lemon juice | 1 | tbsp | lemon juice | 1 | tsp | lemon juice | ≠ |

### no-headers-08-sticky-chicken (no-headers)

**5 ingredients** | 5 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 2 tablespoons soy sauce | 2 | tbsp | soy sauce | 2 | tablespoon | soy sauce | ≠ |
| 1 tablespoon honey | 1 | tbsp | honey | 1 | tablespoon | honey | ≠ |
| 1 tablespoon olive oil | 1 | tbsp | olive oil | 1 | tablespoon | olive oil | ≠ |
| 1 teaspoon tomato puree | 1 | tsp | tomato puree | 1 | teaspoon | tomato puree | ≠ |
| 1 tablespoon Dijon mustard | 1 | tbsp | Dijon mustard | 1 | tablespoon | Dijon mustard | ≠ |

### no-headers-09-corned-beef-hash (no-headers)

**4 ingredients** | 4 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 3 tablespoons unsalted butter | 3 | tbsp | unsalted butter | 45 | tbsp | butter | ≠ |
| 3 cups corned beef | 3 | cup | corned beef | 375 | g | corned beef | ≠ |
| Dash of kosher salt | — | dash | kosher salt | 0 | g | kosher salt | ≠ |
| Dash of black pepper | — | dash | black pepper | 0 | g | black pepper | ≠ |

### no-headers-10-thai-beef-stir-fry (no-headers)

**3 ingredients** | 2 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 2 tablespoons vegetable oil | 2 | tbsp | vegetable oil | 30 | tbsp | vegetable oil | ≠ |
| 400g beef strips | 400 | g | beef strips | 400 | g | beef strips | ✓ |
| 2 tablespoons oyster sauce | 2 | tbsp | oyster sauce | 30 | tbsp | oyster sauce | ≠ |

### unusual-metadata-01-beef-empanadas (unusual-metadata)

**18 ingredients** | 13 disagreements | 9 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 60g lard | — | — | 60g lard | 0.6 | g | lard | ≠ |
| - 340g warm water | — | — | 340g warm water | 3.4 | g | warm water | ≠ |
| - 1 tsp salt | 1 | tsp | salt | 0.5 | tsp | salt | ≠ |
| - 600g all purpose flour | — | — | 600g all purpose flo | 0.6 | g | all purpose flour | ≠ |
| - 3 tomatoes | 3 | — | tomatoes | 3 | tomatoes | tomatoes | ≠ |
| - 1 clove garlic | 1 | clove | garlic | 1 | clove | garlic | ✓ |
| - 1 large red onion | 1 | — | large red onion | 1 | clove | garlic | ≠ |
| - Bunch of spring onions | — | bunch | spring onions | 1 | clove | garlic | ≠ |
| - 750g sirloin steak | — | — | 750g sirloin steak | 0.75 | g | sirloin steak | ≠ |
| - 1 tablespoon dried oregano | 1 | tbsp | dried oregano | 1 | tbsp | dried oregano | ✓ |
| - 1 tsp paprika | 1 | tsp | paprika | 1 | tsp | paprika | ✓ |
| - 1 tsp red pepper flakes | 1 | tsp | red pepper flakes | 1 | tsp | red pepper flakes | ✓ |
| - 1 tsp parsley | 1 | tsp | parsley | 1 | tsp | parsley | ✓ |
| - Salt to taste | — | — | salt | 0 | nil | salt | ≠ |
| - Pepper to taste | — | — | pepper | 0 | nil | pepper | ≠ |
| - 3 eggs | 3 | — | eggs | 2 | eggs | eggs | ≠ |
| - Splash of egg wash | — | splash | egg wash | 0 | nil | egg wash | ≠ |
| - Drizzle of chimichurri sauce | — | — | drizzle of chimichur | 0 | nil | chimichurri sauce | ≠ |

### unusual-metadata-02-chicken-basquaise (unusual-metadata)

**19 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1.5kg chicken | — | — | 1.5kg chicken | 0.81 | ml |  |
| - 25g butter | — | — | 25g butter | 0.89 | ml |  |
| - 6 tablespoons olive oil | 6 | — | tablespoons olive oi | 0.83 | ml | unit-abbreviation |
| - 2 sliced red onions | 2 | — | red onions | 1.00 | ml |  |
| - 3 large red peppers | 3 | — | large red peppers | 1.00 | ml |  |
| - 130g chorizo | — | — | 130g chorizo | 0.89 | ml |  |
| - 8 sun-dried tomatoes | 8 | — | sun-dried tomatoes | 0.99 | ml |  |
| - 6 cloves sliced garlic | 6 | clove | garlic | 0.93 | ml |  |
| - 300g basmati rice | — | — | 300g basmati rice | 0.79 | ml |  |
| - Drizzle of tomato puree | — | — | drizzle of tomato pu | 0.92 | ml |  |
| - 1/2 tsp paprika | 0.5 | tsp | paprika | 0.99 | ml |  |
| - 4 bay leaves | 4 | — | bay leaves | 0.91 | ml |  |
| - Handful of thyme | — | handful | thyme | 1.00 | ml |  |
| - 350ml chicken stock | — | — | 350ml chicken stock | 0.78 | ml |  |
| - 180g dry white wine | — | — | 180g dry white wine | 0.88 | ml |  |
| - 2 lemons | 2 | — | lemons | 1.00 | ml |  |
| - 100g black olives | — | — | 100g black olives | 0.74 | ml |  |
| - Salt to serve | — | — | salt | 1.00 | ml |  |
| - Pepper to serve | — | — | pepper | 1.00 | ml |  |

### unusual-metadata-03-apple-cake (unusual-metadata)

**10 ingredients** | 8 disagreements | 5 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 4 eggs | 4 | — | eggs | 4 | egg | egg | ≠ |
| - 200g sugar | — | — | 200g sugar | 2 | g | sugar | ≠ |
| - 200g self-raising flour | — | — | 200g self-raising fl | 2 | g | self-raising flour | ≠ |
| - 200g melted butter | — | — | butter | 2 | g | melted butter | ≠ |
| - 1 tsp vanilla extract | 1 | tsp | vanilla extract | 1 | tsp | vanilla extract | ✓ |
| - 1 tsp ground cinnamon | 1 | tsp | ground cinnamon | 1 | tsp | ground cinnamon | ✓ |
| - 3 apples | 3 | — | apples | 3 | egg | apple | ≠ |
| - Pinch of salt | — | pinch | salt | 0 | pinch | salt | ≠ |
| - Sprinkling of powdered sugar | — | — | sprinkling of powder | 0 | sprinkle | powdered sugar | ≠ |
| 4. Add cinnamon, pinch of salt and vanil | 4 | pinch | add cinnamon | 0 | none | cinnamon | ≠ |

### unusual-metadata-04-thai-pumpkin-soup (unusual-metadata)

**11 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1.5kg pumpkin | — | — | 1.5kg pumpkin | 0.78 | ml |  |
| - 4 tsp sunflower oil | 4 | tsp | sunflower oil | 1.00 | ml |  |
| - 1 sliced onion | 1 | — | onion | 1.00 | ml |  |
| - 1 tbsp grated ginger | 1 | tbsp | ginger | 0.99 | ml |  |
| - 1 stalk lemongrass | 1 | stalk | lemongrass | 0.97 | ml |  |
| - 4 tablespoons Thai red curry paste | 4 | tbsp | thai red curry paste | 0.78 | ml |  |
| - 400ml coconut milk | — | — | 400ml coconut milk | 0.80 | ml |  |
| - 800ml vegetable stock | — | — | 800ml vegetable stoc | 0.81 | ml |  |
| - Lime juice to taste | — | — | lime juice | 1.00 | ml |  |
| - Sugar to taste | — | — | sugar | 1.00 | ml |  |
| - Red chilli to serve | — | — | red chilli | 1.00 | ml |  |

### unusual-metadata-05-kentucky-fried-chicken (unusual-metadata)

**17 ingredients** | 6 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 whole chicken, cut up | 1 | — | whole chicken | 1 | whole | chicken | ≠ |
| - 2 quarts neutral frying oil | 2 | — | quarts neutral fryin | 2 | qt | frying oil | ≠ |
| - 1 egg white | 1 | — | egg white | 1 | egg white | egg white | ≠ |
| - 1 1/2 cups flour | 1 | 1/2 | cups flour | 1 | 1.5 | cups flour | ≠ |
| - 1 tablespoon brown sugar | 1 | tbsp | brown sugar | 1 | tbsp | brown sugar | ✓ |
| - 1 tablespoon salt | 1 | tbsp | salt | 1 | tsp | salt | ≠ |
| - 1 tablespoon paprika | 1 | tbsp | paprika | 1 | tsp | paprika | ≠ |
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
| - 5 tablespoons vegetable oil | 5 | — | tablespoons vegetabl | 7.8125 | tbsp | vegetable oil | ≠ |
| - 1 cinnamon stick | 1 | — | cinnamon stick | 1 | stick | cinnamon | ≠ |
| - 3 cloves | 3 | — | cloves | 3 | clove | clove | ≠ |
| - 3 star anise | 3 | — | star anise | 3 | star anise | star anise | ≠ |
| - 3 cardamom pods | 3 | — | cardamom pods | 3 | cardamom pods | cardamom pods | ≠ |
| - 1 cup coconut cream | 1 | cup | coconut cream | 240 | ml | coconut cream | ≠ |
| - 1 cup water | 1 | cup | water | 240 | ml | water | ≠ |
| - 2 tablespoons tamarind paste | 2 | tbsp | tamarind paste | 3 | tbsp | tamarind paste | ≠ |
| - 6 lime leaves | 6 | — | lime leaves | 6 | leaf | lime | ≠ |
| - 1 tablespoon sugar | 1 | tbsp | sugar | 15 | tsp | sugar | ≠ |
| - 5 shallots | 5 | — | shallots | 5 | shallot | shallot | ≠ |

### unusual-metadata-07-eccles-cakes (unusual-metadata)

**13 ingredients** | 10 disagreements | 8 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 250g butter (for pastry) | — | — | 250g butter | 250 | g | butter | ≠ |
| - 350g plain flour | — | — | 350g plain flour | 350 | g | plain flour | ≠ |
| - Juice of 1/2 lemon | — | — | lemon | 0.5 | lemon | lemon | ≠ |
| - 25g butter (for filling) | — | — | 25g butter | 25 | g | butter | ≠ |
| - 200g currants | — | — | 200g currants | 200 | g | currants | ≠ |
| - 50g mixed peel | — | — | 50g mixed peel | 50 | g | mixed peel | ≠ |
| - 100g muscovado sugar | — | — | 100g muscovado sugar | 100 | g | muscovado sugar | ≠ |
| - 1 tsp cinnamon | 1 | tsp | cinnamon | 1 | tsp | cinnamon | ✓ |
| - 1 tsp ginger | 1 | tsp | ginger | 1 | tsp | ginger | ✓ |
| - 1 tsp allspice | 1 | tsp | allspice | 1 | tsp | allspice | ✓ |
| - Zest of 1 lemon | 1 | — | lemon | 1 | lemon | lemon | ≠ |
| - 1 beaten egg | 1 | — | egg | 1 | egg | egg | ≠ |
| - Sprinkling of sugar | — | — | sprinkling of sugar | 1 | sprinkle | sugar | ≠ |

### unusual-metadata-08-salmon-eggs-benedict (unusual-metadata)

**9 ingredients** | 8 disagreements | 3 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 salmon fillets | 2 | — | salmon fillets | 2 | fillet | salmon | ≠ |
| - 2 English muffins, split and toasted | 2 | — | english muffins | 2 | muffin | English muffin | ≠ |
| - 4 eggs | 4 | — | eggs | 4 | egg | egg | ≠ |
| - 1 tablespoon white vinegar | 1 | tbsp | white vinegar | 1 | tbsp | vinegar | ≠ |
| - 3 egg yolks | 3 | — | egg yolks | 3 | egg | egg yolk | ≠ |
| - 150g unsalted butter, melted | — | — | unsalted butter | 150 | g | butter | ≠ |
| - 1 tablespoon lemon juice | 1 | tbsp | lemon juice | 1 | tbsp | lemon juice | ✓ |
| - Salt and pepper to taste | — | — | salt and pepper | 0 |  | salt and pepper | ≠ |
| - Fresh dill for garnish | — | — | fresh dill | 0 |  | dill | ≠ |

### unusual-metadata-09-chicken-couscous (unusual-metadata)

**10 ingredients** | 9 disagreements | 6 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1 tbsp olive oil | 1 | tbsp | olive oil | 1 | tbsp | olive oil | ✓ |
| - 1 chopped onion | 1 | — | onion | 1 | tbsp | onion | ≠ |
| - 200g chicken breast | — | — | 200g chicken breast | 400 | g | chicken breast | ≠ |
| - Pinch of ginger | — | pinch | ginger | 1 | pinch | ginger | ≠ |
| - 2 tablespoons harissa spice | 2 | — | tablespoons harissa  | 2 | tbsp | harissa spice | ≠ |
| - 10 dried apricots | 10 | — | dried apricots | 10 | piece | dried apricots | ≠ |
| - 220g chickpeas | — | — | 220g chickpeas | 220 | g | chickpeas | ≠ |
| - 200g couscous | — | — | 200g couscous | 200 | g | couscous | ≠ |
| - 200ml chicken stock | — | — | 200ml chicken stock | 200 | ml | chicken stock | ≠ |
| - Handful of coriander | — | handful | coriander | 1 | handful | coriander | ≠ |

### unusual-metadata-10-dundee-cake (unusual-metadata)

**14 ingredients** | 9 disagreements | 7 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 100g whole almonds | — | — | 100g whole almonds | 100 | g | almonds | ≠ |
| - 180g butter | — | — | 180g butter | 180 | g | butter | ≠ |
| - 180g muscovado sugar | — | — | 180g muscovado sugar | 180 | g | muscovado sugar | ≠ |
| - Zest of 1 orange | 1 | — | orange | 1 | orange | orange | ≠ |
| - 3 tablespoons apricot jam | 3 | tbsp | apricot jam | 3 | tbsp | apricot jam | ✓ |
| - 225g plain flour | — | — | 225g plain flour | 225 | g | flour | ≠ |
| - 1 tsp baking powder | 1 | tsp | baking powder | 1 | tsp | baking powder | ✓ |
| - 3 large eggs | 3 | — | large eggs | 2 | eggs | eggs | ≠ |
| - 100g ground almonds | — | — | almonds | 100 | g | almonds | ≠ |
| - 2 tablespoons milk | 2 | tbsp | milk | 2 | tbsp | milk | ✓ |
| - 500g dried fruit | — | — | 500g dried fruit | 500 | g | dried fruit | ≠ |
| - 100g glace cherries | — | — | 100g glace cherries | 100 | g | glace cherries | ≠ |
| - 1 tablespoon milk (for glaze) | 1 | tbsp | milk | 1 | tbsp | milk | ✓ |
| - 2 tsp caster sugar (for glaze) | 2 | tsp | caster sugar | 2 | tsp | caster sugar | ✓ |

### messy-01-beef-bourguignon (messy)

*No ingredients classified by OCRLineClassifier*

### messy-02-general-tsos-chicken (messy)

**5 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 3/4 cup plain flour | 0.75 | cup | plain flour | 1.00 | regex |  |
| 1 tsp salt | 1 | tsp | salt | 1.00 | regex |  |
| 1/2 tsp onion salt | 0.5 | tsp | onion salt | 1.00 | regex |  |
| 1/4 tsp garlic powder | 0.25 | tsp | garlic powder | 1.00 | regex |  |
| In a bowl, add the chicken, 1 pinch of s | — | — | In a bowl, add the c | 0.75 | ml | unit-abbreviation |

### messy-03-beef-lo-mein (messy)

*No ingredients classified by OCRLineClassifier*

### messy-04-irish-stew (messy)

**7 ingredients** | 3 disagreements | 3 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| You need about 2 lbs lamb shoulder (or m | — | — | you need | 2 | lb | lamb shoulder | ≠ |
| 4-5 medium potatoes peeled and quartered | — | — | medium potatoes | 4 | medium | potatoes | ≠ |
| 2 cups beef stock | 2 | cup | beef stock | 2 | cup | beef stock | ✓ |
| 1 tablespoon butter | 1 | tbsp | butter | 1 | tbsp | butter | ✓ |
| a sprig of thyme | — | sprig | thyme | 1 | sprig | thyme | ≠ |
| 1 tablespoon Worcestershire sauce | 1 | tbsp | Worcestershire sauce | 1 | tbsp | Worcestershire sauce | ✓ |
| 1 tablespoon tomato paste | 1 | tbsp | tomato paste | 1 | tbsp | tomato paste | ✓ |

### messy-05-spanish-chicken-pie (messy)

**7 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1 kg potatoes | 1 | kg | potatoes | 1 | kg | potatoes | ✓ |
| 3 tsp paprika | 3 | tsp | paprika | 3 | tsp | paprika | ✓ |
| 2 teaspoons olive oil | 2 | tsp | olive oil | 2 | tsp | olive oil | ✓ |
| 2 cloves minced garlic | 2 | clove | minced garlic | 2 | clove | minced garlic | ✓ |
| 800g tinned tomatoes | 800 | g | tinned tomatoes | 800 | g | tinned tomatoes | ✓ |
| 300g chicken | 300 | g | chicken | 300 | g | chicken | ✓ |
| 140g roasted pepper | 140 | g | roasted pepper | 140 | g | roasted pepper | ✓ |

### messy-06-hot-and-sour-soup (messy)

**13 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| 1/3 cup mushrooms | 0.333333 | cup | mushrooms | 1.00 | regex |  |
| 1/3 cup wood ear mushrooms | 0.333333 | cup | wood ear mushrooms | 1.00 | regex |  |
| 2/3 cup tofu (cubed) | 0.666667 | cup | tofu (cubed) | 1.00 | regex |  |
| 1/2 cup bbq pork (sliced) | 0.5 | cup | bbq pork (sliced) | 1.00 | regex |  |
| 2-1/2 cups chicken stock | — | — | 2-1/2 cups chicken s | 0.81 | ml | mixed-fraction |
| 1/2 tsp salt | 0.5 | tsp | salt | 1.00 | regex |  |
| 1/4 tsp sugar | 0.25 | tsp | sugar | 1.00 | regex |  |
| 1 tsp sesame seed oil | 1 | tsp | sesame seed oil | 1.00 | regex |  |
| 1/4 tsp white pepper | 0.25 | tsp | white pepper | 1.00 | regex |  |
| 1/2 tsp hot sauce | 0.5 | tsp | hot sauce | 1.00 | regex |  |
| 1-1/2 cups vinegar | — | — | 1-1/2 cups vinegar | 0.88 | ml | mixed-fraction |
| 1 tsp soy sauce | 1 | tsp | soy sauce | 1.00 | regex |  |
| 1/4 cup spring onions | 0.25 | cup | spring onions | 1.00 | regex |  |

### messy-07-chicken-fried-rice (messy)

*No ingredients classified by OCRLineClassifier*

### messy-08-creamy-tomato-soup (messy)

*No ingredients classified by OCRLineClassifier*

### messy-09-szechuan-beef (messy)

**1 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| First Cook the beef by adding 2 Tablespo | — | — | first cook | 0.55 | ml | unit-abbreviation |

### messy-10-sweet-and-sour-chicken (messy)

*No ingredients classified by OCRLineClassifier*

### international-01-tandoori-chicken (international)

**12 ingredients** | 7 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - Juice of 2 lemons | 2 | — | lemons | 2 | lemons | lemon | ≠ |
| - 4 tsp paprika | 4 | tsp | paprika | 4 | tsp | paprika | ✓ |
| - 2 finely chopped red onions | 2 | — | red onions | 2 | onions | red onion | ≠ |
| - 16 skinless chicken thighs | 16 | — | skinless chicken thi | 16 | thighs | chicken | ≠ |
| - Vegetable oil for brushing | — | — | vegetable oil | 0 | unknown | vegetable oil | ≠ |
| - 300ml Greek yoghurt | — | — | 300ml greek yoghurt | 300 | ml | Greek yoghurt | ≠ |
| - 1 large piece ginger, grated | 1 | large piece | ginger | 1 | ginger | ginger | ≠ |
| - 4 garlic cloves, crushed | 4 | — | garlic cloves | 4 | cloves | garlic | ≠ |
| - 3/4 tsp garam masala | 0.75 | tsp | garam masala | 0.75 | tsp | garam masala | ✓ |
| - 3/4 tsp ground cumin | 0.75 | tsp | ground cumin | 0.75 | tsp | ground cumin | ✓ |
| - 1/2 tsp chilli powder | 0.5 | tsp | chilli powder | 0.5 | tsp | chilli powder | ✓ |
| - 1/4 tsp turmeric | 0.25 | tsp | turmeric | 0.25 | tsp | turmeric | ✓ |

### international-02-chicken-congee (international)

**9 ingredients** | 9 disagreements | 6 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 225g chicken | — | — | 225g chicken | 0.225 | g | chicken | ≠ |
| - Pinch of salt | — | pinch | salt | 0 | pinch | salt | ≠ |
| - Pinch of white pepper | — | pinch | white pepper | 0 | pinch | white pepper | ≠ |
| - 1 tsp ginger cordial | 1 | tsp | ginger cordial | 0.049 | tsp | ginger cordial | ≠ |
| - 1 tsp fresh ginger, sliced | 1 | tsp | fresh ginger | 0.049 | tsp | fresh ginger | ≠ |
| - 1 tbs spring onions, chopped | 1 | — | tbs spring onions | 0.042 | tbs | spring onions | ≠ |
| - 110g rice | — | — | 110g rice | 0.11 | g | rice | ≠ |
| - 2L water | — | — | 2l water | 0.055 | g | coriander | ≠ |
| - 55g fresh coriander | — | — | fresh coriander | 0 |  | water | ≠ |

### international-03-beef-asado (international)

**14 ingredients** | 12 disagreements | 5 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 1.5kg beef | — | — | 1.5kg beef | 1.5 | kg | beef | ≠ |
| - 1 beef stock concentrate | 1 | — | beef stock concentra | 1 | stock concentrate | beef stock concentra | ≠ |
| - 225g tomato puree | — | — | 225g tomato puree | 225 | g | tomato puree | ≠ |
| - 750ml water | — | — | 750ml water | 750 | ml | water | ≠ |
| - 6 tablespoons soy sauce | 6 | — | tablespoons soy sauc | 6 | tbsp | soy sauce | ≠ |
| - 1 tbs white wine vinegar | 1 | tbsp | white wine vinegar | 1 | tsp | white wine vinegar | ≠ |
| - 2 tbs crushed pepper | 2 | — | pepper | 2 | tbsp | crushed pepper | ≠ |
| - 4 bay leaves | 4 | — | bay leaves | 4 | bay leaves | bay leaves | ≠ |
| - 1/2 lemon | — | — | 1/2 lemon | 0.5 | lemon | lemon | ≠ |
| - 2 tbs tomato sauce | 2 | tbsp | tomato sauce | 2 | tbsp | tomato sauce | ✓ |
| - 3 tbs butter | 3 | tbsp | butter | 3 | tbsp | butter | ✓ |
| - 120ml olive oil | — | — | 120ml olive oil | 120 | ml | olive oil | ≠ |
| - 1 chopped onion | 1 | — | onion | 1 | chopped | onion | ≠ |
| - 4 cloves garlic | 4 | clove | garlic | 4 | cloves | garlic | ≠ |

### international-04-parkin-cake (international)

**9 ingredients** | 9 disagreements | 6 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 200g butter | — | — | 200g butter | 200 | g | butter | ≠ |
| - 1 large egg | 1 | — | large egg | 1 | large egg | egg | ≠ |
| - 4 tbs milk | 4 | — | tbs milk | 4 | tbs | milk | ≠ |
| - 200g golden syrup | — | — | 200g golden syrup | 200 | g | golden syrup | ≠ |
| - 85g black treacle | — | — | black treacle | 85 | g | black treacle | ≠ |
| - 85g brown sugar | — | — | 85g brown sugar | 85 | g | brown sugar | ≠ |
| - 100g oatmeal | — | — | 100g oatmeal | 100 | g | oatmeal | ≠ |
| - 250g self-raising flour | — | — | 250g self-raising fl | 250 | g | self-raising flour | ≠ |
| - 1 tbs ground ginger | 1 | tbsp | ginger | 1 | tbs | ground ginger | ≠ |

### international-05-minced-beef-pie (international)

**10 ingredients** | 9 disagreements | 5 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs vegetable oil | 2 | — | tbs vegetable oil | 2 | tbs | vegetable oil | ≠ |
| - 500g minced beef | — | — | beef | 5 | g | minced beef | ≠ |
| - 1 chopped onion | 1 | — | onion | 1 | chopped | onion | ≠ |
| - 1 tbs tomato puree | 1 | tbsp | tomato puree | 1 | tbs | tomato puree | ≠ |
| - 1 1/2 tbsp plain flour | 1.5 | tbsp | plain flour | 1.5 | tbsp | plain flour | ✓ |
| - 75g mushrooms | — | — | 75g mushrooms | 75 | g | mushrooms | ≠ |
| - 250ml beef stock | — | — | 250ml beef stock | 250 | ml | beef stock | ≠ |
| - Dash of Worcestershire sauce | — | dash | worcestershire sauce | 0.5 | dash | Worcestershire sauce | ≠ |
| - 400g shortcrust pastry | — | — | 400g shortcrust past | 4 | g | shortcrust pastry | ≠ |
| - 1 egg yolk | 1 | — | egg yolk | 1 | egg yolk | egg yolk | ≠ |

### international-06-massaman-beef-curry (international)

**13 ingredients** | 10 disagreements | 5 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 85g peanuts | — | — | 85g peanuts | 0.4 | g | peanuts | ≠ |
| - 400ml tin coconut cream | — | tin | coconut cream | 0.4 | l | coconut cream | ≠ |
| - 4 tbsp massaman curry paste | 4 | tbsp | massaman curry paste | 4 | tbsp | massaman curry paste | ✓ |
| - 600g stewing beef, cut into strips | — | — | 600g stewing beef | 0.6 | g | beef shin | ≠ |
| - 450g waxy potatoes | — | — | 450g waxy potatoes | 0.45 | g | waxy potatoes | ≠ |
| - 1 onion, cut in thin wedges | 1 | — | onion | 1 | onion | onion | ≠ |
| - 4 lime leaves | 4 | — | lime leaves | 4 | leaves | lime leaves | ≠ |
| - 1 cinnamon stick | 1 | — | cinnamon stick | 1 | stick | cinnamon stick | ≠ |
| - 1 tbsp tamarind paste | 1 | tbsp | tamarind paste | 1 | tbsp | tamarind paste | ✓ |
| - 1 tbsp palm or soft light brown sugar | 1 | tbsp | palm or soft light b | 1 | tbsp | sugar | ≠ |
| - 1 tbsp fish sauce | 1 | tbsp | fish sauce | 1 | tbsp | fish sauce | ✓ |
| - 1 red chilli, deseeded and finely slic | 1 | — | red chilli | 1 | chilli | red chilli | ≠ |
| - Jasmine rice to serve | — | — | jasmine rice | 1 | cup | jasmine rice | ≠ |

### international-07-madeira-cake (international)

**7 ingredients** | 7 disagreements | 4 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 175g butter | — | — | 175g butter | 175 | g | butter | ≠ |
| - 175g caster sugar | — | — | 175g caster sugar | 175 | g | caster sugar | ≠ |
| - 3 eggs | 3 | — | eggs | 2 | egg | eggs | ≠ |
| - 250g self-raising flour | — | — | 250g self-raising fl | 250 | g | self-raising flour | ≠ |
| - 3 tbs milk | 3 | — | tbs milk | 3 | tbs | milk | ≠ |
| - Zest of 1 lemon | 1 | — | lemon | 1 | lemon | lemon | ≠ |
| - Mixed peel to glaze | — | — | mixed peel | 1 | mixed | peel | ≠ |

### international-08-thai-green-chicken-soup (international)

**14 ingredients** | 13 disagreements | 6 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs sunflower oil | 2 | tbsp | sunflower oil | 2 | tbs | sunflower oil | ≠ |
| - 1 chopped onion | 1 | — | onion | 1 |  | onion | ≠ |
| - 500g chicken thighs | — | — | 500g chicken thighs | 500 | g | chicken thighs | ≠ |
| - 4 sliced garlic cloves | 4 | — | garlic cloves | 4 | tbs | garlic cloves | ≠ |
| - 280g Thai green curry paste | — | — | - 280g Thai green cu | 280 | g | Thai green curry pas | ≠ |
| - 400ml coconut milk | — | — | 400ml coconut milk | 400 | ml | coconut milk | ≠ |
| - 2 litres chicken stock | 2 | litres | chicken stock | 2 | L | chicken stock | ≠ |
| - 5 lime leaves | 5 | — | lime leaves | 5 |  | lime leaves | ≠ |
| - 2 tbs fish sauce | 2 | — | tbs fish sauce | 2 | tbs | fish sauce | ≠ |
| - 1 bunch spring onions | 1 | bunch | spring onions | 1 | bunch | spring onions | ✓ |
| - 280g green beans | — | — | 280g green beans | 280 | g | green beans | ≠ |
| - 150g bamboo shoots | — | — | 150g bamboo shoots | 150 | g | bamboo shoots | ≠ |
| - Juice of 2 limes | 2 | — | limes | 2 |  | limes | ≠ |
| - Bunch of basil | — | bunch | basil | 1 | bunch | basil | ≠ |

### international-09-red-peas-soup (international)

**15 ingredients** | 0 disagreements | 0 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 cups kidney beans | 2 | cup | kidney beans | 0.83 | ml |  |
| - 1 large carrot | 1 | — | large carrot | 0.99 | ml |  |
| - 2 chopped spring onions | 2 | — | spring onions | 1.00 | ml |  |
| - 4 sprigs thyme | 4 | — | sprigs thyme | 0.83 | ml |  |
| - 1 diced onion | 1 | — | onion | 1.00 | ml |  |
| - 1/2 tsp black pepper | 0.5 | tsp | black pepper | 0.91 | ml |  |
| - 2 chopped red peppers | 2 | — | red peppers | 1.00 | ml |  |
| - 4 mashed garlic cloves | 4 | — | garlic cloves | 0.94 | ml |  |
| - 1 tbs allspice | 1 | — | tbs allspice | 0.83 | ml | unit-abbreviation |
| - 900g beef | — | — | 900g beef | 0.83 | ml |  |
| - 2L water | — | — | 2l water | 0.84 | ml |  |
| - 4 potatoes | 4 | — | potatoes | 1.00 | ml |  |
| - 1 cup plain flour | 1 | cup | plain flour | 0.99 | ml |  |
| - 1/4 cup water | 0.25 | cup | water | 0.98 | ml |  |
| - 1 cup coconut milk | 1 | cup | coconut milk | 0.99 | ml |  |

### international-10-fish-soup-ukha (international)

**9 ingredients** | 9 disagreements | 2 FM fixes

| Input | P.Qty | P.Unit | P.Name | FM.Qty | FM.Unit | FM.Name | |
|-------|-------|--------|--------|--------|---------|---------|---|
| - 2 tbs olive oil | 2 | tbsp | olive oil | 2 | tbs | olive oil | ≠ |
| - 1 sliced onion | 1 | — | onion | 1 | sliced | onion | ≠ |
| - 2 medium carrots | 2 | — | medium carrots | 2 | medium | carrots | ≠ |
| - 750ml fish stock | — | — | 750ml fish stock | 750 | ml | fish stock | ≠ |
| - 750ml water | — | — | 750ml water | 750 | ml | water | ≠ |
| - 4 large potatoes | 4 | — | large potatoes | 4 | large | potatoes | ≠ |
| - 3 bay leaves | 3 | — | bay leaves | 3 | bay leaves | bay leaves | ≠ |
| - 1 whole cod fillet | 1 | — | whole cod fillet | 1 | whole | cod fillet | ≠ |
| - 1 whole salmon fillet | 1 | — | whole salmon fillet | 1 | whole | salmon fillet | ≠ |

