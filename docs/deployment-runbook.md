# Genesis Way — Deployment Runbook

Covers all external services involved in building and shipping the app.
Updated: March 2026 after Sprint 5 calendar sync implementation.

---

## Architecture Overview

```
iOS App (Swift/SwiftUI)
    │
    ├── Supabase ──── Auth (Apple Sign-In backend) + user state persistence
    ├── Google Cloud ─ OAuth 2.0 client for Google Calendar access
    └── Vercel ─────── Next.js API middleware (OAuth callback relay + calendar sync pull)
```

The iOS app never talks to Google Calendar directly — all requests go through the Vercel API layer, which holds the client secret.

---

## 1. GitHub

**Repo:** `threatlvlmidnight/genesis-way`
**Production branch:** `main` → auto-deploys to Vercel
**Working branch:** `pre-release-2` (current sprint)

### Deploying to Vercel

Vercel tracks `main`. Any push to `main` triggers a production deployment automatically.

```bash
# Merge sprint branch and push
git checkout main
git merge pre-release-2 --no-edit
git push origin main
git checkout pre-release-2
```

To deploy a preview (test before promoting):
```bash
git push origin pre-release-2
# Vercel builds a preview URL automatically — check vercel.com/dashboard
```

---

## 2. Vercel

**Project:** `genesis-way`
**Production URL:** `https://genesis-way.vercel.app`
**Dashboard:** https://vercel.com/dashboard → threatlvlmidnight → genesis-way

### API Routes (all under `/api/calendar/`)

| Route | Method | Purpose |
|-------|--------|---------|
| `/api/calendar/oauth/callback` | GET | Receives Google redirect, bounces code to `genesisway://` scheme for `ASWebAuthenticationSession` |
| `/api/calendar/oauth/callback` | POST | Exchanges auth code + PKCE verifier for Google access/refresh tokens |
| `/api/calendar/sync/pull` | POST | Pulls events for selected calendars over a ±7 day window |
| `/api/calendar/import` | POST | Imports ICS calendar URLs (Apple Calendar flow) |

### Required Environment Variables

Set these in Vercel Dashboard → genesis-way → Settings → Environment Variables:

| Variable | Value | Notes |
|----------|-------|-------|
| `GOOGLE_OAUTH_CLIENT_ID` | `609243271731-nkcl43ltitd9itdeaduf24alr5timo8e.apps.googleusercontent.com` | From Google Cloud Console → Clients |
| `GOOGLE_OAUTH_CLIENT_SECRET` | `****YEGM` (full value) | From Google Cloud Console → Clients → Client secrets |

After adding or changing env vars, **redeploy** (Vercel does not hot-reload env vars):
- Vercel Dashboard → Deployments → latest → `...` → Redeploy, OR
- Push a new commit to `main`

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Build error: `export const dynamic not configured` | `output: "export"` in next.config.ts | Remove `output: "export"` — it's for static GitHub Pages only |
| `Server is missing Google OAuth client id` | Env vars not set or deployment not redeployed | Add vars, redeploy |
| Preview builds a new URL each time | Expected — Vercel generates unique preview URLs | Use `main` branch for stable prod URL |

---

## 3. Google Cloud

**Project:** `GenesisWay`
**Console:** https://console.cloud.google.com → select project GenesisWay

### APIs Enabled

- Google Calendar API (required for sync pull)

### OAuth Client

**Type:** Web application
**Name:** GenesisWay Calendar
**Client ID:** `609243271731-nkcl43ltitd9itdeaduf24alr5timo8e.apps.googleusercontent.com`

**Authorized JavaScript Origins:**
```
https://genesis-way.vercel.app
```

**Authorized Redirect URIs:**
```
https://genesis-way.vercel.app/api/calendar/oauth/callback
```

> ⚠️ These must match **exactly** what the iOS app sends as `redirect_uri`. Google returns `400 redirect_uri_mismatch` or `401 invalid_client` if they don't.

### OAuth Consent Screen

- **Status:** Testing (free tier — only test users can sign in)
- **Test users:** Add any Gmail accounts needed for testing under Audience → Test users
- To go to production: complete Google's OAuth verification process (required before public release)

### If You Recreate the OAuth Client

If the client is deleted or recreated:
1. Copy the new Client ID and Secret
2. Update `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` in Vercel env vars
3. Update the hardcoded fallback in `ios/GenesisWay/State/GenesisStore.swift` → `GoogleCalendarConfiguration.fromBundle()` → `hardcodedClientId`
4. Update `INFOPLIST_KEY_GW_GOOGLE_OAUTH_CLIENT_ID` in `ios/GenesisWay.xcodeproj/project.pbxproj` (both Debug and Release)
5. Redeploy Vercel and clean build iOS

---

## 4. Supabase

**Project:** `bolxsqpvabvpjbtbhmpf`
**Dashboard:** https://app.supabase.com → bolxsqpvabvpjbtbhmpf
**Project URL:** `https://bolxsqpvabvpjbtbhmpf.supabase.co`

### iOS Config Keys

| Key | Value | Where Used |
|-----|-------|-----------|
| `GW_SUPABASE_URL` | `https://bolxsqpvabvpjbtbhmpf.supabase.co` | `SupabaseAuthConfiguration.fromBundle()` |
| `GW_SUPABASE_ANON_KEY` | `sb_publishable_LbTmRHJIRpnaRXOHXC66ag_9VViLL32` | `SupabaseAuthConfiguration.fromBundle()` |

These are baked into the iOS binary at build time via `INFOPLIST_KEY_GW_*` build settings in `project.pbxproj`. They resolve from `Bundle.main` at runtime; if that fails (e.g. during local dev), they fall back to `ProcessInfo.processInfo.environment` (Xcode scheme env vars), and finally to hardcoded values in code.

### Schema

See `docs/supabase-calendar-schema.sql` for the calendar tables (`user_calendar_connections`, `synced_calendar_events`).

---

## 5. iOS Build Config

### Where Keys Live

All sensitive keys are injected at build time via `INFOPLIST_KEY_*` settings in `project.pbxproj`. Do not commit keys to source code as string literals in app logic — the hardcoded fallbacks in `GenesisStore.swift` are an exception for demo/dev convenience and should be rotated before public release.

| Build Setting | Debug | Release |
|--------------|-------|---------|
| `INFOPLIST_KEY_GW_SUPABASE_URL` | ✅ | ✅ |
| `INFOPLIST_KEY_GW_SUPABASE_ANON_KEY` | ✅ | ✅ |
| `INFOPLIST_KEY_GW_GOOGLE_OAUTH_CLIENT_ID` | ✅ | ✅ |
| `INFOPLIST_KEY_GW_CALENDAR_API_BASE_URL` | ✅ | ✅ |

### Smoke Build

Always run before committing iOS changes:
```bash
./scripts/ios_smoke.sh
```

### Clean Build (required after config changes)

In Xcode: **Product → Clean Build Folder** (`Shift+Cmd+K`), then re-run.

---

## 6. End-to-End Test Checklist

Run this after any infrastructure change before demo:

- [ ] App launches on device
- [ ] Apple Sign-In completes (Supabase auth config green)
- [ ] Calendar Settings → Google OAuth app config shows green
- [ ] Tap **Connect Google Calendar** → browser opens → Google sign-in → closes → status shows Connected
- [ ] Calendar picker shows user's calendars
- [ ] Tap **Sync Now** → event count > 0
- [ ] Open Fill → Daily Planner → verify events appear in correct time slots
- [ ] All-day events appear in the All Day slot on the correct date

---

## 7. Key URLs Quick Reference

| Service | URL |
|---------|-----|
| Vercel dashboard | https://vercel.com/dashboard |
| Vercel production | https://genesis-way.vercel.app |
| Supabase dashboard | https://app.supabase.com |
| Google Cloud Console | https://console.cloud.google.com |
| GitHub repo | https://github.com/threatlvlmidnight/genesis-way |
| App Store Connect | https://appstoreconnect.apple.com |
