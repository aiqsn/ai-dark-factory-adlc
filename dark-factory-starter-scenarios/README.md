# Dark Factory Starter: hidden scenarios and evals

**Keep this repository private.** It holds the tests the coding agent must never see. If the agent could read them, it could learn to pass them without doing the work, which is exactly how agents game visible tests.

Name it `<factory-repo>-scenarios`. The factory's workflows check it out at `.holdout/` using the read-only `SCENARIOS_TOKEN`. The build job never gets that token.

```text
run.sh                          runs every scenario against APP_URL, or starts the app locally first
requirements.txt                pytest + requests
scenarios/
  conftest.py                   tiny read-only client (sends PROBE_KEY as X-API-Key when set)
  test_shopper_search.py        8 holdout scenarios, written the way a shopper uses search
evals/
  baseline.json                 the reviewer scores a factory change must not fall below
  reviewer/run.sh               scores a reviewer: catch rate and false rejects
  reviewer/cases/NNN-*/         spec.md, diff.patch, expected.json (3 planted defects, 1 clean)
  redteam/run.sh                checks the spec red-team names every known gap in a weak spec
  redteam/001-rate-limit/       a weak spec and the gaps a good critique must find
  build/run.sh                  replays golden specs through the agent and runs hidden tests
  build/001-top-three/          spec.md, hidden.test.js, base.txt
```

## Where each part runs

| What | Workflow (in the factory repo) | When |
| --- | --- | --- |
| `run.sh` with no `APP_URL` | `factory-verify.yml` | Every factory PR: starts the PR's code with `wrangler dev` |
| `run.sh` with `APP_URL` | `factory-health.yml` | Nightly, against production |
| `evals/reviewer/run.sh` | `factory-evals.yml` | Weekly, and on PRs that change the factory's prompts |
| `evals/redteam/run.sh`, `evals/build/run.sh` | Run by hand, or add your own workflow | Before switching models |

## Writing good holdouts

- **Write them as a user would act**, not by restating the acceptance criteria. A holdout should catch a build that satisfies the letter of the spec but not its intent.
- **Keep them read-only.** The nightly run hits production.
- **Grow them from real failures.** Each escaped bug becomes a new scenario and a new reviewer eval case. Each spec that confused the agent becomes a golden spec in `evals/build/`.
- **Keep them fast.** The whole suite runs on every factory PR.

## Adding eval cases

- **Reviewer cases.** Add a folder under `evals/reviewer/cases/` with the spec, a unified diff and `expected.json` containing `{"defect": true}` or `{"defect": false}`. Keep at least one clean case for every few defect cases, so a reviewer that rejects everything doesn't score well. After you add cases, re-run the eval and update `baseline.json` in the same commit.
- **Golden specs.** Set `base.txt` to the commit just before the feature was built, so the agent starts from the same place a real build did. `HEAD` works only while the feature doesn't exist yet.

## Local use

```bash
# from the factory repo folder, with this repo beside it
APP_URL=http://127.0.0.1:8787 bash ../dark-factory-starter-scenarios/run.sh   # against `make dev`
bash ../dark-factory-starter-scenarios/run.sh                                  # starts the app itself
```
