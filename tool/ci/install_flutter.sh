#!/usr/bin/env bash
# Installs the Flutter SDK named in .github/flutter-version.txt (ADR 0005)
# into $RUNNER_TEMP/flutter and puts it on PATH. A plain git clone of the
# release tag, so CI needs no third-party setup action (security.md G6).
set -euo pipefail

version="$(tr -d '[:space:]' < .github/flutter-version.txt)"
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Unexpected Flutter version: '$version'" >&2
  exit 1
fi
dir="${RUNNER_TEMP:?}/flutter"
git clone --quiet --depth 1 --branch "$version" https://github.com/flutter/flutter.git "$dir"
echo "$dir/bin" >> "${GITHUB_PATH:?}"
"$dir/bin/flutter" --disable-analytics >/dev/null
"$dir/bin/flutter" --version
