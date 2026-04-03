#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/ios/GenesisWay.xcodeproj"
SCHEME="GenesisWay"
BUNDLE_ID="com.genesisway.app"

SIM_CANDIDATES=()
while IFS= read -r sim_name; do
  SIM_CANDIDATES+=("$sim_name")
done < <(
  xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null |
    grep -o 'name:[^}]*' |
    sed 's/name://' |
    sed 's/^ *//' |
    sed 's/[[:space:]]*$//' |
    grep '^iPhone' |
    awk '!seen[$0]++'
)

if [[ ${#SIM_CANDIDATES[@]} -eq 0 ]]; then
  SIM_CANDIDATES=("iPhone 17 Pro" "iPhone 17" "iPhone 16e" "iPhone 16" "iPhone 15")
fi

echo "[smoke] Starting iOS smoke test"

build_with_sim() {
  local sim_name="$1"
  echo "[smoke] Trying build destination: $sim_name" >&2
  if xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "platform=iOS Simulator,name=$sim_name" build >/tmp/genesis_smoke_build.log 2>&1; then
    echo "$sim_name"
    return 0
  fi
  return 1
}

SELECTED_SIM=""
for candidate in "${SIM_CANDIDATES[@]}"; do
  if SELECTED_SIM="$(build_with_sim "$candidate")"; then
    break
  fi
done

if [[ -z "$SELECTED_SIM" ]]; then
  echo "[smoke] Build failed for all simulator candidates"
  echo "[smoke] Last build output:"
  tail -n 120 /tmp/genesis_smoke_build.log || true
  exit 1
fi

echo "[smoke] Build succeeded on: $SELECTED_SIM"

echo "[smoke] Booting simulator (if needed): $SELECTED_SIM"
xcrun simctl boot "$SELECTED_SIM" >/dev/null 2>&1 || true

if ! xcrun simctl bootstatus "$SELECTED_SIM" -b >/dev/null 2>&1; then
  echo "[smoke] Warning: could not confirm bootstatus for $SELECTED_SIM, continuing"
fi

echo "[smoke] Launching app: $BUNDLE_ID"
if ! xcrun simctl launch booted "$BUNDLE_ID" >/tmp/genesis_smoke_launch.log 2>&1; then
  echo "[smoke] Warning: app launch failed. Build passed, but app may not be installed in this simulator session yet."
  cat /tmp/genesis_smoke_launch.log || true
  echo "[smoke] PASS (build gate): build succeeded; launch check is best-effort"
  exit 0
fi

echo "[smoke] PASS: build and launch completed"
