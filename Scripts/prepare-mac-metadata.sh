#!/bin/bash
set -euo pipefail

if [[ "${EFFECTIVE_PLATFORM_NAME:-}" != "-maccatalyst" ]]; then
    exit 0
fi

info_path="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
resources_path="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

# Mac Catalyst does not link the advertising or consent SDKs.
for key in GADApplicationIdentifier bannerViewAdUnitID interstitialAdID SKAdNetworkItems NSUserTrackingUsageDescription; do
    /usr/libexec/PlistBuddy -c "Delete :${key}" "$info_path" 2>/dev/null || true
done

for locale in en zh-Hans zh-Hant; do
    localized_info="${resources_path}/${locale}.lproj/InfoPlist.strings"
    if [[ -f "$localized_info" ]]; then
        /usr/libexec/PlistBuddy -c 'Delete :NSUserTrackingUsageDescription' "$localized_info" 2>/dev/null || true
    fi
done

# Build configuration files are inputs, not resources for the shipped app.
for config in Debug Production Release; do
    rm -f "${resources_path}/${config}.xcconfig"
done
