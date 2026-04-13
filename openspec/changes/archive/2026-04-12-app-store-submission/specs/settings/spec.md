## MODIFIED Requirements

### Requirement: The system MUST hide developer/diagnostic tools in Release builds using #if DEBUG conditional compilation.
The system MUST hide developer tools AND diagnostic logging controls in Release builds using `#if DEBUG` conditional compilation. This includes the Diagnostics section (DiagnosticLogger log viewer, export, and clear actions) and the Developer Tools section. Additionally, DiagnosticLogger and DebugLogService SHALL be replaced with no-op stubs in Release builds so that all call sites compile but perform zero file I/O.

#### Scenario: Release build hides diagnostics
- **WHEN** the app is built in Release mode
- **THEN** the Settings view shows no Diagnostics section, no Developer Tools section, and no debug views

#### Scenario: Release build performs no diagnostic file I/O
- **WHEN** the app launches in a Release build
- **THEN** DiagnosticLogger does not create or write to `forager-diagnostics.log`, and DebugLogService methods are no-ops

#### Scenario: Debug build retains full logging
- **WHEN** the app is built in Debug mode
- **THEN** DiagnosticLogger writes to disk, DebugLogService captures in-memory logs, and Settings shows both Diagnostics and Developer Tools sections

#### Scenario: CloudKit OSLog is preserved in Release
- **WHEN** CloudKitLogger logs an event in a Release build
- **THEN** the OSLog call fires normally but the DiagnosticLogger bridge is a no-op
