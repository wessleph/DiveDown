#!/usr/bin/env bash
# Boots the first available iPhone simulator and writes its UDID to
# $GITHUB_OUTPUT as `udid`.
set -euo pipefail

udid="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for d in devices[runtime]:
        if d["name"].startswith("iPhone"):
            print(d["udid"])
            sys.exit(0)
sys.exit(1)
')"
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid" -b
echo "udid=$udid" >> "${GITHUB_OUTPUT:?}"
