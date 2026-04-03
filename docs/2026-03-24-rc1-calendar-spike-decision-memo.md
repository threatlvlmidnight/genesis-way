# RC1-Calendar Spike Decision Memo

Date: 2026-03-24
Owner: Genesis Way Product/Engineering
Status: Approved 2026-03-24

## Goal
Define the v1 Google Calendar integration strategy: read-only pull into Fill, local export handoff from Shape, OAuth architecture, Supabase integration design, and failure-mode behavior. Output feeds directly into implementation stories ready to pull.

## Dependency Note
Calendar sync requires an authenticated `user_id` as the foreign key for all Supabase-stored data. The Auth epic (Auth A1–A7) must be completed before Cal A3 onwards can ship. Cal A1 and Cal A2 (OAuth flow fix and schema) can proceed in parallel with auth implementation.

---

## Spike Questions — Answered

### 1. One-way import first vs full two-way in same milestone?
**Decision: v1 = one-way Google Calendar pull plus local export handoff.**

The planning experience still centers on Fill alongside the user's existing calendar, but Genesis does not need to write directly to Google Calendar in v1. Scheduled tasks remain local to Genesis unless the user explicitly chooses to export them.

- **Pull:** Auto-triggered when user opens Fill for a given day. Fetches events from selected Google calendars and displays them as reference blocks on the timeline.
- **Export handoff:** When the user uses Schedule in Shape, tapping `Export to Calendar` immediately opens an Apple-native prefilled new-event compose flow (`EventKitUI`). `Open Calendar` remains a secondary convenience action to jump to the calendar app. This is a user-initiated handoff, not provider write-back.
- Required OAuth scope: `https://www.googleapis.com/auth/calendar.readonly`.

---

### 2. Source of truth and conflict policy
**Decision: Google Calendar is the source of truth for imported calendar blocks; Genesis tasks remain local unless explicitly exported.**

This removes remote write reconciliation from v1. Rules:
- External Google events are always read-only reference blocks in Fill — never become Genesis tasks.
- Scheduled Genesis tasks stay local to the app unless the user explicitly exports them from Shape.
- Exported tasks are not reconciled back into Genesis in v1; edits in the calendar app do not mutate Genesis tasks.
- Conflict rule for pulled events: **Google wins** for imported reference blocks.

---

### 3. Mapping model for task ↔ event IDs and deleted events
**v1 does not require task ↔ provider link tracking:**

- `synced_calendar_events` — cache of externally-owned Google events. Reference-only in Fill.
- No `task_event_links` table is needed in v1 because Genesis is not creating or reconciling provider-owned events.

**Deleted events:**
- External events use a full-replace strategy for the pull window. Events absent from the latest Google response are removed from `synced_calendar_events`.
- Exported tasks remain local Genesis tasks. If the user later edits or deletes the exported event in their calendar app, Genesis does not reconcile that change in v1.

---

### 4. Token refresh / offline retry / error UX behavior
**Token lifecycle:**
- Authorization Code flow stores a `refresh_token` in Supabase `user_calendar_connections` (encrypted at rest).
- Token refresh happens **server-side** (API route). The iOS app never handles a raw refresh token directly.
- If `access_token` is expired at pull time, the server refreshes it silently before calling Google and writes the updated token + `token_expires_at` back to `user_calendar_connections`.

**Offline behavior:**
- On pull failure: serve the most recently cached events from `synced_calendar_events`. Fill timeline shows cached blocks with a "last synced [time]" indicator.
- On export handoff failure: scheduled tasks remain local in Genesis; surface a non-blocking message from Shape and keep the export/open actions available for retry.
- App launch and core task flows are never blocked by calendar sync.

**Error UX:**
- Sync failures surface as a **non-blocking inline banner** on the Fill screen. Never a modal. Never a launch blocker.
- Banner text: *"Calendar sync unavailable — tap to retry."*

**Re-auth required:**
- If the refresh token is revoked, the next pull returns a 401. Because the user is actively in Fill when this happens, surface a **re-auth prompt directly on the Fill screen** — not buried in Settings.
- Re-auth prompt (inline, dismissible): *"Your Google Calendar connection needs to be renewed."* + "Reconnect" button. Tapping reconnects without leaving Fill. Dismissing hides the banner for the session.

---

### 5. Quota / rate-limit and sync cadence strategy
**Quota:**
- Google Calendar API free tier: 1M queries/day per project, 10 queries/user/second.
- At v1 user volumes, no practical quota concern. No throttle infrastructure needed beyond sensible cadence.

**v1 cadence (foreground-only):**
- **Pull:** Triggered on Fill screen open for a given day. Auto-pulls if last sync for that day is >15 minutes ago. Manual "Sync Now" always triggers a pull (no throttle).
- **Export handoff:** Triggered when the user schedules a task in Shape and explicitly taps `Export to Calendar`, which presents a prefilled Apple calendar compose flow immediately. This uses local device affordances rather than Google Calendar write APIs.
- Sync window for pull: current day ± 7 days (focused on the active planning window).

**v1.x cadence (background):**
- Supabase Edge Function or Google Calendar push webhooks. Deferred — v1 is foreground-only since Google handles calendar notifications and Genesis handles task notifications independently.

---

### 6. Authorization Code flow — Supabase validation
**Confirmed required.** The existing `lib/googleCalendar.ts` uses `response_type: token` (implicit flow), which returns a short-lived access token only. This must change.

**Web layer changes (`lib/googleCalendar.ts`):**
- Change `response_type` from `"token"` to `"code"`.
- Add PKCE (`code_challenge`, `code_challenge_method: "S256"`).
- Add a server-side API route `/api/calendar/oauth/callback` to receive the authorization code and exchange it for access + refresh tokens via Google's token endpoint. Tokens are written to Supabase `user_calendar_connections`.
- The client never sees the refresh token.

**iOS native (new):**
- Use `ASWebAuthenticationSession` with Authorization Code + PKCE.
- On callback, pass the authorization code to the same `/api/calendar/oauth/callback` route to complete the exchange and store tokens in Supabase.
- Required OAuth scope: `https://www.googleapis.com/auth/calendar.readonly`.
- During connect flow: call `calendarList.list` to fetch the user's available calendars and present a picker in Calendar Settings for them to select which calendars to pull from. Store selection as `selected_calendar_ids` in `user_calendar_connections`.

---

### 7. Supabase Edge Function — background sync validation
**Confirmed feasible, deferred to v1.x.** v1 is foreground-only for three reasons:
1. Google handles calendar notifications server-side for all external events.
2. Genesis handles task/reminder notifications via iOS directly.
3. There is no user experience gap that background sync would close in v1.

The Supabase schema and RLS design is fully compatible with adding an Edge Function for background sync in v1.x without breaking changes.

---

### 8. RLS policy design
**`user_calendar_connections` table:**
```sql
-- Users can only access their own calendar connection
CREATE POLICY "user_calendar_connections_self"
  ON user_calendar_connections
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

**`synced_calendar_events` table:**
```sql
-- Users can only access their own synced events
CREATE POLICY "synced_calendar_events_self"
  ON synced_calendar_events
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

Edge Functions use `service_role` key to bypass RLS for server-side sync operations.

---

## v1 Scope Boundary

**In scope for v1:**
- Authorization Code + PKCE OAuth flow (replace implicit flow in web layer; add iOS native flow).
- `calendar.readonly` OAuth scope.
- Supabase schema: `user_calendar_connections` + `synced_calendar_events` with RLS.
- **Pull:** Google Calendar events → `synced_calendar_events` → Fill timeline as read-only reference blocks. Triggered on Fill open (15-min throttle).
- **Export handoff:** User-initiated `Export to Calendar` from Shape opens a prefilled Apple calendar compose flow immediately; `Open Calendar` is an optional secondary action. No direct Google Calendar create API calls.
- Calendar picker: user selects which Google calendars to pull from during connect flow.
- Foreground-only sync cadence.
- Offline cache: serve last successful pull; show "last synced" indicator on Fill.
- Re-auth prompt surfaced on Fill screen when connection needs renewal.
- Non-blocking banner for transient sync failures.
- Calendar Settings screen: real connected/disconnected state, connect/disconnect flows, calendar picker, sync status.

**Out of scope for v1:**
- Background sync via Edge Function (deferred to v1.x).
- Apple Calendar sync (future milestone — utilities exist to migrate Apple → Google).
- Provider write-back from Genesis to Google Calendar.
- Conflict resolution UI beyond pulled reference blocks.
- Google Calendar push webhooks.
- Task ↔ provider reconciliation for exported events.

---

## Supabase Schema

### `user_calendar_connections`
| Column | Type | Notes |
|---|---|---|
| id | uuid | PK, default gen_random_uuid() |
| user_id | uuid | FK → auth.users, NOT NULL |
| provider | text | `google` only for v1 |
| access_token | text | Short-lived, refreshed server-side |
| refresh_token | text | Authorization Code flow, never sent to client |
| token_expires_at | timestamptz | Server checks before each API call |
| selected_calendar_ids | text[] | Chosen during connect flow; null = not yet configured |
| sync_preferences | jsonb | Future: cadence, window overrides |
| last_synced_at | timestamptz | |
| created_at | timestamptz | default now() |

### `synced_calendar_events`
Caches externally-owned Google events. Read-only reference blocks in Fill.

| Column | Type | Notes |
|---|---|---|
| id | uuid | PK, default gen_random_uuid() |
| user_id | uuid | FK → auth.users, NOT NULL |
| provider | text | `google` |
| provider_event_id | text | Google event ID |
| title | text | |
| start_at | timestamptz | null for all-day events |
| all_day | boolean | |
| synced_at | timestamptz | Timestamp of last pull |
| created_at | timestamptz | default now() |

Unique constraint: `(user_id, provider, provider_event_id)` — supports upsert on re-sync.

## Failure-Mode Test Matrix

| Scenario | Expected Behavior |
|---|---|
| Network offline at Fill open | Serve cached events; show "last synced X ago"; no banner on first load |
| Network offline, cache empty | Fill timeline shows no calendar blocks; no error shown unless user taps Sync Now |
| User taps Sync Now while offline | Non-blocking banner: "Calendar sync unavailable — tap to retry" |
| Access token expired, refresh succeeds | Silent server-side refresh; events load normally |
| Access token expired, refresh fails (401) | Re-auth prompt shown inline on Fill screen |
| Refresh token revoked by user in Google | Re-auth prompt shown inline on Fill screen on next pull attempt |
| User dismisses re-auth prompt | Banner hidden for session; prompt reappears on next Fill open |
| Google API 5xx error on pull | Non-blocking banner; serve stale cache |
| Google API 429 rate limit | Retry with exponential backoff server-side; banner after 3 failed retries |
| External event deleted in Google before next pull | Full-replace removes it from synced_calendar_events on next successful pull |
| User exports a scheduled task, then changes it in Calendar app | Genesis task stays unchanged; export is a one-time handoff in v1 |
| User taps Export to Calendar and denies calendar permission | Show permission guidance and keep the task scheduled locally; retry remains available |
| User taps Export to Calendar but device handoff fails | Non-blocking message in Shape; task stays scheduled locally |
| User taps Open Calendar without a resolvable target | Non-blocking message in Shape; no task data lost |
| Supabase write fails during sync | Events not updated; serve stale cache; log diagnostic event |
| App upgraded, schema migration pending | Cal events hidden until migration completes; no crash |

---

## Decisions Closed During Spike
- **Sync direction for v1:** Pull-only for Google Calendar, plus local export handoff from Shape for user-scheduled tasks.
- **Export trigger:** User chooses Schedule in Shape, then explicitly taps `Export to Calendar`, which opens a prefilled Apple event compose flow immediately; exported events are not reconciled back into Genesis.
- **OAuth flow:** Authorization Code + PKCE required. Implicit flow (`response_type: token`) in `lib/googleCalendar.ts` must be replaced.
- **iOS OAuth:** `ASWebAuthenticationSession` with Authorization Code + PKCE.
- **OAuth scope:** `calendar.readonly`.
- **Source of truth:** Google Calendar wins for imported reference blocks; Genesis tasks remain local unless exported.
- **Sync cadence for v1:** Foreground-only. Background Edge Function deferred to v1.x — Google handles calendar notifications, Genesis handles task notifications.
- **Calendar picker:** User selects which Google calendars to pull from during the connect flow. Stored as `selected_calendar_ids`.
- **Deleted events:** External events use full-replace strategy inside the pull window. Exported tasks are not reconciled in v1.
- **Apple Calendar timing:** Future only. Utilities exist to migrate Apple → Google; not a v1 concern.
- **Supabase RLS:** Standard `auth.uid() = user_id` policies on calendar tables. Edge Functions use service_role key.
- **Error UX:** Non-blocking banner only. Never a launch blocker or modal.
- **Re-auth UX:** Surfaced inline on the Fill screen (where the user needs calendar most), not buried in Calendar Settings.

---

## Implementation Stories

| ID | Story |
|---|---|
| Cal A1 | Replace implicit OAuth flow in `lib/googleCalendar.ts` with Authorization Code + PKCE; update scope to `calendar.readonly`; add `/api/calendar/oauth/callback` server-side token exchange route; client never handles refresh token directly. |
| Cal A2 | Create Supabase schema: `user_calendar_connections` and `synced_calendar_events` tables with RLS policies and unique constraints. |
| Cal A3 | iOS native OAuth: implement `ASWebAuthenticationSession` Authorization Code + PKCE in `CalendarSettingsScreen`; after token exchange, call `calendarList.list` to fetch available calendars and present a picker; store `selected_calendar_ids` and connection in Supabase; show connected state. *(Depends on Auth A1–A2)* |
| Cal A4 | Event pull service: server-side API route `/api/calendar/sync/pull` — reads user's connection and `selected_calendar_ids`, refreshes token if expired, fetches Google Calendar events for current day ±7 days, and upserts external events into `synced_calendar_events` using a full-replace strategy for the pull window. |
| Cal A5 | Shape scheduling export handoff: after a user schedules a task in Shape, tapping `Export to Calendar` immediately opens a prefilled Apple calendar event composer via `EventKitUI` (`EKEventEditViewController`), while `Open Calendar` remains a secondary convenience action; no direct Google Calendar create APIs. |
| Cal A6 | Fill timeline integration: on Fill screen open trigger pull (Cal A4) if last sync >15 min ago; render `synced_calendar_events` as read-only reference blocks; show "last synced" indicator; show inline re-auth prompt if pull returns 401. *(Depends on Cal A4)* |
| Cal A7 | Calendar Settings screen: replace stub with real connected/disconnected state from Supabase; connect/disconnect OAuth flows with calendar picker; manual "Sync Now" wired to Cal A4; "last synced" timestamp display. *(Depends on Cal A3, Cal A4)* |
| Cal A8 | Offline cache and error UX: serve cached `synced_calendar_events` on pull failure; non-blocking banner on transient failures; inline re-auth prompt on Fill when refresh token is revoked (dismissible per session); non-blocking export/open-calendar failure messaging in Shape. |

---

## Definition of Done Check
- Pull/export scope for v1 locked: **Done** (Google pull on Fill open, local export handoff from Shape).
- Data contract reviewed: **Done** (schema, mapping, conflict rules in this memo).
- Supabase integration design confirmed: **Done** (RLS, Authorization Code flow, pull cache contract).
- Implementation stories drafted: **Done** (Cal A1–A8 above).
