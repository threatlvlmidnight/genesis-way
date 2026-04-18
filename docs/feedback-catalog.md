# Feedback Catalog

Central log for customer, stakeholder, and tester feedback.

## How To Use
- Add one section per meeting or feedback source.
- Keep raw quotes plus interpreted product implications.
- Mark each item with priority and status so it can move into planning.

## Entry Template

### [Date] [Source]
- Participants:
- Context:
- Summary:

#### Raw Feedback
- 

#### Feedback by Category
Improvement:
- 

Bug:
- 

Feature:
- 

#### Product Signals
- 

#### Decisions
- 

#### Prioritized Actions
- [P0|P1|P2] Action - Owner - Target

#### Open Questions
- 

---

## 2026-03-21 Meeting with Dan and Beth
- Participants: Dan, Beth
- Context: Product feedback and go-forward discussion for coaching app positioning, roadmap, and launch opportunities.
- Summary: Strong positive validation from Beth and clear decision to move forward. Team is leaning toward naming/branding aligned to Dan's seminar and coaching brand to strengthen value proposition and customer acquisition.

#### Raw Feedback
- "I LOVE THIS!"
- Guided layout was "captured beautifully".
- Flow value: dump thoughts -> fill plan -> visual completion (items marked through) felt motivating.
- Stress-relief value from seeing schedule alerts.
- Parking Lot placement (last icon) felt intuitive and useful.
- Mobile advantage over paper: always available, similar to keeping grocery list in phone notes.
- Navigation concern: "Once I begin the process is there a way to go back to the homepage?"
- Accessibility concern: smallest/dimmest font is difficult to read.
- Collaboration request: ability to communicate/work collectively on project or parking list items.

#### Feedback by Category
Improvement:
- Increase baseline text legibility (font size and contrast), especially for smallest/dimmest text.
- Add a clearer and more persistent path back to Home after entering flow screens.
- Preserve and amplify progress/completion cues that make digital feel better than paper.

Bug:
- Potential navigation bug or discoverability defect: user could not find how to return to Home once inside the process.

Feature:
- Shared/collaborative project and Parking Lot workflows (multi-user communication and collective planning).
- Google Calendar sync as a critical roadmap feature.

#### Product Signals
- High perceived emotional value: relief, clarity, momentum.
- Strong PMF signal for paper-first users transitioning to digital.
- Accessibility/readability is a likely adoption blocker for some users.
- Collaboration/multi-user workflow is a potential expansion path.
- Seminar distribution channel could drive top-of-funnel acquisition.

#### Decisions
- Move forward with development.
- Explore app naming/branding anchored to Dan's brand and seminar system.
- Treat Google Calendar sync as a critical roadmap item.
- Continue validating tiered monetization.

#### Prioritized Actions
- [P0] Add or improve Home navigation affordance after entering workflow - Product/Design - Next sprint.
- [P0] Improve text legibility options (larger text sizes, stronger contrast choices) - Product/Design - Next sprint.
- [P0] Deliver Google Calendar sync milestone - Engineering - Roadmap now.
- [P1] Define brand/name options tied to Dan's seminar identity - Product/Marketing - This month.
- [P1] Draft monetization tiers and value ladder (free gateway -> paid coaching/system upsell) - Product/Business - This month.
- [P2] Scope collaboration concepts for shared lists/projects - Product/Engineering - Discovery backlog.
- [P1] Prepare conference pilot concept for Rocky/time-management event - Product/Business - Before Friday discussion.

#### Open Questions
- How much measurable value will the app bring by user segment (seminar attendees vs coaching clients)?
- What final name and brand system should ship in v1?
- Which monetization model should be in v1 vs post-v1?
- Should collaboration be framed as account sharing, invited workspaces, or async messaging?

#### Suggested Jira Backlog Buckets
- Accessibility and UX Polish
- Core Workflow Navigation
- Calendar and Scheduling Integrations
- Branding and Positioning
- Monetization and Packaging
- Collaboration Discovery

## 2026-04-02 Dan Input (Onboarding + Core Flow)
- Participants: Dan
- Context: Post-review content and functional feedback across Onboarding, Dump, Shape, Fill, and Park flows.
- Summary: Copy and sequencing changes are straightforward and high impact; three functional issues are release-critical (Shape-to-Fill item handoff, calendar sync failure, and Parking Lot carryover persistence).

#### Raw Feedback
- Onboarding terminology update: change "Sustain it" to "Finish it".
- Add Work/Home/Hobby/School prompt in onboarding and dump guidance.
- Genesis Pattern language should read: Dump it - Shape it - Fill it - Finish it - Rest.
- Shape onboarding and Shape screen should enforce and clearly present filters: Eliminate, Automate, Delegate, Schedule, Park.
- Fill onboarding and Fill screen should emphasize syncing calendar and assigning tasks to time.
- Functional regression: Shape items no longer appear in Fill.
- Functional issue: calendar will not sync.
- Park terminology and framing update: "Parking Lot" with Someday/Maybe subtitle.
- Functional issue: Parking Lot should carry items across consecutive days.

#### Feedback by Category
Improvement:
- Refresh onboarding copy for all 4 steps with consistent terminology and instructional sequence.
- Align Shape filter naming and order in onboarding and task controls.
- Update Fill instructional text to focus on calendar sync, time assignment, reminders, and margin.
- Rename Park to Parking Lot and update supporting microcopy.

Bug:
- Shape-to-Fill transfer regression (items processed in Shape are not visible in Fill).
- Calendar sync failure on Fill path.
- Parking Lot carryover persistence regression across days.

Feature:
- No net-new feature requested; feedback is primarily UX/copy refinement plus bug fixes.

#### Product Signals
- Dan is optimizing for language clarity and operational simplicity in the daily loop.
- Copy consistency is tightly coupled with coaching method adoption.
- Reliability issues in Fill/Calendar/Parking Lot undermine trust in the workflow and should be treated as top-priority fixes.

#### Decisions
- Create a dedicated epic for Dan's 2026-04-02 feedback round.
- Prioritize functional regressions before non-blocking copy polish.
- Keep terms aligned across onboarding and runtime screens (Finish it, Parking Lot, filter set).
- Normalize calendar wording in UX copy to "synced".

#### Prioritized Actions
- [P0] Fix Shape-to-Fill transfer regression so shaped items appear in Fill timeline/input list - Engineering - Immediate.
- [P0] Fix calendar sync reliability in Fill path (sync initiation + error handling + user feedback) - Engineering - Immediate.
- [P0] Fix Parking Lot day-to-day carryover persistence - Engineering - Immediate.
- [P1] Apply onboarding copy updates for Dump, Shape, Fill, Finish plus Genesis Pattern language normalization - Product/Design/Engineering - Next sprint.
- [P1] Apply Dump/Shape/Fill/Park in-screen copy and label updates (including filter button text and section names) - Product/Design/Engineering - Next sprint.
- [P1] Run targeted regression on daily loop after fixes (Dump -> Shape -> Fill -> Parking Lot) - QA/Engineering - Next sprint.

#### Open Questions
- Proposed finalized Finish It wording: "Finish your task list or consciously move each item forward. Run each incomplete item through the filters."

---

## 2026-04-08 User/Tester Feedback (Onboarding, Shape, Fill)
- Participants: Tester (name unknown)
- Context: Ad-hoc feedback submitted across three screens after latest build. Three issues noted.
- Summary: One legibility regression on the Onboarding CTA, one filter label naming conflict on Shape, and a continuing calendar sync failure on Fill.

#### Raw Feedback
- Onboarding / Dump It: "On the bottom of the app…can't read 'Begin the Journey' button."
- Shape: "Under the five filters: change 'move' with 'schedule'. The five filters are: Eliminate, Automate, Delegate, Schedule, Park."
- Fill: "I am unable to sync my calendar."

#### Feedback by Category
Improvement:
- Increase contrast/legibility of the "Begin the Journey" CTA at the bottom of the onboarding screen.
- Revert Shape filter label from "Move" back to "Schedule" to match the canonical five-filter set: Eliminate, Automate, Delegate, Schedule, Park.

Bug:
- "Begin the Journey" button is unreadable (likely contrast or theme issue at bottom of screen).
- Calendar sync is still not functioning; user cannot complete the Fill sync step.

Feature:
- No new features requested.

#### Product Signals
- The "Begin the Journey" button legibility issue is a first-impression blocker — users cannot start the journey if the CTA is invisible.
- "Move" vs "Schedule" label confusion indicates GW-P07c rename introduced a terminology mismatch with the coaching method language.
- Calendar sync failure (recurring) suggests the underlying fix may be incomplete or regressed.

#### Decisions
- Restore Shape filter label to "Schedule" to align with Dan's coaching method terminology.
- Fix "Begin the Journey" button contrast/visibility immediately.
- Re-investigate calendar sync; treat as a regression.

#### Prioritized Actions
- [P0] Fix "Begin the Journey" button legibility on Onboarding screen — Product/Design/Engineering — Immediate.
- [P0] Rename Shape filter "Move" → "Schedule" to restore canonical five-filter set — Engineering — Immediate.
- [P0] Re-investigate and fix calendar sync failure on Fill path — Engineering — Immediate.

#### Open Questions
- Is the "Begin the Journey" button legibility issue theme-specific or universal?

#### Resolved
- "Move" vs "Schedule" label: Dan confirmed 2026-04-08 — the filter should be labeled "Schedule". GW-P07c "Move" rename is superseded by GW-P15b.
