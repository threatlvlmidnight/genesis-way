# First-Time Setup Checklist

Use this as your step-by-step launch checklist for getting to TestFlight.

## 1) Apple account and team

- [ ] In Xcode, open Settings -> Accounts and confirm your paid team appears.
- [ ] In the project target Signing and Capabilities, set Team to your paid team.
- [ ] Keep Automatically manage signing enabled.

## 2) App Store Connect API key for CI

1. Open App Store Connect -> Users and Access -> Integrations -> App Store Connect API.
2. Click Generate API Key.
3. Save these values safely:
   - Key ID
   - Issuer ID
   - Private key file (.p8)

Then add in GitHub repo settings:

- Secrets and variables -> Actions -> Secrets:
  - APP_STORE_CONNECT_KEY_ID
  - APP_STORE_CONNECT_ISSUER_ID
  - APP_STORE_CONNECT_PRIVATE_KEY (paste full .p8 content)
- Secrets and variables -> Actions -> Variables:
  - APPLE_TEAM_ID
  - APP_IDENTIFIER (com.genesisway.app)

## 3) App Store Connect app metadata

Open your app record and confirm:

- [ ] App name and bundle identifier are correct
- [ ] Privacy policy URL set
- [ ] App privacy questionnaire completed
- [ ] Age rating completed
- [ ] Export compliance answered
- [ ] Test information added (for external testing)

## 4) Run first automated upload

From GitHub Actions:

- [ ] Run workflow: iOS TestFlight
- [ ] Confirm build appears in App Store Connect -> TestFlight

## 5) Verify install

- [ ] Add at least one internal tester
- [ ] Install build through TestFlight app
- [ ] Smoke test onboarding + core navigation
