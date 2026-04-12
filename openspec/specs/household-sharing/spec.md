# Spec: Household Sharing

## Overview

CloudKit-powered household collaboration enabling couples, roommates, and families to share all grocery lists, recipes, meal plans, and related data through a shared database zone. Uses NSPersistentCloudKitContainer with a dual-store architecture (private store for personal data, shared store for household data). The system supports household creation, member invitation via public share links, member management, and security hardening including invitation expiration and API key encryption.

## Requirements

- REQ-001: The system MUST support creating a household that migrates all existing user data from the private CloudKit zone to a new shared zone using an attach-then-share pattern.
  - Scenario: Given a user with 5 recipes and 3 lists in personal scope, When they create "Smith Family" household, Then all data migrates to the shared zone, the Household entity is created as aggregate root with relationships to all scoped entities, and the user becomes owner.

- REQ-002: The system MUST support inviting members via a public share link (CKShare with publicPermission .readWrite) sent through Messages or ShareSheet.
  - Scenario: Given the household owner taps "Invite Member", When a share URL is generated and sent via Messages, Then the recipient can tap the link to accept the invitation and join the household.

- REQ-003: The system MUST revert CKShare publicPermission to .none after a member accepts an invitation (owner-side only).
  - Scenario: Given a share URL was created with .readWrite permission, When the invited member accepts, Then the owner's device detects the new participant and reverts publicPermission to .none, preventing further URL usage.

- REQ-004: The system MUST expire pending invitations after 24 hours and auto-clean expired HouseholdMember records on app launch.
  - Scenario: Given an invitation was created 25 hours ago, When the app launches, Then the expired pending HouseholdMember record is deleted and the share URL no longer grants access.

- REQ-005: The system MUST enforce a 10-member cap per household (accepted + non-expired pending combined).
  - Scenario: Given a household with 9 accepted members and 1 pending invitation, When the owner tries to invite another member, Then a memberCapReached error is displayed.

- REQ-006: The system MUST allow the owner to cancel individual pending invitations (swipe-to-cancel) and revoke all pending invitations.
  - Scenario: Given 2 pending invitations, When the owner swipes left on one and taps Cancel, Then that pending HouseholdMember is deleted; if no pending members remain, publicPermission reverts to .none.

- REQ-007: The system MUST allow members to leave a household with an optional data export, migrating their local data back to personal scope.
  - Scenario: Given a member wants to leave, When they tap "Leave Household" and choose to export recipes, Then their local data migrates to the private zone and they lose access to the shared zone.

- REQ-008: The system MUST allow the owner to remove members from the household and to delete the household entirely with data migration back to the owner's private zone.
  - Scenario: Given the owner removes a member, When the removal processes, Then the member loses shared zone access and the owner's data remains in the shared zone.

- REQ-009: The system MUST operate in exactly one active scope at a time: .personal OR .household, never both (DataScope enum).
  - Scenario: Given a user joins a household, When the scope transitions to .household, Then all @FetchRequest queries use the household's householdKey and new entities are created in the shared store.

- REQ-010: The system MUST use the ManagedObjectFactory for all HouseholdScoped entity creation to ensure correct store assignment (ADR 014). The factory MUST be a non-optional dependency in all services and repositories that create HouseholdScoped entities. Fallback creation via `Entity(context:)` is FORBIDDEN in production code paths. If factory creation fails, the error MUST be propagated to the caller — never silently creating an unscoped entity.
  - Scenario: Given code needs to create a new Recipe in household scope, When it calls ManagedObjectFactory.make(Recipe.self, in: scope), Then the Recipe is assigned to the correct persistent store (private or shared) based on the active scope.
  - Scenario: Given a service or repository that creates HouseholdScoped entities is initialized, Then the factory parameter MUST be non-optional (`ManagedObjectFactory`, not `ManagedObjectFactory?`).
  - Scenario: Given `factory.make()` throws an error during entity creation, Then the error MUST be propagated to the caller and no entity SHALL be created via direct `Entity(context:)` fallback.
  - Scenario: Given a service instantiates a Household*Repository inline, Then the service MUST pass its own factory instance to the repository init.
  - Scenario: Given entity creation occurs in tests, SwiftUI previews, DefaultSeeder, or HouseholdService migration methods, Then direct `Entity(context:)` is acceptable as documented exceptions per ADR 014.

- REQ-011: The system MUST use a dual-store architecture with private store (forager.sqlite) for personal data and shared store (forager_shared.sqlite) for household data, with asymmetric owner/member behavior (ADR 008).
  - Scenario: Given an owner device, When household data syncs, Then the owner's shared zone data lives in the private store (owner's zone), while a member device receives shared zone data in the shared store.

- REQ-012: The system MUST deduplicate categories after CloudKit sync using a dedupe-after-creation pattern with automatic self-healing convergence within 60 seconds.
  - Scenario: Given two household members both create a "Produce" category simultaneously, When CloudKit syncs both, Then CategoryDeduplicator detects the duplicate and removes one, preserving all item assignments.

- REQ-013: The system MUST prevent duplicate invitations by checking for existing accepted members (alreadyMember error) and pending invitations (invitationPending error) before generating a share URL.
  - Scenario: Given a member has already accepted, When the owner tries to invite the same iCloud account, Then an alreadyMember error is displayed without creating a new share link.

## Implementation Notes

- Core entities: Household (aggregate root with relationships to all scoped entities), HouseholdMember (tracks members with role, joinedDate, invitedDate)
- Household has householdKey for fetch predicates and household relationship for zone routing -- both are necessary
- HouseholdScopeProvider.activeScope determines current scope
- Owner vs member store assignment is asymmetric -- never hardcode store assignment
- API key encryption (AES-GCM) is specified in M9.30 but implementation status is PLANNED
- Schema v10 added invitedDate/lastInviteDate on Household; v9 added household/householdKey to Ingredient + GroceryListItem
- HouseholdService handles all household lifecycle operations
- CloudKit sync latency target: changes visible across devices within 5 seconds (30 seconds validated in practice)
