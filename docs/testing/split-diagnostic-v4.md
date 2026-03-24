# Split Diagnostic v4 — Detailed localSplitText logging

**Purpose**: Find exactly why "1/2 teaspoon each onion powder and garlic powder" fails to split.
**Branch**: `main`
**Build**: Build from Xcode (Product > Run), iPhone 17 Pro simulator

## Steps

1. Build and run from Xcode
2. Skip walkthrough
3. Import: `https://pinchofyum.com/spicy-shrimp-tacos-with-garlic-cilantro-lime-slaw`
4. Skip import guide
5. Check Xcode console immediately

## Expected Console Output

For the WORKING split (chili powder and cumin):
```
🔀 localSplitText 'each' pattern: qty='2 teaspoons' afterEach='chili powder and cumin'
🔀 localSplitText split: first='chili powder' second='cumin'
```

For the FAILING split (onion powder and garlic powder):
```
🔀 localSplitText 'each' pattern: qty='1/2 teaspoon' afterEach='onion powder and garlic powder'
🔀 localSplitText split: first='onion powder' second='garlic powder'
```

OR if it fails:
```
🔀 localSplitText: no ' and ' in afterEach='...' chars=[hex values]
```

## Capture

Copy ALL lines starting with `🔀 localSplitText` from the console.
