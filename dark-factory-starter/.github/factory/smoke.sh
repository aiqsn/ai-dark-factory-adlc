#!/usr/bin/env bash
# .github/factory/smoke.sh <base-url> [expected-git-sha] [extra request header]
# Read-only probes: every check in probes/checks.txt runs 3 times; any wrong status,
# missing text, slow response or wrong version fails the step.
set -uo pipefail
base="${1%/}"; sha="${2:-}"; header="${3:-}"; fail=0
args=(-s -o /tmp/probe-body -w '%{http_code} %{time_total}\n' --max-time 10)
[ -n "$header" ] && args+=(-H "$header")
[ -n "${PROBE_KEY:-}" ] && args+=(-H "X-API-Key: $PROBE_KEY")
summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
echo "| Probe | Status | Time | Result |" >> "$summary"; echo "| --- | --- | --- | --- |" >> "$summary"

if [ -n "$sha" ]; then
  curl "${args[@]}" "$base/version" > /dev/null
  got=$(tr -d '[:space:]' < /tmp/probe-body)
  if [ "$got" = "$sha" ]; then echo "| GET /version | match | | pass |" >> "$summary"
  else echo "| GET /version | got '$got' | | FAIL |" >> "$summary"; fail=1; fi
fi

while read -r method path want text; do
  { [ -z "$method" ] || [ "${method:0:1}" = "#" ]; } && continue
  text="${text//\"/}"
  for _ in 1 2 3; do
    read -r code secs < <(curl "${args[@]}" -X "$method" "$base$path")
    ok=pass
    [ "$code" = "$want" ] || ok=FAIL
    if [ -n "$text" ] && ! grep -qF -- "$text" /tmp/probe-body; then ok=FAIL; fi
    awk "BEGIN { exit !($secs > ${MAX_SECONDS:-1.5}) }" && ok=FAIL
    echo "| $method $path | $code | ${secs}s | $ok |" >> "$summary"
    [ "$ok" = pass ] || fail=1
  done
done < probes/checks.txt
exit $fail
