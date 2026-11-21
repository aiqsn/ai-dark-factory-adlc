#!/usr/bin/env bash
# .github/factory/review.sh <github|openrouter> <model> <rubric-file>
# Sends one reviewer the spec ($SPEC), the diff (/tmp/diff.patch) and its rubric; prints only a JSON verdict.
# Missing or broken output becomes {}, which the merge step treats as a reject.
set -uo pipefail
case "$1" in
  github)     url=https://models.github.ai/inference/chat/completions; key=${GITHUB_TOKEN:-} ;;
  openrouter) url=https://openrouter.ai/api/v1/chat/completions;       key=${OPENROUTER_API_KEY:-} ;;
  *) echo '{}'; exit 0 ;;
esac
[ -n "$key" ] && [ -n "${2:-}" ] || { echo '{}'; exit 0; }
jq -n --arg model "$2" --rawfile rubric "$3" --rawfile diff /tmp/diff.patch \
      --arg spec "${SPEC:0:4000}" '{
  model: $model,
  messages: [
    {role: "system", content: $rubric},
    {role: "user", content: ("SPEC:\n" + $spec + "\n\nDIFF:\n" + $diff +
      "\n\nReply with JSON only: {\"approve\": bool, \"risk\": \"low|medium|high\", \"summary\": string, \"defects\": [{\"file\": string, \"line\": number, \"problem\": string}]}")}
  ]}' \
| curl -s --max-time 120 "$url" -H "Authorization: Bearer $key" -H "Content-Type: application/json" -d @- \
| jq -r '.choices[0].message.content // ""' 2>/dev/null \
| python3 -c "import re,sys; t=sys.stdin.read(); m=re.search(r'\{.*\}', t, re.S); print(m.group(0) if m else '{}')"
