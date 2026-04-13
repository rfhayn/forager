## ADDED Requirements

### Requirement: Privacy policy discloses AI data flow
The privacy policy SHALL disclose that the optional AI ingredient parsing feature sends ingredient text to Anthropic's Claude API when the user enables the feature and provides their own API key.

#### Scenario: User reads privacy policy with AI disclosure
- **WHEN** a user views the privacy policy at the public URL
- **THEN** the policy includes a section explaining the optional AI feature, that it is off by default, that the user must provide their own API key, that only ingredient text is sent, and that the developer never sees the data

#### Scenario: Third-party language is accurate
- **WHEN** the privacy policy describes third-party data sharing
- **THEN** it lists Anthropic's Claude API as a conditional third party alongside Apple iCloud and household members, with a link to Anthropic's privacy policy

### Requirement: Landing page exists at GitHub Pages root
The GitHub Pages root URL SHALL serve a landing page with app information, a TestFlight link, and links to the privacy policy and support.

#### Scenario: User visits landing page
- **WHEN** a user visits `https://rfhayn.github.io/forager/`
- **THEN** they see the app icon, app name, feature list, a TestFlight beta link, and links to the privacy policy and support

#### Scenario: Landing page is mobile-responsive
- **WHEN** a user views the landing page on a mobile device
- **THEN** the layout adapts to the screen width without horizontal scrolling

### Requirement: README reflects current project state
The README SHALL contain accurate statistics, correct license, and a TestFlight link.

#### Scenario: README stats are current
- **WHEN** a reader views the README
- **THEN** it shows ~345 development hours, 531 tests, 13 Core Data entities, schema v11, iOS 26+, 14 ADRs, and a proprietary license

### Requirement: App Store listing copy is drafted
A reference document SHALL contain all App Store Connect metadata ready to copy into ASC.

#### Scenario: Metadata document contains required fields
- **WHEN** the user opens the listing document
- **THEN** it contains: app name (30 chars), subtitle (30 chars max), description (4000 chars max), keywords (100 chars max), category, copyright, support URL, privacy policy URL, and marketing URL

#### Scenario: ASC submission checklist is complete
- **WHEN** the user follows the submission checklist
- **THEN** it covers: screenshots guidance, privacy nutrition label answers, age rating answers, pricing, app review notes, build selection, and submission steps

### Requirement: Export compliance flag is set
The app's Info.plist SHALL contain `ITSAppUsesNonExemptEncryption` set to `false`.

#### Scenario: Export compliance already configured
- **WHEN** the Info.plist is checked
- **THEN** `ITSAppUsesNonExemptEncryption` is already `false` (no change needed)
