#!/usr/bin/env bash
# Creates (or updates) every label the factory uses. Run once from the repo root: bash scripts/setup-labels.sh
set -euo pipefail
while IFS='|' read -r name color description; do
  gh label create "$name" --color "$color" --description "$description" --force
done <<'LABELS'
spec|0e8a16|A factory spec; the spec red-team comments on it when opened
factory:build|1d76db|Approves the spec and starts a factory build
factory:queued|c5def5|Waiting for the hourly queue drain to start its build
factory|5319e7|Pull request opened by the factory
needs-human|d93f0b|Escalated: a person must review or decide
factory-alert|b60205|Opened by the nightly health check or a rolled-back deploy
escaped-bug|e11d21|A bug that reached main or production past every gate
LABELS
echo "Labels ready."
