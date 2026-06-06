## 1. Session 1 — Canonical text updates (Claude executes)

- [x] 1.1 Update `docs/app-store-listing.md`: change Name to `forager - Shared Shopping`, Subtitle to `Household Sync, Multi-Store`, replace the Description block with the 1,450-char human-voice rewrite, replace Keywords with `household,shared grocery,meal plan,recipe,multi store,shopping list,iCloud sync,cooking,family`, replace What's New copy, add a note under Screenshots referencing the new five-shot set, keep the Age Rating 17+ answers unchanged
- [x] 1.2 Rewrite `docs/index.html` hero tagline to `Shared grocery lists for households. No account. No server. Just iCloud.`, reorder the feature bullets to lead with the no-account claim, add a new Screenshots section with three `<img>` tags referencing the new captioned shots (placeholder filenames: `screenshots/01-household-invite.png`, `screenshots/02-group-by-store.png`, `screenshots/03-on-device-parsing.png`)
- [x] 1.3 Create `docs/app-store-rejection-43a-response.md` containing: Rejection record (date, submission ID, guideline cited, reviewer device), Resolution Center reply letter (exact text as submitted), Screenshot shot-list with UI state + caption copy for all five shots, 45-second video script with beat table, 30-second video script (condensed), Submission History (undated entry for "prepared 2026-04-21"), and a final Verification section with the checks the reviewer is expected to run
- [x] 1.4 Update `openspec/specs/app-store-assets/spec.md` living spec to reference the repositioning once archived (this is a no-op during the proposal; the archive step at close-out promotes the delta into the living spec) — verified no-op, delta lives in `openspec/changes/reposition-app-store-listing/specs/app-store-assets/spec.md` and will be promoted by `/opsx:archive` at close-out
- [x] 1.5 Proofread all new copy against `feedback_copy_style.md`: "forager" always lowercase, no em dashes (replace any with commas, periods, colons, or standard hyphens) — verified: all ASC-bound blocks (description, subtitle, keywords, What's New, captions, reply letter) are clean. Em dashes in internal shot-list headings and documentation commentary retained as out-of-scope per the rule's "app copy" definition.
- [x] 1.6 Commit Session 1 changes with message `reposition-app-store-listing: update canonical listing copy and landing page` — committed as `7276217`
- [x] 1.7 Verify build still succeeds (defensive — no code changes expected but metadata files can sometimes get referenced): `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` — BUILD SUCCEEDED confirmed

## 2. Session 2A — Simulator preparation (user executes, ~20 min)

- [ ] 2.1 Boot iPhone 17 Pro Max simulator: `xcrun simctl boot "iPhone 17 Pro Max"` then `open -a Simulator`
- [ ] 2.2 Build forager for the Pro Max target: `xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' build`
- [ ] 2.3 Install and launch: `xcrun simctl install booted "$(find ~/Library/Developer/Xcode/DerivedData/forager-* -path '*Debug-iphonesimulator/forager.app' -type d | head -1)"` then `xcrun simctl launch booted com.richhayn.forager`
- [ ] 2.4 Set simulator to Light Mode: Simulator menu > Features > Toggle Appearance (verify status shows Light)
- [ ] 2.5 Apply the marketing status bar override: `xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularMode notSupported --wifiMode active --wifiBars 3`
- [ ] 2.6 Complete onboarding in the app with a generic first name (suggested: `Rich`)
- [ ] 2.7 Create a household named `The Kitchen` (generic, no real last name) and add a placeholder member named `Alex`
- [ ] 2.8 Create three stores (Settings > Stores > Add): `Trader Joe's`, `Costco`, `Target`
- [ ] 2.9 Create three recipes via text-paste import or manual entry: `Chicken Tikka Masala`, `Chocolate Chip Cookies`, `Shrimp Tacos` (let the parser populate ingredients)
- [ ] 2.10 Create a weekly list named `This Week` with approximately 10 items distributed across the three stores; assign preferred stores to each ingredient template
- [ ] 2.11 Open the meal plan view and assign two or three recipes to the current week
- [ ] 2.12 Verification pass: Dashboard shows populated week + list; Group by Store toggles cleanly and shows at least two store sections; Recipe scaling shows fractional quantities; Household Invite button is visible in Settings > Household
- [ ] 2.13 Snapshot the simulator data state: `xcrun simctl clone booted forager-screenshot-state` (lets you restore this exact state if you need to reshoot a screenshot)

## Session 2 — PAUSED 2026-04-21

Shot 1 v1 captured but blocked on last-name exposure (see `docs/app-store-rejection-43a-response.md` § 9). Session 2 paused when CoreData zone-corruption bug surfaced on the device — bug fix takes precedence before any further screenshot/video work. Resume after bug-fix change ships.

Pinned state:
- [x] Shot 1 v1 captured (last names still visible — needs Option A or B decision)
- [ ] Shot 1 share sheet capture (not yet taken)
- [ ] Shots 2-5 (not yet taken)
- [ ] Walkthrough videos (not yet recorded)

## 3. Session 2B — Capture the five screenshots (user executes, ~45 min)

- [ ] 3.1 Screenshot 1 — Household invite. Navigate to Settings tab > Household. Show household name, member list with Alex, prominent Invite button. Optional: tap Invite and capture with the iOS share sheet partially visible. Press Cmd+S in the simulator window. Rename the saved PNG on Desktop to `01-household-invite-raw.png`
- [ ] 3.2 Screenshot 2 — Group by Store. Navigate to Grocery tab > `This Week` list. Toggle Group by Store ON. Verify at least two store sections visible with 2-4 items each. Check off one item to show live state. Press Cmd+S. Rename to `02-group-by-store-raw.png`
- [ ] 3.3 Screenshot 3 — On-device parsing. Navigate to the recipe import flow (Recipes > Import > Paste Text or equivalent). Paste the sample text from `docs/app-store-rejection-43a-response.md` Screenshot 3 spec (Spaghetti Carbonara ingredient block). Load the preview so parsed structure is visible. Do NOT trigger Claude. Press Cmd+S. Rename to `03-on-device-parsing-raw.png`
- [ ] 3.4 Screenshot 3 verification: open the raw PNG in Preview and confirm that a first-time viewer can see the parsed structure (quantity, unit, ingredient, qualifier). If it's not visually obvious, pivot to the inline ingredient edit screen with autocomplete suggestions visible and reshoot.
- [ ] 3.5 Screenshot 4 — Dashboard. Navigate to Home tab. Verify greeting, populated Meal Plan card, populated This Week card, and Quick Actions row are all visible. Press Cmd+S. Rename to `04-dashboard-raw.png`
- [ ] 3.6 Screenshot 5 — Recipe scaling. Navigate to Recipes > Chicken Tikka Masala. Scroll to the servings stepper. Bump servings from 4 to 8 so fractional quantities appear (e.g. `6 tsp`, `3 cups`). Press Cmd+S. Rename to `05-recipe-scaling-raw.png`
- [ ] 3.7 Sanity check: open all five raw PNGs in Preview. Confirm each is exactly 1320 × 2868 px. If any differ, the simulator was the wrong model (verify 2.1 used iPhone 17 Pro Max) and reshoot.

## 4. Session 2C — Composite overlay captions (user executes, ~30 min)

- [ ] 4.1 Open Keynote. Create a new blank document. Set Slide Size to Custom: 1320 × 2868 pixels.
- [ ] 4.2 For Slide 1: insert `01-household-invite-raw.png`, resize to fit the bottom 75% of the slide. Add a text box in the top 25% with the two-line caption (line 1: `Invite your household with a link.`, line 2: `No account. No signup. No email.`). Font: SF Pro Rounded Bold. Line 1 size ~90pt, line 2 size ~60pt. Color: `#000000` (or consistent forager green `#27AE60` if you prefer — keep same choice across all 5)
- [ ] 4.3 Slide 2 (`02-group-by-store-raw.png`): caption lines `One list. Every store.` and `Multi-stop shopping without the juggle.`
- [ ] 4.4 Slide 3 (`03-on-device-parsing-raw.png`): caption lines `Your grocery list stays on your phone.` and `AI parsing, no server round-trip.`
- [ ] 4.5 Slide 4 (`04-dashboard-raw.png`): caption lines `Your week, at a glance.` and `Meals planned. Groceries ready.`
- [ ] 4.6 Slide 5 (`05-recipe-scaling-raw.png`): caption lines `Scale any recipe. Fractions made friendly.` and `0.25× to 4×, always readable.`
- [ ] 4.7 Verify all five slides look visually consistent (same font size ratio, same color, same caption placement). If any slide feels cramped, resize the screenshot to 70% and expand the caption area to 30%.
- [ ] 4.8 Export: File > Export To > Images > Format PNG > Image Quality Best. In the dialog, verify the exported resolution matches 1320 × 2868 (Keynote exports at display resolution by default; you may need to open each exported PNG in Preview and scale to 1320 × 2868 if Keynote outputs at 2x or 3x)
- [ ] 4.9 Rename final PNGs: `01-household-invite.png` through `05-recipe-scaling.png`. Verify each is exactly 1320 × 2868 px (`sips -g pixelWidth -g pixelHeight 01-household-invite.png` in Terminal)
- [ ] 4.10 Copy final PNGs to `docs/beta/screenshots/` (new directory — create with `mkdir -p docs/beta/screenshots`). This puts them in version control alongside the landing page.

## 5. Session 2D — Record the walkthrough video (user executes, ~45 min)

- [ ] 5.1 Reset simulator data state to the prepared screenshot state: `xcrun simctl terminate booted com.richhayn.forager` then `xcrun simctl launch booted com.richhayn.forager`
- [ ] 5.2 Start recording from the simulator: `xcrun simctl io booted recordVideo --codec=h264 ~/Desktop/forager-walkthrough-raw.mov`
- [ ] 5.3 Perform the beats in order, holding each for 2-3 seconds:
  - Beat 1 (0:00-0:04): Open the app, land on Dashboard
  - Beat 2 (0:04-0:12): Settings > Household > Invite via Link > iOS share sheet appears
  - Beat 3 (0:12-0:18, optional): accepting device demonstration (skip if staging a second simulator is complex)
  - Beat 4 (0:18-0:28): Grocery tab > This Week > toggle Group by Store > sections snap into place
  - Beat 5 (0:28-0:38): Recipes > Import > paste ingredient text > parsed preview appears
  - Beat 6 (0:38-0:45): return to Dashboard, hold on populated state
- [ ] 5.4 Stop recording: `Ctrl+C` in the terminal running `xcrun simctl io`
- [ ] 5.5 Open `forager-walkthrough-raw.mov` in iMovie. Trim any dead space at the start and end. Add title cards (text overlay) between beats with the caption copy from `docs/app-store-rejection-43a-response.md` video script
- [ ] 5.6 Export 45-second version: iMovie > File > Share > File. Resolution: 1080p. Quality: High. Compress: Faster. Save as `forager-walkthrough-45s.mp4`. Verify file size is under 25 MB; if larger, reduce Quality to Medium and re-export
- [ ] 5.7 Export 30-second version (optional — only if uploading to ASC as an App Preview): return to iMovie, trim to 30 seconds, cut the optional Beat 3, save as `forager-walkthrough-30s.mp4`
- [ ] 5.8 Verify both videos play cleanly in QuickTime before upload. If any audio issues (from accidentally recording with mic on), re-export with audio muted.

## 6. Session 3 — App Store Connect submission (user executes, ~40 min)

- [ ] 6.1 Open App Store Connect > My Apps > forager > App Store tab > iOS App > select version 2.0
- [ ] 6.2 Update Name field to `forager - Shared Shopping`. If ASC validates and accepts, proceed. If there is a naming collision error, fall back to checking whether `forager` alone is available; if not, leave the name as the current value and note this in the reply letter.
- [ ] 6.3 Update Subtitle to `Household Sync, Multi-Store`
- [ ] 6.4 Replace Description with the text from `docs/app-store-listing.md` Description block (paste, verify no trailing whitespace, confirm character count under 4,000)
- [ ] 6.5 Replace Keywords with the text from `docs/app-store-listing.md` Keywords block (verify character count under 100)
- [ ] 6.6 Replace What's New in This Version with the new copy from `docs/app-store-listing.md`
- [ ] 6.7 Scroll to App Previews and Screenshots > 6.9" iPhone section. Delete all existing screenshots.
- [ ] 6.8 Upload the five captioned screenshots in order: `01-household-invite.png` through `05-recipe-scaling.png`. Verify ASC shows them in the intended order.
- [ ] 6.9 If ASC flags a "Missing" indicator for 6.3" iPhone, use ASC's auto-scale feature (enabled by default for most cases) or upload the same five screenshots scaled to the 6.3" dimensions (Preview > Tools > Adjust Size, or Keynote re-export at 1290 × 2796)
- [ ] 6.10 (Optional) Upload the 30-second App Preview video to the 6.9" iPhone App Preview slot
- [ ] 6.11 Verify all required ASC fields show no "Missing" indicators. Save changes.
- [ ] 6.12 Navigate to the Resolution Center (App Store Connect > app > App Store tab, or the messaging icon near the top-right if Apple opened a conversation thread)
- [ ] 6.13 Open the thread from the 2026-04-21 rejection
- [ ] 6.14 Paste the reply letter text from `docs/app-store-rejection-43a-response.md` into the reply field. Verify character count under 4,000.
- [ ] 6.15 Use the attach-file button to attach: `01-household-invite.png`, `02-group-by-store.png`, `03-on-device-parsing.png`, and `forager-walkthrough-45s.mp4`
- [ ] 6.16 Submit the reply. No Resubmit click is needed — Apple resumes review automatically for metadata-cited rejections.
- [ ] 6.17 Update `docs/app-store-rejection-43a-response.md` Submission History section with a dated entry for the submission (today's date, reply text confirmed as sent, attachments listed)
- [ ] 6.18 Commit the submission history update with message `reposition-app-store-listing: record Resolution Center reply submitted YYYY-MM-DD`

## 7. Session 4 — Monitor the review response (user executes, ~48-72 hr wait)

- [ ] 7.1 Check email for Apple Review response daily. Typical response window: 24-72 hours.
- [ ] 7.2 If approved: update `docs/current-story.md` to mark M7.7 as APPROVED; archive this OpenSpec change via `/opsx:archive reposition-app-store-listing`; celebrate
- [ ] 7.3 If rejected again with the same 4.3(a) template: document the second rejection in `docs/app-store-rejection-43a-response.md` Submission History; open a new OpenSpec change `escalate-43a-to-app-review-board` to draft the Board appeal letter
- [ ] 7.4 If rejected with a different guideline: treat the 4.3(a) as resolved; open a separate change to triage the new guideline; keep this change active until both the new guideline is resolved AND the overall submission is approved
- [ ] 7.5 If Apple asks a follow-up question in the Resolution Center (rather than approving or rejecting): draft a reply in `docs/app-store-rejection-43a-response.md` first, then paste into ASC; update Submission History

## 8. Close-out

- [ ] 8.1 Run `/review` to catch any issues with the branch's changes before PR
- [ ] 8.2 Update `docs/development-journal.md` with the session narrative (use `/dev-journal`)
- [ ] 8.3 Log key insights to `docs/insights-log.md` (use `/log-insight`) — at minimum: the "metadata = screenshots + text" finding from Apple Forum 772135, the three-owned-positions framing, and any new learnings from the review outcome
- [ ] 8.4 Run `/pr` to create the pull request with all branch changes
- [ ] 8.5 After PR merges (squash to main), run `/opsx:archive reposition-app-store-listing` to promote the delta spec into the living spec and archive the change
