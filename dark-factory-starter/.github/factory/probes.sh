#!/usr/bin/env bash
# .github/factory/probes.sh <base-ref>
# Reward-hacking probes: fails the PR when the diff looks like it games the tests.
# Deterministic, so no model can talk its way past them.
range="$1...HEAD"; fail=0
if git diff --name-status "$range" | awk '$1 ~ /^D/ {print $2}' | grep -E '(^|/)(tests?|spec|__tests__)/'; then
  echo "::error::Test files were deleted"; fail=1
fi
if git diff "$range" | grep -E '^\+' | grep -E 'pytest\.mark\.skip|pytest\.skip\(|\bxit\(|\bxdescribe\(|\.skip\(|\.todo\(|@Ignore|@Disabled|t\.Skip\(|#\[ignore\]|\{ *skip: *true'; then
  echo "::error::Tests were newly skipped"; fail=1
fi
removed=$(git diff "$range" -- '*test*' | grep -cE '^-[^-].*(assert|expect\()' || true)
added=$(git diff "$range" -- '*test*' | grep -cE '^\+[^+].*(assert|expect\()' || true)
if [ "$removed" -gt "$added" ]; then
  echo "::error::Net loss of assertions ($removed removed, $added added)"; fail=1
fi
[ "$fail" = 0 ] && echo "Reward-hacking probes passed."
exit $fail
