#!/usr/bin/env bash
# .github/factory/health.sh: 7-day factory metrics, written to the job summary;
# opens, updates or closes one "Factory alert" issue. Critical alerts can pause the factory.
set -uo pipefail
since=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

prs=$(gh pr list --label factory --state all --limit 200 --json number,createdAt,mergedAt,labels,body,comments \
  | jq --arg s "$since" '[.[] | select(.createdAt >= $s)]')
total=$(jq length <<<"$prs")
auto=$(jq '[.[] | select(.mergedAt != null and ([.labels[].name] | index("needs-human") | not))] | length' <<<"$prs")
human=$(jq '[.[] | select([.labels[].name] | index("needs-human"))] | length' <<<"$prs")
overturned=$(jq '[.[] | select(.mergedAt != null and ([.labels[].name] | index("needs-human")))] | length' <<<"$prs")
attempts=$(jq '[.[] | .body | capture("factory-run (?<j>\\{[^}]*\\})") | .j | fromjson | .attempts]
  | if length > 0 then (add / length * 10 | round / 10) else 0 end' <<<"$prs")
disagree=$(jq '[.[] | .comments[].body | capture("factory-review (?<j>\\{.*\\}) -->") | .j | fromjson
  | select(.prosecutor.approve != .second.approve)] | length' <<<"$prs")
failed=$(gh run list --workflow factory-build.yml --created ">=$since" --limit 200 --json conclusion \
  | jq '[.[] | select(.conclusion == "failure")] | length')
escaped=$(gh issue list --label escaped-bug --state all --search "created:>=${since%%T*}" --json number -q length)
left=$(curl -s https://openrouter.ai/api/v1/key -H "Authorization: Bearer ${OPENROUTER_API_KEY:-}" \
  | jq -r '.data.free_model_daily_requests.remaining // "unknown"' 2>/dev/null || echo unknown)

alerts=()
[ "${HOLDOUTS:-}" = "failure" ] && alerts+=("CRITICAL: nightly holdouts failed against main")
[ "${SMOKE:-}" = "failure" ] && alerts+=("CRITICAL: production smoke probes failed")
[ "${escaped:-0}" -gt 0 ] && alerts+=("CRITICAL: $escaped escaped bug(s) reported this week")
if [ "$total" -ge 5 ]; then
  [ $((auto * 100 / total)) -lt 50 ] && alerts+=("First-pass success is $auto of $total PRs, below 50%")
  [ $((disagree * 100 / total)) -gt 30 ] && alerts+=("Reviewers disagreed on $disagree of $total PRs, above 30%")
fi
[ "$human" -ge 5 ] && [ $((overturned * 100 / human)) -gt 40 ] \
  && alerts+=("People merged $overturned of $human escalations: the reviewers may be too strict")
awk "BEGIN { exit !($attempts > 2.5) }" && alerts+=("Average attempts per spec is $attempts, above 2.5")
[ "$failed" -ge 3 ] && alerts+=("$failed build runs failed this week; check the logs for provider errors")

report=$(cat <<REPORT
| Metric (last 7 days) | Value |
| --- | --- |
| Factory PRs opened | $total |
| Auto-merged with no person involved | $auto |
| Escalated to needs-human | $human (merged by a person: $overturned) |
| Average agent attempts per spec | $attempts |
| Reviewer disagreements | $disagree |
| Failed build runs | $failed |
| Escaped bugs reported | $escaped |
| Nightly holdouts on main | ${HOLDOUTS:-skipped} |
| Production smoke probes | ${SMOKE:-skipped} |
| Free OpenRouter requests left now | $left |
REPORT
)
echo "$report" >> "$summary"

open=$(gh issue list --label factory-alert --state open --json number -q '.[0].number // empty')
if [ ${#alerts[@]} -gt 0 ]; then
  body="$(printf -- '- %s\n' "${alerts[@]}")"$'\n\n'"$report"
  if [ -n "$open" ]; then gh issue comment "$open" --body "$body"
  else gh issue create --title "Factory alert" --label factory-alert --assignee "$ASSIGNEE" --body "$body"; fi
  if [ -n "${DISCORD_WEBHOOK:-}" ]; then
    curl -s -H "Content-Type: application/json" \
      -d "$(jq -n --arg c "Factory alert: ${alerts[0]}" '{content: $c}')" "$DISCORD_WEBHOOK" > /dev/null
  fi
  if printf '%s\n' "${alerts[@]}" | grep -q '^CRITICAL' && [ -n "${FACTORY_ADMIN_PAT:-}" ]; then
    GH_TOKEN="$FACTORY_ADMIN_PAT" gh variable set FACTORY_ENABLED --body false && echo "Factory paused."
  fi
elif [ -n "$open" ]; then
  gh issue close "$open" --comment "All metrics are back inside their thresholds."$'\n\n'"$report"
fi
