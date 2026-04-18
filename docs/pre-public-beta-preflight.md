# Pre-Public Beta Pre-Flight Checklist

Complete these before opening the app to external users outside the internal test group.

---

## 1. Infrastructure & Domain

- [x] `coachdan.app` DNS configured and valid on Vercel
- [x] `www.coachdan.app` redirecting (302) to `coachdan.app`
- [x] SSL certificates issued on both domains
- [x] Supabase project resumed and Site URL updated to `https://coachdan.app`
- [ ] Remove `localhost` from Supabase redirect URLs (replace with a staging URL if needed)
- [ ] Confirm `https://coachdan.app` loads the deployed app correctly in a browser

---

## 2. Google OAuth (Calendar Sync)

- [x] Add `https://coachdan.app` to Authorized JavaScript Origins in Google Cloud Console
- [x] Add `https://coachdan.app/api/calendar/oauth/callback` to Authorized Redirect URIs
- [ ] Submit OAuth app for Google verification (required before non-test users can sign in with Google)
- [ ] Add any beta tester Gmail accounts to OAuth test users list in the meantime

---

## 3. iOS Build

- [ ] Clean build and smoke test after domain/scheme changes (`./scripts/ios_smoke.sh`)
- [ ] Confirm bundle ID changed to `app.coachdan.ios` in App Store Connect (or decide to keep old ID)
- [ ] Update `APP_IDENTIFIER` in GitHub Actions secrets/variables if bundle ID changed
- [ ] Update app name to "Coach" in App Store Connect metadata
- [ ] Confirm `coachdan://` URL scheme is registered and OAuth callback works on device

---

## 4. Security

- [ ] Rotate hardcoded fallback keys in `GenesisStore.swift` before any public build (client ID, base URL)
- [ ] Confirm `GOOGLE_OAUTH_CLIENT_SECRET` is only in Vercel env vars, never in source code
- [ ] Confirm Supabase anon key is acceptable for public exposure (anon keys are safe by design — verify RLS policies are in place)
- [ ] Review Supabase Row Level Security (RLS) on all tables — ensure users can only read/write their own data
- [ ] Remove or gate any debug/diagnostic endpoints before public release
- [ ] Review `lib/debug.ts` — confirm debug output is stripped or gated in production builds

---

## 5. App Store & Legal

- [ ] Privacy policy written and hosted at a public URL
- [ ] Privacy policy URL added to App Store Connect
- [ ] App privacy questionnaire completed in App Store Connect
- [ ] Terms of service written (if required for paid tiers)
- [ ] Age rating completed
- [ ] Export compliance answered

---

## 6. Monetization Gate

- [ ] Decide which features are free vs. paid before opening to external beta users
- [ ] Confirm paywall boundaries are in place so testers cannot access paid features without a valid entitlement
- [ ] StoreKit/RevenueCat sandbox tested end-to-end
- [ ] Remove "⚠️ Test: Show Paywall" button from App Settings Developer section before public release

---

## 7. Stability & Regression

- [ ] Full end-to-end test pass on device (see `docs/v1-regression-test-plan.md`)
- [ ] Apple Sign-In → Supabase auth flow verified on device
- [ ] Google Calendar connect → sync → Fill display verified on device
- [ ] No Sev 1 bugs open in KANBAN backlog

---

## 8. TestFlight External Testing

- [ ] Build submitted to TestFlight
- [ ] Beta App Review approved for external testing
- [ ] Beta tester invite links or email list ready
- [ ] Feedback channel set up for beta testers (email, form, or TestFlight feedback)
