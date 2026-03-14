# The Genesis Way — Product Roadmap (iOS Build Phase)

## Current Phase

The demo phase is complete.

- Design spec approved and shared with Dan.
- Web proof of concept exists and is useful as a reference implementation.
- We are now entering the starting phase for the actual iOS app.

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

## Milestone 0 (Completed): Demo Validation

Status: complete

1. Visual design spec produced: [docs/design-spec.html](docs/design-spec.html)
2. Spec published for sharing/review
3. Roadmap reset decision made after successful demo

## Milestone 1: iOS Foundation (Start Here)

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

## Milestone 2: Core Genesis Workflow (MVP)

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

## Milestone 3: Calendar Integrations (Google-First)

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

## Milestone 4: Account + Sync Infrastructure

Goal: Make data portable and resilient beyond one device.

1. Choose backend stack for user accounts + sync
2. Auth + secure token storage
3. Cloud sync for tasks/settings/calendar mappings
4. Conflict handling and sync status UX

Exit criteria:

1. User data survives reinstall/device changes
2. Calendar connection state persists securely
3. Sync errors are visible and recoverable

## Milestone 5: Beta Readiness

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
