---
name: forager-architecture-audit
description: Check codebase for architectural violations (factory bypass, raw assign, scope compliance, service layer). TRIGGER when the user discusses creating Core Data objects in production code, adding new entity creation sites, or before PR creation on milestones that touch the service/model layer.
user_invocable: true
---

# Architecture Audit

Run this audit before any milestone that creates Core Data objects, during code review, and as a quality gate.

## Checks

### 1. Factory Bypass Detection (ADR 014)
Search for direct creation of HouseholdScoped entities outside exempt files:

```bash
# Search for direct Entity(context:) for HouseholdScoped types
grep -rn 'WeeklyList(context:\|Recipe(context:\|PlannedMeal(context:\|MealPlan(context:\|Category(context:\|IngredientTemplate(context:' \
  --include='*.swift' \
  --exclude-dir=foragerTests \
  --exclude-dir=foragerUITests \
  --exclude='*Preview*' \
  --exclude='DefaultSeeder.swift' \
  --exclude='SampleDataSeeder.swift' \
  --exclude='ManagedObjectFactory.swift' \
  --exclude='HouseholdService.swift'
```

**Expected**: Zero matches in non-exempt production files.
**Exempt files**: Tests, previews, seeders, HouseholdService (migration), ManagedObjectFactory itself.
**Note**: Repository files may have fallback paths with direct creation — these are acceptable IF they also have factory-first branches.

### 2. Raw Assign Detection
Search for `viewContext.assign(` or `context.assign(` outside `ManagedObjectFactory.swift`:

```bash
grep -rn 'viewContext\.assign(\|context\.assign(' --include='*.swift' --exclude='ManagedObjectFactory.swift'
```

**Expected**: Zero matches.

### 3. ADR 013 Scope Compliance
Search for HouseholdScoped fetch requests missing `householdKey` predicate:

```bash
# Look for fetch requests on HouseholdScoped entities
grep -rn 'NSFetchRequest<WeeklyList>\|NSFetchRequest<Recipe>\|NSFetchRequest<MealPlan>\|NSFetchRequest<PlannedMeal>\|NSFetchRequest<Category>\|NSFetchRequest<IngredientTemplate>' \
  --include='*.swift' \
  --exclude-dir=foragerTests
```

Then verify each fetch includes a `householdKey` predicate.

### 4. Service Layer Compliance
Search for `context.save()` in view files (views should use services):

```bash
grep -rn 'context\.save()\|viewContext\.save()' forager/Views/ --include='*.swift'
```

**Expected**: Zero matches (all saves through service layer).

## How to Run

Use the Grep tool to execute each check. Report violations with file:line references.

## When to Run
- Before starting any milestone that creates Core Data objects
- During code review / PR creation
- After completing service or view layer changes
- As a quality gate before marking milestone complete
