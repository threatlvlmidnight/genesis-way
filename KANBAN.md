# Genesis Way Board
> Synced: 2026-03-16T12:00:00.000Z | Branch: pre-release-v1
 | Dirty: yes

## Roadmap Sprint Plan

Planning assumptions:

- Sprints are session-paced, not time-boxed — multiple sprints can be completed in a single working session
- One roadmap epic plus one stabilization/polish lane per sprint
- Do not start Calendar implementation that depends on user identity until Auth A1-A7 is complete
- Do not start Monetization implementation until Auth and Calendar are both stable on device

**Demo Release Target: Friday March 27, 2026**
Dan is demoing the app for a potential client on Friday. A build including auth and calendar sync (0.3.0) must ship before then. Monetization (0.4.0) is explicitly deferred past Friday — do not pull monetization work into pre-demo sprints.
- Sprints 1–5 are pre-demo priority. Complete these in order before Friday.
- Sprint 1 scope note: if session time is limited before Friday, the demo-critical path is to complete Sprint 1 RC blockers first, then move directly to Sprints 2–5. Polish/UI items in Sprint 1 not needed for demo stability can be deferred post-demo.
- Sprints 6–8 are post-demo and should not be started until after Friday.

### Sprint 1 - 0.1.2 hardening and RC readiness [DEMO-CRITICAL — complete before Friday March 27]

Goal: finish the daily-flow stabilization work and clear the minimum release blockers needed to start the auth and calendar epics. **Post-demo polish and new features have been pulled out and moved to Backlog to keep this sprint as short as possible.**

Pull first:

- Device test pass while app is running on phone
- Feature: As a user, I need a daily-flow experience (morning plan + end-of-day prep), including configurable reminders and links to viewing other days' flow. Scope for v1: time-based reminders only (no in-app special prompt), no default times (set during onboarding), evening reminder opens Fill for that day, cross-day support is Dump-only for now, allow editing future days, keep past days read-only. (Phase 1 started: Dump cross-day date navigation + past read-only, reminder configuration scaffold, evening reminder tap route to Fill)
- Release: pre-release-v1 full regression run and RC sign-off (execute docs/v1-regression-test-plan.md + docs/v1-release-quick-run.md; automation: scripts/ios_smoke.sh and .github/workflows/ios-smoke.yml)
- UI: Fill screen currently shows two settings icons; consolidate to one clear settings entry point
- UI: Remove duplicate settings icon on Shape screen — single gear entry point already exists via top overlay; remove any redundant in-screen instance
- UI: Remove the Clear action from Shape screen
- Polish: updated app icon refresh - added 6 selectable icon variants (Chrome default, Textile, Stone, Molten, Obsidian Glass, Monochrome)

Exit criteria:

- Core daily flow is stable on device
- RC regression completes without Sev 1 / Sev 2 blockers
- No embarrassing duplicate UI controls visible during demo
- Ready to start Sprint 2 (Auth) immediately after

### Sprint 2 - 0.2.0 auth foundation vertical slice

Goal: establish account identity and secure session handling without breaking the guest-first local flow.

Pull first:

- Auth A1: Add AuthClient abstraction and Supabase implementation scaffold.
- Auth A2: Add secure session storage in Keychain.
- Auth A3: Add Settings entry points — Sign in, Sign out, account status.
- Auth A4: Implement Apple Sign In flow and callback handling.

Exit criteria:

- Guest-first flow still works
- Apple Sign In succeeds end-to-end
- Session persists safely across relaunch

### Sprint 3 - 0.2.0 auth migration hardening plus calendar groundwork

Goal: finish account-linking safety work and unblock the Calendar epic in parallel.

Pull first:

- Auth A5: Implement anonymous-to-account data linking migration.
- Auth A6: Add migration diagnostics events and failure retry behavior.
- Auth A7: Add regression tests for migration idempotency and account relinking.
- A1.4 Add formal XCTest coverage for migration safety and metadata normalization (AC: old saved payload loads without crash and gets pending/day defaults)
- Cal A1: Replace implicit OAuth flow in lib/googleCalendar.ts with Authorization Code + PKCE; update scope to calendar.readonly; add /api/calendar/oauth/callback server-side token exchange route.
- Cal A2: Create Supabase schema — user_calendar_connections and synced_calendar_events tables with RLS policies and unique constraints.

Exit criteria:

- Existing local users can link an account without data loss
- Auth regressions are covered by tests
- Calendar backend prerequisites are ready for native connect flow

### Sprint 4 - 0.3.0 calendar connect and pull

Goal: make Fill reliably useful alongside Google Calendar without introducing provider write-back complexity.

Pull first:

- Cal A3: iOS native OAuth — ASWebAuthenticationSession Authorization Code + PKCE; after exchange present calendar picker; store selected_calendar_ids in Supabase; show connected state. (Depends on Auth A1-A2)
- Cal A4: Event pull service — /api/calendar/sync/pull; reads selected calendars, refreshes token if expired, fetches events for day ±7 days, and upserts them into synced_calendar_events using a full-replace strategy for the pull window.
- Cal A7: Calendar Settings screen — replace stub with real connected/disconnected state, connect/disconnect with calendar picker, Sync Now, last-synced display. (Depends on Cal A3, Cal A4)

Exit criteria:

- User can connect Google Calendar on device
- Fill shows pulled Google events reliably with selected calendars
- Reconnect / disconnect basics work

### Sprint 5 - 0.3.0 calendar export handoff, Fill integration, and failure UX

Goal: finish the pull-based calendar experience and add explicit export/open-calendar handoff from Shape.

Pull first:

- Cal A5: Shape scheduling export handoff — after a user schedules a task in Shape, tapping Export to Calendar immediately opens a prefilled Apple calendar event composer (EventKitUI / EKEventEditViewController); keep Open Calendar as a secondary convenience action; no direct Google Calendar create APIs.
- Cal A6: Fill timeline integration — trigger pull on Fill open (15-min throttle); render synced_calendar_events as read-only reference blocks; inline re-auth prompt on 401. (Depends on Cal A4)
- Cal A8: Offline cache and error UX — serve cached events on failure; non-blocking banner with retry; inline re-auth prompt on Fill (dismissible per session); non-blocking export/open-calendar failure messaging in Shape.
- Post-beta bug triage pass

Exit criteria:

- Shape export handoff works on device
- Fill pull and cached reference blocks behave correctly
- Offline, retry, and re-auth flows are validated

### Sprint 6 - 0.4.0 monetization foundation and paywall [POST-DEMO — do not start before Friday March 27]

Goal: add entitlements and purchase flow only after the core app and calendar habit loop are trustworthy.

Pull first:

- Mon A1: Add monetization domain model and entitlement service abstraction; support states for active subscription, offer-code access, expired access, and preview mode.
- Mon A2: Integrate StoreKit 2 + RevenueCat for monthly and annual subscriptions; keep product IDs and displayed price copy configurable so pricing can be tuned without code churn.
- Mon A3: Build the paywall shown after Intro > Start the Journey; include monthly and annual plans, Restore Purchases, code redemption entry point, and continue-to-preview option.
- Mon A4: Add preview mode gating across the app — unpaid users can browse but cannot add new tasks; all task-creation entry points should route to the paywall.

Exit criteria:

- Purchases and restore work end-to-end in sandbox/TestFlight
- Preview mode gating is enforced consistently
- Paywall does not break onboarding or guest flow

### Sprint 7 - 0.4.0 monetization hardening and launch-readiness [POST-DEMO — do not start before Friday March 27]

Goal: finish subscription lifecycle handling, seminar/tester access, and launch instrumentation.

Pull first:

- Mon A5: Add Settings account/subscription screen with current plan, entitlement status, manage subscription, restore purchases, redeemed-code status, and sign-in/account linkage hooks.
- Mon A6: Add offer-code and cohort-access support for seminar/testing rollouts using Apple offer codes first; support time-boxed access such as 3-month cohort grants without custom billing infrastructure.
- Mon A7: Add entitlement restore and lifecycle handling for reinstall, device change, sign-in/sign-out, renewal, cancellation, billing issue, and expiration states using trusted third-party vendor flows.
- Mon A8: Add monetization telemetry events and funnel tracking — paywall shown, plan selected, purchase started, purchase completed, restore started/completed, code redeemed, preview entered, paywall exit, entitlement expired.
- Review session 2026-03-14: Clarify trailing note "Sni" and convert into actionable ticket(s)

Exit criteria:

- Entitlement lifecycle is stable in real-world edge cases
- Seminar/testing cohort access is operational
- Monetization funnel is measurable before GA

### Sprint 8 - 1.0 release hardening and beta-to-GA cutover [POST-DEMO]

Goal: run the final integrated release pass after Auth, Calendar, and Monetization are all live together.

Pull first:

- External tester group created
- Beta App Review submitted
- Post-beta bug triage pass
- Release: pre-release-v1 full regression run and RC sign-off (execute docs/v1-regression-test-plan.md + docs/v1-release-quick-run.md; automation: scripts/ios_smoke.sh and .github/workflows/ios-smoke.yml)

Exit criteria:

- Integrated auth + calendar + monetization flows pass regression
- Beta findings are triaged and only accepted-risk issues remain
- Board is clean enough to declare 1.0 scope complete

## Deferred Until After 1.0

Keep these in Backlog, but do not pull them into active sprints unless they directly unblock the 1.0 path:

- Feature: Shared/collaborative project and Parking Lot workflows (multi-user communication and collective planning) - discovery requested from Dan/Beth feedback
- Future: Indexed note system per task — allow users to attach freeform notes to any task, viewable and editable from Pile/Shape/Park, so they can track context and retrieve it later
- Android port
- Future: deeper calendar integration for Genesis Way after the v1 Google pull + local export milestone; evaluate provider write-back, Apple Calendar parity, or both.
- Test voice entry and parsing
- Feature: iOS widget support (home screen + lock screen widgets showing today's Big 3 and pile count)
- Epic: Version 2 planning - authenticated logins, social actions (shared delegations, collaborative task handoff)
- UI: Add links to Dan's website/branding and a lightweight Find out more page
- Feature: Full-day timeline window mode — allow scheduling from 12:00 AM through 12:00 AM next day (24-hour planning span)
- Feature: Scheduled reminders — allow user to configure recurring notifications (e.g. morning Pile reminder, evening plan-tomorrow reminder) with day-of-week and time controls in App Settings
- Feature: Parking lot recurring review reminders — allow user to set weekly, monthly, or quarterly reminder to review the Park screen and promote items into the active Pile
- Feature: As the developer/tester, I need to preview any day's Dump/Shape/Fill state so I can validate Loop automation behavior across dates.

## Backlog

- [ ] 0.2.0 Feature Release: Authentication and user accounts (priority 1)
- [ ] 0.3.0 Feature Release: Google Calendar pull integration + local calendar export handoff (priority 2)
- [ ] 0.4.0 Feature Release: Monetization baseline with tiering and entitlement gating (priority 3)

- [ ] Epic: GW-E06 Dan Feedback Round (2026-04-02) - onboarding language alignment + daily-loop reliability

### GW-E06 Sprint Breakdown
- Sprint E06.1 (UI copy polish): GW-P01a, GW-P01b, GW-P01c, GW-P01d, GW-P01e, GW-P02, GW-P03a, GW-P03b, GW-P03c, GW-P04a, GW-P04b, GW-P05a
- Sprint E06.2 (Reliability fixes): GW-P04c, GW-P04d, GW-P05b
- Sprint E06.3 (Validation): GW-QA01 using docs/2026-04-03-gw-e06-testing-plan.md

- Epic: GW-E07 UX Polish Sprint (2026-04-03) - onboarding skip persistence, genesis pattern removal, Shape filter reorder, guidance legibility
- Sprint E07.1 (Implementation): GW-P07a, GW-P07b, GW-P07c, GW-P07d, GW-P07e

- Epic: GW-E08 Polish & Refinement Sprint (2026-04-03) - keyboard button spacing, Loop chip wrap, Loop fixed count entry, delegated tasks in Fill, delegate reminder view
- Sprint E08.1 (Implementation): GW-P08a, GW-P08b, GW-P08c, GW-P08d, GW-P08e

- Epic: GW-E09 Guidance & Discoverability Sprint (2026-04-03) - step-by-step in-screen guidance for Dump, Shape, Fill; 5-filter explainer; board tidy
- Sprint E09.1 (Implementation): GW-P09a, GW-P09b, GW-P09c

- Epic: GW-E10 UX & Usability Sprint (2026-04-04) - Work/Personal lane clarity in Shape, inline task editing on Dump, Parking Lot recurring review reminders
- Sprint E10.1 (Implementation): GW-P10a, GW-P10b, GW-P10c

- [x] GW-P01a Onboarding / Dump It copy update: replace "sustain it" with "finish it" and add Work/Home/Hobby/School prompt in Step 1 guidance.
- [x] GW-P01b Onboarding / Shape It copy update: use filter sequence Eliminate, Automate, Delegate, Schedule, Park; reorder In Practice bullets to match workflow.
- [x] GW-P01c Onboarding / Fill It copy update: emphasize calendar sync + assigning each task to a time/place; remove "Choose your daily big 3" from Step 3; refresh In Practice bullets.
- [x] GW-P01d Onboarding / Finish It copy update: rename Sustain It to Finish It, add tagline, and set In Practice copy to "Finish your task list or consciously move each item forward. Run each incomplete item through the filters."
- [x] GW-P01e Onboarding / Genesis Pattern normalization: update all onboarding pattern labels to "Dump it - Shape it - Fill it - Finish it - Rest" while preserving arrows.
- [x] GW-P02 Dump screen guidance copy update: "Get everything out of your head. List tasks at Work, Home, Hobby, School. Don't filter. Don't worry about the order."
- [x] GW-P03a Shape screen terminology update: title/labels to Shape It and How Shape It Works with Work/Personal tagging and filter instructions.
- [x] GW-P03b Shape screen process microcopy update: in DUMP TO PROCESS, change "all pending items are ready for fill" to "all pending items are ready, click Fill below".
- [x] GW-P03c Shape screen filter button relabel: Eliminate | Automate | Delegate | Schedule | Park.
- [x] GW-P04a Fill screen top description update: "Sync your calendar, then assign each task to a time (drag and drop)."
- [x] GW-P04b Fill "How fill works" section update: When will I do this? Move tasks to timeline/day, finish your day on paper before it begins, schedule reminders.
- [x] GW-P04c BUG: Shape -> Fill handoff regression; ensure shaped items consistently appear in Fill again.
- [x] GW-P04d BUG: Calendar will not sync; restore pull/sync flow and add visible failure feedback + retry path.
- [x] GW-P05a Park screen rename: change "The Park" to "Parking Lot" with subtitle "Someday/Maybe List. Not now. Not never. Just not today."
- [x] GW-P05b BUG: Parking Lot carryover persistence across consecutive days.
- [ ] GW-QA01 Regression pass: execute docs/2026-04-03-gw-e06-testing-plan.md and verify Dump -> Shape -> Fill -> Parking Lot flow after GW-E06 items (including sync and cross-day persistence).
- [x] GW-P06 HIGH PRIORITY follow-on (pull immediately after GW-E06): Calendar link/session hardening - when app reopens next day after initial setup, calendar sync remains connected and operational (no broken sync state). Include token/session refresh reliability, reconnect UX, and next-day cold-start regression coverage.

- [x] GW-P07a FIX: Skip intro onboarding on re-open — write showIntroOnLaunch=false in beginJourney() and skipToPlanner() so the intro cards only show once; accessible via App Settings reset.
- [x] GW-P07b IMPROVEMENT: Remove "genesis pattern" GlassCard from OnboardingScreen; keep the daily flow reminder setup card and Begin the Journey CTA unchanged.
- [x] GW-P07c IMPROVEMENT: Reorder Shape 5-filter grid to Eliminate (red), Automate, Delegate, Move, Park; rename "Schedule" grid button to "Move"; inside the Move sheet swap segment order to Schedule | Move with Schedule as default (appointment mode first).
- [x] GW-P07d IMPROVEMENT: Shape guidance text legibility — upgrade guidance body copy from textMuted to textPrimary so it reads clearly in all themes.
- [x] GW-P07e CLEANUP: Remove all duplicate " 2" files from docs/, scripts/, and assets now that E06 validation sign-off is complete.

- [x] GW-P08a POLISH: Keyboard Done button overlap — remove redundant safeAreaInset Done capsule from DumpScreen, FillScreen, ParkScreen; rely solely on ToolbarItemGroup(placement: .keyboard) for a single, native-placement Done button.
- [x] GW-P08b POLISH: Loop Recurrence weekday chips word-wrap — Mon/Tue chips are wrapping to 2 lines; fix by using a smaller font size (10pt) so all 7 chips fit on one line.
- [x] GW-P08c POLISH: Loop Fixed Count — add direct TextField keyboard entry alongside the Stepper so users can type a count without tapping +/-.
- [x] GW-P08d IMPROVEMENT: Delegated dump items visible in Fill — show today's delegated DumpItems in a distinct "Delegated" sub-section inside the Task Pool with amber/muted tint and assignee label.
- [x] GW-P08e IMPROVEMENT: View scheduled delegate follow-up reminders — add a "Pending Delegations" card in ParkScreen showing open DelegateFollowUpItem entries with due date and mark-complete action.

- [x] GW-P09a POLISH: Step-by-step guidance on Dump screen — replace flat empty-state copy with numbered "Step 1 / Step 2 / Step 3" guidance card visible when list is empty; copy: Step 1 = Empty your head fully, Step 2 = Don't filter yet, Step 3 = Tap Shape when done.
- [x] GW-P09b POLISH: Step-by-step guidance on Fill screen — upgrade the "How fill works" card to numbered steps matching the GW-P04a/b copy: Step 1 = Sync your calendar, Step 2 = Assign each task to a time, Step 3 = Finish your day on paper before it begins, Step 4 = Start your day.
- [x] GW-P09c IMPROVEMENT: Shape 5-filters explainer — add a collapsible or static sub-card beneath "How Shape It Works" that explains each filter with a short one-liner: Eliminate (won't do it, delete it), Automate (repeating task — create a Loop), Delegate (assign to someone + follow-up reminder), Move (pick a date or time), Park (not now, not never — Parking Lot).

- [x] GW-P10a IMPROVEMENT: Work vs Personal lane clarity — add a one-line sub-hint beneath the Work/Personal lane buttons on each Shape item explaining the distinction: Work = output, deadlines, obligations; Personal = home, health, relationships. Closes Review lane UX/Copy feedback item.
- [x] GW-P10b FEATURE: Inline task editing on Dump screen — tapping an existing captured item opens it for one-tap in-place text editing rather than delete-and-re-add. Add store.updateDumpItemText(id:text:) and switch item row to TextField on tap; save on submit or dismiss.
- [x] GW-P10c FEATURE: Parking Lot recurring review reminders — add a weekly/monthly/quarterly UNUserNotificationCenter repeating reminder that prompts the user to review their Parking Lot; configure frequency and time in App Settings Reminders section; show badge in Park screen when review is overdue.

- [ ] Feature: Shared/collaborative project and Parking Lot workflows (multi-user communication and collective planning) - discovery requested from Dan/Beth feedback
- [ ] Feature: As the developer/tester, I need to preview any day's Dump/Shape/Fill state so I can validate Loop automation behavior across dates.
- [ ] Feature: Full-day timeline window mode — allow scheduling from 12:00 AM through 12:00 AM next day (24-hour planning span)
- [ ] Feature: Scheduled reminders — allow user to configure recurring notifications (e.g. morning Pile reminder, evening plan-tomorrow reminder) with day-of-week and time controls in App Settings
- [x] Feature: Inline task editing on Pile screen — tapping an existing task item opens it for in-place text editing rather than requiring delete-and-re-add
- [x] Feature: Parking lot recurring review reminders — allow user to set weekly, monthly, or quarterly reminder to review the Park screen and promote items into the active Pile
- [x] Fix: Skip intro onboarding cards on re-open — write a "hasCompletedOnboarding" flag to persistent storage when user taps "Begin journey"; only show intro cards when flag is absent or reset via App Settings
- [ ] Future: Indexed note system per task — allow users to attach freeform notes to any task, viewable and editable from Pile/Shape/Park, so they can track context and retrieve it later
- [ ] External tester group created
- [ ] Beta App Review submitted
- [x] Post-beta bug triage pass
- [ ] Review session 2026-03-14: Clarify trailing note "Sni" and convert into actionable ticket(s)
- [ ] Android port
- [ ] Future: deeper calendar integration for Genesis Way. Question: after the v1 Google pull + local export milestone, do we want provider write-back, Apple Calendar parity, or both in the next pass?
- [ ] End-of-day carryover badges and history view
- [ ] A1.4 Add formal XCTest coverage for migration safety and metadata normalization (AC: old saved payload loads without crash and gets pending/day defaults)

### Post-Demo Sprint 1 Cleanup (pull into first sprint after Friday March 27)
- [x] UI: Each screen's guidance page should be step-by-step (e.g. "Step 1: Empty your head fully...")
- [x] UI: Add a 5-filters subsection to the Shape guidance screen explaining each filter (Delegate, Do, Delete, Park, Schedule)
- [ ] UI: Add a graphic or animation to the 5-filters subsection in Shape guidance to visually illustrate each filter
- [x] UI: Execution Progress should use dual-color independent tracking (Big 3 completion + scheduled task completion), not a single combined percentage.
- [ ] UI: Allow reordering items within the same hour bucket in Daily Planner
- [ ] Feature: Scheduling preview + confirm flow when assigning an item to a day so users can see what is already scheduled that day before confirming - Test: in Shape, tap Schedule on a pending item and verify the preview updates as date/time changes; confirm appointments, timed tasks, task pool items, and pending pile items are shown for that day; save and verify the item lands on the selected day/time. Then tap Move on a pending item, verify the preview updates as the day changes, save, and confirm the item appears in that day's pending pile.
- [ ] Feature: Daily Planner should support configurable visible hour range (user chooses how many hours to show) - Test: in App Settings, change Daily Planner start and end hours; return to Fill and verify the timeline updates to the selected range, All Day remains at the top, drag/drop still works in visible slots, and saved settings persist after closing and reopening the app.
- [ ] Epic: Google Calendar integration (v1) — pull selected calendars into Fill as read-only reference blocks, plus local calendar export handoff from Shape; Authorization Code + PKCE OAuth, calendar picker, Supabase schema with RLS (see docs/2026-03-24-rc1-calendar-spike-decision-memo.md). Depends on Auth epic for Cal A3+.
- [ ] Cal A1: Replace implicit OAuth flow in lib/googleCalendar.ts with Authorization Code + PKCE; update scope to calendar.readonly; add /api/calendar/oauth/callback server-side token exchange route.
- [ ] Cal A2: Create Supabase schema — user_calendar_connections and synced_calendar_events tables with RLS policies and unique constraints.
- [ ] Cal A3: iOS native OAuth — ASWebAuthenticationSession Authorization Code + PKCE; after exchange present calendar picker; store selected_calendar_ids in Supabase; show connected state. (Depends on Auth A1–A2)
- [ ] Cal A4: Event pull service — /api/calendar/sync/pull; reads selected calendars, refreshes token if expired, fetches events for day ±7 days, and upserts them into synced_calendar_events using a full-replace strategy for the pull window.
- [ ] Cal A5: Shape scheduling export handoff — after a user schedules a task in Shape, tapping Export to Calendar immediately opens a prefilled Apple calendar event composer (EventKitUI / EKEventEditViewController); keep Open Calendar as a secondary convenience action; no direct Google Calendar create APIs.
- [ ] Cal A6: Fill timeline integration — trigger pull on Fill open (15-min throttle); render synced_calendar_events as read-only reference blocks; inline re-auth prompt on 401. (Depends on Cal A4)
- [ ] Cal A7: Calendar Settings screen — replace stub with real connected/disconnected state, connect/disconnect with calendar picker, Sync Now, last-synced display. (Depends on Cal A3, Cal A4)
- [ ] Cal A8: Offline cache and error UX — serve cached events on failure; non-blocking banner with retry; inline re-auth prompt on Fill (dismissible per session); non-blocking export/open-calendar failure messaging in Shape.
- [ ] Epic: Monetization (v1) — StoreKit 2 + RevenueCat subscriptions, no free tier, preview mode when unpaid, offer-code access for seminar/testing cohorts, paywall after Start the Journey.
- [ ] Mon A1: Add monetization domain model and entitlement service abstraction; support states for active subscription, offer-code access, expired access, and preview mode.
- [ ] Mon A2: Integrate StoreKit 2 + RevenueCat for monthly and annual subscriptions; keep product IDs and displayed price copy configurable so pricing can be tuned without code churn.
- [ ] Mon A3: Build the paywall shown after Intro > Start the Journey; include monthly and annual plans, Restore Purchases, code redemption entry point, and continue-to-preview option.
- [ ] Mon A4: Add preview mode gating across the app — unpaid users can browse but cannot add new tasks; all task-creation entry points should route to the paywall.
- [ ] Mon A5: Add Settings account/subscription screen with current plan, entitlement status, manage subscription, restore purchases, redeemed-code status, and sign-in/account linkage hooks.
- [ ] Mon A6: Add offer-code and cohort-access support for seminar/testing rollouts using Apple offer codes first; support time-boxed access such as 3-month cohort grants without custom billing infrastructure.
- [ ] Mon A7: Add entitlement restore and lifecycle handling for reinstall, device change, sign-in/sign-out, renewal, cancellation, billing issue, and expiration states using trusted third-party vendor flows.
- [ ] Mon A8: Add monetization telemetry events and funnel tracking — paywall shown, plan selected, purchase started, purchase completed, restore started/completed, code redeemed, preview entered, paywall exit, entitlement expired.
- [ ] Epic: Authentication (v1) — Supabase Auth + Apple Sign In + guest-first local mode + anonymous-to-account migration (see docs/2026-03-21-rc1-auth-spike-decision-memo.md)
- [ ] Auth A1: Add AuthClient abstraction and Supabase implementation scaffold.
- [ ] Auth A2: Add secure session storage in Keychain.
- [ ] Auth A3: Add Settings entry points — Sign in, Sign out, account status.
- [ ] Auth A4: Implement Apple Sign In flow and callback handling.
- [ ] Auth A5: Implement anonymous-to-account data linking migration.
- [ ] Auth A6: Add migration diagnostics events and failure retry behavior.
- [ ] Auth A7: Add regression tests for migration idempotency and account relinking.
- [ ] Test voice entry and parsing
- [ ] Feature: iOS widget support (home screen + lock screen widgets showing today's Big 3 and pile count)
- [ ] Epic: Version 2 planning - authenticated logins, social actions (shared delegations, collaborative task handoff)
- [x] Polish: Adjust spacing on the keyboard Done button - it sits too close to the top of the keyboard and nearly overlaps it #kickback
- [ ] Polish: guided setup should visually indicate which control/button to press on each step - I like the icon you added, but it should also circle or highlight the actual buttons in the UI as well #kickback
- [x] Polish: In Automate > Loop > Recurrence, Mon and Tue are word wrapping to 2 lines. Keep them on 1 line. Adjust font size if needed.
- [x] UI: Under Automate > Loop > Duration > Fixed count, keep +/- controls and also allow direct keyboard entry of the count value.
- [ ] Polish: Get new icons centered and working on device (moved from Ready; pending final branding direction)
- [x] Improvement: Remove the "genesis pattern" box control on intro screens.
- [x] Improvement: Reorder Shape 5-filters to Eliminate (Red), Automate, Delegate, Move, Park; keep non-Eliminate actions gray.
- [x] Improvement: Swap Schedule and Move positions; show Schedule on the primary button and make Schedule the default (first toggle option) when selected.
- [x] Improvement: Add a way to view scheduled delegate follow-up reminders.
- [x] Improvement: Keep delegated tasks visible in Fill stage and render them in a distinct color state.

## Ready


## In Progress

- [ ] Validation: Run end-to-end calendar sync on device (connect Google, select calendars, trigger Fill pull, verify read-only timeline render, force retry/re-auth path, verify cached fallback behavior)
- [ ] Sprint E06.3: GW-QA01 validation pass using docs/2026-04-03-gw-e06-testing-plan.md on simulator and physical device
- [x] Sprint E10.1: GW-P10a through GW-P10c implementation pass

## Blocked

- [ ] Set signing to paid Apple team in Xcode (waiting on Apple account propagation)
- [ ] Confirm paid Apple Developer team appears in Xcode (waiting on Apple account propagation)
- [ ] Add App Store Connect API key secrets in GitHub (waiting for App Store Connect/API access)
- [ ] Verify App Store Connect app metadata is complete (waiting for App Store Connect/API access)

## Triage

## Review

- [x] Improvement: Add clear return-to-Home affordance from in-flow screens; validate discoverability with first-time users. Note: behavior should route to Intro screen (not Dump), button may need rename, and should be visible on Dump.
- [x] UX/Copy: Add clear guidance for Shape buttons explaining Work vs Personal categories and why two categories are intentionally sufficient #kickback
- [x] UI: Execution Progress should use dual-color independent tracking (Big 3 completion + scheduled task completion), not a single combined percentage.

- [ ] Feature: Loop action redesign - Replace Dump repeating-rule flow with Loop as the main recurrence setup. Configure Loop from an Automate menu (not Shape/Pile). Recurrence options: Daily, Weekly, or specific weekdays (Mon-Sun chips). Duration options: Forever or fixed future occurrence count. Saving Loop does NOT resolve/remove the current task from today's pile. Future occurrences generate by schedule regardless of completion and de-duplicate to one instance per day max; missed items roll forward as a single carried-over instance. If lane is unset when loop is created, future instances remain unassigned. - Test: (1) In Dump, type a task and tap the Automate (wand) menu — verify "Loop current input" is available and opens the Loop editor sheet. (2) In the editor, set Daily + Forever, leave lane Unassigned, save — verify today's pile is unchanged and a confirmation message appears. (3) Kill and reopen the app, verify the loop rule persists and appears under Loop Rules in App Settings. (4) In App Settings > Loop Rules, confirm the rule shows Daily · Forever · Unassigned, then delete it and verify it is removed. (5) Create a Weekly loop — confirm it shows the anchor weekday in App Settings. (6) Create a Specific Weekdays loop — tap chips to select Mon/Wed/Fri, confirm the summary shows those days. (7) Create a Fixed Count loop (4 occurrences) — confirm the count decrements by 1 after manual date simulation or that remainingOccurrences is set to 4 in diagnostics. (8) Create a loop from an existing captured item via "Loop captured item" sub-menu — confirm the text pre-fills in the editor. (9) Verify saving a loop on an item that already has a lane pre-sets that lane in the editor. (10) Set lane to Work on a loop, save — verify future items generated carry the Work lane.

## Done

- [x] Sprint E10.1 complete: UX & usability sprint shipped (Work/Personal one-liner hint on Shape lane buttons, inline tap-to-edit on Dump items with commit-on-submit, Parking Lot recurring review reminders with frequency/time settings and overdue badge in Park)
- [x] Sprint E09.1 complete: Guidance & discoverability sprint shipped (Dump empty-state → 3-step numbered GlassCard, Fill guidance → 4-step numbered GlassCard, Shape 5-filters explainer subsection added with inline Eliminate/Automate/Delegate/Move/Park one-liners)
- [x] Sprint E08.1 complete: Polish & refinement sprint shipped (keyboard Done button deduped across 3 screens, Loop weekday chips fixed to 10pt single-line, Loop fixed count now supports direct TextField entry, delegated dump items appear in Fill Task Pool with amber "Delegated" badge + assignee, Pending Delegations card added to Parking Lot with mark-complete action)
- [x] Sprint E07.1 complete: UX polish sprint shipped (onboarding skip persistence, genesis pattern card removed, Shape filter reorder Eliminate→Automate→Delegate→Move→Park, Schedule/Move picker swapped to Schedule-first, Shape guidance upgraded to textPrimary, all " 2" duplicate files removed)
- [x] Sprint 5 complete: calendar export handoff, Fill integration, and failure UX shipped (Shape Export to Calendar composer + Open Calendar handoff, Fill pull-on-open throttle + read-only synced blocks, non-blocking retry/dismiss banner with cached-event fallback messaging, and final triage pass)
- [x] Sprint 4 complete: calendar connect and pull shipped on device (native Google OAuth handoff/callback, calendar picker and connected state, /api/calendar/sync/pull + Sync Now wiring, Fill read-only pulled event rendering with 15-minute pull throttle, and inline retry/re-auth handling)
- [x] Sprint 3 complete: auth migration hardening delivered (linkage/relink safety, diagnostics events/viewer/export, auto/manual retry, regression probe) and calendar groundwork delivered (Google OAuth Authorization Code + PKCE callback route and Supabase calendar schema draft)
- [x] Sprint 2 complete: auth foundation vertical slice closed with live Supabase Apple sign-in exchange, keychain session persistence, settings account controls, remote sign-out invalidation, and Apple Sign In entitlement wiring
- [x] Sprint 1 complete: 0.1.2 hardening and RC readiness lane closed on branch pre-release-v1
- [x] Sprint 1 QA note: smoke build/launch passes and daily-flow reminder setup hardened; complete physical-device spot pass before external demo handoff
- [x] Spike (RC1-Monetization): Monetization model and entitlement architecture for v1. Decision: StoreKit 2 + RevenueCat, no free tier, paywall after Start the Journey, preview mode for unpaid users, Apple offer codes for seminar/testing access.
- [x] Spike (RC1-Auth): Authentication and user account architecture for v1. Decision: Supabase Auth + Apple Sign In + guest-first local mode. Memo: docs/2026-03-21-rc1-auth-spike-decision-memo.md
- [x] Spike (RC1-Calendar): Google Calendar integration design for v1. Decision: pull selected calendars into Fill, keep Genesis tasks local, add explicit Export to Calendar / Open Calendar handoff from Shape, calendar picker, Authorization Code + PKCE OAuth, foreground-only cadence. Memo: docs/2026-03-24-rc1-calendar-spike-decision-memo.md
- [x] UI: add keyboard Done button on all keyboard-entry screens
- [x] Bug: optimize first focus/open of Pile input field to remove initial lock-up/delay
- [x] Bug: fix Fill drag-and-drop so task scheduling works reliably again
- [x] Validate first iOS TestFlight workflow run output
- [x] Phase C: rebuild Fill as appointment-first daily timeline scheduler
- [x] Phase D: add evening "5-minute plan tomorrow" notification with custom time
- [x] Fill: remove "From Pile" section now that Task Pool exists
- [x] Fill task pool: add drag-handle indicator so users know rows are draggable
- [x] Fill copy: rename "Planning Day" label to "Daily Planner"
- [x] Fill/Settings: move reminder enable controls fully into App Settings and remove duplicate Fill controls
- [x] Fill task pool UX: remove "PILE" badge column and group pool items by Work vs Personal
- [x] Global naming: rename "Dump" to "Pile" across app screens/nav/copy
- [x] End-of-day carryover badges and history view
- [x] Onboarding refresh: keep pile/fill animations and replace the other two steps for the new daily paradigm
- [x] Delegate flow expansion: completion now prompts optional follow-up reminder (default +7 days, customizable)
- [x] Review session 2026-03-14: Repeating tasks model initial pass (every X days rules + auto-add to pile + settings management)
- [x] Weekly planning mode initial pass (Fri/Sun card in Fill with top 3 weekly goals + macro dump)
- [x] Onboarding refresh scope locked: polished intro copy/flows against new daily paradigm
- [x] Review session 2026-03-14: First-time guided setup walkthrough added after intro (calendar -> pile -> shape -> fill)
- [x] Add upgraded haptics
- [x] UI copy audit: removed/confirmed absence of "this is not x, its y" phrasing in app UI
- [x] Onboarding refresh: kept pile/fill animations and replaced the other two with new paradigm visuals/flows
- [x] Review session 2026-03-14: Shape intro animation refreshed to geometric triangle draw sequence
- [x] Review session 2026-03-14: Fill task pool simplified to drag-handle interactions (removed Add buttons)
- [x] UI: Increase drag-and-drop handle size in Fill Task Pool rows so touch targets are easier to grab on device.
- [x] Review session 2026-03-14: Fill placed-state indicator added (tasks remain visible with Placed styling)
- [x] Review session 2026-03-14: Fill timeline now includes explicit All Day slot at top
- [x] Review session 2026-03-14: Fill planning guardrail requires all tasks to be assigned before Start Day
- [x] Review session 2026-03-14: Big 3 quick-add delivered (task dropdown chooser + long-press add-from-pool)
- [x] Review session 2026-03-14: Delegate follow-up completion flow delivered (default +7 day reminder, customizable)
- [x] Review session 2026-03-14: Move Google Calendar setup controls from Fill/Sustain into App Settings
- [x] Review session 2026-03-14: Shape readiness indicator per pending task (ready when lane is selected)
- [x] Review session 2026-03-14: Shape lane defaults to unselected; user must choose Work/Personal for readiness
- [x] Review session 2026-03-14: Removed Work Queue and Personal Queue sections from Shape screen
- [x] Review session 2026-03-14: Settings custom theme selector delivered in App Settings (OLED black, light/dark gradient-inspired palettes, colorful variants; brown default)
- [x] Review session 2026-03-14: Pile quick-add keyboard flow delivered (Enter submits, clears input, keeps field focused/keyboard active)
- [x] A1.5 Developer diagnostics panel added (filter/day/carry stats + migration self-check)
- [x] B1.4 Shape oversized-task detection + Jam Session refinement prompt
- [x] D1.1 initial pass: daily rollover carries incomplete past-day tasks into today's pile
- [x] D1.2 Evening planning reminder scheduling with custom time in settings
- [x] D1.3 Delegate follow-up data capture (assignee + follow-up date)
- [x] D1.4 Delegate screen v2 with open follow-up list and completion toggles
- [x] B1.5 Schedule behavior rework: prompt for date + time, create scheduled appointment on timeline (not pile)
- [x] B1.6 Move behavior rework: prompt for date only, move item to that date's pile without scheduling
- [x] C1.1 initial pass: Fill shows today's scheduled appointments from Shape schedule flow
- [x] C1.2 initial pass: drag task IDs onto timeline blocks and move unscheduled tasks by day
- [x] C1.3 initial pass: Start Day guardrail blocks execution until all daily items have disposition
- [x] Fill task pool now includes unfiltered daily pile items (missing filter selection no longer hides items)
- [x] B1.2 Shape UI: Work and Personal columns with drag between lists
- [x] Shape filter actions animated with press feedback
- [x] Shape Schedule action initial pass implemented (date-only to pile) - superseded by B1.5 clarified behavior
- [x] Shape Move action initial pass implemented (next-day shortcut) - superseded by B1.6 clarified behavior
- [x] Shape Park action moves item to Park list
- [x] Delegate screen stub added and wired from Shape Delegate action
- [x] Phase B: rebuild Shape screen around 5 filters + Work/Personal dual lists
- [x] B1.1 Shape UI: per-item 5-filter controls (schedule, move forward, eliminate, delegate, park)
- [x] B1.3 Shape UI: ordering controls (Work top-down, Personal bottom-up)
- [x] A1.1 Add day-scoped pile metadata to DumpItem (filter outcome, lane, day key, carry flag)
- [x] A1.2 Migrate legacy spoke/rhythm daily data into archived fields and clear daily spoke dependency
- [x] A1.3 Convert W/P behavior to system-generated task IDs (remove user-editable rating control)
- [x] Planning alignment session summary completed from Dan call notes
- [x] Add Shape-to-Fill bridge so categorized dump items can be promoted into Work/Personal planning
- [x] Should have a way to edit which tasks are the daily three, and modify the W and P raitings. lets also add ? buttons to explain what each option does
- [x] Add keyboard navigation to adding lists
- [x] Updated icon
- [x] Add text wrapping across the ui
- [x] Update the fill screen. Right now I dont understand what the point is or how to use it
- [x] Set reminders and alerts (integrate wiht ios)
- [x] Add scheduling options to integrate with reminders and alerts where it makes sense
- [x] UI: Move 1 Dump it 2 Shape it etc to below the animation (Screen 1)
- [x] Wordwrap text in animation box in intro in all steps
- [x] UI: Make a different animation for 4 Sync (the others are perfect) - reworked
- [x] Add a step to first-time intro for Google Calendar sync
- [x] Add voice-to-list AI parsing feature in Dump screen
- [x] Create iOS App Icon
- [x] App settings menu
- [x] Add start Intro option to settings menu
- [x] Guided first time setup checklist added
- [x] Polish: hide build number in app chrome and show it only at the bottom of App Settings
- [x] Polish: remove debug screen numbers from app UI entirely
- [x] UI: remove Quick Connect Google Calendar and Open Calendar Settings buttons from intro
- [x] Testing: add a new lightweight developer test day data set with fewer items
- [x] Feature: add a question mark guide button beside settings on Pile, Shape, and Fill
- [x] Feature: add per-screen guide content for Pile, Shape, and Fill help screens
- [x] Bug: Start Guided Setup in App Settings does not launch guided setup flow reliably
- [x] Polish: after guided setup completes, return the user to Pile
- [x] Feature: rework Big 3 focus into dropdown selection from task pool plus Other/manual entry - This is improved, and I do see the drop down, but the drop down is not filling with the tasks from the task pool. Also there is not a way to manually enter something.
- [x] Bug: When guided setup starts, suppress Pile text-field auto-focus until guided setup exits so keyboard does not cover guided setup
- [x] Polish: Replace Shape readiness badge with task border state (green border = ready for Fill, red border = not ready)
- [x] Feature: Expand per-screen question-mark guides with detailed Dan-source guidance for Pile, Shape, and Fill
- [x] Polish: Shape It intro/onboarding animation rework v3 — card-deal sort animation (pile on left, 3 cards fly to tagged destinations, 3s loop)
- [x] UI: Each screen's guidance page should be step-by-step (e.g. "Step 1: Empty your head fully...")
- [x] UI: Add a 5-filters subsection to the Shape guidance screen explaining each filter (Delegate, Do, Delete, Park, Schedule)
- [ ] UI: Add a graphic or animation to the 5-filters subsection in Shape guidance to visually illustrate each filter
- [ ] UI: Rename all in-app daily-flow references from "Pile" to "Dump" (including step name) without breaking behavior
- [ ] UI: Allow reordering items within the same hour bucket in Daily Planner
- [ ] UI: Add links to Dan's website/branding and a lightweight "Find out more" page
- [x] Fastlane beta lane added
- [x] GitHub Actions iOS TestFlight workflow added
- [x] Local board workflow docs added
- [ ] Polish: updated app icon refresh - added 6 selectable icon variants (Chrome default, Textile, Stone, Molten, Obsidian Glass, Monochrome)
- [ ] UI: Remove the Clear action from Shape screen
- [ ] UI: Fill screen currently shows two settings icons; consolidate to one clear settings entry point
- [ ] UI: Remove duplicate settings icon on Shape screen — single gear entry point already exists via top overlay; remove any redundant in-screen instance
- [ ] Feature: Scheduling preview + confirm flow when assigning an item to a day so users can see what is already scheduled that day before confirming - Test: in Shape, tap Schedule on a pending item and verify the preview updates as date/time changes; confirm appointments, timed tasks, task pool items, and pending pile items are shown for that day; save and verify the item lands on the selected day/time. Then tap Move on a pending item, verify the preview updates as the day changes, save, and confirm the item appears in that day's pending pile.
- [ ] Feature: Daily Planner should support configurable visible hour range (user chooses how many hours to show) - Test: in App Settings, change Daily Planner start and end hours; return to Fill and verify the timeline updates to the selected range, All Day remains at the top, drag/drop still works in visible slots, and saved settings persist after closing and reopening the app.
- [x] Improvement: Increase baseline text legibility (font size/contrast), especially smallest and dimmest type from latest feedback.
- [x] Improvement: Preserve/strengthen completion and progress feedback (mark-through, completion cues) because users report motivational value.
- [x] Device test pass while app is running on phone
- [x] Feature: As a user, I need a daily-flow experience (morning plan + end-of-day prep), including configurable reminders and links to viewing other days' flow. Scope for v1: time-based reminders only (no in-app special prompt), no default times (set during onboarding), evening reminder opens Fill for that day, cross-day support is Dump-only for now, allow editing future days, keep past days read-only. (Phase 1 started: Dump cross-day date navigation + past read-only, reminder configuration scaffold, evening reminder tap route to Fill)
- [x] Release: pre-release-v1 full regression run and RC sign-off (execute docs/v1-regression-test-plan.md + docs/v1-release-quick-run.md; automation: scripts/ios_smoke.sh and .github/workflows/ios-smoke.yml)
