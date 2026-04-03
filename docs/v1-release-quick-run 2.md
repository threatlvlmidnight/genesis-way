# Genesis Way v1 Release Quick Run (35 Minutes)

Use this as the fast pre-RC/pre-submit pass. For full coverage, run docs/v1-regression-test-plan.md.

## Run Metadata
- Build/commit:
- Tester:
- Device:
- Date/time:

## 1. Build + Launch Smoke (5 min)
1. Build app for simulator.
2. Launch app on simulator/device.
3. Verify no crash on startup.

Pass if:
- Build succeeds.
- App launches to usable UI.

## 2. Core Flow Smoke (10 min)
1. Dump: add 2 items, delete 1, verify persistence after relaunch.
2. Shape: lane one item, run Move and Automate on another.
3. Fill: place one task on timeline and one in All Day.
4. Park: park one item and verify it appears.

Pass if:
- No broken navigation.
- No crashes in core path.

## 3. Shape Critical UX Checks (5 min)
1. Verify task card spacing looks consistent (first card included).
2. Verify Move button opens segmented control with Move | Schedule.
3. Verify Automate segmented control is Loop | Custom with Loop default.

Pass if:
- UI matches expected behavior.

## 4. Reminder + Daily Flow Checks (5 min)
1. Onboarding/settings reminder setup can be saved.
2. Configure evening reminder near-future time.
3. On real device, tap evening reminder and verify it routes to Fill.

Pass if:
- Reminder config persists.
- Evening reminder deep-link works.

## 5. Loop + Persistence Checks (5 min)
1. Create loop rule from Shape Automate > Loop.
2. Reopen app and verify loop rule persists in settings.
3. Verify item automation actions do not unexpectedly remove pending item.

Pass if:
- Loop behavior and persistence are stable.

## 6. Calendar Integration Checks (5 min)
1. Connect Google Calendar in Settings and run Sync Now.
2. Open Fill and verify pulled events render as read-only reference blocks.
3. Force a sync failure (offline/token issue) and verify Fill shows inline non-blocking retry banner.
4. In Shape > Schedule, use Export to Calendar and verify Apple event composer opens prefilled.

Pass if:
- Fill remains usable during calendar failures and cached events still show when available.
- Shape export handoff opens composer and local scheduled data remains intact on cancel.

## Quick GO/NO-GO
- GO if all sections pass and no Sev 1/Sev 2 findings.
- NO-GO if any crash, data-loss, or core flow blocker appears.

## Report Template
- Result: GO / NO-GO
- Sev 1:
- Sev 2:
- Sev 3:
- Notes:
