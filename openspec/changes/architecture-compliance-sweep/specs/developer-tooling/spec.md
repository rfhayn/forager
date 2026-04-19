## MODIFIED Requirements

### Requirement: Architecture audit skill

The project SHALL provide an `/architecture-audit` skill that scans the codebase for violations of architectural rules defined in the `architecture` capability. The skill SHALL be invokable on demand and SHALL report violations with file:line references.

The skill's Check 3 (scope-aware fetch compliance, ADR 013) SHALL restrict its scan to `Services/` and `forager/Repositories/`. View-layer `@FetchRequest` is explicitly out of scope for Check 3 pending the future `decide-view-layer-scope-architecture` change; the skill file SHALL include a "Non-goal" note documenting this boundary so future contributors do not extend the check to views prematurely.

The skill's Check 4 (view-save violations, service-layer-pattern) SHALL scan `forager/Views/**/*.swift` for `context.save()`, `viewContext.save()`, and `.managedObjectContext.save()` calls, excluding files matching `*Preview*` via grep glob, and the skill prose SHALL instruct the reader to discount matches inside `#Preview { }` blocks and `PreviewProvider` extensions when the file itself is not named `*Preview*`.

#### Scenario: Developer runs architecture-audit

- **WHEN** a developer invokes `/architecture-audit` before creating a pull request
- **THEN** the skill scans the codebase and reports any architectural violations it detects (factory enforcement, scope-aware fetch in services/repositories, view-save ownership excluding previews)

#### Scenario: Audit reports zero violations on compliant code

- **WHEN** the skill is run against a clean codebase
- **THEN** the skill reports success with zero violations, including zero false positives from preview-block save calls

#### Scenario: Check 3 does not flag view @FetchRequest

- **WHEN** Check 3 (scope-aware fetch compliance) scans the codebase
- **THEN** it scans only `Services/` and `forager/Repositories/`; any unscoped `@FetchRequest` in `forager/Views/` is explicitly NOT reported by Check 3, and the skill file contains a "Non-goal" note making this boundary clear

#### Scenario: Check 4 excludes preview save calls

- **WHEN** Check 4 (view-save violations) scans `forager/Views/**/*.swift`
- **THEN** files matching `*Preview*` are excluded via grep glob, AND the skill prose instructs readers to discount matches inside `#Preview { }` blocks and `PreviewProvider` extensions in non-preview-named files; the check SHALL report zero violations on the post-fix tree

#### Scenario: Skill is extensible for new architectural rules

- **WHEN** a new architectural rule is added to the `architecture` capability spec
- **THEN** the `/architecture-audit` skill MAY be extended with a corresponding check without disrupting existing checks; extensions to Check 3 covering view-layer `@FetchRequest` specifically SHALL wait for the `decide-view-layer-scope-architecture` change to land and define the normative pattern
