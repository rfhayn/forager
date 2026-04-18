# Spec: App Store Assets

## Overview

Web presence and documentation required for App Store submission: privacy policy, landing page, README, App Store listing copy, and submission checklist.

## Requirements

- REQ-001: The privacy policy SHALL disclose that the optional AI ingredient parsing feature sends ingredient text to Anthropic's Claude API when the user enables the feature and provides their own API key.
  - Scenario: Given a user views the privacy policy at the public URL, Then the policy includes a section explaining the optional AI feature, that it is off by default, that the user must provide their own API key, that only ingredient text is sent, and that the developer never sees the data.
  - Scenario: Given the privacy policy describes third-party data sharing, Then it lists Anthropic's Claude API as a conditional third party alongside Apple iCloud and household members, with a link to Anthropic's privacy policy.

- REQ-002: The GitHub Pages root URL SHALL serve a landing page with app information, a TestFlight link, and links to the privacy policy and support.
  - Scenario: Given a user visits https://rfhayn.github.io/forager/, Then they see the app icon, app name, feature list, a TestFlight beta link, and links to the privacy policy and support.
  - Scenario: Given a user views the landing page on a mobile device, Then the layout adapts to the screen width without horizontal scrolling.

- REQ-003: The README SHALL contain accurate statistics, correct license, and a TestFlight link.
  - Scenario: Given a reader views the README, Then it shows ~345 development hours, 531 tests, 13 Core Data entities, schema v11, iOS 26+, 14 ADRs, and a proprietary license.

- REQ-004: A reference document SHALL contain all App Store Connect metadata ready to copy into ASC.
  - Scenario: Given the user opens the listing document, Then it contains: app name (30 chars), subtitle (30 chars max), description (4000 chars max), keywords (100 chars max), category, copyright, support URL, privacy policy URL, and marketing URL.
  - Scenario: Given the user follows the submission checklist, Then it covers: screenshots guidance, privacy nutrition label answers, age rating answers, pricing, app review notes, build selection, and submission steps.

- REQ-006: The Age Rating declaration SHALL answer "Yes" to "Unrestricted Web Access" because the recipe import feature fetches user-supplied URLs.
  - Scenario: Given the Age Rating questionnaire is being answered, Then "Unrestricted Web Access" is set to "Yes" and the resulting age rating is 17+.
  - Scenario: Given the listing document describes the Age Rating, Then it explicitly calls out that "Unrestricted Web Access: Yes" is required and explains why (recipe URL import), with a reference to the 2026-04-17 rejection (guideline 2.3.6) that established this requirement.

- REQ-005: The app's Info.plist SHALL contain `ITSAppUsesNonExemptEncryption` set to `false`.
  - Scenario: Given the Info.plist is checked, Then `ITSAppUsesNonExemptEncryption` is already `false`.

## Implementation Notes

- Privacy policy: `docs/privacy.html` (hosted via GitHub Pages)
- Landing page: `docs/index.html` (hosted via GitHub Pages)
- App icon for web: `docs/icon.png` (512px)
- README: `README.md` (repo root)
- Listing copy: `docs/app-store-listing.md`
- GitHub Pages serves from `main` branch `/docs` directory
