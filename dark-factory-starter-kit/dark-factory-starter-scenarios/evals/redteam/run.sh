#!/usr/bin/env bash
# evals/redteam/run.sh <gemini-model-id>   (needs GEMINI_API_KEY; run from the factory repo root)
# Runs the spec red-team on each weak spec and checks its critique names every known gap.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
found=0; total=0
for case in "$here"/*/; do
  critique=$(jq -n --arg model "$1" --rawfile rubric .github/factory/spec-redteam.md --rawfile spec "$case/spec.md" \
      '{model: $model, messages: [{role: "system", content: $rubric}, {role: "user", content: $spec}]}' \
    | curl -s https://generativelanguage.googleapis.com/v1beta/openai/chat/completions \
        -H "Authorization: Bearer $GEMINI_API_KEY" -H "Content-Type: application/json" -d @- \
    | jq -r '.choices[0].message.content // ""' | tr '[:upper:]' '[:lower:]')
  while read -r gap; do
    total=$((total + 1))
    if grep -qF -f <(jq -r '.any_of[]' <<<"$gap") <<<"$critique"; then found=$((found + 1))
    else echo "$(basename "$case"): missed '$(jq -r .name <<<"$gap")'" >&2; fi
  done < <(jq -c '.gaps[]' "$case/gaps.json")
done
jq -n --argjson f "$found" --argjson t "$total" '{gap_coverage: (if $t > 0 then $f / $t else 0 end), gaps: $t}'
