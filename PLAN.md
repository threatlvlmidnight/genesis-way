# The Genesis Way — Development Plan

## Project Overview

A proof-of-concept mobile web app for **Dan Holland's Genesis Way** productivity framework. Built by Dan's son to demonstrate the system and potentially partner with Dan to commercialize it.

**Goal:** Show Dan a polished, interactive demo of his framework — clean enough to impress, simple enough to pivot fast.

**Demo URL:** Deploy to Vercel for a shareable link. No login required. Data persists in `localStorage`.

---

## Design System (Approved)

Visual direction: **A2 — Glass Jakarta** (warm charcoal + gold glassmorphism, iOS-native feel)

| Token | Value |
|---|---|
| Background | `#0c0a06` |
| Gold accent | `#c8a96e` |
| Glass card | `rgba(255,255,255,0.03)` + `backdrop-filter: blur(40px)` |
| Glass border | `rgba(200,169,110,0.1)` |
| Top shimmer | `linear-gradient(to right, transparent, rgba(200,169,110,0.3), transparent)` |
| Font | Plus Jakarta Sans Variable (300–800) |
| Phone width | 390px shell on desktop, full-screen on mobile |

**Reference mockup:** `../mockup-A2-glass-jakarta.html` (open in browser to see approved design)

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Next.js 15 (App Router) | Easy Vercel deploy, React |
| Styling | CSS-in-JS (inline styles) + globals.css | Full design control for custom dark theme |
| UI components | shadcn/ui (installed but minimal use) | Available for future forms/dialogs |
| Font | `@fontsource-variable/plus-jakarta-sans` | Self-hosted, no Google Fonts GDPR concern |
| Data | `localStorage` | No backend needed for POC |
| Deploy | Vercel | Free tier, instant sharing |

---

## File Structure

```
genesis-way/
├── app/
│   ├── globals.css         ← Design tokens, glass utilities, font import
│   ├── layout.tsx          ← Metadata, root HTML
│   └── page.tsx            ← Main client component: state + routing
├── components/
│   ├── PhoneWrapper.tsx    ← Responsive: phone shell (desktop) / full-screen (mobile)
│   ├── BottomNav.tsx       ← 4-tab navigation: Dump / Shape / Fill / Park
│   └── screens/
│       ├── OnboardingScreen.tsx  ← Framework intro + 3 phase cards + CTA
│       ├── DumpScreen.tsx        ← Brain dump capture list
│       ├── ShapeScreen.tsx       ← Week calendar + Five Filters assignment
│       ├── FillScreen.tsx        ← Daily planner (THE showpiece screen)
│       └── ParkScreen.tsx        ← Long-term parking lot
```

---

## The Genesis Way Framework (for content reference)

### 3 Phases
1. **Dump It** — Empty the mind. Get everything on paper. No filtering.
2. **Shape It** — Give structure. Three tools: wall calendar, digital calendar, paper planner.
3. **Fill It** — Assign every task a time slot before the day begins.

### Five Filters (applied in Shape phase)
- **Eliminate** — Not worth doing at all
- **Automate** — Set up a system to handle it
- **Delegate** — Someone else should own this
- **Schedule** — Time-block it on the calendar
- **Park** — Not now, not never — someday

### Task Coding System
- Work tasks: **W1, W2, W3…** (top-priority first, numbered down)
- Personal tasks: **P1, P2, P3…** (numbered from bottom up — personal life as foundation)
- Priority levels: A (must do), B (should do), C (nice to do)
- Delegation levels 1–5 (1 = do it yourself → 5 = full authority)

### Key Concepts
- **Daily Big 3** — Three non-negotiable outcomes for the day
- **Jam Session** — 90-minute deep focus block (no interruptions)
- **168 Hours** — Dan's framing: you have 168 hours/week, not just a workday
- **F.O.C.U.S.** — Follow One Course Until Successful
- **Long-Term Parking** — Items that don't fit this week but shouldn't be forgotten

### Dan Holland's Influences
- Stephen Covey (7 Habits), David Allen (GTD), Michael Hyatt, John Maxwell
- Samurai discipline metaphor (lethal precision, not spiritual)
- Biblical creation narrative as metaphor for the 3-phase process

---

## Current App State

### What's built ✅
- [x] Responsive phone shell (desktop: 390px bezel, mobile: full-screen)
- [x] Dynamic Island + home bar (iOS aesthetic)
- [x] Ambient warm glow background
- [x] Glass card component with top shimmer
- [x] **Onboarding screen** — wordmark, 3 phase cards with quotes, CTA button
- [x] **Dump screen** — add/remove items, capture list
- [x] **Shape screen** — week mini-calendar, Five Filters, item assignment
- [x] **Fill screen** — Jam Session card, Daily Big 3 (interactive checkboxes), Work/Personal tasks with filter badges
- [x] **Park screen** — categorized parking (This Week / Next Month / Someday)
- [x] Bottom nav with active state
- [x] localStorage persistence
- [x] Clean build (no TypeScript errors)

### What's next 🔲
- [ ] **Deploy to Vercel** — `vercel --prod` from genesis-way directory
- [ ] **Add task creation in Fill** — Allow adding Work/Personal tasks inline
- [ ] **Weekly view in Shape** — Drag dump items onto day slots
- [ ] **Delegation modal** — When delegating a task, pick delegation level 1-5
- [ ] **Priority badges** — A/B/C priority on tasks
- [ ] **Animations** — Slide transitions between screens, check animation on Big 3
- [ ] **Onboarding flow** — Multi-step wizard rather than single screen
- [ ] **Settings** — User name (to personalize "Good morning, Dan")

---

## Deployment

### To deploy to Vercel (first time):
```bash
cd "c:/Users/godda/OneDrive/Desktop/Project Genesis/genesis-way"
vercel
```
Follow prompts: login → link to project → deploy. Get a `*.vercel.app` URL.

### To redeploy after changes:
```bash
vercel --prod
```

---

## Design Notes for Future Sessions

- **No serif fonts** — Plus Jakarta Sans only, all weights
- **No pure white text** — Use `#f0e4d0` for primary, `#c0b090` for secondary
- **Gold is reserved** — Only use `#c8a96e` for interactive/active states, not decorative text
- **Glass cards need `overflow: hidden`** — Otherwise the top shimmer `::before` bleeds out
- **Phone wrapper is responsive** — Below 480px it goes full-screen automatically
- **State lives in `page.tsx`** — Screens are dumb components receiving props
- **localStorage key** — `"genesis-way-v1"` (increment version to wipe old state)

---

## Key Files to Read When Resuming

1. `app/page.tsx` — App state, routing, default data
2. `components/screens/FillScreen.tsx` — The main showpiece, most complex screen
3. `app/globals.css` — All design tokens and utilities
4. `../mockup-A2-glass-jakarta.html` — The approved visual reference (open in browser)
5. `../framework-analysis.md` — Complete Genesis Way framework breakdown
