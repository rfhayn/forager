## ADDED Requirements

### Requirement: Mac App Store distribution enabled
The system SHALL be distributed on the Mac App Store via "Designed for iPad" by setting `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES` in both Debug and Release build configurations.

#### Scenario: App available on Mac App Store
- **WHEN** the iOS app is submitted to the App Store with Mac support enabled
- **THEN** the same listing appears on the Mac App Store for Apple Silicon Macs

### Requirement: Camera features hidden on Mac
The system SHALL hide camera-dependent features when running on Mac (`ProcessInfo.processInfo.isiOSAppOnMac == true`). This includes the document scanner (`VNDocumentCameraViewController`) and any camera capture options.

#### Scenario: Import menu on Mac
- **WHEN** a user opens the recipe import menu on Mac
- **THEN** "Browse for Recipe", "Paste URL", and "Paste Recipe Text" options are visible
- **THEN** "Import from Photo" is visible (photo library only, no camera)
- **THEN** the document scanner / "Scan Document" option is NOT visible

#### Scenario: Photo import on Mac
- **WHEN** a user opens the photo import view on Mac
- **THEN** only the photo library picker is available
- **THEN** the "Scan Document" button is NOT visible

### Requirement: Device name extraction supports Mac
The system SHALL extract the user's first name from Mac device names (e.g., "Rich's MacBook Pro" → "Rich") for the dashboard greeting and household setup.

#### Scenario: Dashboard greeting on Mac
- **WHEN** the app launches on a Mac with device name "Rich's MacBook Pro"
- **THEN** the dashboard displays "Good morning, Rich" (not a broken fallback)

#### Scenario: Unknown device name format
- **WHEN** the device name does not match any known pattern (iPhone, iPad, iPod, Mac, MacBook, iMac, Mac mini, Mac Pro, Mac Studio)
- **THEN** the system falls back to a generic greeting ("Good morning")

### Requirement: Minimum font size for Mac readability
The system SHALL use a minimum font size of 11pt (or `.caption2` dynamic type) for all text displayed in the app. No text SHALL be smaller than 11pt.

#### Scenario: Small text on Mac
- **WHEN** the app displays text that was previously 8pt or 10pt
- **THEN** the text renders at 11pt minimum, readable on Mac displays

### Requirement: Manual refresh available on Mac
The system SHALL provide a toolbar refresh button on views that use pull-to-refresh, since pull-to-refresh is not available with mouse/trackpad interaction on Mac.

#### Scenario: Grocery lists refresh on Mac
- **WHEN** a user views the grocery lists screen on Mac
- **THEN** a refresh button is available in the toolbar
- **THEN** tapping it triggers the same refresh action as pull-to-refresh on iOS

#### Scenario: Meal plans refresh on Mac
- **WHEN** a user views the meal plans screen on Mac
- **THEN** a refresh button is available in the toolbar

### Requirement: Sheet dismiss behavior on Mac
The system SHALL allow interactive dismiss (ESC key, click outside) on modal sheets when running on Mac, except for sheets with unsaved edits where data loss would occur.

#### Scenario: Read-only sheet on Mac
- **WHEN** a user presents a sheet without active editing (e.g., category assignment, ingredient selection)
- **THEN** the sheet can be dismissed with ESC key or clicking outside

#### Scenario: Edit sheet on Mac
- **WHEN** a user presents a sheet with active editing (e.g., CreateRecipeView, EditRecipeView)
- **THEN** the sheet MUST NOT be dismissible by clicking outside (prevents data loss)

### Requirement: NavigationView migrated to NavigationStack
All uses of the deprecated `NavigationView` SHALL be replaced with `NavigationStack` for improved Mac window behavior and iPad compatibility.

#### Scenario: Sheet with navigation
- **WHEN** a sheet is presented that contains navigation hierarchy
- **THEN** it uses `NavigationStack` (not deprecated `NavigationView`)
- **THEN** no double navigation chrome appears on Mac

### Requirement: Adaptive grid layouts
Color picker grids SHALL use adaptive column sizing (`GridItem(.adaptive(minimum:))`) instead of fixed column counts, to properly fill available width on Mac screens.

#### Scenario: Color picker on Mac
- **WHEN** a user opens a category or store color picker on Mac
- **THEN** the grid adapts to fill the available width with appropriately sized items

### Requirement: Sheet presentation detents adapt to Mac
Sheet presentations that use fixed `.medium` detent SHALL use a larger detent (`.large` or `.fraction(0.7)`) to better utilize Mac screen space.

#### Scenario: Sheet on Mac
- **WHEN** a sheet with `.medium` detent is presented on Mac
- **THEN** the sheet uses a larger presentation size appropriate for the Mac window
