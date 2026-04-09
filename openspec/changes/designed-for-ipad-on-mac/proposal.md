## Why

The forager iOS app already runs on Apple Silicon Macs via compatibility mode with full CloudKit Production sync — all data (recipes, grocery lists, meal plans, household sharing) works perfectly. Rather than maintaining a separate native macOS target (M19, scrapped), we can formally enable "Designed for iPad" distribution with light polish to make the experience solid on Mac. This gets forager onto the Mac App Store with minimal effort and zero ongoing maintenance burden.

## What Changes

- Enable `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` in Xcode project settings
- Hide camera-dependent features (document scanner) on Mac — prevents crash from `VNDocumentCameraViewController`
- Fix device name extraction for Mac (greeting shows "Good morning, Rich" not broken fallback)
- Bump minimum font sizes for Mac readability (8pt → 11pt minimum)
- Add manual refresh toolbar buttons where pull-to-refresh doesn't work on Mac
- Improve sheet dismiss behavior on Mac (allow ESC-dismiss where safe)
- Migrate deprecated `NavigationView` to `NavigationStack` (27 files — improves Mac window behavior)
- Use adaptive grid columns in color pickers instead of fixed 5-column layout
- Adjust sheet presentation detents to be larger on Mac
- Archive foragerMac App Store Connect record (ID 6761905908) — iOS listing auto-extends to Mac

## Capabilities

### New Capabilities
- `mac-compatibility`: Platform detection, camera feature gating, device name extraction, and Mac-specific UI adjustments for "Designed for iPad" distribution

### Modified Capabilities
- `recipes`: Recipe import flow hides camera/scanner options on Mac; NavigationView → NavigationStack migration
- `grocery-lists`: Pull-to-refresh alternative on Mac; haptic feedback graceful degradation; NavigationView → NavigationStack
- `meal-planning`: Pull-to-refresh alternative on Mac; haptic feedback graceful degradation; NavigationView → NavigationStack
- `settings`: Onboarding/welcome flow works in sheet mode on Mac (fullScreenCover becomes sheet)

## Impact

- **Xcode project**: `project.pbxproj` — flip Mac support flag (2 build configurations)
- **App Store Connect**: Archive separate foragerMac record, iOS listing auto-distributes to Mac
- **Import views**: `DocumentScannerView.swift`, `PhotoImportView.swift`, `RecipeImportSheet.swift` — platform guards
- **Dashboard**: `DashboardView.swift` — device name extraction fix
- **Services**: `HouseholdService.swift`, `DiagnosticLogger.swift` — device name fallback
- **27 view files**: NavigationView → NavigationStack migration (non-breaking, improves iPad too)
- **3 view files**: Font size bumps
- **5 sheet presentations**: ESC-dismiss enablement on Mac
- **2 color pickers**: Adaptive grid columns
- **3 sheets**: Larger presentation detents
- **No Core Data changes, no schema changes, no service layer changes**
