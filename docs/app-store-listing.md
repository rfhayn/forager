# forager - App Store Listing

**Last Updated**: July 24, 2026 (fresh app record — "forager - Groceries, managed.", App ID 6794530669, bundle `com.richhayn.foragerapp`; description/keywords carried from the 2026-04-23 repositioning, recovered from commit `7276217`)

---

## Part A: App Store Connect Metadata

### App Information

| Field | Value |
|-------|-------|
| **Name** | forager - Groceries, managed. |
| **Subtitle** | Household Sync, Multi-Store |
| **Primary Category** | Food & Drink |
| **Secondary Category** | Productivity |
| **Copyright** | 2026 Rich Hayn |
| **Age Rating** | 17+ (required — recipe URL import = Unrestricted Web Access) |
| **Price** | Free |

### URLs

| Field | URL |
|-------|-----|
| **Support URL** | https://github.com/rfhayn/forager/issues |
| **Privacy Policy URL** | https://rfhayn.github.io/forager/privacy.html |
| **Marketing URL** | https://rfhayn.github.io/forager/ |

### Description

```
forager helps your household plan meals, build grocery lists, and cook together -- all synced through iCloud.

GROCERY LISTS
Create lists organized by store section. Check items off as you shop. Share lists with your household in real time through iCloud. Assign preferred stores to ingredients and group your list by store for efficient multi-stop shopping.

RECIPES
Save your favorite recipes with ingredients and instructions. Import from websites, pasted text, or photos. Scale servings up or down and quantities adjust automatically -- always shown in kitchen-friendly fractions.

MEAL PLANNING
Plan your week on a calendar. Assign recipes to days, then generate your grocery list with one tap. Duplicate ingredients merge automatically with smart quantity conversion.

HOUSEHOLD SYNC
Invite family members to your household. Everyone sees the same lists, recipes, and meal plans -- synced instantly via iCloud. No account to create, no server to trust.

SMART INGREDIENTS
forager understands ingredient text. Type "2 cups flour" or "a pinch of saffron" and it parses quantity, unit, and ingredient automatically. A 3-tier parsing engine (pattern matching, machine learning, and natural language processing) handles everything from simple amounts to complex recipe language.

PRIVACY FIRST
Your data stays in your iCloud account. No third-party servers, no tracking, no ads. An optional AI parsing feature is available for power users who provide their own API key -- forager works fully without it.
```

### Keywords (100 characters max)

```
grocery,shopping list,recipe,household,family,iCloud,cooking,ingredients,food,weekly,pantry
```

Note: Words already in the app name ("forager", "smart", "meal", "planner") are indexed automatically by Apple and excluded from keywords to maximize search coverage.

### What's New in This Version

```
First release! Plan meals, build grocery lists, and share everything with your household through iCloud.
```

### App Review Notes

```
forager uses iCloud (CloudKit) for data storage and sync. Household sharing requires two iCloud accounts to test fully -- one to create the household, another to accept the invitation.

The AI ingredient parsing feature (Settings > AI Integration) is optional and off by default. It requires the user to provide their own Anthropic API key. The app works fully without it.

No login or account creation is required. All data is stored in the user's iCloud account.
```

---

## Part B: App Store Connect Submission Checklist

### Screenshots

- [ ] **6.9" iPhone** (1320 x 2868) -- 3-5 screenshots from real device (iPhone Pro Max)
- [ ] Recommended screens:
  - Grocery list (with items, categories visible)
  - Recipe detail (with ingredients, scaling)
  - Meal plan calendar
  - Dashboard
  - Recipe import
- [ ] Use light mode with real, representative data
- [ ] Avoid Household Members view (shows real names + emails)
- [ ] Dashboard greeting shows first name only -- acceptable
- [ ] Optional: rename household to something generic before Settings screenshots

### Privacy Nutrition Labels

- [ ] "Do you or your third-party partners collect data from this app?" --> **Yes**
- [ ] Select: **User Content** > **Other User Content**
- [ ] "Is this data linked to the user's identity?" --> **No**
- [ ] "Is this data used for tracking?" --> **No**
- [ ] Purpose: **App Functionality**

Note: This covers the optional Claude API ingredient parsing. CloudKit data is exempt per Apple's guidance (stored in user's own iCloud, developer does not access it).

### Age Rating Questionnaire

- [ ] Content questions (violence, sexual content, profanity, etc.): **None** / **No**
- [ ] **Unrestricted Web Access: Yes** — required because the recipe URL import feature fetches user-supplied URLs. Answering No here was the cause of the 2026-04-17 rejection (guideline 2.3.6).
- [ ] Expected result: **17+** (mandatory once Unrestricted Web Access = Yes; not negotiable without restricting URL import to an allowlist)

### Pricing

- [ ] Price: **Free**
- [ ] Territories: **All** (or select specific regions)

### Export Compliance

- [ ] `ITSAppUsesNonExemptEncryption` already set to `false` in Info.plist
- [ ] App uses only standard iOS encryption (HTTPS/TLS) -- qualifies for exemption

### Build Selection

- [ ] Select latest TestFlight build
- [ ] Ensure version number matches the App Store version page
- [ ] Build must have finished processing (not in "Processing" state)

### Submission

- [ ] All metadata fields complete (no "Missing" indicators in ASC)
- [ ] Screenshots uploaded for 6.9" iPhone
- [ ] Privacy nutrition labels completed
- [ ] Age rating completed
- [ ] Select **Manual Release** (recommended for first submission)
- [ ] Submit for review
- [ ] Monitor email for Apple communications (typical review: 24-48 hours)
- [ ] Respond within 24 hours if Apple contacts you
