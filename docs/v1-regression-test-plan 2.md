# Genesis Way v1 Regression Test Plan

## Purpose
This plan is the full manual regression checklist for pre-release-v1 before cutting the final release candidate (RC).

Fast path companion:
- docs/v1-release-quick-run.md (30-minute quick pass)
- scripts/ios_smoke.sh (automated build+launch smoke)
- .github/workflows/ios-smoke.yml (PR smoke automation)

## Scope
- iOS app core flow: Onboarding -> Dump -> Shape -> Fill -> Park
- Daily flow behavior and reminders
- Loop automation behavior
- Data persistence, restart safety, and migration sanity
- Settings and calendar-related controls

Out of scope for v1 RC:
- Android
- Social/authenticated v2 concepts

## Test Pass Metadata
Record this before every run:
- Build/commit:
- Date/time:
- Tester:
- Device(s):
- iOS version(s):
- App install type: clean install / upgrade install

## Environment Matrix
Run at least these two passes:
1. Simulator pass (fast functional)
2. Real device pass (notifications, keyboard, haptics, app lifecycle)

Recommended device coverage:
- One modern iPhone size (ex: iPhone 16)
- One smaller viewport if available

## Defect Severity
- Sev 1: crash, data loss, or blocked core flow
- Sev 2: major feature broken but workaround exists
- Sev 3: minor UI/UX issue, copy issue, polish

## Release Exit Criteria (RC Gate)
All must be true:
1. No open Sev 1 defects
2. No open Sev 2 defects in core flow
3. Full checklist executed on simulator and real device
4. Reminder flow validated on real device
5. Data persistence/restart scenarios pass

---

## A. Install, Launch, and Navigation
### A1. Fresh install baseline
Steps:
1. Install and launch app from clean state.
2. Verify onboarding appears.
3. Verify app does not crash during first render.
Expected:
- Onboarding loads successfully.
- No layout corruption or blocking overlays.

### A2. Tab navigation integrity
Steps:
1. Move through Dump, Shape, Fill, Park tabs repeatedly.
2. Open and close Settings from each relevant screen.
Expected:
- Navigation is stable.
- No stuck screens, no tab mismatch, no crashes.

### A3. Relaunch continuity
Steps:
1. Close app from app switcher.
2. Reopen app.
Expected:
- Last saved state and user data persist.
- App opens without regressions.

---

## B. Onboarding and First-Time Setup
### B1. Onboarding progression
Steps:
1. Walk through onboarding content.
2. Validate animations and text readability.
3. Use Begin Journey and Skip paths.
Expected:
- Controls work, no dead ends.
- Correct next destination for each path.

### B2. Daily reminder setup in onboarding
Steps:
1. In onboarding, configure morning/evening reminder settings.
2. Save reminder setup.
3. Verify begin action gate behavior.
Expected:
- Reminder setup can be saved.
- Begin behavior matches current v1 intended gating.

---

## C. Dump Screen
### C1. Text capture
Steps:
1. Add multiple items via keyboard.
2. Verify Enter/submit behavior and focus behavior.
3. Delete one item.
Expected:
- Items add in selected day context.
- Delete works and list updates immediately.

### C2. Voice capture
Steps:
1. Start voice capture.
2. Speak multiple tasks with separators.
3. Stop recording and verify parsing.
Expected:
- Transcript captured.
- Parsed items appear in list.
- Error messaging is clear when parsing fails.

### C3. Cross-day view and edit rules
Steps:
1. Change Dump day to a past day.
2. Attempt add/edit/delete.
3. Change to today/future day and repeat.
Expected:
- Past day is read-only.
- Today/future day allows normal editing.
- Day picker and Today button work.

### C4. Persistence of day-scoped items
Steps:
1. Add items to today and a future day.
2. Kill app and reopen.
3. Revisit each day.
Expected:
- Items remain on correct days after restart.

---

## D. Shape Screen
### D1. Task list presentation and spacing
Steps:
1. Open Shape with at least 3 pending items.
2. Verify first card spacing vs subsequent cards.
Expected:
- Card margins are visually consistent.

### D2. Lane selection readiness
Steps:
1. For a pending item, assign Work and Personal.
2. Verify readiness indicators update.
Expected:
- Lane assignment updates immediately.
- Readiness messaging reflects actual state.

### D3. Filter actions
Steps:
1. Run Eliminate, Delegate, Park on different items.
2. Verify expected movement/outcome each time.
Expected:
- Each filter applies correct outcome without visual glitches.

### D4. Move/Schedule unified flow
Steps:
1. Tap Move button on an item.
2. In sheet, verify segmented control order is Move | Schedule.
3. Verify Move is selected by default.
4. Switch to Schedule and save appointment.
Expected:
- Segmented control order and default are correct.
- Move and Schedule each persist expected behavior.

### D5. Automate flow (Custom + Loop)
Steps:
1. Tap Automate on item.
2. Verify segmented control order is Loop | Custom.
3. Verify Loop is selected by default.
4. Save a custom note.
5. Save a loop rule.
Expected:
- Toggle order/default are correct.
- Item remains pending after automation actions.
- Custom note and loop save correctly.

### D6. Automate weekday chips and fixed count UX
Steps:
1. In Loop recurrence weekdays, inspect chip labels.
2. In fixed count mode, test +/- controls and direct keyboard entry (when implemented).
Expected:
- Weekday chips do not wrap incorrectly (Mon/Tue single line).
- Fixed count behavior matches shipped implementation.

---

## E. Fill Screen
### E1. Daily planner timeline integrity
Steps:
1. Verify All Day and hour slots render correctly.
2. Validate configured planner hour range reflects settings.
Expected:
- Timeline is complete and accurate.

### E2. Drag-and-drop planning
Steps:
1. Drag task pool items into All Day and timed slots.
2. Move placed tasks between slots.
Expected:
- Drag/drop works reliably.
- Task placement state updates correctly.

### E3. Big 3 and start-day guardrails
Steps:
1. Assign Big 3 from pool.
2. Attempt Start Day with unresolved planning states.
Expected:
- Guardrails enforce required conditions.
- Clear messaging for blocked actions.

### E4. Appointment visibility
Steps:
1. Create scheduled items from Shape.
2. Confirm they appear in Fill on correct day/time.
Expected:
- Appointments render correctly and consistently.

---

## F. Park and Delegate
### F1. Parked items behavior
Steps:
1. Park items from Shape.
2. Verify visibility and persistence in Park.
Expected:
- Park list matches actions and persists across restart.

### F2. Delegate follow-up lifecycle
Steps:
1. Delegate an item.
2. Add assignee and follow-up date.
3. Complete with and without reminder.
Expected:
- Delegate records remain consistent.
- Completion/reminder status updates correctly.

---

## G. Settings and Configurations
### G1. Theme and icon settings
Steps:
1. Cycle through theme options.
2. Change app icon variant.
Expected:
- Theme applies immediately.
- Icon switching works where supported.

### G2. Reminder settings
Steps:
1. Toggle reminder master and lead time settings.
2. Configure morning and evening reminder times.
Expected:
- Settings persist and re-open correctly.
- Invalid/empty states are handled safely.

### G3. Loop rules management
Steps:
1. Review existing loop rules.
2. Delete one rule.
Expected:
- Rule list updates and persists correctly.

---

## H. Reminder Behavior (Real Device Priority)
### H1. Morning reminder scheduling
Steps:
1. Enable morning reminder and set near-future test time.
2. Background app and wait for notification.
Expected:
- Reminder fires at expected time.

### H2. Evening reminder deep link
Steps:
1. Enable evening reminder and set near-future test time.
2. Tap delivered notification.
Expected:
- App opens/navigates to Fill as specified.

### H3. Reminder disabled state
Steps:
1. Disable reminders.
2. Verify pending requests are cleared/updated per expected behavior.
Expected:
- No stale reminder behavior remains.

---

## I. Data Integrity and Migration Safety
### I1. App restart and data durability
Steps:
1. Build a mixed dataset: dump items, loops, scheduled tasks, delegate follow-ups.
2. Force close and relaunch.
Expected:
- No data loss.
- Relationships remain intact.

### I2. Legacy payload compatibility sanity
Steps:
1. Validate app startup with older saved state if available.
2. Open diagnostics if present.
Expected:
- No crash on decode/migration.
- Default/optional fields are safely normalized.

### I3. Auth migration retry and relink safety
Steps:
1. In Settings diagnostics, run migration self-check.
2. Trigger a migration retry from account settings.
3. Verify migration event history updates with retry/probe events.
4. Copy diagnostics report and verify it includes migration status, retry count, and relink counters.
Expected:
- Migration checks are idempotent and do not corrupt local auth state.
- Retry path does not regress account status or session persistence.
- Diagnostics output contains enough detail for triage.

---

## J. UI Polish and Accessibility Sanity
### J1. Text clipping/wrapping
Steps:
1. Scan all major screens for clipped text or bad wraps.
2. Verify Shape chips/buttons/toggles remain legible.
Expected:
- No critical clipping in core workflow.

### J2. Keyboard interaction
Steps:
1. Trigger keyboard in Dump/Delegate/other input screens.
2. Verify Done button placement and dismissal behavior.
Expected:
- Keyboard controls are usable and non-overlapping.

---

## L. Auth and Account Foundation (Sprint 3)
### L1. Apple Sign In with backend exchange
Steps:
1. Sign in with Apple from Settings account area.
2. Confirm account state moves to signed in and backend shows Supabase.
3. Kill app and relaunch.
Expected:
- Sign-in succeeds and persists after restart.
- Backend status remains visible and accurate.

### L2. Sign out invalidation
Steps:
1. While signed in, trigger Sign Out in Settings.
2. Relaunch app.
Expected:
- Local session is cleared.
- Backend sign-out path completes without leaving stale signed-in state.

---

## M. Calendar OAuth and Schema Groundwork (Sprint 3)
### M1. Google OAuth Authorization Code + PKCE callback
Steps:
1. Start calendar connect flow.
2. Complete provider auth and return through callback route.
Expected:
- Callback route handles code exchange path without implicit-token dependency.
- Auth failure path returns actionable errors.

### M2. Supabase calendar schema readiness
Steps:
1. Apply docs/supabase-calendar-schema.sql in a staging project.
2. Validate table creation, constraints, and RLS policies.
Expected:
- user_calendar_connections and synced_calendar_events tables create successfully.
- RLS blocks cross-user reads/writes.

---

## N. Calendar Pull Integration (Sprint 4)
### N1. Fill pull on open and read-only render
Steps:
1. Connect Google Calendar and select at least one calendar source.
2. Open Fill for today and wait for sync to complete.
3. Confirm external events appear as read-only blocks in matching timeline slots (including All Day when applicable).
Expected:
- Fill renders pulled external events without converting them into editable Genesis tasks.
- Existing local tasks remain draggable/editable and are visually distinct from external blocks.

### N2. Fill sync throttle and last-synced metadata
Steps:
1. Open Fill and confirm a pull occurs.
2. Re-open Fill within 15 minutes and verify no duplicate forced pull is triggered.
3. Verify Last synced text is present after successful pull.
Expected:
- Pull is throttled to the configured window unless manual retry/sync is used.
- Last synced indicator updates after successful pulls.

### N3. Fill degraded sync UX
Steps:
1. Force sync failure (offline or invalid token path).
2. Open Fill and verify non-blocking error banner appears with Retry and Dismiss actions.
3. If cached events exist, verify they still render while failure banner is shown.
4. Trigger a 401/unauthorized response and verify reconnect guidance appears.
Expected:
- Planner remains usable when calendar sync fails.
- Error UI is inline, non-blocking, and supports retry/dismiss.
- Cached events continue to display when available.

---

## O. Calendar Export Handoff (Sprint 5)
### O1. Shape export to Apple Calendar composer
Steps:
1. In Shape, schedule an item via the Schedule sheet.
2. Tap Export to Calendar.
3. Verify Apple Calendar event composer opens with prefilled title/date/time.
Expected:
- Item is scheduled in Genesis even if export composer is canceled.
- Prefilled event data appears in the composer.

### O2. Shape open-calendar fallback and permission handling
Steps:
1. In Shape schedule flow, tap Open Calendar.
2. Verify Calendar app opens to a valid date context.
3. Deny calendar permission for export path and retry Export to Calendar.
Expected:
- Open Calendar path is non-blocking and does not drop scheduled data.
- Permission failure surfaces user-facing guidance while keeping local scheduled state intact.

---

## K. Performance and Stability Smoke
### K1. Rapid interaction stress
Steps:
1. Rapidly add/remove items.
2. Rapid tab switching and repeated sheet open/close.
Expected:
- No crashes, hangs, or severe jank.

### K2. Long-session sanity
Steps:
1. Use app continuously for 10-15 minutes across all tabs.
Expected:
- Stable memory/interaction behavior.

---

## Final Sign-Off Template
- Build/commit tested:
- Simulator pass: PASS / FAIL
- Real device pass: PASS / FAIL
- Open Sev 1:
- Open Sev 2:
- Open Sev 3:
- RC recommendation: GO / NO-GO
- Notes:
