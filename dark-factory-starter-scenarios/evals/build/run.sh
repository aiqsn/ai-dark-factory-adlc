#!/usr/bin/env bash
# evals/build/run.sh "<model chain>"   e.g. "openrouter/<id>:free groq/openai/gpt-oss-120b"
# Run from the factory repo root with provider keys in the environment and aider installed.
# For each golden spec: check out its base commit in a scratch worktree (never pushed), let the
# agent build it, then run the hidden test. Prints pass rate and attempts used.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root=$(pwd); passed=0; total=0; attempts_total=0
for case in "$here"/*/; do
  name=$(basename "$case"); total=$((total + 1))
  base=$(cat "$case/base.txt"); work="/tmp/eval-build-$name"
  git worktree remove --force "$work" 2>/dev/null; git worktree add --detach "$work" "$base" > /dev/null
  (cd "$work" && npm ci --silent)
  attempt=0; ok=0
  for model in $1; do
    attempt=$((attempt + 1))
    (cd "$work" && timeout 15m aider --model "$model" --yes-always --no-auto-commits --no-gitignore \
      --no-show-model-warnings --map-tokens 1024 --read AGENTS.md --test-cmd "make test" --auto-test \
      --message-file "$case/spec.md" > "/tmp/eval-build-$name-$attempt.log" 2>&1)
    cp "$case/hidden.test.js" "$work/test/zz-hidden.test.js"
    if (cd "$work" && make test > /dev/null 2>&1); then ok=1; break; fi
    rm -f "$work/test/zz-hidden.test.js"
  done
  passed=$((passed + ok)); attempts_total=$((attempts_total + attempt))
  echo "$name: $([ $ok = 1 ] && echo pass || echo fail) after $attempt attempt(s)" >&2
  cd "$root" && git worktree remove --force "$work"
done
jq -n --argjson p "$passed" --argjson t "$total" --argjson a "$attempts_total" \
  '{pass_rate: (if $t > 0 then $p / $t else 0 end), mean_attempts: (if $t > 0 then $a / $t else 0 end), specs: $t}'
