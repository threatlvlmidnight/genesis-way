# GW-E06 Testing Plan (Dan Feedback Round 2026-04-02)

## Purpose
Define the expected testing list before implementation for all GW-E06 changes so build work and QA are aligned from day one.

## Scope
- Onboarding copy and structure updates (GW-P01a through GW-P01e)
- Runtime copy updates in Dump, Shape, Fill, and Parking Lot (GW-P02, GW-P03a, GW-P03b, GW-P03c, GW-P04a, GW-P04b, GW-P05a)
- Reliability fixes (GW-P04c, GW-P04d, GW-P05b)
- End-to-end validation (GW-QA01)

Out of scope:
- Auth and monetization features
- New UI redesign beyond specified copy/label/flow corrections

## Risk Priorities
- P0: Shape to Fill handoff regression (core flow blocker)
- P0: Calendar sync failure (core Fill utility blocker)
- P0: Parking Lot carryover loss across days (data continuity blocker)
- P1: Copy and label consistency across onboarding and runtime screens

## Test Environment
Run on both:
1. Simulator pass (fast verification)
2. Real device pass (calendar auth/session behavior, notification interactions, lifecycle)

Record for each run:
- Build/commit
- Tester
- Device and iOS version
- Install type (clean install or upgrade)

## Traceability Matrix (Ticket -> Tests)

### GW-P01a Onboarding / Dump It copy update
1. Open onboarding step 1 and verify "finish it" appears where prior "sustain it" text existed.
2. Verify In Practice includes Work, Home, Hobby, School prompt.
Pass:
- Updated text appears exactly once and no legacy wording remains.

### GW-P01b Onboarding / Shape It copy update
1. Open Shape onboarding card.
2. Verify filter sequence is Eliminate, Automate, Delegate, Schedule, Park.
3. Verify In Practice bullets appear in the requested order.
Pass:
- Sequence and bullet order match ticket wording.

### GW-P01c Onboarding / Fill It copy update
1. Open Fill onboarding card.
2. Verify wording emphasizes syncing calendar and assigning tasks to a time/place.
3. Verify "Choose your daily big 3" is removed from step 3.
4. Verify In Practice bullets include synced calendar, margin protection, and calendar placeholder assignment.
Pass:
- Removed phrase is absent and replacement bullets are present.

### GW-P01d Onboarding / Finish It copy update
1. Open step 4 and verify title is "Finish It" (not "Sustain It").
2. Verify tagline text appears: Close your day, move what matters, and reset for tomorrow.
3. Verify In Practice includes finalized sentence: Finish your task list or consciously move each item forward. Run each incomplete item through the filters.
Pass:
- All finalized copy appears exactly as approved.

### GW-P01e Onboarding / Genesis Pattern normalization
1. On each onboarding step, verify Genesis Pattern shows:
   Dump it - Shape it - Fill it - Finish it - Rest
2. Verify arrows/visual connectors remain present.
Pass:
- Pattern is consistent across all onboarding screens.

### GW-P02 Dump screen guidance copy update
1. Open Dump guidance/help text.
2. Verify description reads: Get everything out of your head. List tasks at Work, Home, Hobby, School. Don't filter. Don't worry about the order.
Pass:
- Full sentence matches expected wording and punctuation.

### GW-P03a Shape terminology update
1. Open Shape screen and guidance section.
2. Verify title/labels use SHAPE it and How Shape It Works.
3. Verify supporting copy references Work/Personal tagging plus filters.
Pass:
- Section labels and supporting text align with spec.

### GW-P03b Shape process microcopy update
1. In Dump to Process area, verify text says:
   all pending items are ready, click Fill below
Pass:
- Legacy phrase is fully replaced.

### GW-P03c Shape filter button relabel
1. Open actionable item controls in Shape.
2. Verify filter buttons are:
   Eliminate | Automate | Delegate | Schedule | Park
3. Verify no legacy label remains.
Pass:
- All five labels match exactly and are tappable.

### GW-P04a Fill top description update
1. Open Fill screen.
2. Verify top description reads:
   Sync your calendar, then assign each task to a time (drag and drop).
3. Confirm wording uses synced/sync consistently (no sinked typo anywhere).
Pass:
- Description is present and terminology is normalized.

### GW-P04b Fill "How fill works" section update
1. Open How fill works section.
2. Verify content includes:
   - When will I do this?
   - Move work and personal tasks to timeline or another day
   - Finish your day on paper before your day begins
   - Schedule reminders so your plan stays on track
Pass:
- All four ideas are represented in order and readable.

### GW-P04c BUG Shape to Fill handoff regression
1. In Dump, create at least 5 tasks.
2. In Shape, tag and filter tasks (mix Work/Personal plus Schedule/Park/Delegate/Automate as applicable).
3. Navigate to Fill.
4. Verify expected shaped items appear in Fill task pool or scheduled area based on their outcomes.
5. Kill and relaunch app, return to Fill, verify items still appear correctly.
Pass:
- No missing shaped items for current day.
- State persists through relaunch.
Fail examples:
- Item exists in Shape but not in Fill.
- Item appears only after manual refresh/reopen.

### GW-P04d BUG Calendar sync failure
1. Ensure calendar connection exists.
2. Trigger sync via Fill entry and Sync Now control.
3. Verify events are pulled and rendered.
4. Force failure (offline mode or invalid token path).
5. Verify visible non-blocking failure feedback and retry action.
6. Restore connectivity and retry.
Pass:
- Successful sync renders events.
- Failure state is visible, non-blocking, and recoverable.
- Retry leads to successful render when backend is healthy.

### GW-P05a Park rename to Parking Lot
1. Open Park tab and related headings.
2. Verify title is Parking Lot.
3. Verify subtitle reads: Someday/Maybe List. Not now. Not never. Just not today.
4. Verify any direct add entry point still works.
Pass:
- Rename is complete and behavior unchanged.

### GW-P05b BUG Parking Lot carryover persistence
1. Park multiple items on day D.
2. Advance to day D+1 and D+2.
3. Verify parked items persist and remain accessible.
4. Relaunch app and repeat checks.
Pass:
- Parked items carry over across consecutive days and app restarts.
Fail examples:
- Park list resets daily.
- Items disappear after relaunch or date navigation.

### GW-QA01 Full regression for this epic
Execute this sequence after all GW-E06 tickets are merged:
1. Onboarding flow text verification (all 4 steps + Genesis Pattern)
2. Dump capture and guidance text check
3. Shape labels/buttons/microcopy check
4. Fill copy plus Shape-to-Fill handoff check
5. Calendar sync success/failure/retry check
6. Parking Lot rename plus multi-day carryover check
7. App relaunch persistence check
Pass:
- No Sev 1 or Sev 2 defects in the GW-E06 scope.

## Non-Functional Checks
1. No truncated or overlapping text on small and large iPhone sizes.
2. No obvious accessibility regressions in contrast/readability for updated copy blocks.
3. Screen transitions remain stable when quickly switching tabs.

## Defect Severity for This Epic
- Sev 1: Crash, data loss, or blocked core flow
- Sev 2: Core feature broken with workaround (for example manual resync needed every time)
- Sev 3: Copy mismatch, minor UI issue, or low-impact polish

## Exit Criteria (GW-E06)
1. All ticket-specific tests above pass on simulator and real device.
2. No open Sev 1 defects.
3. No open Sev 2 defects in Dump, Shape, Fill, Calendar sync, or Parking Lot persistence.
4. Approved copy appears consistently in onboarding and runtime screens.

## Recommended Execution Order
1. Run P0 bug tests first (GW-P04c, GW-P04d, GW-P05b).
2. Run copy/label validation tests.
3. Run GW-QA01 full flow regression.