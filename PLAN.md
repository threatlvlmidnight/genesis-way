# The Genesis Way — Product Roadmap (iOS Build Phase)

## Current Phase

The demo phase is complete.

- Design spec approved and shared with Dan.
- Web proof of concept exists and is useful as a reference implementation.
- We are now entering the starting phase for the actual iOS app.

## Dan Daily Flow Realignment Plan (Pre-Release 2)

Source of truth: [docs/Brain Dump with Dan](docs/Brain Dump%20with%20Dan)

Goal:

Replace spoke-first daily flow with Dan's operational loop:
`Pile -> Shape (5 filters) -> Fill (daily timeline)`

## Versioned Roadmap (Release Framing)

Versioning standard: Semantic Versioning (`MAJOR.MINOR.PATCH`).

### 0.1.0 (Current Build)

Status: current baseline build.

Scope:

1. Current daily-flow baseline is usable for internal testing and iteration.

### 0.1.2 (Next Release - Current Version Improvements)

Scope:

1. Ship the current Ready-lane quality improvements and polish work.
2. Keep this release focused on UX/readability/navigation refinements, not net-new platform features.

Exit criteria:

1. Ready-lane improvements are complete and validated on device.
2. No critical regressions in core daily flow.

### 0.2.0 (Feature Release 1 - Authentication and User Accounts)

Scope:

1. Add authentication and user account foundation.
2. Preserve existing daily-flow behavior while introducing account-aware state.

Exit criteria:

1. User can sign up/sign in/sign out reliably.
2. Account state persists correctly and safely.

### 0.3.0 (Feature Release 2 - Google Calendar Sync) — Demo Target: Friday March 27, 2026

> **Demo release.** Dan is presenting to a potential client on Friday March 27. This version must be in TestFlight / on-device before that demo. Auth (0.2.0) and Calendar sync (0.3.0) are combined into this milestone. Monetization (0.4.0) is explicitly excluded from this cut.

Scope:

1. Auth and user accounts fully integrated (Sprints 2–3 complete).
2. Google Calendar pull sync and Fill integration working on device (Sprints 4–5 complete).
3. Shape scheduling export handoff included.
4. Offline/failure UX at a demo-safe baseline.

Exit criteria:

1. Apple Sign In, guest mode, and account linking all work on device.
2. Fill shows pulled Google Calendar events reliably.
3. Shape export handoff to calendar works.
4. No Sev 1 blockers in daily flow, auth, or calendar pull path.

### 0.4.0 (Feature Release 3 - Monetization) — Post-Demo (after Friday March 27)

> Not required for the Friday client demo. Begin only after the 0.3.0 demo release is on device and stable.

Scope:

1. Add tiered monetization and entitlement gating.
2. Define free vs paid boundaries without breaking core utility.

Exit criteria:

1. Entitlements are enforced consistently.
2. Purchase/restore flows are functional and tested.

### 1.0.0 (General Availability) — Post-Demo

Scope:

1. Includes all 0.1.2 improvements.
2. Includes all three major features shipped in order:
- Authentication and user accounts (0.2.0/0.3.0 demo cut)
- Google Calendar push/pull sync (0.3.0 demo cut)
- Monetization and entitlement gating (0.4.0, post-demo)
3. Final release hardening for production readiness.

Exit criteria:

1. Core flows are stable and release-quality.
2. Auth + Calendar + Monetization operate together without critical blockers.
3. QA and regression sign-off completed for GA.

### 1.0 Release Feature Priorities (Locked Order)

Scope lock for v1 release candidate, in required implementation order:

1. Authentication and user accounts
2. Google Calendar push and pull sync
3. Monetization layer (tiered plans and entitlement gating)

Release criteria note:

1. These three features are completed and validated in sequence.
2. Any additional UX polish or expansion items are secondary to this RC scope lock.

### Legacy Phase Label: V1 Daily Path Stabilization

Scope:

1. Ship the current daily flow as the core product path:
- Dump/Pile capture
- Shape (5 filters)
- Fill (daily planner)
- Daily loop behaviors (carryover/reminders/delegate follow-up scaffolds)
2. Resolve open bugs and polish blockers in daily workflow before release.

Exit criteria:

1. Core daily path is reliable on-device end-to-end.
2. Known priority bugs are closed or explicitly deferred.
3. UX copy/navigation for the daily path is production-ready.

### Legacy Phase Label: V1.5 Monetization Layer

Scope:

1. Add tiered subscription model and entitlement gating.
2. Define free vs paid feature boundaries without breaking core daily utility.
3. Add billing/settings UX, restoration, and subscription status handling.

Exit criteria:

1. Subscription tiers are purchasable/restorable.
2. Entitlements are enforced consistently.
3. Monetization analytics and support hooks are in place.

### Legacy Phase Label: V2 Backend + Accounts + Extended Platform Features

Scope:

1. Backend infrastructure for authenticated logins and multi-device data portability.
2. Long-term planning modules beyond daily loop.
3. Social collaboration features (for example shared delegations and team handoff workflows).

Exit criteria:

1. Authenticated user accounts and sync are stable.
2. Long-term planning feature set is available behind backend services.
3. Social workflows are functional and privacy-safe.

## Phase A: Foundation and Migration

1. Introduce day-scoped task lifecycle model:
- Daily pile items
- Filter outcomes (scheduled, moved forward, eliminated, delegated, parked)
- Scheduled timeline assignments
- Completion and carryover flags
2. Migrate existing persisted data:
- Preserve dump text
- Archive spoke/rhythm fields for future long-term goals module
- Map current active items into today's pile
3. Reframe W/P codes:
- System-generated immutable IDs for indexing
- Remove user rating edit semantics from codes

Exit criteria:

1. Existing users load into new model without data loss
2. New users start in daily pile flow
3. W/P identifiers are generated only by system

## Phase B: New Shape Experience (No Spokes)

1. Replace spoke assignment UI with filter decision UI
2. Two sortable lists:
- Work (top-down priority)
- Personal (bottom-up priority)
3. Drag/drop between lists and reordering within list
4. Per-item filter action controls (5 directions)
5. Oversize task guidance:
- If task is larger than 15-30 min, create/suggest "jam session" refinement task

Exit criteria:

1. Every pile item can be given a filter outcome
2. Users can reorder and move items between Work and Personal lists
3. No spoke concepts appear in daily Shape flow

## Phase C: Fill as Daily Planner Timeline

1. Build daily planner timeline with appointment-first layout
2. Planning order guidance:
- Appointments first
- Work tasks next
- Personal tasks last
3. Drag task items/codes onto timeline slots
4. List and timeline stay in sync for completion state
5. Require all active items to be assigned a disposition before start-of-day execution

Exit criteria:

1. User can fully plan day before execution
2. Timeline and list reflect same state changes
3. Planner supports rescheduling by day

## Phase D: Daily Loop Automation

1. End-of-day rollover:
- Incomplete items auto-carry to next day's pile
- Mark carried items visually
2. Evening planning reminder:
- Custom time
- Prompt for 5-minute next-day planning
3. Delegate follow-up support scaffold:
- Delegate action can capture who/when and follow-up placeholder

Exit criteria:

1. Next day opens with carried pile and new additions
2. Evening reminder can be configured and triggered
3. Delegate actions have follow-up metadata path

## Phase E: Future Scope (Not in Daily Loop)

1. Re-introduce seven spokes only in long-term goal planning module
2. Keep daily planning independent from goal framework

## Implementation Notes

1. Keep broad-audience copy and Dan-language terms:
- Pile
- Shape
- Fill
- Thin vertical slices
2. Maintain iOS-first architecture with Android portability constraints
3. Validate each phase with device tests before advancing

## Product Direction

Primary product target:

1. Native iOS app (SwiftUI-first)
2. Architecture designed for Android port (Kotlin/Compose) with minimal business-logic rework
3. Google Calendar happy path for connected scheduling
4. Apple Calendar support to a practical level (ICS-first in early versions)
5. Preserve core Genesis system while broadening audience language

Secondary target:

1. Keep web app/design spec as reference and fallback demo surface

---

## North Star Outcomes

1. A reliable daily-use iOS app for Dump -> Shape -> Fill -> Execute -> Park
2. Calendar-assisted planning that reduces manual entry
3. Fast capture and low-friction workflow execution
4. Clean onboarding for broad audience (non-faith-specific copy in app UI)
5. Android-ready architecture so porting is implementation work, not product redesign

---

## Cross-Platform Portability Rules (iOS -> Android)

Non-negotiable implementation constraints from the start:

1. Keep domain logic platform-agnostic
- Use the same entities and state transitions on all platforms
- Avoid embedding business rules directly in SwiftUI views
2. Contract-first data layer
- Define stable JSON schemas for tasks, workflow state, sync metadata, and calendar mappings
- Keep API surface independent of iOS-specific types
3. Design token parity
- Maintain a token table for color, spacing, typography scale, radius, elevation
- Reference tokens in components instead of hardcoding per-screen style values
4. Feature parity checklist
- Every new iOS feature requires an "Android parity note" in planning/PR comments
5. Integration abstraction
- Wrap calendar providers behind a provider interface so Google/ICS mapping logic can be reused
6. Local-first with sync abstraction
- Persistence and sync should be decoupled so Android can mirror behavior with equivalent storage

---

## Milestone Map

## Milestone 0.2.0: Authentication and Accounts

Goal: deliver stable account foundation without regressing daily-flow UX.

1. Authentication and user accounts

Exit criteria:

1. User can create/sign in/out of an account and access persisted account state.

## Milestone 0.3.0: Google Calendar Push/Pull Sync

Goal: deliver practical Google Calendar integration for the primary user path.

1. Google Calendar push/pull sync

Exit criteria:

1. Calendar sync supports both import (pull) and export/update (push) for Google Calendar on happy path.

## Milestone 0.4.0: Monetization and Entitlements

Goal: deliver revenue layer with reliable entitlement behavior.

1. Monetization tiering and entitlement enforcement

Exit criteria:

1. Monetization gates are enforced by entitlement and recover correctly after restore/sign-in changes.

## Milestone 1.0.0: General Availability

Goal: consolidate 0.1.2 + 0.2.0 + 0.3.0 + 0.4.0 into GA release quality.

1. Final stabilization and regression hardening
2. GA release checklist and sign-off

Exit criteria:

1. No critical release blockers across core workflow and major features.
2. End-to-end QA pass completed for GA.

## Legacy Detailed Milestones (Reference)

## Legacy Milestone 0 (Completed): Demo Validation

Status: complete

1. Visual design spec produced: [docs/design-spec.html](docs/design-spec.html)
2. Spec published for sharing/review
3. Roadmap reset decision made after successful demo

## Legacy Milestone 1: iOS Foundation (Start Here)

Goal: Establish native app scaffold and durable local data model.

1. Create Xcode project structure (SwiftUI + MVVM)
2. Define domain models:
- Task
- Big3Item
- DumpItem
- Spoke
- RhythmAnchor
- FillAction
- ExecutionAssignment
- ParkItem
3. Extract business rules/services into testable modules (no view-coupled logic)
4. Persistence layer:
- Start with local storage (SwiftData/Core Data or file-backed model)
5. Navigation shell:
- Native tab structure for Dump / Shape / Fill / Park
- Entry flow for onboarding and week progression
6. Theme system port:
- Recreate Glass Jakarta tokens for iOS components
7. Portability docs baseline:
- Add "Android port notes" section for each major module

Exit criteria:

1. App installs and runs on iPhone simulator/device
2. Data persists across app restarts
3. Core tabs and routing are in place
4. Business logic is callable outside UI layer
5. Android port notes exist for foundation modules

## Legacy Milestone 2: Core Genesis Workflow (MVP)

Goal: End-to-end usable Genesis loop without external integrations.

1. Onboarding + Week 1 perspective flow
2. Dump capture + reflection
3. Shape with seven spokes
4. Rhythm/boundaries step
5. Fill actions and daily Big 3
6. Execute/finish line view
7. Park and rehydrate items into active workflow

Exit criteria:

1. User can complete full loop from onboarding to execute
2. No blockers/crashes in core paths
3. Local-only planning is fully functional

## Legacy Milestone 3: Calendar Integrations (Google-First)

Goal: Add practical event-to-task flow with Google as happy path.

1. Google Calendar direct integration (priority)
- OAuth sign-in
- Select calendars
- Event import into app tasks
- Incremental sync with manual refresh in v1
2. Apple Calendar support (practical v1)
- ICS import/sync workflow
- Read-only ingest path
3. Mapping controls
- Map imported events to Work vs Personal lanes
- Respect W/P code sequencing
- De-duplication rules
4. Provider abstraction for portability
- Keep provider interface generic so Android can implement same contract

Exit criteria:

1. Google user can connect and import/sync events
2. Apple user can import ICS and map events reliably
3. Imported items appear correctly in Fill workflow
4. Provider contracts are documented and Android-implementable

## Legacy Milestone 4: Account + Sync Infrastructure

Goal: Make data portable and resilient beyond one device.

1. Choose backend stack for user accounts + sync
2. Auth + secure token storage
3. Cloud sync for tasks/settings/calendar mappings
4. Conflict handling and sync status UX

Exit criteria:

1. User data survives reinstall/device changes
2. Calendar connection state persists securely
3. Sync errors are visible and recoverable

## Legacy Milestone 5: Beta Readiness

Goal: Ship a testable beta to a small user cohort.

1. Performance pass
2. Crash/error instrumentation
3. Accessibility pass (Dynamic Type, VoiceOver basics, contrast)
4. QA checklist for critical flows
5. TestFlight distribution setup
6. Android pre-port package
- Architecture and API contracts reviewed
- UI token parity checklist finalized
- Initial Kotlin/Compose mapping notes completed

Exit criteria:

1. Internal/external TestFlight build available
2. Critical path bug count near zero
3. Feedback loop in place

---

## Immediate Priority Queue (Next 2-3 Weeks)

1. Lock iOS architecture and persistence choice
2. Scaffold native navigation + tab shell
3. Port Dump and Fill screens first (highest daily-use value)
4. Implement task model and coding system (W/P, A/B/C if needed)
5. Add placeholder Calendar Settings screen with provider options:
- Google (coming next)
- Apple ICS import

---

## Calendar Strategy (Explicit)

Google (happy path):

1. Direct integration and ongoing sync target
2. v1 can use manual refresh button
3. v2 can add background refresh/push improvements

Apple:

1. v1 supports ICS import/sync workflow
2. Treat as practical compatibility path for web-linked calendars
3. Re-evaluate deeper Apple-native options later

---

## Assets To Keep Using

1. Product design spec: [docs/design-spec.html](docs/design-spec.html)
2. PDF synthesis reference: [docs/pdf-worksheet-system-reference.md](docs/pdf-worksheet-system-reference.md)
3. Existing web code for behavior reference only

---

## Decisions Log

1. Demo phase complete and accepted as proof point.
2. Roadmap is now iOS-first.
3. Google Calendar gets priority as primary integration path.
4. Apple Calendar supported via practical ICS approach in early phase.
5. Language should remain broad-audience and non-verse-specific in app UI.
6. All iOS implementation decisions must preserve Android portability.
