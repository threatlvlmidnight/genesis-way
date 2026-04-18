# RC1-Auth Spike Decision Memo (Draft)

Date: 2026-03-21
Owner: Genesis Way Product/Engineering
Status: Approved 2026-03-24

## Goal
Define the v1 authentication strategy that keeps Genesis Way local-first, adds account continuity, and minimizes launch risk.

## Recommendation
Use Supabase Auth with a local-first guest mode and Apple Sign In as the primary v1 auth method.

Why this recommendation:
- Fits local-first behavior: users can start immediately without account friction.
- Apple Sign In is expected on iOS and has high trust/conversion.
- Supabase provides a practical baseline for identity plus future backend expansion (sync, collaboration, entitlements) without building custom auth infra.
- Keeps implementation surface small enough for v1 while leaving a clean path to add Google/email later.

## v1 Scope Boundary
In scope for v1:
- Guest mode on first launch (no forced sign-in).
- Optional account creation/link from Settings and onboarding follow-up prompt.
- Sign in with Apple.
- Basic session persistence and sign-out.
- Anonymous local data migration to account-linked profile after sign-in.

Out of scope for v1:
- Forced auth gate on app start.
- Google sign-in.
- Full email/password UX.
- Team/workspace sharing.
- Admin dashboard or complex user-management tooling.

## Decision Matrix
### Option A: Firebase Auth
Pros:
- Mature SDKs and docs.
- Strong social sign-in support.

Cons:
- Less aligned with future relational, policy-heavy product model unless adding extra services.
- Can drift into Firebase lock-in decisions early.

### Option B: Supabase Auth (Recommended)
Pros:
- Strong auth primitives plus straightforward path to Postgres-backed multi-feature roadmap.
- Row-level security support aligns with future user-scoped data concerns.
- Good fit for phased backend adoption.

Cons:
- Slightly more backend configuration work than pure auth-only providers.

### Option C: Custom Auth Service
Pros:
- Maximum control.

Cons:
- Highest security and maintenance burden.
- Not justified for v1 timeline.

## Proposed Auth Flow
1. User opens app and starts in guest mode.
2. Local data is created and stored exactly as today.
3. User taps "Create account" or "Back up data" in Settings/onboarding follow-up.
4. User completes Apple Sign In.
5. App links local profile to remote account identity.
6. Migration routine marks local records with account owner ID.
7. Session token is stored securely; user remains signed in.

## Migration Plan (Anonymous to Account)
Data model additions (high level):
- accountId on user-owned entities.
- localMigrationVersion marker.
- syncState metadata for future sync readiness.

Migration strategy:
- On first successful sign-in, run an idempotent migration job:
  - Attach accountId to all current-day and historical user entities.
  - Preserve task IDs and timeline semantics.
  - Record migration completion timestamp/version.
- If migration fails mid-way, app keeps local data and retries safely on next launch.

Safety requirements:
- Idempotent transforms.
- Never delete local source records before confirmation.
- Add diagnostics event for migration success/failure.

## Security and Compliance Baseline
- Store auth/session secrets in iOS Keychain.
- Use HTTPS-only communication.
- Avoid logging tokens or sensitive auth payloads.
- v1 compliance baseline: add in-app "Request account deletion" path in Settings with documented manual support workflow/SLA.
- v1 compliance baseline: provide support-assisted data export (manual process) for first release.
- Post-v1 scaffolding: define privacy workflow contracts now so full self-serve deletion/export can be added without data model changes.

## Phased Rollout Plan
Phase 1 (v1):
- Guest mode + Apple Sign In.
- Account linking for local data.
- Session persistence and sign-out.

Phase 2 (v1.x):
- Add Google sign-in.
- Add email magic-link sign-in as the first non-social fallback.
- Add lightweight account-management UI.
- Implement privacy workflow scaffolding for future self-serve deletion/export.

Phase 3 (v2):
- Add full email/password authentication (verification + reset) if needed based on adoption.
- Add full self-serve deletion/export privacy center.
- Multi-device sync reliability hardening.
- Collaboration/authz expansion.
- Entitlements integration with monetization layer.

## Risks and Mitigations
Risk: Migration bugs could affect existing local data.
Mitigation: Idempotent migration, pre/post migration snapshots, diagnostics checks.

Risk: Auth friction could reduce early activation.
Mitigation: Keep guest-first flow and make auth optional but encouraged as backup.

Risk: Provider-specific constraints discovered late.
Mitigation: Implement auth behind a thin interface (AuthClient protocol) to keep swap cost manageable.

## Initial Implementation Stories
1. Add AuthClient abstraction and Supabase implementation scaffold.
2. Add secure session storage in Keychain.
3. Add Settings entry points: Sign in, Sign out, account status.
4. Implement Apple Sign In flow and callback handling.
5. Implement anonymous-to-account data linking migration.
6. Add migration diagnostics events and failure retry behavior.
7. Add regression tests for migration idempotency and account relinking.

## Calendar Sync Compatibility
The Supabase backend is sufficient to support Google Calendar sync in future versions. The `user_id` identity established in v1 becomes the foreign key for all user-scoped data, including calendar connections. The planned backend additions required for calendar sync are:

- `user_calendar_connections` table (columns: `user_id`, `provider`, `access_token`, `refresh_token`, `selected_calendar_ids`, `sync_preferences`, `last_synced_at`) — all scoped per user via Postgres Row-Level Security.
- `synced_calendar_events` table for caching pulled provider events as read-only reference blocks in Fill.
- Supabase Edge Functions can support background pull in future versions without requiring the app to be open.

**Important constraint for the Calendar spike (RC1-Calendar):** The current web-layer OAuth implementation in `lib/googleCalendar.ts` uses the implicit flow (`response_type: token`), which returns a short-lived access token only — no refresh token. To persist Google Calendar access to a user account, the calendar sync implementation must switch to the Authorization Code flow so a refresh token can be stored securely in Supabase. This is a calendar feature concern, not an auth architecture concern, and does not affect the v1 auth plan — but it must be addressed when the Calendar spike begins.

## Decisions Closed During Spike
- Google sign-in timing: **Defer to v1.x** (Apple Sign In only in v1).
- Non-Apple fallback at launch: **Do not ship full email/password in v1**; add **email magic-link** in v1.x first, then evaluate full password flow post-v1.
- Compliance baseline for first release: **v1 minimal compliance** (manual deletion/export support paths) with **explicit scaffolding for post-v1 full self-serve privacy workflows**.
- Minimum remote schema before calendar sync: **Resolved** as `user_calendar_connections` plus `synced_calendar_events` keyed by Supabase Auth `user_id`; Authorization Code flow required in calendar feature (see Calendar Sync Compatibility section above).

## Definition of Done Check
- Architecture recommendation approved: Done.
- v1 scope boundary documented: Done in this memo.
- Implementation stories drafted: Done in this memo.
