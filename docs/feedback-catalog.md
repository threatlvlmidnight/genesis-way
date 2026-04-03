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
