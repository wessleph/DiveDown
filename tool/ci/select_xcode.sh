#!/usr/bin/env bash
# Selects the newest Xcode 27 on the runner (image `xcode-27`). From April
# 2027 App Store Connect accepts uploads only from Xcode 27 / iOS 27 SDK or
# later (ITMS-90725, T34).
set -euo pipefail

xcode="$(ls -d /Applications/Xcode_27*.app 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$xcode" ]; then
  echo "No Xcode 27 on this runner:" >&2
  ls -d /Applications/Xcode*.app >&2 || true
  exit 1
fi
sudo xcode-select -s "$xcode/Contents/Developer"
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
