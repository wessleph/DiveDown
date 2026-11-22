#!/usr/bin/env bash
# Runs every integration test file on the iOS simulator given as $1.
#
# `flutter test` sometimes never finds the Dart VM service of the app on the
# CI simulator and waits forever („Waiting for VM Service port to be
# available…“, seen in runs 44826306020 and 45073291735; the same files pass
# in other runs). Each file therefore gets a time limit and one retry, so a
# lost connection costs minutes instead of the whole job. A real test
# failure still fails the step: it fails on the retry as well.
set -uo pipefail

udid="${1:?simulator UDID}"
limit="${2:-420}" # seconds per attempt; a normal run takes 2-3 min

run_once() {
  # perl alarm: macOS has no `timeout` command.
  perl -e 'alarm shift; exec @ARGV' "$limit" \
    flutter test "$1" -d "$udid" -r expanded
}

status=0
for test in integration_test/*_test.dart; do
  echo "::group::$test"
  if ! run_once "$test"; then
    echo "::warning::$test failed or hung, retrying once"
    if ! run_once "$test"; then
      echo "::error::$test failed twice"
      status=1
    fi
  fi
  echo "::endgroup::"
done
exit "$status"
