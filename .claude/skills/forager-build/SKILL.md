---
name: build
description: Build forager with the correct Xcode configuration. Uses iPhone 17 Pro simulator. Filters output for errors and warnings.
---

# Build Forager

Build the project with the correct configuration.

## Build Command

```bash
xcodebuild -project forager.xcodeproj -scheme forager -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -E "BUILD|error:|warning:" | head -30
```

## Configuration

- **Simulator**: iPhone 17 Pro (not iPhone 16 Pro — it's unavailable)
- **Scheme**: forager
- **iOS target**: 26+
- **CloudKit**: DISABLED in DEBUG, ENABLED in Release

## On Build Failure

If the build fails:
1. Read the full error output (remove the grep filter)
2. Check if it's a compilation error, linker error, or signing error
3. For >5 consecutive build errors, stop and reassess approach (quality gate)

## On Build Success

Report:
- BUILD SUCCEEDED
- Number of warnings (if any)
- Build time

## Notes

- The `-quiet` flag suppresses output; avoid it when debugging
- Test plan is missing — `xcodebuild test` will fail (M6 will address this)
- `CURRENT_PROJECT_VERSION` is managed by the user — never modify build numbers
