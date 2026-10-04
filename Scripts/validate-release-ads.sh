#!/bin/bash
set -euo pipefail

if [[ "${EFFECTIVE_PLATFORM_NAME:-}" == "-maccatalyst" ]]; then
    exit 0
fi

if [[ "${CONFIGURATION:-}" != "Release" ]]; then
    exit 0
fi

config_path="${SRCROOT}/Panda Nap/Config/Release.xcconfig"
if [[ ! -s "$config_path" ]]; then
    echo "error: Release.xcconfig is required for Release builds." >&2
    exit 1
fi

validate_id() {
    local name="$1"
    local value="$2"
    local pattern="$3"
    if [[ ! "$value" =~ $pattern || "$value" == ca-app-pub-3940256099942544* ]]; then
        echo "error: $name must be a production AdMob ID in Release." >&2
        exit 1
    fi
}

validate_id "GADApplicationIdentifier" "${GADApplicationIdentifier:-}" '^ca-app-pub-[0-9]{16}~[0-9]{10}$'
validate_id "bannerViewAdUnitID" "${bannerViewAdUnitID:-}" '^ca-app-pub-[0-9]{16}/[0-9]{10}$'
validate_id "interstitialAdID" "${interstitialAdID:-}" '^ca-app-pub-[0-9]{16}/[0-9]{10}$'
