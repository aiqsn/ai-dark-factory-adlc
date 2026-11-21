#!/usr/bin/env bash
# evals/reviewer/run.sh <github|openrouter> <model> <rubric-file>
# Run from the factory repo root, with this repo checked out at .holdout (as factory-evals.yml does).
# Scores a reviewer: catch rate on diffs with a planted defect, false rejects on clean diffs.
set -uo pipefail
cases="$(cd "$(dirname "$0")" && pwd)/cases"
caught=0; bugs=0; false_rejects=0; clean=0
for case in "$cases"/*/; do
  cp "$case/diff.patch" /tmp/diff.patch
  SPEC="$(cat "$case/spec.md")"; export SPEC
  approve=$(bash .github/factory/review.sh "$1" "$2" "$3" | jq -r '.approve // false' 2>/dev/null || echo false)
  if [ "$(jq -r .defect "$case/expected.json")" = "true" ]; then
    bugs=$((bugs + 1)); [ "$approve" != "true" ] && caught=$((caught + 1))
  else
    clean=$((clean + 1)); [ "$approve" != "true" ] && false_rejects=$((false_rejects + 1))
  fi
  echo "$(basename "$case"): approve=$approve" >&2
done
jq -n --argjson c "$caught" --argjson b "$bugs" --argjson f "$false_rejects" --argjson n "$clean" \
  '{catch_rate: (if $b > 0 then $c / $b else 0 end), false_reject_rate: (if $n > 0 then $f / $n else 0 end), cases: ($b + $n)}'
