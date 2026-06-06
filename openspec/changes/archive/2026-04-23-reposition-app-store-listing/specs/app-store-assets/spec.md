## ADDED Requirements

### Requirement: Listing leads with noun-phrase differentiators
The App Store listing (name, subtitle, description, keywords, What's New) SHALL lead with concrete noun-phrase differentiators rather than category tropes. The first 60 characters of the name + subtitle combined SHALL name at least two of the three owned positions (household sync without an account, multi-stop shopping, on-device parsing). The description SHALL NOT use ALL-CAPS section headers for every paragraph. Marketing adjectives (SMART, POWERFUL, INTUITIVE, SEAMLESS, EFFORTLESS) SHALL NOT appear as headlines.

#### Scenario: Name and subtitle combined
- **WHEN** a reviewer reads the first 60 characters of the listing (name + subtitle)
- **THEN** at least two of "household," "shared," "multi-store," "no account," "on-device" appear as nouns or noun phrases

#### Scenario: Description section headers
- **WHEN** a reviewer scans the description
- **THEN** fewer than three paragraphs begin with an ALL-CAPS header, and no paragraph uses a category-trope phrase ("GROCERY LISTS", "RECIPES", "MEAL PLANNING") as its leading element

#### Scenario: Description voice
- **WHEN** a reviewer reads the description end-to-end
- **THEN** at least two concrete scenarios reference specific proper nouns (Trader Joe's, Costco, specific ingredient text, CoreML, NaturalLanguage, Anthropic) rather than abstract category language

### Requirement: Screenshots headline the three owned positions
The five App Store screenshots for the 6.9" iPhone size SHALL collectively headline the three owned positions (P1 household without account, P2 multi-stop Group-by-Store, P3 on-device parsing). At least the first three screenshots SHALL each anchor one of the three positions via (a) the UI state captured and (b) an overlay caption composited above the UI. Overlay captions SHALL use noun phrases, not adjectives.

#### Scenario: Screenshot 1 anchors household without account
- **WHEN** a reviewer views Screenshot 1
- **THEN** the UI state shows the household invite flow (household screen with invite button or the iOS share sheet mid-invite) and the overlay caption names "link," "no account," or equivalent noun phrases

#### Scenario: Screenshot 2 anchors multi-stop shopping
- **WHEN** a reviewer views Screenshot 2
- **THEN** the UI state shows the "Group by Store" grocery view with at least two store sections visible, and the overlay caption names "stores" or "multi-stop" as nouns

#### Scenario: Screenshot 3 anchors on-device parsing
- **WHEN** a reviewer views Screenshot 3
- **THEN** the UI state shows the ingredient import preview with parsed structure visible, and the overlay caption names "on-device," "your phone," or equivalent (no mention of the optional Claude integration in this shot)

#### Scenario: Captions composited not in-app
- **WHEN** the screenshot is captured from the iPhone 17 Pro Max simulator
- **THEN** the caption text is added in a design tool (Keynote, Figma, Pixelmator) above the UI region, not added as in-app UI

### Requirement: App Preview video records the three owned positions
A walkthrough video SHALL exist demonstrating the three owned positions in sequence. The canonical version is 45 seconds and is attached to the Resolution Center reply as proof of functionality for the reviewer. A 30-second version MAY additionally be uploaded to App Store Connect as the permanent App Preview asset. The 45-second version SHALL cover the household invite flow, the Group-by-Store grocery view, and the on-device parser preview at minimum.

#### Scenario: 45-second Resolution Center attachment
- **WHEN** the reply to App Review is submitted
- **THEN** a 45-second (±5s) video attachment shows the household invite flow followed by the Group-by-Store view followed by the on-device parser preview, each held for 2-3 seconds

#### Scenario: Video caption overlays
- **WHEN** a reviewer watches the video
- **THEN** each beat displays a noun-phrase caption identifying the workflow ("Invite your household. No account.", "One list. Every store.", "AI parsing on your iPhone.")

### Requirement: Resolution Center reply documents concrete differentiation
The App Store Connect Resolution Center reply to Apple Review SHALL use a bug-fix-changelog tone, remain under 1,500 of the 4,000-character limit, and name specific competitor apps for concrete differentiation. It SHALL state explicitly that the binary has not changed and that the functionality cited was already present in the build under review. It SHALL list the metadata changes made (subtitle, description headline sections, screenshots, keywords) so the reviewer can verify each.

#### Scenario: Reply names competitors
- **WHEN** a reviewer reads the reply
- **THEN** at least three of AnyList, Plan to Eat, Samsung Food, BigOven, Mealime, Crouton, or Mela are named with the specific axis of comparison (account-based vs. Apple Family Sharing vs. cloud parsing)

#### Scenario: Reply itemizes changes
- **WHEN** a reviewer reads the reply
- **THEN** the reply contains a numbered list of the metadata changes made, covering at minimum subtitle change, description rewrite with headline sections listed, screenshot replacements, and keyword adjustment

#### Scenario: Reply avoids failure patterns
- **WHEN** a reviewer reads the reply
- **THEN** the reply does not ask Apple to identify the allegedly similar apps, does not reference how long the developer has been on the App Store, does not use emotional language, and does not claim originality without evidence

### Requirement: Canonical listing source in docs precedes ASC updates
Canonical source of truth for App Store listing copy SHALL live in `docs/app-store-listing.md` and SHALL be updated before the corresponding fields are updated in App Store Connect. A companion document `docs/app-store-rejection-43a-response.md` SHALL capture the Resolution Center reply letter, video script, screenshot shot-list with overlay caption text, and submission checklist for the 2026-04-21 rejection cycle.

#### Scenario: docs/app-store-listing.md is the source
- **WHEN** ASC is updated with new listing copy
- **THEN** the text in `docs/app-store-listing.md` matches the text in ASC (barring minor whitespace or trailing-newline differences), and the commit history shows the docs update preceded the ASC update

#### Scenario: Rejection response artifacts committed
- **WHEN** the reply is submitted to Apple
- **THEN** `docs/app-store-rejection-43a-response.md` exists in the repository containing the reply letter (as submitted), the 45-second video script, the screenshot shot-list with caption copy, and a dated entry under "Submission History" recording the submission

## MODIFIED Requirements

### Requirement: Landing page reflects repositioning
The GitHub Pages root URL (`https://rfhayn.github.io/forager/`) SHALL serve a landing page whose hero tagline, feature list, and (new) screenshots section align with the repositioning. The hero tagline SHALL lead with a noun-phrase differentiator (household sharing, multi-stop shopping, or on-device parsing) rather than a category-trope phrase. The feature list SHALL lead with the no-account household position. A Screenshots section SHALL include at least three of the five new App Store screenshots.

#### Scenario: Hero tagline
- **WHEN** a user loads the landing page
- **THEN** the hero tagline does not use "meal planner," "grocery list," or "recipe manager" as its first three words, and does name "household," "shared," or equivalent

#### Scenario: Feature list order
- **WHEN** a user reads the feature bullets
- **THEN** the first bullet names household sharing and the absence of an account requirement

#### Scenario: Screenshots visible
- **WHEN** a user scrolls the landing page on a mobile device
- **THEN** at least three of the new App Store screenshots render without horizontal scrolling, each with its overlay caption legible

### Requirement: ASC metadata reference document
The reference document `docs/app-store-listing.md` SHALL contain all App Store Connect metadata fields with current values reflecting the repositioning: app name "forager - Shared Shopping", subtitle "Household Sync, Multi-Store", human-voice description under 4,000 characters, keywords under 100 characters leading with "household,shared grocery,multi store", What's New copy, age rating answers (Unrestricted Web Access = Yes, rating 17+), screenshots guidance referencing the new five-shot set, Resolution Center response notes, and the submission checklist.

#### Scenario: Document contents
- **WHEN** a contributor opens `docs/app-store-listing.md`
- **THEN** the document contains all nine fields (name, subtitle, primary category, secondary category, copyright, age rating, price, description, keywords, What's New, support URL, privacy policy URL, marketing URL) with values matching the repositioning

#### Scenario: Character limits respected
- **WHEN** the fields are copied into ASC
- **THEN** the name is within 30 characters, the subtitle is within 30 characters, the description is within 4,000 characters, and the keywords field is within 100 characters
