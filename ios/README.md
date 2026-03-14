# Genesis Way iOS App (Start)

This folder contains the native SwiftUI foundation for the iOS build phase.

## Included in this start slice

1. App entry + root navigation shell
2. Core domain models and app state store
3. Local persistence via `UserDefaults`
4. Theme tokens (Glass Jakarta baseline)
5. First screens:
- Onboarding
- Dump
- Shape (seven spokes + rhythm anchors)
- Fill
- Park
- Calendar Settings sheet (Google + Apple ICS toggles)
- Shape placeholder

## Structure

- `GenesisWay/App`: app entry point
- `GenesisWay/Models`: platform-agnostic entities
- `GenesisWay/State`: observable app store and persistence
- `GenesisWay/Theme`: color/token setup
- `GenesisWay/Views`: root shell + screens + common components

## Open in Xcode

1. Create a new **iOS App** project in Xcode named `GenesisWay`.
2. Replace the generated Swift files with files from `ios/GenesisWay`.
3. Ensure deployment target is iOS 17+ (or adjust APIs as needed).
4. Run on simulator.

## Portability notes

- Business logic lives in `GenesisStore` and models, not in view layers.
- Domain entities are `Codable` for easier API contract reuse on Android.
- Calendar provider abstraction is planned in next slices (Google happy path + Apple ICS compatibility).

## Automated TestFlight builds

This repo now includes Fastlane and a GitHub Actions workflow to automate iOS builds and TestFlight upload.

### What's included

- `ios/Gemfile`: Fastlane dependency
- `ios/fastlane/Fastfile`: `beta` lane (build + upload), `ci_build` lane (compile check)
- `ios/fastlane/Appfile`: app identifier wiring
- `.github/workflows/ios-testflight.yml`: CI workflow for PR build checks + TestFlight uploads

### One-time setup

1. In Xcode, set your Apple Team on the `GenesisWay` target signing settings (keep automatic signing enabled).
2. In GitHub repository settings, add Actions secrets:
	- `APP_STORE_CONNECT_KEY_ID`
	- `APP_STORE_CONNECT_ISSUER_ID`
	- `APP_STORE_CONNECT_PRIVATE_KEY` (paste the `.p8` key content, including BEGIN/END lines)
3. Add Actions variables:
	- `APPLE_TEAM_ID` (optional but recommended)
	- `APP_IDENTIFIER` (optional override, defaults to `com.genesisway.app`)

### Triggering uploads

- Manual: GitHub Actions -> `iOS TestFlight` -> Run workflow
- Automatic: push a tag like `ios-v1.0.0`

### Local command

From the `ios` folder:

```bash
bundle install
bundle exec fastlane beta
```
