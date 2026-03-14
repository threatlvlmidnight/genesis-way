# Genesis Way PDF Worksheet System Reference

## Scope And Source Files

This document summarizes and normalizes all PDF worksheets currently in the project root. It is intended as the implementation reference for screen design, interaction design, and copy.

Reviewed files:

1. `01 Genesis Way Leader.pdf`
2. `01 Genesis Way Student.pdf`
3. `03 Genesis Way Leader.pdf`
4. `03 Genesis Way Student.pdf`
5. `04 Genesis Way Leader.pdf`
6. `04 Genesis Way Student.pdf`
7. `05 Genesis Way Leader.pdf`
8. `05 Genesis Way Student.pdf`
9. `06 Genesis Way Leader.pdf`
10. `06 Genesis Way Student.pdf`
11. `Week 1 Tools PDFs My Life in 24 Hours New.pdf`
12. `Week 2 Dump It (2).pdf`
13. `Week 3 Shape it.pdf`
14. `Week 4 Shape it Pt 2 (1).pdf`
15. `Week 5 Fill It.pdf`
16. `Week 6 The Emperor of Time.pdf`
17. `THE WHEEL OF LIFE (4).pdf`
18. `Time Management Keynote_(coachplus).pdf`

## Canonical Program Model

The PDFs collectively describe two valid lenses:

1. High-level lens: `Dump It -> Shape It -> Fill It`
2. Full curriculum lens: `Wake Up (Week 1) -> Dump -> Shape -> Rhythm/Boundaries -> Fill -> Execute/Finish`

Canonical order for app flow:

1. `Week 1 Perspective`: My Life in 24 Hours, season awareness, urgency
2. `Week 2 Dump It`: full exposure of load without solving
3. `Week 3 Shape It`: categorize into seven spokes
4. `Week 4 Shape It Part 2`: rhythm and boundaries per spoke
5. `Week 5 Fill It`: one intentional action per spoke
6. `Week 6 Execute`: assignments + deadlines + finish commitments
7. `Park`: parking lot available at any stage

## Core Concepts To Preserve In UX

1. `Awareness before action`
2. `Do not fix too early` (Weeks 2-3 explicitly prohibit solving)
3. `Seven spokes` are the primary organizing model:
   - Spiritual
   - Family
   - Career
   - Physical
   - Mental
   - Social
   - Financial
4. `One thing per category` is preferred over overload
5. `Boundaries protect calling`
6. `Finish lines create urgency`
7. `Rest follows completion`

## Screen Architecture (Recommended)

## 1) Onboarding / Orientation

Purpose:

1. Explain both the 3-step and 6-week views without conflict
2. Set expectations: not productivity hacks, but stewardship framework
3. Route user to first unfinished stage

Required content blocks:

1. Program promise: clarity, stewardship, intentional living
2. Genesis pattern: form -> fill -> finish -> rest
3. CTA options:
   - Start Week 1 path
   - Jump to quick 3-step path

## 2) Week 1: Perspective (New Screen Recommended)

Purpose:

1. Compute life-as-24-hours mapping
2. Collect urgency and stewardship reflections

Inputs:

1. Current age
2. Auto-calculated life-day time equivalent
3. Reflection prompts:
   - What feels urgent now?
   - What is unnecessary/distracting?
   - What should be stewarded intentionally?

Outputs:

1. User season label (Morning, Midday, Evening or custom)
2. One focus sentence

## 3) Dump It (Existing `DumpScreen`)

PDF requirements:

1. Capture all load before any organizing
2. Four dump buckets are explicitly defined:
   - Time
   - Energy
   - Attention
   - Emotional Bandwidth
3. Daily repetition is encouraged

Implementation requirements:

1. Add optional bucket selector per item
2. Add reflection panel after dump session:
   - What surprised me?
   - What explains my exhaustion?
   - What have I been carrying alone?
3. Prevent premature shaping cues on this screen

## 4) Shape It (Existing `ShapeScreen`)

PDF requirements:

1. Place each dumped item into exactly one spoke
2. Do not prioritize/schedule yet
3. Identify crowded and neglected spokes

Implementation requirements:

1. Replace or supplement Five Filters with Seven Spokes assignment mode
2. Enforce single-category assignment
3. Show spoke occupancy counts + imbalance indicators
4. Reflection checkboxes:
   - Peace
   - Clarity
   - Resistance
   - Overwhelm
   - Relief

Note:

The current Five Filters model appears in the keynote/tooling content, but week worksheets center the seven spokes first. Keep both, but order them as:
`Seven Spokes shaping -> Five Filters/placement`.

## 5) Rhythm & Boundaries (New Screen or Shape Substep)

PDF requirements (Week 4):

1. One rhythm anchor per spoke
2. Three boundary decisions:
   - Start
   - Stop
   - Strengthen
3. Rest commitments:
   - One day
   - One evening
   - One protected block
4. One rhythm decision for this week

Implementation requirements:

1. Card per spoke with a single anchor field
2. Boundary triad form
3. Rest/margin commitments section
4. Single "one rhythm this week" commitment

## 6) Fill It (Existing `FillScreen`)

PDF requirements:

1. One specific action per spoke
2. Add timing/frequency for each action
3. Heart-check reflections:
   - Most life-giving action
   - Most obedience-required action
   - Distraction to reject this week

Implementation requirements:

1. Keep Big 3 but map to chosen spoke-actions
2. Require action + when fields before marking a spoke filled
3. Add lightweight weekly review prompt

## 7) Execute / Emperor Of Time (New Screen Recommended)

PDF requirements (Week 6 + Emperor of Time):

1. Season awareness:
   - Discovery / Building / Leading / Finishing / Transition
2. Execution grid: one assignment per spoke with deadline and first action
3. Deadline map:
   - 30 days
   - 90 days
   - 6 months
   - 1 year
4. Boundaries for completion:
   - I will stop
   - I will protect
   - I will finish

Implementation requirements:

1. Execution board with seven rows (one per spoke)
2. Deadline map as milestone cards
3. Completion pledge/signature field
4. Progress state from `planned -> in progress -> finished`

## 8) Park (Existing `ParkScreen`)

Role in worksheets:

1. Protect focus by moving non-now items out of active load
2. Preserve items without mental tax

Implementation requirements:

1. Keep categories (`This Week`, `Next Month`, `Someday`)
2. Add source linkage: parked from Dump, Shape, Fill, or Execute
3. Add rehydrate action: move parked item back into active step

## Data Model (Suggested)

```ts
type Spoke =
  | "spiritual"
  | "family"
  | "career"
  | "physical"
  | "mental"
  | "social"
  | "financial";

type Stage =
  | "week1-perspective"
  | "dump"
  | "shape"
  | "rhythm"
  | "fill"
  | "execute"
  | "park";

interface DumpItem {
  id: string;
  text: string;
  bucket?: "time" | "energy" | "attention" | "emotional";
  spoke?: Spoke;
  filter?: "eliminate" | "automate" | "delegate" | "schedule" | "park";
  parked?: boolean;
  sourceStage: Stage;
}

interface RhythmAnchor {
  spoke: Spoke;
  anchorText: string;
  cadence: "daily" | "weekly" | "monthly";
}

interface FillAction {
  spoke: Spoke;
  action: string;
  when: string;
}

interface ExecutionAssignment {
  spoke: Spoke;
  assignment: string;
  deadline?: string;
  firstStep?: string;
  status: "planned" | "in-progress" | "finished";
}
```

## Copy And Tone Rules (From PDFs)

Use copy that is:

1. Direct and instructional
2. Reflection-oriented, not shaming
3. Language of stewardship, clarity, obedience, completion

Avoid copy that:

1. Implies hustle/perfection
2. Encourages solving during Dump/Shape steps
3. Frames deadlines as anxiety

## Validation Rules Per Stage

1. Week 1 complete when:
   - Age entered
   - Season/focus statement saved
2. Dump complete when:
   - At least one item captured
   - Reflection answered (optional but prompted)
3. Shape complete when:
   - Every active dump item assigned to one spoke
4. Rhythm complete when:
   - At least one rhythm anchor saved
   - Start/Stop/Strengthen boundary fields filled
5. Fill complete when:
   - At least one action assigned with timing
6. Execute complete when:
   - One finish line set in near horizon (30 or 90 day)
   - At least one assignment marked finished

## Gaps Detected Against Current UI

Current app has strong visual foundation and baseline flow, but these worksheet-derived capabilities are missing:

1. Week 1 perspective module (life-day mapping)
2. Seven spokes categorization as primary Shape action
3. Rhythm/Boundaries step
4. Emperor of Time execution and deadline map
5. Explicit finish-state and commission/pledge mechanics
6. Source-linked parking and item rehydration

## Practical Build Sequence

1. Add `Week1PerspectiveScreen`
2. Expand `ShapeScreen` to seven-spokes mode
3. Add `RhythmScreen`
4. Extend `FillScreen` with per-spoke action + timing
5. Add `ExecuteScreen` for deadlines and finish tracking
6. Upgrade `ParkScreen` to source-linked parking
7. Update onboarding copy to show 6-week path + quick path

## Appendix A: Weekly Objective Summary

1. Week 1: Number your days, identify season, gain urgency perspective
2. Week 2: Expose full load across time/energy/attention/emotional bandwidth
3. Week 3: Shape by assigning to seven spokes
4. Week 4: Define rhythm anchors and protective boundaries
5. Week 5: Fill each spoke with one intentional action
6. Week 6: Execute with finish lines, deadlines, and completion discipline

## Appendix B: Relationship Of Supporting PDFs

1. `THE WHEEL OF LIFE (4).pdf`
   - Diagnostic instrument for spoke scoring
   - Best used in Week 3 and periodic re-assessment
2. `Time Management Keynote_(coachplus).pdf`
   - Tooling and operational language (calendar, planner, filters)
   - Useful for optional advanced mode and practical workflows
3. Leader/Student PDFs
   - Strong source for prompts, check-ins, and reflection copy
   - Leader versions include facilitation notes not needed in core user flow
