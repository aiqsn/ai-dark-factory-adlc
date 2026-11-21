#!/usr/bin/env bash
# Runs every hidden scenario. Uses APP_URL when it is set (nightly, against production);
# otherwise starts the app from the factory checkout in the current directory (on PRs).
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
python3 -m pip install -q -r "$here/requirements.txt"

if [ -z "${APP_URL:-}" ]; then
  export WRANGLER_SEND_METRICS=false
  npx wrangler dev --ip 127.0.0.1 --port 8787 > /tmp/wrangler-dev.log 2>&1 &
  trap 'pkill -f "wrangler dev" 2>/dev/null || true' EXIT
  for _ in $(seq 1 90); do curl -sf http://127.0.0.1:8787/healthz > /dev/null && break; sleep 1; done
  curl -sf http://127.0.0.1:8787/healthz > /dev/null || { echo "::error::App did not start"; cat /tmp/wrangler-dev.log; exit 1; }
  export APP_URL=http://127.0.0.1:8787
fi

echo "Running hidden scenarios against $APP_URL"
python3 -m pytest -q "$here/scenarios"
