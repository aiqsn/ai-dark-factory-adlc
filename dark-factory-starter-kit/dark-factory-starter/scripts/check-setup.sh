#!/usr/bin/env bash
# Checks which secrets, variables, labels and companion repo the factory can see.
# Run from the repo root after setup: bash scripts/check-setup.sh
set -uo pipefail
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
secrets=$(gh secret list --json name -q '.[].name' 2>/dev/null)
env_secrets=$(gh secret list --env production --json name -q '.[].name' 2>/dev/null)
vars=$(gh variable list --json name -q '.[].name' 2>/dev/null)
labels=$(gh label list --limit 200 --json name -q '.[].name')
missing=0
check() {  # kind name required(yes/no) note
  local kind=$1 name=$2 req=$3 note=$4 list
  case $kind in secret) list="$secrets"$'\n'"$env_secrets" ;; variable) list=$vars ;; label) list=$labels ;; esac
  if grep -qx "$name" <<<"$list"; then printf '  ok       %-9s %s\n' "$kind" "$name"
  elif [ "$req" = yes ]; then printf '  MISSING  %-9s %-26s %s\n' "$kind" "$name" "$note"; missing=$((missing + 1))
  else printf '  -        %-9s %-26s optional: %s\n' "$kind" "$name" "$note"; fi
}
echo "Factory setup check for $repo"
echo "Core"
check secret OPENROUTER_API_KEY yes "openrouter.ai/keys"
check secret FACTORY_PAT yes "fine-grained PAT: this repo; contents, issues, pull requests read/write"
check secret SCENARIOS_TOKEN yes "fine-grained PAT: $repo-scenarios; contents read"
check variable FACTORY_ENABLED yes "set to true to let builds run"
check variable FACTORY_MODELS yes "space-separated aider model IDs, cheapest quota first"
check variable REVIEW_MODEL yes "OpenRouter free model ID for the second-family reviewer"
check variable PROSECUTOR_MODEL yes "GitHub Models ID for the prosecutor, e.g. openai/gpt-4.1"
check variable AUTO_MERGE no "true once you trust the reviewers (rollout phase 3)"
echo "Extra model providers"
check secret GEMINI_API_KEY no "spec red-team and an extra implementer"
check secret MISTRAL_API_KEY no "extra implementer"
check secret GROQ_API_KEY no "extra implementer"
check variable SPEC_REVIEW_MODEL no "Gemini model ID for the spec red-team"
echo "Alerts"
check variable ALERT_ASSIGNEE no "who gets alert issues (defaults to the repo owner)"
check secret DISCORD_WEBHOOK no "extra ping for alerts"
check secret FACTORY_ADMIN_PAT no "lets critical alerts set FACTORY_ENABLED=false"
echo "Deploys"
check variable DEPLOY_ENABLED no "true to turn on the deploy workflow"
check variable APP_URL no "production URL, used by deploys and nightly probes"
check variable WORKER_NAME no "Cloudflare Worker name (matches wrangler.jsonc)"
check secret CLOUDFLARE_DEPLOY_TOKEN no "Cloudflare API token, Edit Workers template"
check secret CLOUDFLARE_ACCOUNT_ID no "Cloudflare account ID"
check secret PROBE_API_KEY no "read-only key the probes send as X-API-Key"
echo "Labels"
for l in spec factory:build factory:queued factory needs-human factory-alert escaped-bug; do
  check label "$l" yes "run scripts/setup-labels.sh"
done
echo "Companion repo"
if gh repo view "$repo-scenarios" --json visibility -q .visibility >/dev/null 2>&1; then
  vis=$(gh repo view "$repo-scenarios" --json visibility -q .visibility)
  [ "$vis" = PRIVATE ] && echo "  ok       repo      $repo-scenarios (private)" \
    || { echo "  MISSING  repo      $repo-scenarios must be PRIVATE (it is $vis)"; missing=$((missing + 1)); }
else
  echo "  MISSING  repo      $repo-scenarios (create it from the scenarios folder)"; missing=$((missing + 1))
fi
echo
[ "$missing" -eq 0 ] && echo "All required pieces are in place." || echo "$missing required item(s) missing."
exit $(( missing > 0 ))
