#!/usr/bin/env bash
# Selects the newest Xcode 26 on the macOS runner. App Store Connect accepts
# uploads only from Xcode 26 / iOS 26 SDK or later.
set -euo pipefail

xcode="$(ls -d /Applications/Xcode_26*.app 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$xcode" ]; then
  echo "No Xcode 26 on this runner:" >&2
  ls -d /Applications/Xcode*.app >&2 || true
  exit 1
fi
sudo xcode-select -s "$xcode/Contents/Developer"
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
