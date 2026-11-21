# Dark Factory Starter

A working starter kit for the guide **Dark Factory ADLC on a Shoestring** (`docs/guide.html`). It is an issue-to-production coding pipeline that runs on GitHub Actions, the open-source aider agent and free model tiers, for $0 a month.

People write specs with AI and approve them by applying a label. An agent builds each spec, and hidden scenarios and two adversarial reviewers judge the result. Passing changes merge and deploy themselves in stages, and a nightly health check watches the whole thing.

This zip holds two repositories:

| Folder | Becomes | Visibility |
| --- | --- | --- |
| `dark-factory-starter/` | Your factory repo: the app, the workflows and the agent's rules | **Public**, so Actions minutes are free |
| `dark-factory-starter-scenarios/` | The hidden holdout scenarios and the evals | **Private**: the agent must never see it |

The scenarios repo must be named exactly `<factory-repo>-scenarios`, because the workflows look for it by that name.

## What's inside

```text
.github/
  ISSUE_TEMPLATE/spec.md          spec template; adds the "spec" label
  factory/
    review-rubric.md              standard reviewer rubric (second-family review)
    prosecutor.md                 adversarial reviewer: assumes the PR is wrong
    spec-redteam.md               attacks specs before anything is built
    review.sh                     sends one reviewer the spec + diff, prints a JSON verdict
    probes.sh                     reward-hacking probes: deleted tests, new skips, lost assertions
    smoke.sh                      read-only production probes (status, text, latency, version)
    health.sh                     7-day metrics; opens, updates or closes one alert issue
  workflows/
    factory-spec-review.yml       red-teams every new spec (Gemini)
    factory-build.yml             factory:build label -> aider across a model chain -> PR
    factory-verify.yml            guard, tests, probes, mutation, holdouts, 2 reviewers -> merge or escalate
    factory-queue.yml             hourly: starts the oldest factory:queued spec when idle
    factory-health.yml            nightly: holdouts + smoke probes + metrics + alerts
    factory-evals.yml             scores the reviewer against seeded defects; gates factory changes
    deploy.yml                    Cloudflare Workers: preview probe -> 10% canary -> 100%, auto-rollback
  workflows-optional/
    deploy-aws.yml                AWS Lambda alternative (OIDC, weighted alias canary)
src/index.js                      sample app: a tiny product-search API (Cloudflare Worker)
src/lambda.js                     adapter that runs the same app on AWS Lambda
test/index.test.js                unit tests (node --test)
probes/checks.txt                 the production probes, one per line
AGENTS.md                         the agent's standing instructions
Makefile                          install, test, mutation, dev, probe, package, deploy-first
stryker.config.json               mutation testing config
wrangler.jsonc                    Cloudflare config, with preview URLs on
scripts/setup-labels.sh           creates every label the factory uses
scripts/check-setup.sh            checks secrets, variables, labels and the scenarios repo
docs/guide.html                   the full guide
docs/example-specs/               worked spec examples, including a first spec for the sample app
```

## Try it locally first

You need Node 22, Python 3.10 or later, and `make`.

```bash
make install                 # npm ci
make test                    # 6 unit tests
make dev                     # app on http://127.0.0.1:8787 (leave running)
make probe                   # run the production probes against it, in another terminal
```

To run the hidden scenarios against your local app, put the two folders side by side and run `APP_URL=http://127.0.0.1:8787 bash ../dark-factory-starter-scenarios/run.sh`.

## Set it up on GitHub

This takes about an hour. The `gh` commands assume you're in the factory repo folder and signed in with `gh auth login`.

**1. Create both repositories.**

```bash
cd dark-factory-starter
git init -b main && git add -A && git commit -m "Dark factory starter"
gh repo create <you>/<app> --public --source . --push

cd ../dark-factory-starter-scenarios
git init -b main && git add -A && git commit -m "Hidden scenarios and evals"
gh repo create <you>/<app>-scenarios --private --source . --push
cd ../dark-factory-starter
```

**2. Get model keys.** OpenRouter is required; the rest are optional extra free quota. The guide's "Provider keys at a glance" table says where to create each one. GitHub Models needs no key: the workflows use the built-in token.

**3. Create two fine-grained personal access tokens** (GitHub → Settings → Developer settings):

- `FACTORY_PAT`: only the factory repo; Contents, Issues and Pull requests set to read and write. The factory must open and merge PRs with a PAT, because events from the built-in token don't start other workflows.
- `SCENARIOS_TOKEN`: only the scenarios repo; Contents read.

**4. Add secrets and variables.**

```bash
gh secret set OPENROUTER_API_KEY
gh secret set FACTORY_PAT
gh secret set SCENARIOS_TOKEN
gh secret set GEMINI_API_KEY                     # optional
gh secret set MISTRAL_API_KEY                    # optional
gh secret set GROQ_API_KEY                       # optional

gh variable set FACTORY_ENABLED --body true
gh variable set FACTORY_MODELS --body "openrouter/<free-model-id>:free mistral/<devstral-id> groq/openai/gpt-oss-120b"
gh variable set REVIEW_MODEL --body "<openrouter-free-model-id>:free"   # a different family from the implementer
gh variable set PROSECUTOR_MODEL --body "openai/gpt-4.1"                # a GitHub Models ID
gh variable set SPEC_REVIEW_MODEL --body "<gemini-flash-lite-model-id>" # optional
```

Free model lists change often. Copy exact IDs from each provider on the day you set up. In `FACTORY_MODELS`, prefix each one with its aider provider (`openrouter/`, `mistral/`, `groq/`, `gemini/`).

**5. Create the labels:** `bash scripts/setup-labels.sh`

**6. Protect `main`.** Under Settings → Rules, add a ruleset for `main`: require a pull request, require the status check `verify`, and block force pushes. Turn on "Allow auto-merge" under Settings → General.

**7. Check everything:** `bash scripts/check-setup.sh`

**8. Dry run.** File `docs/example-specs/04-sample-app-first-spec.md` as a new issue with the spec template. Read the red-team's comment, edit the spec if needed, then apply `factory:build` and watch the Actions tab. The PR is labelled `needs-human` until you set `AUTO_MERGE=true` (see Rollout).

## Turn on deploys

Deploys are off until you set `DEPLOY_ENABLED=true`. To deploy to Cloudflare Workers, which is free with no card:

1. Create a free Cloudflare account. Create an API token from the "Edit Cloudflare Workers" template.
2. Deploy once by hand, so a stable version exists to roll back to: `npx wrangler login && make deploy-first`.
3. Create a `production` environment under Settings → Environments, and allow deployments only from `main`. While you build trust, add yourself as a required reviewer.
4. Add the credentials as environment secrets, so build and verify jobs can never read them:
   ```bash
   gh secret set CLOUDFLARE_DEPLOY_TOKEN --env production
   gh secret set CLOUDFLARE_ACCOUNT_ID --env production
   gh secret set PROBE_API_KEY            # repository secret: read-only, and the nightly check needs it
   gh variable set APP_URL --body "https://dark-factory-starter.<your-subdomain>.workers.dev"
   gh variable set WORKER_NAME --body "dark-factory-starter"
   gh variable set DEPLOY_ENABLED --body true
   ```

Each merge to `main` then goes through these stages:

1. Upload the new version with no traffic, and probe its preview URL.
2. Send it 10% of traffic, and probe it for 3 minutes.
3. Promote it to 100%, and probe production.

A failure at any point returns traffic to the stable version and opens an alert issue.

**Deploying to AWS Lambda.** To use Lambda instead, move `.github/workflows-optional/deploy-aws.yml` into `.github/workflows/` and delete `deploy.yml`. Then follow "Deploying to AWS Lambda instead" in the guide. That covers the OIDC role, the `live` and `candidate` aliases with function URLs, and a budget alert. The handler is `src/lambda.handler` on the Node.js 22 runtime, and `make package` builds `dist/function.zip`.

## Alerts and evals

- **Nightly health check** (`factory-health.yml`, 06:17 UTC). It runs the holdouts and smoke probes against production and computes the 7-day metrics. Then it keeps one `Factory alert` issue open while anything is out of bounds. Set `ALERT_ASSIGNEE` if alerts shouldn't go to the repo owner. To let critical alerts pause the factory, add `FACTORY_ADMIN_PAT`: a fine-grained token with the repository's Variables permission set to read and write.
- **Evals** (`factory-evals.yml`, weekly and on every PR that changes `.github/factory/` or `AGENTS.md`). These score the reviewer against the seeded-defect cases in the scenarios repo. Make it a required check, so a prompt change that makes the reviewer worse can't merge. To test a new free model, run it by hand with `review_model` set.

## Rollout

Start with every merge manual, and switch on autonomy as the evidence comes in:

1. **Assisted.** Leave `AUTO_MERGE` unset. Every PR lands in `needs-human`, and you merge it.
2. **Trust the reviewers.** When their verdicts match yours on most PRs, set `AUTO_MERGE=true`. Low-risk PRs that pass every check then merge themselves.
3. **Trust deploys.** When the nightly holdouts and probes stay green, remove the required reviewer from the `production` environment.
4. **Dark.** Queue specs with `factory:queued`. The hourly drain builds them one at a time, and you work only on specs, scenarios and alerts.

## Safety notes

- The agent's prompt, rubrics, probes and workflows sit under protected paths. The verify job fails any PR that touches them.
- Issue text reaches shell commands only through `env:`, never through `${{ }}` inside `run:`.
- Free tiers may use prompts for training. Keep secrets, customer data and anything proprietary out of specs and code.
- Nothing here has run against your accounts yet. Do the dry run, and keep a person in the loop until the metrics say otherwise.
