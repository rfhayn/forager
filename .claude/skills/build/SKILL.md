---
name: build
description: "Build the project. ⚠️ CONFIGURE FIRST: Update the build command below for your project. TRIGGER when the user says \"build it\", \"build the app\", \"run a build\", \"compile\", \"does it build\", \"rebuild\", \"try building\", \"does it compile\", or any request to build or compile the project."
---

# Build Project

Build the project with the correct configuration.

## ⚠️ CONFIGURATION REQUIRED

This skill needs your project's build command. Update the command below:

```bash
# TODO: Replace with your build command. Examples:
#   npm run build
#   cargo build --release
#   xcodebuild -project MyApp.xcodeproj -scheme MyApp build
#   ./gradlew build
#   make build
echo "BUILD COMMAND NOT CONFIGURED — edit .claude/skills/build/SKILL.md"
```

## Pre-Build (if orchestration available)

```bash
clauductor event --worker-id [worker-name] --type "build_start" --detail "Build initiated"
```

## On Build Failure

If the build fails:
1. Read the full error output
2. Check if it's a compilation error, dependency error, or configuration error
3. For >5 consecutive build errors, stop and reassess approach (quality gate)

If orchestration available:
```bash
clauductor event --worker-id [worker-name] --type "build_failure" --detail "Build failed: [error summary]"
```

## On Build Success

Report:
- BUILD SUCCEEDED
- Number of warnings (if any)

If orchestration available:
```bash
clauductor event --worker-id [worker-name] --type "build_success" --detail "Build succeeded"
```
