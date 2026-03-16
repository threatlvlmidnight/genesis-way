# Genesis Way Board
> Synced: 2026-03-15T17:50:49.261Z | Branch: pre-release-2
 | Dirty: yes

## Backlog

- [ ] Feature: Scheduled reminders — allow user to configure recurring notifications (e.g. morning Pile reminder, evening plan-tomorrow reminder) with day-of-week and time controls in App Settings
- [ ] Feature: Inline task editing on Pile screen — tapping an existing task item opens it for in-place text editing rather than requiring delete-and-re-add
- [ ] Feature: Parking lot recurring review reminders — allow user to set weekly, monthly, or quarterly reminder to review the Park screen and promote items into the active Pile
- [ ] Fix: Skip intro onboarding cards on re-open — write a "hasCompletedOnboarding" flag to persistent storage when user taps "Begin journey"; only show intro cards when flag is absent or reset via App Settings
- [ ] Future: Indexed note system per task — allow users to attach freeform notes to any task, viewable and editable from Pile/Shape/Park, so they can track context and retrieve it later
- [ ] External tester group created
- [ ] Beta App Review submitted
- [ ] Post-beta bug triage pass
- [ ] Review session 2026-03-14: Clarify trailing note "Sni" and convert into actionable ticket(s)
- [ ] Android port
- [ ] Epic: end-to-end calendar syncing for Genesis Way. Question: is the first milestone Google happy-path only, or Google + Apple ICS in the same pass? - First milestone is google calendar integration only. then apple calendar.
- [ ] End-of-day carryover badges and history view
- [ ] A1.4 Add formal XCTest coverage for migration safety and metadata normalization (AC: old saved payload loads without crash and gets pending/day defaults)
- [ ] Epic - Monetization
- [ ] V1.5: Tiered subscription service and pricing model (monetization layer)
- [ ] Test voice entry and parsing
- [ ] Feature: iOS widget support (home screen + lock screen widgets showing today's Big 3 and pile count)
- [ ] Epic: Version 2 planning - authenticated logins, social actions (shared delegations, collaborative task handoff)

## Ready

- [ ] UI: Remove duplicate settings icon on Shape screen — single gear entry point already exists via top overlay; remove any redundant in-screen instance
- [ ] UX/Copy: Add clear guidance for Shape buttons explaining Work vs Personal categories and why two categories are intentionally sufficient
- [ ] UI: Remove the Clear action from Shape screen
- [ ] Feature: Scheduling preview + confirm flow when assigning an item to a day so users can see what is already scheduled that day before confirming
- [ ] Feature: Daily Planner should support configurable visible hour range (user chooses how many hours to show)
- [ ] Feature: Implement repeating tasks on the Dump screen using existing repeating-task menu definitions
- [ ] UI: Fill screen currently shows two settings icons; consolidate to one clear settings entry point

## In Progress

- [ ] Device test pass while app is running on phone

## Blocked

- [ ] Set signing to paid Apple team in Xcode (waiting on Apple account propagation)
- [ ] Confirm paid Apple Developer team appears in Xcode (waiting on Apple account propagation)
- [ ] Add App Store Connect API key secrets in GitHub (waiting for App Store Connect/API access)
- [ ] Verify App Store Connect app metadata is complete (waiting for App Store Connect/API access)

## Triage

## Review

- [ ] Polish: Adjust spacing on the keyboard Done button - it sits too close to the top of the keyboard and nearly overlaps it
- [ ] Polish: guided setup should visually indicate which control/button to press on each step - I like the icon you added, but it should also circle or highlight the actual buttons in the UI as well #kickback
- [ ] Polish: updated app icon refresh - added 6 selectable icon variants (Chrome default, Textile, Stone, Molten, Obsidian Glass, Monochrome)

## Done

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
- [ ] UI: Each screen's guidance page should be step-by-step (e.g. "Step 1: Empty your head fully...")
- [ ] UI: Add a 5-filters subsection to the Shape guidance screen explaining each filter (Delegate, Do, Delete, Park, Schedule)
- [ ] UI: Add a graphic or animation to the 5-filters subsection in Shape guidance to visually illustrate each filter
- [ ] UI: Rename all in-app daily-flow references from "Pile" to "Dump" (including step name) without breaking behavior
- [ ] UI: Allow reordering items within the same hour bucket in Daily Planner
- [ ] UI: Add links to Dan's website/branding and a lightweight "Find out more" page
- [x] Fastlane beta lane added
- [x] GitHub Actions iOS TestFlight workflow added
- [x] Local board workflow docs added
